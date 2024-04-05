% Clear environment and close all figures
clc;
close all;
clear;

% Define selected spreading factor index
sf_selected_list = [6];

% Define coefficient and packet list for processing
coeff_selected_list = 2:5;
n_packet_list = {0, [1:10], 0, [1:5], 0, [1:5]};
n_mixed_packet_list = 1:100;
pos_list = {[2:7, 9, 10], [2, 4:7, 9, 10], [1:2, 4:5, 9:10], [3, 5, 9], [], [5, 9]};

% Modulation & sampling parameters from `param_configs`
fs = param_configs(3); % Sample rate
bw = param_configs(2); % LoRa bandwidth
sf_list = [7, 8, 9, 10, 11, 12];
CurvingLoRa = {[1], [1, 0], [-1, 2], [1, 0, 0, 0], [-1, 4, -6, 4]};
n_preamble_upchirp = param_configs(5);

% Define constants
head_len = 12.25;
correlation_threshold = 3;
preamble_peak_threshold = 3;
groundtruth_dir = 'non-linear-signal/';

% Iterate over selected spreading factor(s)
for sf_index = sf_selected_list
    sf_selected = sf_list(sf_index);
    nsamp = 2^sf_selected * fs / bw;

    n_packet_list_selected = n_packet_list{sf_index};
    pos_selected_list = pos_list{sf_index};
    
    % Initialize matrices to store results
    ans_matrix = zeros(length(CurvingLoRa), length(n_packet_list_selected), length(n_mixed_packet_list));
    ans_matrix_count = zeros(length(CurvingLoRa), length(n_packet_list_selected), length(n_mixed_packet_list));
    groundtruth_path = fullfile(groundtruth_dir, num2str(sf_selected));

    data_path = 'CuvringLoRa_12_5/';
    feature_data_list = dir(fullfile(data_path));
    n_feature_data_list = length(feature_data_list);

    % Process each feature data file
    for feature_data_index = 1:n_feature_data_list
        feature_data_name = feature_data_list(feature_data_index).name;

        % Skip . and .. directories
        if ismember(feature_data_name, {'.', '..'})
            continue;
        end

        % Parse file name for parameters
        raw_data_name_components = strsplit(feature_data_name, '_');
        sf = str2double(raw_data_name_components{1});
        coeff_index = str2double(raw_data_name_components{2});
        packet_index = str2double(raw_data_name_components{3});
        n_mixed_packets = str2double(raw_data_name_components{5});
        n_mixed_packets_index = find(n_mixed_packet_list == n_mixed_packets);
        
        % Filter out irrelevant data
        if sf ~= sf_selected || ~ismember(packet_index, n_packet_list_selected) || ~ismember(coeff_index, coeff_selected_list) || ~ismember(n_mixed_packets, n_mixed_packet_list)
            continue;
        end

        coeff = CurvingLoRa{coeff_index};

        try
            % Load and process the signal
            fileID = fopen(fullfile(data_path, feature_data_name), 'r');
            [mdata, count_data_read] = io_read_line(fileID);
            pos_index = 1; % Note: `pos_index` does not change in this snippet
            pos_index_named = mod(pos_index - 1, length(pos_selected_list)) + 1;
            pos = pos_selected_list(pos_index_named);
            
            % Load groundtruth and decode frame
            groundtruth_file = sprintf('%d_%d_%d_%s_gt.mat', sf, pos, coeff_index, raw_data_name_components{6});
            load(fullfile(groundtruth_path, groundtruth_file));
            
            frame_length = ceil(length(final_data_frequency_groundtruth) - n_preamble_upchirp + 1) * nsamp;
            sig = mdata(1:frame_length);
            [code_list, n_payload_corrected] = frame_decoder_comp_largescale(sig, sf, coeff, final_data_frequency_groundtruth);
            
            % Update results
            ans_matrix_count(coeff_index, packet_index, n_mixed_packets_index) = length(final_data_frequency_groundtruth) - n_preamble_upchirp;
            ans_matrix(coeff_index, packet_index, n_mixed_packets_index) = n_payload_corrected;
            fprintf('File %s has %d corrected of %d\n', feature_data_name, n_payload_corrected, length(final_data_frequency_groundtruth) - n_preamble_upchirp);
        catch e
            fprintf(1, 'Error in %s: %s\n', feature_data_name, e.message);
        end
    end

    % Save results
    save(fullfile('collision', sprintf('nonlinear_sir20_12_5_sf%d.mat', sf_selected)), 'ans_matrix', 'ans_matrix_count', 'pos_selected_list');
end

fprintf('Experiment Finished!\n');

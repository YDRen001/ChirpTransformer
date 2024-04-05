clear;
clc;
close all;

% Initialization of configuration variables
sf_selected_list = [6]; % Indices of selected spreading factors to be processed
coeff_selected_list = [1, 2, 3, 4, 5]; % Indices of coefficients for signal curving
n_packet = 5; % Number of packet simulations to generate
% List of positions for signal analysis, varies by spreading factor
pos_list = {[2:7, 9, 10], [2, 4:7, 9, 10], [1:2, 4:5, 9:10], [3, 5, 9], [], [9]};
sf_list = [7, 8, 9, 10, 11, 12]; % Available spreading factors
% CurvingLoRa coefficients for different chirp modifications
CurvingLoRa = {[1], [1, 0], [-1, 2], [1, 0, 0, 0], [-1, 4, -6, 4]};
DEBUG = true; % Debug flag to enable additional output for troubleshooting
% Assume param_configs is previously defined array containing system parameters
bw = param_configs(2); % Bandwidth parameter
fs = param_configs(3); % Sampling frequency
fft_scaling = param_configs(4); % Scaling factor for FFT operations
n_preamble_upchirp = param_configs(5); % Number of preamble upchirps

n_packet_instances = 30; % Number of different packet instances to consider
n_mixed_packet_list = 5:5:5; % List specifying how packets are mixed, seems constant but may need adjustment

correlation_threshold = 3; % Threshold for signal correlation detection
head_len = 12.25; % Length of signal head in units
symbol_per_packet = ceil(head_len + 20 + 1); % Total symbols per packet, rounded up
sir_range_min = -20; % Minimum signal-to-interference ratio
sir_range_max = 0; % Maximum signal-to-interference ratio


% Loop through each selected spreading factor index
for sf_index = sf_selected_list
    sf = sf_list(sf_index); % Current spreading factor
    pos_selected_list = pos_list{sf_index}; % Positions selected for current SF
    % Setup directory paths for data saving/loading
    data_dir = fullfile(param_configs(1), 'non-linear-signal/');
    file_path = fullfile(data_dir, 'CuvringLoRa_12_5/');

    % Ensure the output directory exists
    if ~exist(file_path, 'dir')
        mkdir(file_path);
    end
    
    nsamp_per_symbol = 2^sf * fs / bw; % Samples per symbol for the current SF
    frame_length = symbol_per_packet * nsamp_per_symbol; % Frame length in samples
    
    % Loop through each coefficient index selected for processing
    for coeff_index = coeff_selected_list
        coeff = CurvingLoRa{coeff_index}; % Coefficient for current index
        packet_index = 1; % Initialize packet processing
        
        % Process packets up to the specified count
        while packet_index <= n_packet
            packet_interval = 2; % Interval between packets for mixing simulation
            try
                n_mixed_packet_id = []; % IDs of packets chosen for mixing
                n_mixed_pos_id = []; % Positions corresponding to mixed packets
                
                % Ensure enough packets are selected for mixing
                while length(n_mixed_packet_id) < max(n_mixed_packet_list)
                    packet_id_selected = randi([1, n_packet_instances], 1); % Randomly select a packet instance
                    pos_id = pos_selected_list(mod(length(n_mixed_packet_id), length(pos_selected_list)) + 1); % Select position ID cyclically
                    
                    % Construct file names for signal and ground truth data
                    file_name = sprintf('%s%d_%d_%d_%d', data_dir, sf, pos_id, coeff_index, packet_id_selected);
                    final_data_frequency_groundtruth_file = sprintf('%s_gt.mat', file_name);
                    
                    % Check if both the signal file and its ground truth exist
                    if exist(file_name, 'file') && exist(final_data_frequency_groundtruth_file, 'file')
                        n_mixed_packet_id = [n_mixed_packet_id, packet_id_selected]; % Add packet ID to list
                        n_mixed_pos_id = [n_mixed_pos_id, pos_id]; % Add position ID to list
                    end
                end
                
                % Processing the selected packet
                key_words_prefix = [num2str(sf), '_', num2str(n_mixed_pos_id(1)), '_', num2str(coeff_index), '_'];
                fileID = fopen([data_dir, key_words_prefix, num2str(n_mixed_packet_id(1))], 'r');
                [target_chirp, count_data_read] = io_read_line(fileID);
                [frame_sign, frame_st_target] = frame_detect2(target_chirp, n_preamble_upchirp, sf, correlation_threshold);
                target_chirp_only = target_chirp(frame_st_target:frame_st_target + frame_length);
                
                % Signal synchronization and correction
                [sig_raw, toff, foff] = frame_sync2(target_chirp_only, sf);
                t = (0:numel(sig_raw) - 1) / fs;
                sig = sig_raw .* exp(-1i * 2 * pi * foff * t);
                
                payload_woCFO_target = sig(head_len * nsamp_per_symbol + 1:end);
                
                load([data_dir, key_words_prefix, num2str(n_mixed_packet_id(1)), '_gt.mat']);
                final_data_frequency_groundtruth = final_data_frequency_groundtruth(9:end);
                [~, n_payload_corrected] = frame_decoder_comp_test2(payload_woCFO_target, sf, coeff, final_data_frequency_groundtruth);
                
                if n_payload_corrected ~= length(final_data_frequency_groundtruth)
                    disp([key_words_prefix, num2str(n_mixed_packet_id(1))]);
                    continue;
                end

                % Initializing the mixed signal
                mixed_signal = [payload_woCFO_target, zeros(1, (packet_interval + 1) * nsamp_per_symbol)];
                
                % Assume this loop is part of a larger processing block where 'payload_woCFO_target' and other variables are already defined
                for ii = 1
                    % Select the current packet ID and its corresponding position ID from the mixed packets
                    packet_id_selected = n_mixed_packet_id(ii);
                    pos_id_selected = n_mixed_pos_id(ii);
                    % Generate a list excluding the current coefficient index to create interference combinations
                    j = [1 : coeff_index - 1, coeff_index + 1 : 5];
                    % Compute combinations of the remaining coefficients for interference simulation
                    comb_index = nchoosek(j, 5);
                    for kk = 1:2000
                    % Initialize the mixed signal with the target payload and additional zeros for mixing
                    mixed_signal = [payload_woCFO_target, zeros(1, (packet_interval + 1) * nsamp_per_symbol)];
                    % Loop over the first 4 combinations of interference coefficients
                    for inter_index = [comb_index(1), comb_index(2), comb_index(3), comb_index(4)]
                        
                        % Construct the prefix for file names based on current SF, position, and interference index
                        key_words_prefix = [num2str(sf), '_', num2str(pos_id_selected), '_', num2str(inter_index), '_'];
                        % Open the file containing the interfered chirp signal
                        fileID = fopen([data_dir, key_words_prefix, num2str(packet_id_selected)], 'r');
                        % Read the interfered chirp signal line from the file
                        [interfered_chirp, count_data_read] = io_read_line(fileID);
                        % Detect the start of the frame in the interfered chirp signal
                        [frame_sign, frame_st_interference] = frame_detect2(interfered_chirp, n_preamble_upchirp, sf, correlation_threshold);
                        % Isolate the interfered chirp signal based on the detected frame start
                        interfered_chirp_only = interfered_chirp(frame_st_interference:frame_st_interference + frame_length);
                        
                        % Extract the payload from the interfered chirp, removing the Cyclic Frequency Offset (CFO)
                        payload_woCFO = interfered_chirp_only(head_len * nsamp_per_symbol + 1:end);
                        % Randomly select a Signal-to-Interference Ratio (SIR) value for mixing
                        SIR = randi([sir_range_min, sir_range_max], 1);
                        % Calculate a random starting index for the interference signal within the mixed signal
                        initial_index = packet_interval * nsamp_per_symbol + randi([floor(nsamp_per_symbol * 0), ceil(nsamp_per_symbol * 1)], 1);
                        % Shift the interfered payload to the calculated starting index within the mixed signal
                        interfered_chirp_only_sum_shifted = [zeros(1, initial_index), payload_woCFO, zeros(1, length(mixed_signal) - length(payload_woCFO) - initial_index)];
                        % Calculate the amplitude gain required for the interfered signal to achieve the desired SIR
                        amp_interfere_gain = utils.interfere_gain_to_mix_signal(payload_woCFO_target, payload_woCFO, SIR);
                        % Add the scaled interfered signal to the mixed signal
                        mixed_signal = mixed_signal + amp_interfere_gain * interfered_chirp_only_sum_shifted;
                    end
                
                    % Construct the final file name for saving the mixed signal
                    key_words_prefix = [num2str(sf), '_', num2str(coeff_index), '_', num2str(kk), '_'];
                    key_words = [key_words_prefix, num2str(packet_index), '_', num2str(5), '_',  key_words_surfix_packet];
                    % Write the mixed signal to the specified file
                    io_write_iq([file_path, key_words], mixed_signal);
                    end
                end
                packet_index = packet_index + 1;
            catch e
                % Error handling
                fprintf(1, 'The identifier was:\n%s', e.identifier);
                fprintf(1, 'There was an error! The message was:%s\n', e.message);
                disp(n_mixed_packet_id);
            end
        end
    end
end

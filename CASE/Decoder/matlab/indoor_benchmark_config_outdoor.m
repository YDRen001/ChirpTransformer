clc;
clear;
SF_config_list = 9:12;
pos_list = 1:33;

data_root = '/mnt/home/renyidon/data/mobicom2021_server/';
data_dir = 'lora_outdoor_new/';

feature_dir = [data_root, data_dir];

feature_data_list = dir(fullfile(feature_dir));
n_feature_data_list = size(feature_data_list, 1);

Fs = 1000000; % sample rate
BW = 125000;

SF_std = max(SF_config_list);
SF_label_offset = min(SF_config_list) - 1;
fft_scaling = 20;

nsamp = Fs * 2^SF_std / BW;

chirp_down_list = cell(4, 1);

pkt_list=1:50;

for ii = 1:length(chirp_down_list)
    SF_selected = SF_config_list(ii);
    %     chirp_down_list{ii}=utils.gen_multiple_symbol(zeros(1, 2^(4-ii)), true, Fs, BW, SF_selected);
    chirp_down_list{ii} = utils.gen_symbol(0, true, Fs, BW, SF_selected);
end

error_matrix = zeros(length(pos_list), length(pkt_list));
error_matrix_count = zeros(length(pos_list), length(pkt_list));

for feature_data_index = 1:n_feature_data_list
    feature_data_name = feature_data_list(feature_data_index).name;

    if strcmp(feature_data_name, '.') == 1 || strcmp(feature_data_name, '..') == 1
        continue;
    end

    raw_data_name_components = strsplit(feature_data_name(1:end - 4), '_');
    pos_index = str2num(raw_data_name_components{7});
    pkt_index = str2num(raw_data_name_components{9});
    SF_value = str2num(raw_data_name_components{4});

    if (~ismember(SF_value, SF_config_list) ||~ismember(pos_index, pos_list)||~ismember(pkt_index, pkt_list))
        continue;
    end

    disp(feature_data_name);
    
    load([feature_dir, feature_data_name]);

    if (length(chirp) ~= 2^12 * Fs / BW)
        feature_data_name
        continue;
    end

    chirp = chirp(1:nsamp);

    SF_label = SF_value - SF_label_offset;

    peak_value = -100;
    peak_index = 0;

    for ii = 1:size(chirp_down_list, 1)
        n_chirp = 2^(4 - ii);

        for jj = 1:n_chirp
            single_len = length(chirp) / n_chirp;
            chirp_raw_single = chirp((jj - 1) * single_len + 1:jj * single_len);
            chirp_dechirp = chirp_raw_single .* chirp_down_list{ii};
            %                 chirp_dechirp_spectrum=utils.spectrum(chirp_dechirp);
            chirp_fft_raw_single = (fft(chirp_dechirp, nsamp * fft_scaling));

            if jj == 1
                % chirp_peak_overlap = abs(chirp_abs_alias(chirp_fft_raw_single, Fs / BW));
                chirp_peak_overlap = abs(chirp_comp_alias(chirp_fft_raw_single, Fs / BW));
            else
                % chirp_peak_overlap = chirp_peak_overlap + abs(chirp_abs_alias(chirp_fft_raw_single, Fs / BW));
                chirp_peak_overlap = chirp_peak_overlap+abs(chirp_comp_alias(chirp_fft_raw_single, Fs / BW));
            end

        end

        pk_height_overlap = max(chirp_peak_overlap([1:5 * fft_scaling, end - 5 * fft_scaling:end]));
        % [pk_height_overlap, pk_index_overlap] = max(chirp_peak_overlap);

        if (pk_height_overlap > peak_value)
            peak_value = pk_height_overlap;
            peak_index = ii;
        end

    end

    error_matrix(pos_index, pkt_index) = error_matrix(pos_index, pkt_index) + (SF_label == peak_index);
    error_matrix_count(pos_index, pkt_index) = error_matrix_count(pos_index, pkt_index) + 1;
end

error_matrix = error_matrix ./ error_matrix_count;
feature_path = [data_root, 'nsdi_benchmark/', 'benchmark_outdoor_config_12_125000_5_comp.mat'];
save(feature_path, 'error_matrix');

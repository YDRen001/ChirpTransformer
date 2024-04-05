clc;
clear;
close all;

% generate multi-path signal

fig_switch = false;
% data_root = 'D:\mobicom2021_server\';
data_root = '/mnt/home/renyidon/data/mobicom2021_server/';
data_dir = 'lora_outdoor_trace/';
feature_dir = [data_root, data_dir];

feature_data_list = dir(fullfile(feature_dir));
n_feature_data_list = size(feature_data_list, 1);

SNR_minimal = -40;
SNR_list = SNR_minimal:0;
instance_list=1:35;

Fs = 1000000; % sample rate
BW = 125000;

SF_config_list = 9:12;
SF_std = max(SF_config_list);
SF_label_offset = min(SF_config_list)-1;

nsamp = Fs * 2^SF_std / BW;

chirp_down_list = cell(4,1);
for ii=1:length(chirp_down_list)
    SF_selected=SF_config_list(ii);
    chirp_down_list{ii}=utils.gen_multiple_symbol(zeros(1, 2^(4-ii)), true, Fs, BW, SF_selected);
end

error_matrix = zeros(10, 1);
error_matrix_count = zeros(10, 1);

for feature_data_index = 1:n_feature_data_list
    % try
        feature_data_name = feature_data_list(feature_data_index).name;

        if strcmp(feature_data_name, '.') == 1 || strcmp(feature_data_name, '..') == 1
            continue;
        end

        raw_data_name_components = strsplit(feature_data_name(1:end - 4), '_');
        
        if (~ismember(str2num(raw_data_name_components{4}), SF_config_list)||~ismember(str2num(raw_data_name_components{3}), SNR_list)||~ismember(str2num(raw_data_name_components{6}), instance_list))
            continue;
        end

        position_index = str2num(raw_data_name_components{7});
        load([feature_dir, feature_data_name]);
        
        if (length(chirp) ~= 2^12 * Fs / BW)
            feature_data_name
            continue;
        end
        chirp=chirp(1:nsamp);

        SF_label = str2num(raw_data_name_components{4}) - SF_label_offset;

        peak_value = -100;
        peak_index = 0;

        for ii = 1:size(chirp_down_list, 1)
            chirp_dechirp = chirp .* chirp_down_list{ii};
            chirp_fft_raw = (fft(chirp_dechirp, nsamp * 10));

            chirp_peak_overlap = abs(chirp_abs_alias(chirp_fft_raw, Fs / BW));
            [pk_height_overlap, pk_index_overlap] = max(chirp_peak_overlap([1:100, end - 100:end]));
            % [pk_height_overlap, pk_index_overlap] = max(chirp_peak_overlap);

            if (pk_height_overlap > peak_value)
                peak_value = pk_height_overlap;
                peak_index = ii;
            end

        end

        error_matrix(position_index, 1) = error_matrix(position_index, 1) + (SF_label == peak_index);
        error_matrix_count(position_index, 1) = error_matrix_count(position_index, 1) + 1;
    % catch
    %     warning('Problem using function.  Assigning a value of 0.');
    %     continue;
    % end

end

error_matrix = error_matrix ./ error_matrix_count;
feature_path = [data_root, 'benchmark/', 'benchmark_outdoor_config_dechirp_',num2str(SF_std),'_max.mat'];
save(feature_path, 'error_matrix');
%     end
% end

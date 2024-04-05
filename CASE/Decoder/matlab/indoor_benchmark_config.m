% clc;
% clear;
% SF_config_list = 9:12;
% SNR_list=[-40:0];

data_root = '/mnt/home/renyidon/data/mobicom2021_server/';
% data_dir = 'indoor_cross_domain/';
% data_dir = 'simu_config/';
data_dir = 'lora_indoor_config/';

feature_dir = [data_root, data_dir];

feature_data_list = dir(fullfile(feature_dir));
n_feature_data_list = size(feature_data_list, 1);

instance_list=1:50;
code_list=0:5;

Fs = 1000000; % sample rate
BW = 125000;

SF_std = max(SF_config_list);
SF_label_offset = min(SF_config_list)-1;
fft_scaling = 20;

nsamp = Fs * 2^SF_std / BW;

chirp_down_list = cell(4,1);
for ii=1:length(chirp_down_list)
    SF_selected=SF_config_list(ii);
%     chirp_down_list{ii}=utils.gen_multiple_symbol(zeros(1, 2^(4-ii)), true, Fs, BW, SF_selected);
    chirp_down_list{ii}=utils.gen_symbol(0, true, Fs, BW, SF_selected);
end

error_matrix = zeros(length(SNR_list), 1);
error_matrix_count = zeros(length(SNR_list), 1);

for feature_data_index = 1:n_feature_data_list
    % try
        feature_data_name = feature_data_list(feature_data_index).name;
        
        if strcmp(feature_data_name, '.') == 1 || strcmp(feature_data_name, '..') == 1
            continue;
        end

        raw_data_name_components = strsplit(feature_data_name(1:end - 4), '_');
        
        if (~ismember(str2num(raw_data_name_components{1}), code_list)||~ismember(str2num(raw_data_name_components{4}), SF_config_list)||~ismember(str2num(raw_data_name_components{3}), SNR_list)||~ismember(str2num(raw_data_name_components{6}), instance_list))
            continue;
        end
        disp(feature_data_name);
        [~,SNR_index]=find(str2num(raw_data_name_components{3})==SNR_list);
        load([feature_dir, feature_data_name]);
        
        if (length(chirp) ~= 2^12 * Fs / BW)
            feature_data_name
            continue;
        end
        chirp=chirp(1:nsamp);
        
        SF_value=str2num(raw_data_name_components{4});
        SF_label = SF_value - SF_label_offset;


        peak_value = -100;
        peak_index = 0;

        for ii = 1:size(chirp_down_list, 1)
            n_chirp=2^(4-ii);
            for jj=1:n_chirp
                single_len=length(chirp)/n_chirp;
                chirp_raw_single=chirp((jj-1)*single_len+1:jj*single_len);
                chirp_dechirp = chirp_raw_single .* chirp_down_list{ii};
%                 chirp_dechirp_spectrum=utils.spectrum(chirp_dechirp);
                chirp_fft_raw_single = (fft(chirp_dechirp, nsamp * fft_scaling));
                if jj==1
                    % chirp_peak_overlap = abs(chirp_abs_alias(chirp_fft_raw_single, Fs / BW));
                    chirp_peak_overlap = abs(chirp_comp_alias(chirp_fft_raw_single, Fs / BW));
                else
                    % chirp_peak_overlap = chirp_peak_overlap+abs(chirp_abs_alias(chirp_fft_raw_single, Fs / BW));
                    chirp_peak_overlap = chirp_peak_overlap+abs(chirp_comp_alias(chirp_fft_raw_single, Fs / BW));
                end
            end
            pk_height_overlap =max(chirp_peak_overlap([1:5*fft_scaling, end - 5*fft_scaling:end]));
            % [pk_height_overlap, pk_index_overlap] = max(chirp_peak_overlap);

            if (pk_height_overlap > peak_value)
                peak_value = pk_height_overlap;
                peak_index = ii;
            end

        end
        error_matrix(SNR_index, 1) = error_matrix(SNR_index, 1) + (SF_label == peak_index);
        error_matrix_count(SNR_index, 1) = error_matrix_count(SNR_index, 1) + 1;
    % catch
    %     warning('Problem using function.  Assigning a value of 0.');
    %     continue;
    % end
end

error_matrix = error_matrix ./ error_matrix_count;
feature_path = [data_root, 'nsdi_benchmark/', 'benchmark_lora_config_dechirp_',num2str(SF_std),'_5_comp.mat'];
save(feature_path, 'error_matrix','SNR_list');
%     end
% end

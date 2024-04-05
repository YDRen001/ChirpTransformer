clc;
clear;
close all;

% generate multi-path signal
% root_dir='D:\mobicom2021_server\';
root_dir = '/mnt/home/renyidon/data/mobicom2021_server/';
raw_data_dir = [root_dir, 'raw_outdoor_new/'];

feature_dir = [root_dir, '/lora_outdoor_new/'];

if ~exist([feature_dir, ''], 'dir')
    mkdir([feature_dir, '']);
end

position_list = 1:33;

benchmark_error_matrix = zeros(length(position_list), 1);
benchmark_error_matrix_count = zeros(length(position_list), 1);

SF_std = 12;
Fs = 125e3 * 8;
SF_STD = 12;
BW = 125000;

for postion_index = position_list
    node_index = postion_index;

    raw_data_dir_per_configuration = [raw_data_dir, 'pos', num2str(postion_index)];
    
    if ~exist(raw_data_dir_per_configuration, 'dir')
        raw_data_dir_per_configuration
        continue;
    end
    
    raw_data_list = scan_dir(raw_data_dir_per_configuration);
    n_raw_data_list = length(raw_data_list);
    
    nsamp = Fs * 2^SF_std / BW;
    
    for raw_data_index = 1:n_raw_data_list
        
        raw_data_name = raw_data_list{raw_data_index};
        [pathstr, raw_data_name_whole, ext] = fileparts(raw_data_name);
        if strcmp(ext, '.png') == 1
            continue;
        end
        [~, pkt_name, ext_pkt] = fileparts(pathstr);
        pkt_name = strsplit([pkt_name,ext_pkt], '(');
        packet_index=pkt_name{1}(4:end);        
        raw_data_name_components = strsplit([raw_data_name_whole, ext], '_');
           
        chirp_raw = io_read_iq(raw_data_name);
        chirp_raw_length = length(chirp_raw);
        
        if (chirp_raw_length ~= nsamp)
            raw_data_name
            continue;
        end
        
        SF = str2num(raw_data_name_components{3});
        
        if (SF == 7 || SF == 8)
            continue;
        end
        
        code_word_offset = str2double(raw_data_name_components{2});
        
        %% conventional signal processing
        
        code_word_label = mod(round(code_word_offset), 2^SF);
        
        benchmark_error_matrix_count(postion_index, 1) = benchmark_error_matrix_count(postion_index, 1) + 1;
        
        % if (SF == 12)
        %     if (code_word_label == 0 || code_word_label == 1 || code_word_label == 4095 || code_word_label == 2 || code_word_label == 4094)
        %         benchmark_error_matrix(postion_index, 1) = benchmark_error_matrix(postion_index, 1) + 1;
        %     end
        % end

        if (SF == 12)
            if (code_word_label == 0)
                benchmark_error_matrix(postion_index, 1) = benchmark_error_matrix(postion_index, 1) + 1;
            end
        end
        
        chirp = chirp_raw;
        SNR_index = -27;
        
        feature_path = [feature_dir, '/', num2str(code_word_label), '_', raw_data_name_components{2}, '_', num2str(SNR_index), '_', raw_data_name_components{3}, '_', raw_data_name_components{4}, '_', raw_data_name_components{1}, '_', num2str(postion_index), '_', num2str(node_index), '_', num2str(packet_index), '.mat'];
        
        if ~exist(feature_path, 'file')
            save(feature_path, 'chirp');
        end
    end 
end

error_matrix = benchmark_error_matrix ./ benchmark_error_matrix_count;
feature_path = [root_dir, 'nsdi_benchmark/', 'benchmark_outdoor_dechirp_12_125000.mat'];
save(feature_path, 'error_matrix');

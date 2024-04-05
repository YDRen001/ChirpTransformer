clc;
clear;
close all;

% generate multi-path signal
% root_dir='D:\mobicom2021_server\';
root_dir = '/mnt/home/renyidon/data/mobicom2021_server/';
raw_data_dir = [root_dir, 'raw_outdoor/'];
chirp_data_dir = [root_dir, 'raw_cross_domain/Pos2/Node3/'];

feature_dir = [root_dir, '/lora_outdoor_trace/'];
dechirp_path = [root_dir, 'nsdi_benchmark/', 'benchmark_outdoor_dechirp_12_125000_trace.mat'];

if ~exist([feature_dir, ''], 'dir')
    mkdir([feature_dir, '']);
end

data_batch_list = 1:10;
packet_batch_list = 1:20;

if ~exist(dechirp_path, 'file')
    benchmark_error_matrix = zeros(length(data_batch_list), 1);
else
    a=load(dechirp_path);
    benchmark_error_matrix=a.error_matrix;
end
benchmark_error_matrix_count = ones(length(data_batch_list), 1);

SF_std = 12;
Fs = 125e3 * 8;
BW = 125000;

SNR_list=[-27,-32,-33,-30,-35,-28,-31,-33,-30,-25];

chirp_down = utils.gen_symbol(0,true,Fs,BW,SF_std);
nsamp = Fs * 2^SF_std / BW;
code_list=0:5;

for postion_index = 1:10
    node_index = postion_index
    
    for packet_index = packet_batch_list
        raw_data_dir_per_configuration = [raw_data_dir, 'Pos', num2str(postion_index), '/', 'pkt', num2str(packet_index)];
        
        chirp_data_dir_per_configuration = [chirp_data_dir,'/', 'pkt', num2str(packet_index)];
        
        if ~exist(raw_data_dir_per_configuration, 'dir')
            raw_data_dir_per_configuration
            continue;
        end
        
        raw_data_list = scan_dir(raw_data_dir_per_configuration);
        chirp_data_list = scan_dir(chirp_data_dir_per_configuration);
        n_raw_data_list = length(raw_data_list);
        
        
        for raw_data_index = 1:n_raw_data_list
            raw_data_name = raw_data_list{raw_data_index};
            chirp_data_name = chirp_data_list{raw_data_index};
            
            [pathstr, raw_data_name_whole, ext] = fileparts(raw_data_name);
            raw_data_name_components = strsplit([raw_data_name_whole, ext], '_');
            
            [pathstr, chirp_data_name_whole, ext] = fileparts(chirp_data_name);
            chirp_data_name_components = strsplit([chirp_data_name_whole, ext], '_');
            
            
            if ((str2num(raw_data_name_components{1})~=str2num(chirp_data_name_components{1}))||(str2num(raw_data_name_components{3})~=str2num(chirp_data_name_components{3}))||(str2num(raw_data_name_components{4})~=str2num(chirp_data_name_components{4})))
                warning('Data not paired');
                continue;
            end
            SF = str2num(raw_data_name_components{3});
            code_word_offset = str2double(chirp_data_name_components{2});
            
            %% conventional signal processing
            
            code_word_label = mod(round(code_word_offset), 2^SF);

            if (SF == 7 || SF == 8 || ~ismember(code_word_label, code_list))
                continue;
            end
            
            chirp_raw = io_read_iq(chirp_data_name);
            noise_raw = io_read_iq(raw_data_name);
            chirp_raw_length = length(chirp_raw);
            
            if (chirp_raw_length ~= nsamp)
                raw_data_name
                continue;
            end
            
            SNR_index = SNR_list(postion_index);
            chirp = utils.add_noise_outdoor(chirp_raw,noise_raw,SNR_index);
            %             chirp_spectrum=utils.spectrum(chirp);
            
            
            if (SF == 12)
                chirp_dechirp = chirp .* chirp_down;
                chirp_fft_raw =(fft(chirp_dechirp, nsamp*10));
                
                chirp_peak_overlap=abs(chirp_abs_alias(chirp_fft_raw, Fs/BW));
                [pk_height_overlap,pk_index_overlap]=max(chirp_peak_overlap);
                
                estimated_label=mod(round(pk_index_overlap/10),2^SF_std);
                benchmark_error_matrix(postion_index, 1) = benchmark_error_matrix(postion_index, 1) + (estimated_label==code_word_label);
                benchmark_error_matrix_count(postion_index, 1) = benchmark_error_matrix_count(postion_index, 1) + 1;
                
            end
            
            
            feature_path = [feature_dir, '/', num2str(code_word_label), '_', raw_data_name_components{2}, '_', num2str(SNR_index), '_', raw_data_name_components{3}, '_', raw_data_name_components{4}, '_', raw_data_name_components{1}, '_', num2str(postion_index), '_', num2str(node_index), '_', num2str(packet_index), '.mat'];
            
            if ~exist(feature_path, 'file')
                save(feature_path, 'chirp');
            end
        end
        
    end
    
end


error_matrix = benchmark_error_matrix ./ benchmark_error_matrix_count;
save(dechirp_path, 'error_matrix');
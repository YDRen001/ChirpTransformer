% clc;
% clear;
% SF_index_list = 1:6;

root_dir = '/mnt/home/renyidon/data/mobicom2021_server/';
% root_dir='D:\mobicom2021_server\';
raw_data_dir = [root_dir, 'raw_indoor_config/'];

feature_dir = [root_dir, 'lora_indoor_config/'];

if ~exist([feature_dir, ''], 'dir')
    mkdir([feature_dir, '']);
end

SNR_list = [-40:0];
SF_list = 7:12;
BW_list = [125000];
data_batch_list = {'7', '8', '9', '10', '11', '12'};

Fs = 125e3 * 8;
SF_STD = 12;
fft_scaling = 20;
epoch_iters = 10;

for SF_index = SF_index_list
    data_batch = data_batch_list{SF_index};
    SF = SF_list(SF_index)
    
    for BW_index = 1:length(BW_list)
        BW = BW_list(BW_index);
        raw_data_dir_per_configuration = [raw_data_dir, data_batch];
        
        if ~exist(raw_data_dir_per_configuration, 'dir')
            continue;
        end
        
        raw_data_list = scan_dir(raw_data_dir_per_configuration);
        n_raw_data_list = length(raw_data_list);
        chirp_down = utils.gen_symbol(0, true, Fs, BW, SF);
        n_symbol = 2^(SF_STD - SF);
%         chirp_down = utils.gen_multiple_symbol(zeros(1, n_symbol), true, Fs, BW, SF);
        nsamp = Fs * 2^SF / BW;
        
        for raw_data_index = 1:n_raw_data_list
            raw_data_name = raw_data_list{raw_data_index};
            [pathstr, raw_data_name_whole, ext] = fileparts(raw_data_name);
            raw_data_name_components = strsplit(strcat(raw_data_name_whole, ext), '_');
            test_str = raw_data_name_components{1};
            %% generate chirp symbol with code word (between [0,2^SF))
            chirp_raw = io_read_iq(raw_data_name);
            chirp_raw_length = length(chirp_raw);
            
            if (chirp_raw_length ~= 2^SF_STD * Fs / BW)
                continue;
            end
            
            code_word_label = str2double(raw_data_name_components{2});
            instance_label = str2double(raw_data_name_components{1});
            code_word_label = mod(round(code_word_label), 2^SF);
            disp(instance_label);
            %% conventional signal processing
            for jj=1:n_symbol
                single_len=length(chirp_raw)/n_symbol;
                chirp_fft_raw_single=chirp_raw((jj-1)*single_len+1:jj*single_len);
                chirp_dechirp = chirp_fft_raw_single .* chirp_down;
                chirp_fft_raw = (fft(chirp_dechirp, nsamp * fft_scaling));
                if jj==1
                    chirp_peak_overlap = abs(chirp_abs_alias(chirp_fft_raw, Fs / BW));
                else
                    chirp_peak_overlap = chirp_peak_overlap+abs(chirp_abs_alias(chirp_fft_raw, Fs / BW));
                end
            end
            % chirp_peak_overlap = abs(chirp_comp_alias(chirp_fft_raw, Fs / BW));
            [pk_height_overlap, pk_index_overlap] = max(chirp_peak_overlap);
            
            code_word_fft = mod(pk_index_overlap, 2^SF * fft_scaling) / fft_scaling;
            code_words=mod(round(code_word_fft), 2^SF);
            if (code_words ~= code_word_label)
                disp(raw_data_name_whole);
                continue;
            end
            
            %% SNR noise
            
            for epoch_index = 1:epoch_iters
                chirp_raw = chirp_raw * exp(1i * 2 * pi * epoch_index / epoch_iters);
                instance_label_true = epoch_index + (instance_label - 1) * epoch_iters;
                
                for SNR = SNR_list
                    
                    if SNR ~= 35
                        chirp = utils.add_noise(chirp_raw, SNR, Fs, BW, SF);
                        SNR_index = SNR;
                    else
                        chirp = chirp_raw;
                        SNR_index = 35;
                    end
                    
                    if (length(chirp) ~= 2^SF_STD * Fs / BW)
                        raw_data_name
                        continue;
                    end
                    
                    %                                     chirp_spectrum=utils.spectrum(chirp);
                    feature_path = [feature_dir, num2str(code_words), '_', num2str(code_word_label), '_', num2str(SNR), '_', num2str(SF), '_', num2str(BW), '_', num2str(instance_label_true), '.mat'];
                    
                    if ~exist(feature_path, 'file')
                        save(feature_path, 'chirp');
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

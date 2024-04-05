clc;
clear;
close all;

% generate multi-path signal
Fs =1000000;         % sample rate

fig_switch=false;
data_root = '/mnt/home/renyidon/data/mobicom2021_server/';
data_dir='lora_indoor_config\';
feature_dir = [data_root,data_dir];

feature_data_list=dir(fullfile(feature_dir));
n_feature_data_list=size(feature_data_list,1);

SNR_list=[-40:2:0, 5:5:35];

SF_list=[10];
BW_list=[125000];

for BW=BW_list
    for SF=SF_list
        chirp_down = utils.gen_symbol(0,true,Fs,BW,SF);
        error_matrix=zeros(length(SNR_list),1);
        error_matrix_count=zeros(length(SNR_list),1);
        nsamp = Fs * 2^SF / BW;
        for feature_data_index=1:n_feature_data_list
            feature_data_name=feature_data_list(feature_data_index).name;
            if strcmp(feature_data_name,'.')==1||strcmp(feature_data_name,'..')==1
                continue;
            end
            raw_data_name_components = strsplit(feature_data_name(1:end-4),'_');
            
            if ~ismember(str2num(raw_data_name_components{3}),SNR_list) || str2num(raw_data_name_components{4})~=SF || str2num(raw_data_name_components{5})~=BW
                continue;
            end
            
            [~,SNR_index]=find(str2num(raw_data_name_components{3})==SNR_list);
            load([feature_dir,feature_data_name]);
            
            if(length(chirp)~=2^SF*Fs/BW)
                feature_data_name
                continue;
            end
            
            chirp_dechirp = chirp .* chirp_down;
            chirp_fft_raw =fft(chirp_dechirp, nsamp*50);
            
%             chirp_fft_raw =abs(fft(chirp_dechirp, nsamp*10));
%             align_win_len = length(chirp_fft_raw) / (Fs/BW);
%             
%             chirp_fft_overlap=(chirp_fft_raw(1:align_win_len))+(chirp_fft_raw(end-align_win_len+1:end));
%             %             chirp_fft_overlap=flip(chirp_fft_overlap);
%             chirp_peak_overlap=abs(chirp_fft_overlap);
            chirp_peak_overlap=chirp_comp_alias(chirp_fft_raw, Fs/BW);
            [pk_height_overlap,pk_index_overlap]=max(chirp_peak_overlap);          
            
            code_word_label=str2num(raw_data_name_components{2});
            
            estimated_label_true=pk_index_overlap/50;
            estimated_label=mod(round(estimated_label_true),2^SF);
%             if(estimated_label~=code_word_label)
%                 feature_data_name
%                 estimated_label_true
%                 code_word_label
%                 %                             continue;
%             end
            error_matrix(SNR_index,1)=  error_matrix(SNR_index,1)+(estimated_label==code_word_label);
            error_matrix_count(SNR_index,1)=error_matrix_count(SNR_index,1)+1;
        end
        error_matrix=error_matrix./error_matrix_count;
        feature_path = [data_root, 'nsdi_benchmark/','benchmark_indoor_config_',num2str(SF),'_',num2str(BW),'.mat'];
        save(feature_path, 'error_matrix');
    end
end
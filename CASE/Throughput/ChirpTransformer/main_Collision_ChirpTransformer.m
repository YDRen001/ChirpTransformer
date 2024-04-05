clear;
clc;
close all;

% Define the directory where the raw signal files are stored
raw_signals_dir = 'raw_signals';

% Define the sample rate and bandwidth from parameter configurations
Fs = param_configs(3); % sample rate        
BW = param_configs(2); % LoRa bandwidth

% Define filenames of the raw signal files
filenames = {'7_0_7_125000', '10_0_8_125000', '12_0_9_125000', '15_0_10_125000', '20_0_11_125000', '17_0_12_125000'};

% Preallocate x for efficiency
x = zeros(6,32768); % Adjust size as needed based on your signal lengths

% Load signals, normalize, and store in x
for idx = 1:length(filenames)
    full_path = fullfile(raw_signals_dir, filenames{idx}); % Construct full file path
    fileID = fopen(full_path, 'r');
    output = fread(fileID, 'float');
    fclose(fileID);
    output = reshape(output, 2, []);
    x(idx,:) = (output(1,:) + 1i * output(2,:)) .* sqrt(0.3 / mean(abs(output(1,:) + 1i * output(2,:)).^2));
end

ifo = 0; % Initial frequency offset (ground truth)

% Loop through combination numbers
for combination_number = 1:5
    ser=zeros(6,nchoosek(6,combination_number));
    for SF = 7 : 12
        j = [1:SF-7,SF-5:6];
        index = nchoosek(j,combination_number); 
        for k = 1:size(index,1)
            count = 0;
            for i = 1 : 2000 % If you need more iterations, adjust this loop
                g = 10.^(-rand(combination_number+1,1)*20/20);
                to = ceil(rand(combination_number,1)*32768);
                
                % Generate signal with interference
                sig = x(SF-6,:).*g(1);
                for m = 1:combination_number
                    sig = sig + x(index(k,m),[to(m):32768,1:to(m)-1]).*g(m+1);
                end
                
                % Signal processing and SER calculation
                downchirp = gen_symbol(0,true,Fs,SF);
                dechirp = repmat(downchirp,1,2^(12-SF));
                de_samples = sig .* dechirp;
                fft_res = fft(de_samples, 32768*10);
                freq_pwr = abs(fft_res);
                
                z = chirp_comp_alias([fft_res,freq_pwr], Fs/BW);  
                [ma, I] = max(abs(z)); 
                value = mod(round(I /numel(z) * 2^SF), 2^SF);
                if value == ifo
                    count = count+1;
                end
            end
            ser(SF-6,k) = count/i;
        end
    end
    % Save ser matrix for each combination_number
    save(sprintf('concurrency%d.mat', combination_number+1), 'ser');
end
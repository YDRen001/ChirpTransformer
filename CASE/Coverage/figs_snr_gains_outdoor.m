clear;
clc;
close all;

%% Set Parameters for Loading Data
lineA = ["-", ":", "--", '-.'];
lineC = ["*", "s", "o", "^", "+", "p", "d"];
lineS = ["-*", "--s", ":^", '-.p'];

fig = figure;
set(fig, 'DefaultAxesFontSize', 70);
set(fig, 'DefaultAxesFontWeight', 'bold');
set(fig, 'PaperSize', [5.9 * 3 4.4 * 3]);

color_list = distinguishable_colors(10);
color_list(2, :) = color_list(4, :);
color_list(1, :) = color_list(5, :);
color_list(3, :) = color_list(8, :);

%% decoding via deep learning

n_positions = 33;
snr_zero = zeros(n_positions, 2);

error_path = ['ChirpTransformer.mat'];
a_p = load(error_path);
error_matrix = struct2cell(a_p);

error_matrix = 1 - error_matrix{3};
[error_matrix, mini_index] = mink(error_matrix, 10, 2);
snr_zero(:, 1) = mean(error_matrix, 2);

error_path = ['baseline.mat'];
a = load(error_path);
error_matrix = 1 - a.error_matrix;
snr_zero(:, 2) = mean(error_matrix, 2);


position_selected = [1:5, 7:8, 10:22];
n_positions = length(position_selected);
snr_zero = snr_zero(position_selected, :);

b=bar(snr_zero,'EdgeColor','none');

for k = 1:size(snr_zero, 2)
    b(k).FaceColor = color_list(k, :);
end

legend({'Ours', 'Baseline'}, 'NumColumns', 3, 'Location', 'northwest')
% xticklabels({'#1','#2','#3','#4','#5','#6','#7','#8','#9','#10'})
xlabel('Position'); % y label
ylabel('Symbol Error Rate'); % y label
ylim([0, 1]);
set(gcf, 'WindowStyle', 'normal', 'Position', [0, 0, 640 * 2, 480 * 2]);
%saveas(gcf, ['snr_gains_outdoor.pdf'])
disp(mean(snr_zero));

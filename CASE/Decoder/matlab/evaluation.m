% MAIN
% Version 30-Nov-2019
% Help on http://liecn.github.com
clear;
% clc;
close all;

%% Set Parameters for Loading Data
lineA=["-",":","--",'-.'];
% lineB=[left_color,"b","m","g"];
lineC=["*","s","o","^","+","p","d"];
lineS=["-*","--s",":^",'-.p'];

fig=figure;
set(fig,'DefaultAxesFontSize',20);
set(fig,'DefaultAxesFontWeight','bold');

set(fig,'PaperSize',[6.8 4]);

data_root = '/mnt/home/renyidon/data/mobicom2021_server/';
color_list = linspecer(5);

%% decoding via deep learning
% benchmark_indoor_platform_woCFO_error_matrix_12_125000.mat:-40:15
% benchmark_indoor_platform_woCFO_error_matrix_12_125000_tong.mat:-50:-10
code_str_list={'bit2_3_64_4_64_1_0_pre_trained_crossdomain','benchmark/benchmark_indoor_platform_woCFO_error_matrix_12_125000'};

error_path = [data_root,code_str_list{1},'.mat'];
a = load(error_path);
error_matrix =struct2cell(a);
error_matrix=1-error_matrix{1};
error_matrix(21:26)
plot([-50:20],error_matrix,"-.*",'Marker',lineC{1},'MarkerSize',8,'LineWidth',2,'color',color_list(1,:));
hold on;

error_path = [data_root,code_str_list{2},'.mat'];
a = load(error_path);
error_matrix =1-a.error_matrix;
plot(-40:15,error_matrix,"-.*",'LineWidth',2,'Marker',lineC{2},'MarkerSize',8,'color',color_list(2,:));
hold on;

legend(['Ours'],['Benchmark']);
xlabel('SNR (dB)'); % x label
ylabel('SER'); % y label
xlim([-50,-10]);
set(gca,'Ytick',0:0.2:1)
set(gcf,'WindowStyle','normal','Position', [200,200,640,360]);
saveas(gcf,['/mnt/home/lichenni/projects/mobicom2021/evaluations/',code_str_list{1},'.png'])


clear;
clc;
close all;

%% Set Parameters for Loading Data
lineA=["-",":","--",'-.'];
lineC=["*","s","o","^","+","p","d"];
lineS=["-*","--s",":^",'-.p'];

fig=figure;
set(fig,'DefaultAxesFontSize',70);
set(fig,'DefaultAxesFontWeight','bold');
set(fig,'PaperSize',[5.9*3 4.4*3]);

color_list = distinguishable_colors(10);
color_list(2, :) = color_list(4, :);
color_list(1, :) = color_list(5, :);
color_list(3, :) = color_list(8, :);
%% decoding via deep learning

position_selected=[1:5,7:8,10:22];

error_path = ['ChirpTransformer.mat'];
a_p = load(error_path);
error_matrix =struct2cell(a_p);

error_matrix=1-error_matrix{3};
[error_matrix,mini_index] = mink(error_matrix,10,2);
error_matrix=error_matrix(position_selected,:);

plot_data=(sort(error_matrix(:)));

[F,X,Flo,Fup] = ecdf(plot_data);
plot(X,F,"-*",'LineWidth',8,'color',color_list(1,:),'MarkerIndices', 1:5:length(F),'MarkerSize',20); 
hold on;

error_path = ['baseline.mat'];
a = load(error_path);
error_matrix=1-a.error_matrix;
error_matrix=error_matrix(position_selected,:);

plot_data=(sort(error_matrix(:)));
[F,X,Flo,Fup] = ecdf(plot_data);
plot(X,F,":^",'LineWidth',8,'color',color_list(2,:),'MarkerIndices', 1:1:length(F),'MarkerSize',20); 
hold on;



legend({'Ours','Baseline'},'NumColumns',1,'Location','northwest')
ylabel('CDF'); % y label
title('');
xlabel('SER across Packets / Positions'); % y label
% ylim([0,1]);
set(gcf,'WindowStyle','normal','Position', [0,0,640*2,480*2]);
%saveas(gcf,['snr_cdf_outdoor.pdf'])


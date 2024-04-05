close all;
clear 
clc
fig = figure;
set(fig, 'DefaultAxesFontSize', 35);
set(fig, 'DefaultAxesFontWeight', 'bold');
set(fig, 'PaperSize', [15 10]);

total=2200*3600;
airtime(1,:)=[61.7,113.2,205.8,370.7,823.3,1482.8]; %SF7
airtime(2,:)=[66.8,123.4,226.3,411.6,823.3,1646.6]; %SF8
airtime(3,:)=[71.9,133.6,246.8,452.6,905.2,1810.4]; %SF9
airtime(4,:)=[77.1,143.9,246.8,493.6,987.1,1810.4]; %SF10
airtime(5,:)=[82.2,154.1,267.3,493.6,1061.1,1974.3];%SF11
airtime(6,:)=[87.3,164.4,287.7,534.5,1151.0,2138.1];%SF12

for payload = 1 : 6
    data_path = ["U1\G1\"];
    track1 = dir(fullfile(data_path));a7=0;
    snr=zeros(1,1);p1=0;count=0;p2=0;num=zeros(1,5);sum=0;num0=zeros(1,5);

    for i = 3 : 18
        tab = readtable(['U1\G1\',track1(i).name]);
        snr=table2array(tab(:,'SNR'));
        for j = 1 : length(snr)
            sum=sum+1;
            if snr(j) >= -6.2
                a7=a7+1;
            end
            if snr(j) >= -6.2 && a7 >= 20  
                continue;
            end
            if snr(j) < -6.2 && snr(j) >=-9.8 && num(1)>=20
                continue;
            elseif snr(j) < -9.8 && snr(j) >= -12.8 && num(2)>=20
                continue;
            elseif snr(j) < -12.8 && snr(j) >= -15.6 && num(3)>=20
                continue;
            elseif snr(j) < -15.6 && snr(j) >= -18.2 && num(4)>=20
                continue;
            end
    
            if snr(j) < -8.9 && snr(j) >=-9.8 && num0(1)>=4
                continue;
            elseif snr(j) < -11.9 && snr(j) >= -12.8 && num0(2)>=4
                continue;
            elseif snr(j) < -15 && snr(j) >= -15.6 && num0(3)>=4
                continue;
            elseif snr(j) < -17.7 && snr(j) >= -18.2 && num0(4)>=4
                continue;
            end
    
            if snr(j) >= -8.9
                p1=p1+power(airtime(payload,1));
            elseif snr(j) < -8.9 && snr(j) >= -11.9
                p1=p1+power(airtime(payload,2));
            elseif snr(j) < -11.9 && snr(j) >= -15
                p1=p1+power(airtime(payload,3));
            elseif snr(j) < -15 && snr(j) >= -17.7
                p1=p1+power(airtime(payload,4));
            elseif snr(j) < -17.7 && snr(j) >= -21.6
                p1=p1+power(airtime(payload,5));
            elseif snr(j) < -21.6
                p1=p1+power(airtime(payload,6));
            end
            if snr(j) >= -6.2
                p2=p2+power(airtime(payload,1));
            elseif snr(j) < -6.2 && snr(j) >= -9.8
                p2=p2+power(airtime(payload,2));
            elseif snr(j) < -9.8 && snr(j) >= -12.8
                p2=p2+power(airtime(payload,3));
            elseif snr(j) < -12.8 && snr(j) >= -15.6
                p2=p2+power(airtime(payload,4));
            elseif snr(j) < -15.6 && snr(j) >= -18.2
                p2=p2+power(airtime(payload,5));
            elseif snr(j) < -18.2
                p2=p2+power(airtime(payload,6));
            end
            if snr(j) < -6.2 && snr(j) >=-8.9
                num(1)=num(1)+1;
            elseif snr(j) < -9.8 && snr(j) >= -11.9
                num(2)=num(2)+1;
            elseif snr(j) < -12.8 && snr(j) >= -15
                num(3)=num(3)+1;
            elseif snr(j) < -15.6 && snr(j) >= -17.7
                num(4)=num(4)+1;
            elseif snr(j) < -18.2 && snr(j) >= -21.6
                num(5)=num(5)+1;
            end
            if snr(j) < -8.9 && snr(j) >=-9.8
                num0(1)=num0(1)+1;
            elseif snr(j) < -11.9 && snr(j) >= -12.8
                num0(2)=num0(2)+1;
            elseif snr(j) < -15 && snr(j) >= -15.6
                num0(3)=num0(3)+1;
            elseif snr(j) < -17.7 && snr(j) >= -18.2
                num0(4)=num0(4)+1;
            end
        count=count+1;
        end
    end

    num=zeros(1,5);num0=zeros(1,5);
    data_path = ["D:\Morph_Encoder\Battery\U1\G2\"];
    track1 = dir(fullfile(data_path));a7=0;

    for i = 3 : 13
        tab = readtable(['D:\Morph_Encoder\Battery\U1\G2\',track1(i).name]);
        snr=table2array(tab(:,'SNR'));
        for j = 1 : length(snr)
            sum=sum+1;
            if snr(j) >= -6.2
                a7=a7+1;
            end
            if snr(j) >= -6.2 && a7 >= 10  
                continue;
            end
            if snr(j) < -6.2 && snr(j) >=-9.8 && num(1)>=10
                continue;
            elseif snr(j) < -9.8 && snr(j) >= -12.8 && num(2)>=10
                continue;
            elseif snr(j) < -12.8 && snr(j) >= -15.6 && num(3)>=10
                continue;
            elseif snr(j) < -15.6 && snr(j) >= -18.2 && num(4)>=10
                continue;
            end
            
            if snr(j) < -8.9 && snr(j) >=-9.8 && num0(1)>=2
                continue;
            elseif snr(j) < -11.9 && snr(j) >= -12.8 && num0(2)>=2
                continue;
            elseif snr(j) < -15 && snr(j) >= -15.6 && num0(3)>=2
                continue;
            elseif snr(j) < -17.7 && snr(j) >= -18.2 && num0(4)>=2
                continue;
            end
    
            if snr(j) >= -8.9
                p1=p1+power(airtime(payload,1));
            elseif snr(j) < -8.9 && snr(j) >= -11.9
                p1=p1+power(airtime(payload,2));
            elseif snr(j) < -11.9 && snr(j) >= -15
                p1=p1+power(airtime(payload,3));
            elseif snr(j) < -15 && snr(j) >= -17.7
                p1=p1+power(airtime(payload,4));
            elseif snr(j) < -17.7 && snr(j) >= -21.6
                p1=p1+power(airtime(payload,5));
            elseif snr(j) < -21.6
                p1=p1+power(airtime(payload,6));
            end
            if snr(j) >= -6.2
                p2=p2+power(airtime(payload,1));
            elseif snr(j) < -6.2 && snr(j) >= -9.8
                p2=p2+power(airtime(payload,2));
            elseif snr(j) < -9.8 && snr(j) >= -12.8
                p2=p2+power(airtime(payload,3));
            elseif snr(j) < -12.8 && snr(j) >= -15.6
                p2=p2+power(airtime(payload,4));
            elseif snr(j) < -15.6 && snr(j) >= -18.2
                p2=p2+power(airtime(payload,5));
            elseif snr(j) < -18.2
                p2=p2+power(airtime(payload,6));
            end
            if snr(j) < -6.2 && snr(j) >=-8.9
                num(1)=num(1)+1;
            elseif snr(j) < -9.8 && snr(j) >= -11.9
                num(2)=num(2)+1;
            elseif snr(j) < -12.8 && snr(j) >= -15
                num(3)=num(3)+1;
            elseif snr(j) < -15.6 && snr(j) >= -17.7
                num(4)=num(4)+1;
            elseif snr(j) < -18.2 && snr(j) >= -21.6
                num(5)=num(5)+1;
            end
            if snr(j) < -8.9 && snr(j) >=-9.8
                num0(1)=num0(1)+1;
            elseif snr(j) < -11.9 && snr(j) >= -12.8
                num0(2)=num0(2)+1;
            elseif snr(j) < -15 && snr(j) >= -15.6
                num0(3)=num0(3)+1;
            elseif snr(j) < -17.7 && snr(j) >= -18.2
                num0(4)=num0(4)+1;
            end
            count=count+1;
        end
    end

    packet=240; % packet per day
    p1=p1/count; year1(payload)=total/(p1*packet); % ChirpTransformer Rate Adaption
    p2=p2/count; year2(payload)=total/(p2*packet);% LoRaWAN Rate Adaption
    
    rxtime = (airtime(payload,6)-61.7)/((2138.1-61.7)/(164-5.1))+5.1;
    p0=1.6*3.7+140*airtime(payload,6)/1000+16.6*rxtime/1000+(360-1.6-airtime(payload,6)/1000-rxtime/1000)*0.0017;
    year0(payload)=total/(p0*packet);
    power0(payload)=p0*3.6*packet;power1(payload)=p1*3.6*packet;power2(payload)=p2*3.6*packet;
end

plot(year0,'-o','MarkerSize',20,'LineWidth',7);hold on;
plot(year1,'-o','MarkerSize',20,'LineWidth',7);hold on;
plot(year2,'-o','MarkerSize',20,'LineWidth',7);
xlabel('Payload Size (bytes)');
set(gca, 'xtick', 1:6);set(gca, 'ytick',0:200:800);
axis([1 6 0 800]);grid on;
xticklabels({'10','14','18','22','26','30'});
ylabel('Battery Life (days)');
legend('Fixed-SF12','ChirpTransformer','LoRa','Location','North','NumColumns',3,'FontSize', 35)
set(gca,'gridlinestyle','-','Gridalpha',0.5);set(gca, 'FontSize', 40);
set(gcf, 'WindowStyle', 'normal', 'Position', [0, 0, 720*2, 480*2]);
%saveas(gcf, ['battery_life.pdf']);

function [answer]=power(airtime_index) %function to calculate the power for each packet transmission
    rx = (airtime_index-61.7)/((2138.1-61.7)/(164-5.1))+5.1; %reception window estimation
    answer=1.6*3.7+140*airtime_index/1000+16.6*rx/1000+(360-1.6-airtime_index/1000-rx/1000)*0.0017; 
    % airtime_index: on-air time | 1.6: MCU only time | 3.7: MCU only current
    % 140: MCU+TX current | 16.6: MCU + RX current |360: Time gap between 2 packets
    % 0.0017 sleep current | the power unit is mAs
end
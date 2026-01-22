% ===========================
% i_extract_lbf.m
% Author: Justine, 10.23.24
% ===========================
clc;
clear;
close all;
warning("off");

%% Define parameters
SCAN = 1:188;
freq = 400;
CH = 8;

folder = "./data/";

save_enable = true;

tic
%% Run
for ch = CH
    signal = [];
    for i = SCAN
    
        disp(['Scan ', num2str(i)]);
    
        % Load data
        filename = strcat(folder, 'ch_', num2str(ch), '_scan_', num2str(i), '_', num2str(freq), 'hz_swv.mat');
        openfile = load(filename);
        voltage = openfile.data(1, 20:end-50);
        current = openfile.data(2, 20:end-50);
        
        figure(10000)
        hold on;
        [i_signal, ~, ~, ~] = i_extract_lbf(voltage, current);
        hold off;

        signal(i) = i_signal;
    end
    disp('Running complete :)')
    %%
    signal = nonzeros(signal);
    figure(4000)
    hold on;
    plot(signal, DisplayName=strcat('i_{signal} of ch ', num2str(ch)))
    legend;
    xlabel('Sample (a.u.)')
    ylabel('Peak Value')
    hold off;

    %% Main plot
    if save_enable    
        filename = strcat('i_signal_ch',num2str(ch), '_', num2str(freq),'hz_lbf.mat');
        save(filename, 'signal');
        filename_pic = strcat('i_signal_ch',num2str(ch), '_', num2str(freq),'hz_lbf.png');
        saveas(gcf, filename_pic);
    end

    pause(2);
    close all;
end
toc

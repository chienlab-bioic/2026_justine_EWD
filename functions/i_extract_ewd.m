%%% ===== Release note =====
% Author: Justine Tsai, ChienLab, EECS, UC Berkeley
% Date: November 2025
% Version: v1

% Extract SWV peak current using Extension-enhanced Wavelet Decomposition (EWD).
% Inputs: voltage0 [V], current0 [A], V_peak_width [V_left V_right], plot_all (true/false)
% Output: i_signal [A] (peak current)
% Requires: Wavelet Toolbox (modwt, modwtmra)
% Docs: see README.md for method details + parameter guidance.
%%% ========================

function i_signal = i_extract_ewd(voltage0, current0, V_peak_width, plot_all)
    
%% Step0: Parameters 
    repeat_cycle = 8; % Increase the repeating cycle if the signal and baseline is still blended
    degree = ceil(length(current0)/10)-1; % Filtering amount

%% Step1: Filtering and Signal Truncation
    current0 = current0-min(current0);
    p = polyfit(voltage0, current0, degree);
    diff0 = polyval(p, voltage0);
    diff1 = diff(diff0);
    diff1 = movmean(diff1, 40);
    diff2 = diff(diff1);
    diff2 = movmean(diff2, 40);
    
    peak_width_num_L = round(V_peak_width(1)/mean(diff(voltage0)));
    peak_width_num_L = int32(peak_width_num_L);
    peak_width_num_R = round(V_peak_width(2)/mean(diff(voltage0)));
    peak_width_num_R = int32(peak_width_num_R);
   
    quar_length = round(length(current0)/4);
    saddle = find(diff2 == min(diff2(quar_length:end-quar_length)), 1);

    left_min = saddle - peak_width_num_L;
    right_min = saddle + peak_width_num_R;

    current1 = current0(left_min:right_min);

    voltage1 = voltage0(left_min:right_min);
    length1 = length(voltage1);

%% Step2: Signal Extension and Mirroring
    voltage = linspace(0, repeat_cycle * 2 * voltage1(end), repeat_cycle * 2 * length1);
    current = [current1, current1 - current1(1) + current1(end)];
    for i = 1:repeat_cycle - 2
        current = [current, current1 - current1(1) + current(end)];
    end
    current = [current, flip(current, 2)];

%% Step3: DWT
    dwt_method = 'fk8';
    % num_level = floor(log2(length(current))) - 1;
    num_level = 10;

    m = modwt(current, dwt_method, num_level);
    mra = modwtmra(m, dwt_method);
%% Step4: Recombination
    for i = 1:num_level+1
        signal = mra(i, :);
        
        signal_sign = sign(signal);
        signal_sign(signal_sign == 0) = 1;
        zero_crossing_num(i) = numel(find(diff(signal_sign) ~= 0));
    end
    zero_crossing_num;
    range = find(zero_crossing_num <= 6*repeat_cycle & zero_crossing_num >= 3*repeat_cycle);

    i_dwt = sum(mra(range, :), 1);

    i_dwt1 = reshape(i_dwt, length1, repeat_cycle * 2);
    for j = repeat_cycle + 1 : repeat_cycle * 2
        i_dwt1(:, j) = flip(i_dwt1(:, j));
    end
    i_dwt1_eff = i_dwt1(:, [2: repeat_cycle-1, repeat_cycle+2: end-1]);

%% Step5: Peak Extraction
    i_dwt_current = mean(i_dwt1_eff, 2);
    i_dwt_current = i_dwt_current-min(i_dwt_current);
    [i_signal, i_idx] = max(i_dwt_current(round(length1/4):round(length1*3/4)));
    i_idx = i_idx + round(length1/4)-1;

%% Plot
    if plot_all % Set plot_all to true to show all the steps, usually for debugging
        
        % Plot the current and its derivatives; use this to check if the peak location is found correctly
        figure(Name='Finding Peak Location -> Diff twice')
        movegui('west')
        subplot(3,1,1)
        hold on;
        plot(voltage0, current0)
        plot(voltage0, diff0)        
        plot(voltage0([left_min, right_min]), diff0([left_min, right_min]), 'ko')
        subplot(3,1,2)
        hold on;
        plot(diff1)
        subplot(3,1,3)
        hold on;
        plot(diff2)
        
        % Plot the extended raw data
        figure(Name='Extended Raw Data')
        plot(voltage, current)
        
        % Plot the reconstructed signals from each level of DWT coefficients 
        figure(Name='MODWT')
        set(gcf, 'Position', [0 0 1000 1000])
        subplot(ceil((num_level+1)/2), 2, 1)
        hold on;
        plot(voltage, current)

        for i = 1:num_level+1
            subplot(ceil((num_level+2)/2), 2, i+1)
            hold on;
            plot(mra(i, :))
            title(['Rec Level ' num2str(i)])
        end

        % Plot each level of DWT coefficients 
        figure(Name='Wavelet Coefficients')
        set(gcf, 'Position', [0 0 1000 1000])
        subplot(ceil((num_level+1)/2), 2, 1)
        hold on;
        plot(voltage, current)
        title('Extended Raw Data')

        for i = 1:num_level+1
            subplot(ceil((num_level+2)/2), 2, i+1)
            hold on;
            plot(m(i, :))
            title(['Coef Level ' num2str(i)])
        end

        % Plot the SWV of each repeat cycle and the averaged (final) result
        figure(Name='Reconstruction')
        plot(voltage0, current0, 'DisplayName', '0')
        hold on;
        for j = 1:size(i_dwt1_eff, 2)
            plot(voltage1, i_dwt1_eff(:, j), 'DisplayName', num2str(j))
        end
        plot(voltage1, i_dwt_current, LineWidth=2.5)
        legend;
        hold off;
    end
    
    %% Plot raw data, truncated region, reconstructed SWV, and peak 
    figure(10000)
    movegui('east')
    subplot(2,1,1)
    hold on;
    plot(voltage0, current0, 'Color', 1/255*[217 93 93], 'DisplayName', 'Raw data')
    plot(voltage1, current1, 'Color', 1/255*[93 93 93], 'DisplayName', 'Raw data')
    subplot(2,1,2)
    hold on;
    plot(voltage1, i_dwt_current, 'Color', 1/255*[232 196 60], 'DisplayName', 'Denoised data')
    plot(voltage1(i_idx), i_signal, 'ko')
end


function [i_signal, i_peak, i_background, V_peak] = i_extract_lbf(voltage, current)

% Abandon some amount of data points
abandoned_front = 0;
abandoned_end = 0;

voltage(1:abandoned_front) = [];
current(1:abandoned_front) = [];
voltage(end-abandoned_end:end) = [];
current(end-abandoned_end:end) = [];

% --- polynomial fitting ---
p = polyfit(voltage, current, 26);
current_fitted = polyval(p, voltage);

p0 = polyfit(voltage, current, 1);
current_fitted_linear = polyval(p0, voltage);

% --- create rotation matrix ---
theta = atan2(p0(1), 1)/pi*180; % -30deg
theta_rotate = theta; % same
% theta_rotate = 0;
R = [cosd(theta_rotate) -sind(theta_rotate); sind(theta_rotate) cosd(theta_rotate) ];
matrix_data = [voltage' current_fitted']; % create matrix data
Z = matrix_data*R; % rotation
current_rotated = Z(:, 2);


%% --- MB peak ---
current_fitted = current_rotated;

v1 = -0.45;
v2 = -0.25;
index1 = find(voltage > v1);
index_start = index1(1);
index2 = find(voltage < v2);
index_end = index2(length(index2));

% MB peak current raw value
i_peak = max(current_fitted(index_start:index_end));
index_peak = find(current_fitted == i_peak);
V_peak = voltage(index_peak);

%% --- baseline: just find local minimum ---
v3 = V_peak -0.2;
v4 = V_peak -0;

index3 = find(voltage > v3);
background1_start = index3(1);
index4 = find(voltage < v4);
background1_end = index4(length(index4));
i_min1 = min(current_fitted(background1_start:background1_end));
index_background1 = find(current_fitted == i_min1);

v5 = V_peak + 0;
v6 = V_peak + 0.2;
index5 = find(voltage > v5);
background2_start = index5(1);
index6 = find(voltage < v6);
background2_end = index6(length(index6));
i_min2 = min(current_fitted(background2_start:background2_end));
index_background2 = find(current_fitted == i_min2);

% --- slope ---
m = (current_fitted(index_background2) - current_fitted(index_background1))/(voltage(index_background2) - voltage(index_background1));
b = current_fitted(index_background2) - m*voltage(index_background2);
y = m*voltage + b;
% 
% --- figure plotting ---
figure(10000);
set(gcf, 'Color', 'White')
plot(voltage, current);
hold on;

plot(voltage, current_fitted, 'r');
plot(voltage, current_fitted_linear, 'm');

plot(voltage, current_rotated, 'c');
hold on;

plot(voltage, y, '-k');
plot(voltage(index_background1), y(index_background1), 'go')
plot(voltage(index_background2), y(index_background2), 'go')
plot(voltage(index_peak), y(index_peak), 'go')
xlabel('Voltage')
ylabel('Current (uA)')

% --- calculation for the signal current ---
i_background = m*voltage(index_peak) + b; % y = mx + b
i_signal = i_peak - i_background; % result

end
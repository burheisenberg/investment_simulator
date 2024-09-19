%% Dynamic Financial Savings Model with Reward Function
clear, clc, close all

% Initial Conditions
initial_saving = 30000;
monthly_savings = [0, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000]';
months_in_year = 12;

% Growth rates and interpolated data for Dollar and BIST100
dollar_initial = 34.1;
bist100_initial = 9760;
growth_rate_dollar = 1.0194;  % 1.94% monthly
growth_rate_bist100 = 1.0194;

dollar_rate = dollar_initial * growth_rate_dollar .^ (0:length(monthly_savings)-1)';
bist100_rate = bist100_initial * growth_rate_bist100 .^ (0:length(monthly_savings)-1)';

% TCMB monthly interest rates
interest_rates = (1 + [42 37 37 32 32 32 32 27 27 17 17 17]/100)'.^(1/12) - 1;

% Initial Savings Distribution (Random start)
distribution = rand(1,4);  % TL, Dollar, BIST100, Bank (Interest)
distribution = distribution/sum(distribution)

% Initialize saving arrays
tl_savings = zeros(length(monthly_savings), 1);
dollar_savings = zeros(length(monthly_savings), 1);
bist100_savings = zeros(length(monthly_savings), 1);
bank_savings = zeros(length(monthly_savings), 1);

% First month savings
tl_savings(1) = (initial_saving + monthly_savings(1)) * distribution(1);
dollar_savings(1) = (initial_saving + monthly_savings(1)) * distribution(2) / dollar_rate(1);
bist100_savings(1) = (initial_saving + monthly_savings(1)) * distribution(3) / bist100_rate(1);
bank_savings(1) = (initial_saving + monthly_savings(1)) * distribution(4);

% Initialize dynamic strategy update parameters
learning_rate = 0.3;  % How fast the strategy changes each month

% Allocate savings over months and dynamically update the strategy
for i = 2:length(monthly_savings)
    
    % Calculate the previous month's total savings
    total_savings_last_month = tl_savings(i-1) + dollar_savings(i-1) * dollar_rate(i-1) + ...
                               bist100_savings(i-1) * bist100_rate(i-1) + bank_savings(i-1);
    
    % Allocate this month's savings based on the current strategy (distribution)
    tl_savings(i) = tl_savings(i-1) + monthly_savings(i) * distribution(1);
    dollar_savings(i) = dollar_savings(i-1) + monthly_savings(i) * distribution(2) / dollar_rate(i);
    bist100_savings(i) = bist100_savings(i-1) + monthly_savings(i) * distribution(3) / bist100_rate(i);
    bank_savings(i) = interest_calc(bank_savings(i-1), interest_rates(i-1)) + monthly_savings(i) * distribution(4);
    
    % Calculate the current month's total savings
    total_savings_this_month = tl_savings(i) + dollar_savings(i) * dollar_rate(i) + ...
                               bist100_savings(i) * bist100_rate(i) + bank_savings(i);
    
    % Calculate the reward (change in total savings)
    reward = total_savings_this_month - total_savings_last_month;
    
    % Update strategy dynamically (policy learning)
    % The idea is to increase the allocation to the categories that contributed more to the reward
    grad = [tl_savings(i), dollar_savings(i)*dollar_rate(i), bist100_savings(i)*bist100_rate(i), bank_savings(i)] / total_savings_this_month;
    distribution = distribution + learning_rate * grad;  % Gradient ascent step
    
    % Normalize distribution to ensure it sums to 1
    distribution = distribution / sum(distribution);
    
end

% Total savings in TL terms
total_savings_tl = tl_savings + dollar_savings .* dollar_rate + bist100_savings .* bist100_rate + bank_savings;

% Total savings in Dollars
total_savings_dollars = (tl_savings + bank_savings) ./ dollar_rate + dollar_savings + bist100_savings .* (bist100_rate ./ dollar_rate);

% Visualization
months_vector = datetime(2024, 10:9+length(dollar_rate), 1)';

% Visualizing Monthly Savings in TL
figure;
plot(months_vector, tl_savings, '-o', 'DisplayName', 'TL Savings');
hold on;
plot(months_vector, dollar_savings .* dollar_rate, '-s', 'DisplayName', 'Dollar Savings');
plot(months_vector, bist100_savings .* bist100_rate, '-^', 'DisplayName', 'BIST100 Savings');
plot(months_vector, bank_savings, '-d', 'DisplayName', 'Bank Savings');
plot(months_vector, total_savings_tl, '-*', 'DisplayName', 'Total Savings');
title('Monthly Savings Over Time');
xlabel('Month');
ylabel('Savings in TL');
legend;
grid on;

%% Function to calculate interest
function total_earning = interest_calc(bank_saving, interest_rate)
    total_earning = (interest_rate + 1) * bank_saving;
end

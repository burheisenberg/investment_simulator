%% make money
clear, clc, close all
% dolar-tl exchange rate in August 2023 is 27
% dolar-tl exchange rate in September 2024 is 34
% net increase in exchange rate is 26%
% we can expect the worst case exchange rate is 43 (in August 2025)
% optimistic number is below 30 (announced by Wells Fargo)

% bist100 in September 2023 is 7800
% bist100 in September 2024 is 9800

% for both dollar and bist100 annual average change is 26%
% it makes 1.94% monthly increase in average (multiplier of 1.0194)

% tcmb interest rate in August 2024 is 50% annually (3.4% monthly)

% Savings Distribution: 
% 20% TL, 30% Dollars, 20% BIST100, 30% Bank (interest)
distribution = [0.0, 0.0, 0.05, 0.95]; 

% Monthly and initial saving details
initial_saving = 30000;
monthly_savings = [35000, 45000, 35000, 35000, 35000, 35000, 35000, 35000, 35000, 35000, 35000]';
interest_rates = (1+[42    42    42    42    42    42    42    42    42    42    42    42]/100)'.^(1/12)-1; % Monthly interest rates

% Interpolation for Exchange rates and BIST100 index using a growth factor (1.94% monthly increase)
months_in_year = 12; % Defining the number of months for interpolation
growth_rate_dollar = 1.0194; % Monthly increase factor of 1.94% (annual 26%)
growth_rate_bist100 = 1.0194;

% Interpolating exchange rate and BIST100 index over the period
dolar_exch = 34.1 * growth_rate_dollar .^ (0:length(monthly_savings)-1)';
bist100 = 9760 * growth_rate_bist100 .^ (0:length(monthly_savings)-1)';

% Initialize arrays for savings types
tl_savings = zeros(length(monthly_savings), 1); % TL-based savings
dollar_savings = zeros(length(monthly_savings), 1); % Dollar-based savings
bist100_savings = zeros(length(monthly_savings), 1); % BIST100-based savings
bank_savings = zeros(length(monthly_savings), 1); % Savings in the bank (interest-bearing)

% First month savings allocation
tl_savings(1) = (initial_saving+monthly_savings(1)) * distribution(1);
dollar_savings(1) = (initial_saving+monthly_savings(1)) * distribution(2) / dolar_exch(1); 
bist100_savings(1) = (initial_saving+monthly_savings(1)) * distribution(3) / bist100(1); 
bank_savings(1) = (initial_saving+monthly_savings(1)) * distribution(4); % In TL, subject to interest

% Calculate savings over 12 months
[tl_savings, dollar_savings, bist100_savings, bank_savings] = ...
    allocate_savings(monthly_savings, distribution, tl_savings, dollar_savings, bist100_savings, bank_savings, interest_rates, dolar_exch, bist100);

% Total savings combining all forms (in TL)
total_savings_tl = tl_savings + dollar_savings .* dolar_exch + bist100_savings .* bist100 + bank_savings;

% Total savings in dollars
total_savings_dollars = (tl_savings + bank_savings) ./ dolar_exch + dollar_savings + bist100_savings .* (bist100 ./ dolar_exch);

% Create timetable for each savings type
months = datetime(2024, 10:9+length(monthly_savings), 1)';
TT_tl = timetable(months, tl_savings, dollar_savings.*dolar_exch, bist100_savings.*bist100, bank_savings, total_savings_tl);
TT_dollar = timetable(months, tl_savings./dolar_exch, dollar_savings, bist100_savings .* (bist100 ./ dolar_exch), bank_savings./dolar_exch, total_savings_dollars);

% Plot the results in TL
plot_timetable(TT_tl, 'Savings Distribution in TL')

% % Plot the results in Dollars
plot_timetable(TT_dollar, 'Savings Distribution in Dollars')

%% Function to allocate savings
function [tl_savings, dollar_savings, bist100_savings, bank_savings] = ...
    allocate_savings(monthly_savings, distribution, tl_savings, dollar_savings, bist100_savings, bank_savings, interest_rates, dolar_exch, bist100)

for i = 2:length(monthly_savings)
    % Allocate monthly savings based on the distribution
    tl_savings(i) = tl_savings(i-1) + monthly_savings(i) * distribution(1);
    dollar_savings(i) = dollar_savings(i-1) + monthly_savings(i) * distribution(2) / dolar_exch(i);
    bist100_savings(i) = bist100_savings(i-1) + monthly_savings(i) * distribution(3) / bist100(i);
    bank_savings(i) = interest_calc(bank_savings(i-1), interest_rates(i-1)) + monthly_savings(i) * distribution(4); % Bank deposits with interest
end

end

%% Function to calculate interest for bank deposits
function total_earning = interest_calc(bank_saving, interest_rate)
    total_earning = (interest_rate + 1) * bank_saving;
end

%% Function to plot savings timetable
function plot_timetable(time_table, titletext)
    figure;
    months = time_table.months;
    plot(months,time_table.Variables);
    %legend(time_table.Properties.VariableNames);
    legend('TL','Dollar','Bist100','Bank Interest','Total Savings','Location','best')
    title([titletext,' ', num2str(time_table(end,end).Variables)]);
end

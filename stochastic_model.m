%% make money with stochasticity
clear, clc, close
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

% Savings Distribution for each month (20% TL, 30% Dollars, 20% BIST100, 30% Bank initially)
distribution_matrix = [
    0.05, 0.2, 0.2, 0.55;   % Month 1
    0.05, 0.2, 0.2, 0.55;    % Month 2 (Varying allocation)
    0.05, 0.2, 0.2, 0.55;    % Month 3
    0.05, 0.2, 0.2, 0.55;    % Month 4
    0.05, 0.2, 0.2, 0.55;      % Month 5
    0.05, 0.2, 0.2, 0.55;    % Month 6
    0.05, 0.2, 0.2, 0.55;    % Month 7
    0.05, 0.2, 0.2, 0.55;      % Month 8
    0.05, 0.2, 0.2, 0.55;    % Month 9
    0.05, 0.2, 0.2, 0.55;    % Month 10
    0.05, 0.2, 0.2, 0.55];     % Month 11

% Monthly and initial saving details
initial_saving = 30000;
monthly_savings = [0000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 20000, 000]';

% Parameters for stochasticity
stdev_interest = 0.02; % Standard deviation for interest rates
stdev_dollar = 0.02; % Standard deviation for dollar exchange rate (2%)
stdev_bist100 = 0.03; % Standard deviation for BIST100 (3%)

% Interpolation for Exchange rates and BIST100 index using a growth factor (1.94% monthly increase)
months_in_year = 12; % Defining the number of months for interpolation
growth_rate_dollar = 1.26; % Monthly increase factor of 1.94%
growth_rate_bist100 = 1.26;


% Apply random normal perturbations to interest rates, dollar exchange, and bist100
interest_rates = (1+42*ones(length(monthly_savings),1)/100).^(1/12)-1; % Monthly interest rates
dolar_exch = 34.1 * ones(length(monthly_savings),1);
bist100 = 9760 * ones(length(monthly_savings),1);

for i=2:length(monthly_savings)

    interest_rates(i) = interest_rates(i-1) * (1 + stdev_interest * randn());
    dolar_exch(i) = dolar_exch(i-1) * (1 + stdev_dollar * randn()) * 1.0194;
    bist100(i) = bist100(i-1) * (1 + stdev_bist100 * randn()) * 1.0194;

end


% Initialize arrays for savings types
tl_savings = zeros(length(monthly_savings), 1); % TL-based savings
dollar_savings = zeros(length(monthly_savings), 1); % Dollar-based savings
bist100_savings = zeros(length(monthly_savings), 1); % BIST100-based savings
bank_savings = zeros(length(monthly_savings), 1); % Savings in the bank (interest-bearing)

% First month savings allocation (use the first row of the distribution matrix)
tl_savings(1) = (initial_saving+monthly_savings(1)) * distribution_matrix(1,1);
dollar_savings(1) = (initial_saving+monthly_savings(1)) * distribution_matrix(1,2) / dolar_exch(1); 
bist100_savings(1) = (initial_saving+monthly_savings(1)) * distribution_matrix(1,3) / bist100(1); 
bank_savings(1) = (initial_saving+monthly_savings(1)) * distribution_matrix(1,4); % In TL, subject to interest

% Calculate savings over 12 months with varying distributions and stochastic factors
[tl_savings, dollar_savings, bist100_savings, bank_savings] = ...
    allocate_savings(monthly_savings, distribution_matrix, tl_savings, dollar_savings, bist100_savings, bank_savings, interest_rates, dolar_exch, bist100);

% Total savings combining all forms (in TL)
total_savings_tl = tl_savings + dollar_savings .* dolar_exch + bist100_savings .* bist100 + bank_savings;

% Total savings in dollars
total_savings_dollars = (tl_savings + bank_savings) ./ dolar_exch + dollar_savings + bist100_savings .* (bist100 ./ dolar_exch);

% Create timetable for each savings type
months = datetime(2024, 10:9+length(monthly_savings), 1)';
TT_tl = timetable(months, tl_savings, dollar_savings.*dolar_exch, bist100_savings.*bist100, bank_savings, total_savings_tl);
TT_dollar = timetable(months, tl_savings./dolar_exch, dollar_savings, bist100_savings .* (bist100 ./ dolar_exch), bank_savings./dolar_exch, total_savings_dollars);

% Plot the results in TL
plot_timetable(TT_tl, 'Savings Distribution in TL (with stochasticity)')

% % Plot the results in Dollars
plot_timetable(TT_dollar, 'Savings Distribution in Dollars (with stochasticity)')

%% Function to allocate savings with varying distributions
function [tl_savings, dollar_savings, bist100_savings, bank_savings] = ...
    allocate_savings(monthly_savings, distribution_matrix, tl_savings, dollar_savings, bist100_savings, bank_savings, interest_rates, dolar_exch, bist100)

for i = 2:length(monthly_savings)
    % Allocate monthly savings based on the distribution for each month
    tl_savings(i) = tl_savings(i-1) + monthly_savings(i) * distribution_matrix(i,1);
    dollar_savings(i) = dollar_savings(i-1) + monthly_savings(i) * distribution_matrix(i,2) / dolar_exch(i);
    bist100_savings(i) = bist100_savings(i-1) + monthly_savings(i) * distribution_matrix(i,3) / bist100(i);
    bank_savings(i) = interest_calc(bank_savings(i-1), interest_rates(i-1)) + monthly_savings(i) * distribution_matrix(i,4); % Bank deposits with interest
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

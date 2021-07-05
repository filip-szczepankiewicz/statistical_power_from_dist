function    [pow, res] = stat_power_from_dist(g1, g2, alpha, n_tails, do_simulate)
% function    [pow, res] = stat_power_from_dist(g1, g2, alpha, n_tails, do_simulate)
%
% Written by Filip Szczepankiewicz, 2014-03-31
% Updated by Filip Szczepankiewicz, 2020-02-17
%            Clarifications added in the help text.
% Updated by Filip Szczepankiewicz, 2021-07-05
%            Minor corrections to text, added reference, and increased size
%            of simulation.
% 
% If you find this code useful, please cite:
%            Szczepankiewicz F et al. Variability in diffusion kurtosis imaging: impact on study design, 
%            statistical power and interpretation.Neuroimage. 2013 Aug 1;76:145-54. Epub 2013 Mar 16.
%            doi: 10.1016/j.neuroimage.2013.02.078. 
%
%
% OUTPUT:
% pow         - This is the statistical power of the test, i.e., the probability of
%               correctly rejecting the null hypothesis . It is defined as a probability 
%               between 0 and 1, also denoted as 1 - beta where beta is the type II error
%               rate.
% res         - This is a structure that contains the minimum number of subjects
%               per group needed to reach varying levels of statistical
%               power. It also gives an estimated minimum absolute effect
%               size for the same levels of power, assuming the input
%               distribution. It also contains a message about the kind of test
%               that was considered in the calculations.
%
% INPUT:
% g1          - This is a vector containing the information about group 1.
%               The format is: g1 = [mean stddev sampsize].
% g2          - This is the definition of group 2. It can be a vector in
%               the same format as g1, a scalar value, or it can be left empty/undefined.
%               If it is a vector, the test compares the two distributions g1 vs g2.
%               If it is a scalar, the g1 mean is tested for differing from
%               this value. If it is undefined or left empty, it is set to
%               zero; thus g1 is tested for differing from zero.
% alpha       - This is the threshold level of significance.
% n_tails     - This is the number of tails that are included in the test.
%               Note that one tailed tests are directed along the effect direction (m1 - m2).
% do_simulate - simulates the scenario defined in g1 and g2 as a means of
%               validating the results. This option also returns the
%               simulated power and its IQR. Note that this is slow!
%
% EXAMPLES:
%               Example 1:
%               g1 = [1.1 0.1 30];
%               This defines a group with mean = 1.1, stddev = 0.1 and sample size = 30.
%
%               g2 can be either a scalar defining a mean value or a vector in the same
%               format as g1.
%               If g2 is a scalar the distribution defined in g1 is compared to the
%               scalar value. Otherwise the distributions defined in g1 and g2 are
%               compared.
%
%               Assuming that g2 has mean = 1.2, stddev = 0.3 and sample size = 25
%               we get that a two-tailed t-test would have a statistical power
%               of 0.34 at a significance level of 0.05.
%
%               [pow, res] = fsz_calc_power_from_dist([1.1 0.1 30], [1.2 0.3 25], 0.05, 2)
%
%               pow = 0.3375
%
%               res =
%                   pow_dem: [0.7000 0.8000 0.9000 0.9500 0.9900]
%                     n_min: [58 73 98 121 170]
%                    es_min: [0.1617 0.1821 0.2108 0.2352 0.2832]
%                       msg: 'Two-sample t-test'
%
%
%               Example 2:
%               In the first example the power was low. However, the test
%               estimated that if the absolute effect size was increased to 0.2108 the
%               expected power would increase to 0.9. Likewise, the test
%               estimated that the power would be 0.9 if the group size was
%               increased to 98 subjects/samples per group. Lets try it!
%
%               First we change the effect size:
%
%               [pow, res] = fsz_calc_power_from_dist([1.1 0.1 30], [1.1+0.2108 0.3 25], 0.05, 2)
%
%               pow = 0.9004
% 
%               res = 
%                  pow_dem: [0.7000 0.8000 0.9000 0.9500 0.9900]
%                    n_min: [13 17 22 28 39]
%                   es_min: [0.1617 0.1821 0.2108 0.2352 0.2832]
%                      msg: 'Two-sample t-test'
%
%
%               Now we go back to the original effect size (0.1) and change the
%               sample size instead (from 30 and 25 to 98 and 98):
%                
%               [pow, res] = fsz_calc_power_from_dist([1.1 0.1 98], [1.2 0.3 98], 0.05, 2)
% 
%               pow = 0.8739
% 
%               res = 
%                  pow_dem: [0.7000 0.8000 0.9000 0.9500 0.9900]
%                    n_min: [62 79 106 130 184]
%                   es_min: [0.0801 0.0902 0.1044 0.1162 0.1386]
%                      msg: 'Two-sample t-test'
%
%               Note that the estimated group size to get power = 0.9 was
%               underestimated. This is normal, and requires that the
%               test/estimation is performed repeated times, updating the
%               accuracy of the estimation.
%
% ------------------------------------------------------------------------------------------------


% Complete input
if nargin < 2 || isempty(g2)
    g2 = 0;
end

if nargin < 3
    alpha = 0.05;
end

if nargin < 4
    n_tails = 2;
end

if nargin < 5
    do_simulate = 0;
end

verbose = 0;


% Group 1 statistics
m1 = g1(1);
s1 = g1(2);
n1 = g1(3);

% Group 2 Statistics
if numel(g2) == 1 % Test distribution 1 versus scalar value
    m2 = g2;
    s2 = 0;
    n2 = 1;
    
    stat_mode = 1; % Distribution vs scalar
    stat_msg  = 'One-sample t-test';
    
else               % Test distribution 1 vs distribution 2
    m2 = g2(1);
    s2 = g2(2);
    n2 = g2(3);
    
    stat_mode = 2; % Distribution vs distribution
    stat_msg  = 'Two-sample t-test';
    
end


% Check input
if n1 < 2;     error('Size of "group 1" must be > 1!')    ; end
if m1 == m2 && verbose;   warning('The effect size is = 0!')         ; end

if stat_mode == 1
    if n1 < 10 && verbose; warning('Small sample sizes may result in poor power estimation!'); end
    
elseif stat_mode == 2
    if any([n1 n2] < 10) && verbose; warning('Small sample sizes may result in poor power estimation!'); end
    if n2 < 2; error('Size of "group 2" size must be > 1!'); end
    
end



% Absolute effect size (ES)
ES = m1 - m2;

% Standard error of the difference (SE)
SE = sqrt(s1^2/n1 + s2^2/n2);

% t-statistic (t)
t = ES / SE;

% Pooled standard deviation (s12)
s12 = sqrt( ( ( n1-1)*s1^2 + (n2-1)*s2^2 ) / (n1+n2-2));

% Degrees of freedom (df)
switch stat_mode
    case 1
        df = n1 - 1;
    case 2
        df = round(  (s1^2 / n1 + s2^2 / n2)^2 / ...
            ( (s1^2/n1)^2 / (n1 - 1) + (s2^2/n2)^2 / (n2 - 1))  );
end

% Calculate critical t-value
t_crit = tinv(1-alpha/n_tails, df);

% Estimate power
switch n_tails
    case 1
        pow = 1 -       nctcdf(         t_crit, df, abs(t)  );
        
    case 2
        pow = 1 - diff( nctcdf([-1 1] * t_crit, df, abs(t)) );
end

% Define vector containing multiple levels of demanded power for
% the calculation of necessary sample sizes.
pow_dem = [0.7 0.8 0.9 0.95 0.99];

% Estimate minimum effect size detectable at input conditions
t_alpha = tinv(1-alpha/n_tails, df);
t_pi    = tinv(pow_dem, df);

es_min  = SE * (t_alpha + t_pi);

% Estimation of sample sizes assuming z-distribution (underestimation
% expexted for small sample sizes n < 30). t-distribution (tinv) is not
% used because the number of degrees of freedom is unknown. Perhaps this
% can be estimated from the z-distribution first, and then used in
% t-distribution? Alternatively, an itterative calculation can be
% performed.

z_alpha = norminv(1-alpha/n_tails);
z_pi    = norminv(pow_dem);

switch stat_mode
    case 1
        n_min = ceil(    s12^2*(z_alpha + z_pi).^2 / ES^2);
        
    case 2
        n_min = ceil(2 * s12^2*(z_alpha + z_pi).^2 / ES^2);
end

res.pow_dem = pow_dem;
res.n_min   = n_min;
res.es_min  = es_min;
res.msg     = stat_msg;

if any(n_min < 30) && verbose; warning('Small sample sizes (n < 30) are likely to be underestimated!'); end


%% SIMULATE
% Use numerical simulations to validate that the analytical solution is
% accurate. Note that this takes some time!

if do_simulate
    
    if n_tails == 1
        if m1 > m2
            tails = 'right';
        else
            tails = 'left';
        end
    else
        tails = 'both';
    end
    
    iter_o = 100; % Number of outer iterations
    iter_i = 300; % Number of inner iterations
    
    pow_tmp = zeros(iter_o, 1)*nan;
    
    for io = 1:iter_o
        
        h = zeros(iter_i, 1)*nan;
        
        for ii = 1:iter_i
            
            x = m1 + randn(n1, 1) * s1;
            y = m2 + randn(n2, 1) * s2;
            
            switch stat_mode
                case 1
                    [h(ii), p] = ttest (x, y, 'alpha', alpha, 'tail', tails);
                    
                case 2
                    [h(ii), p] = ttest2(x, y, 'alpha', alpha, 'tail', tails, 'vartype', 'unequal');
                    
            end
        end
        
        pow_tmp(io) = sum(h) / iter_i;
        
    end
    
    pow_sim = mean(pow_tmp);
    pow_sim_25prctl = prctile(pow_tmp, 25);
    pow_sim_75prctl = prctile(pow_tmp, 75);
    
    disp(['SIMULATED  POW = ' num2str(pow_sim, 3) ' IQR = [' num2str(pow_sim_25prctl,3 ) ' ' num2str(pow_sim_75prctl, 3) ']'])
    disp(['CALCULATED POW = ' num2str(pow, 3)])
    
end






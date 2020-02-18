# Statistical power calculator
By: Filip Szczepankiewicz  

This is a simple calculator for statistical power implemented in Matlab. Run the function ```stat_power_from_dist(g1, g2, alpha, n_tails, do_simulate)``` and check below for instructions and examples. The code also includes a numerical simulation of the test, so that the result can be rapidly validated, and distribution of statistical power can be extracted.

## Reference
If you use these resources, please cite:  
[Szczepankiewicz F, Lätt J, Wirestam R, Leemans A, Sundgren P, van Westen D, Ståhlberg F, Nilsson M. Variability in diffusion kurtosis imaging: impact on study design, statistical power and interpretation.Neuroimage. 2013 Aug 1;76:145-54. doi: 10.1016/j.neuroimage.2013.02.078. Epub 2013 Mar 16.](https://www.sciencedirect.com/science/article/abs/pii/S1053811913002334?via%3Dihub)

## Description
    function    [pow, res] = stat_power_from_dist(g1, g2, alpha, n_tails, do_simulate)

    Written by Filip Szczepankiewicz, 2014-03-31
    Updated by Filip Szczepankiewicz, 2020-02-17
               Clarifications added in the help text.

    OUTPUT:
    pow         - This is the statistical power of the test, i.e., the probability of
                  correctly rejecting the null hypothesis (that suggested effect does
                  not exists). It is defined as a probability between 0 and
                  1, also denoted as 1 - beta where beta is the type II error
                  rate.
    res         - This is a structure that contains the minimum number of subjects
                  per group needed to reach varying levels of statistical
                  power. It also gives an estimated minimum absolute effect
                  size for the same levels of power, assuming input
                  distribution. It also contains a message about the kind of test
                  that was considered in the calculatitons.

    INPUT:
    g1          - This is a vector containing the information about group 1.
                  The format is: g1 = [mean stddev sampsize].
    g2          - This is the definition of group 2. It can be a vector in
                  the same format as g1, a scalar value, or it can be left empty/undefined.
                  If it is a vector the test compares the two distributions g1 vs g2.
                  If it is a scalar, the g1 mean is tested for differing from
                  this value. If it is undefined or left empty, it is set to
                  zero; thus g1 is tested for differing from zero.
    alpha       - This is the threshold level of significance.
    n_tails     - This is the number of tails that are included in the test.
                  Note that one tailed tests are directed along the effect direction (m1 - m2).
    do_simulate - simulates the scenario defined in g1 and g2 as a means of
                  validating the results. This option also returns the
                  simulated power and its IQR. Note that this is slow!

## Examples
### Example 1
                  g1 = [1.1 0.1 30];
                  This defines a group with mean = 1.1, stddev = 0.1 and sample size = 30.

                  g2 can be either a scalar defining a mean value or a vector in the same
                  format as g1.
                  If g2 is a scalar the distribution defined in g1 is compared to the
                  scalar value. Otherwise the distributions defined in g1 and g2 are
                  compared.

                  Assuming that g2 has mean = 1.2, stddev = 0.3 and sample size = 25
                  we get that a two-tailed t-test would have a statistical power
                  of 0.34 at a significance level of 0.05.

                  [pow, res] = fsz_calc_power_from_dist([1.1 0.1 30], [1.2 0.3 25], 0.05, 2)

                  pow = 0.3375

                  res =
                      pow_dem: [0.7000 0.8000 0.9000 0.9500 0.9900]
                        n_min: [58 73 98 121 170]
                       es_min: [0.1617 0.1821 0.2108 0.2352 0.2832]
                          msg: 'Two-sample t-test'

### Example 2
                  In the first example the power was low. However, the test
                  estimated that if the absolute effect size was increased to 0.2108 the
                  expected power would increase to 0.9. Likewise, the test
                  estimated that the power would be 0.9 if the group size was
                  increased to 98 subjects/samples per group. Lets try it!

                  First we change the effect size:

                  [pow, res] = fsz_calc_power_from_dist([1.1 0.1 30], [1.1+0.2108 0.3 25], 0.05, 2)

                  pow = 0.9004

                  res = 
                     pow_dem: [0.7000 0.8000 0.9000 0.9500 0.9900]
                       n_min: [13 17 22 28 39]
                      es_min: [0.1617 0.1821 0.2108 0.2352 0.2832]
                         msg: 'Two-sample t-test'


                  Now we go back to the original effect size (0.1) and change the
                  sample size instead (from 30 and 25 to 98 and 98):

                  [pow, res] = fsz_calc_power_from_dist([1.1 0.1 98], [1.2 0.3 98], 0.05, 2)

                  pow = 0.8739

                  res = 
                     pow_dem: [0.7000 0.8000 0.9000 0.9500 0.9900]
                       n_min: [62 79 106 130 184]
                      es_min: [0.0801 0.0902 0.1044 0.1162 0.1386]
                         msg: 'Two-sample t-test'

                  Note that the estimated group size to get power = 0.9 was
                  underestimated. This is normal, and requires that the
                  test/estimation is performed repeated times, updating the
                  accuracy of the estimation.

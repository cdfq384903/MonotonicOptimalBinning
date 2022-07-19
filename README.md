# MonotonicOptimalBinning
This project mainly implements the Monotonic Optimal Bining(MOB) algorithm. We extend the application of this algorithm which can be applied to numerical and categorical data. In order to avoid the problem of too many bins, we optimize the p-value and provide bins size first binning and monotonicity first binning methods for user to  discretize data more conveniently.

## How to use
### Step 0. Set up develop environment
1. Make sure you have already sign up sas member. If not please sign up as following https://www.sas.com/profile/ui/#/create<br>
2. Create folder structure as following <br>
<p align="left">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/sas%20folder%20structure1.png" alt="folder structure 1"/>
</p>

### Step 1. Download this repository
  ```git clone https://github.com/cdfq384903/MonotonicOptimalBinning.git```

### Step 2. Upload source code and testing data
1. Upload source code as show below.<br>
<p align="left">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/sas%20folder%20structure2.png" alt="folder structure 2"/>
</p>
Note: we made some modifications to this file(german_data_credit_cat.csv) and detail as show below <br>

a.revise all column names <br>
b.revise the value of CostMatrixRisk <br>

* original value <br>
  * 1 = Good Risk <br>
  * 2 = Bad Risk <br>

* revise value <br>
  * 0 = Good Risk <br>
  * 1 = Bad Risk <br>

### Step 3. Demo

#### Numerical variable

##### Size First Bining(SFB)
Run MainSizeFirstBining.sas script <br>
Note: Undering SFB algorithm. The WoE transformation result of DurationInMonth variable. It presents the monotonicity of WoE. <br>
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/SFB%20WoE%20Bar%20chart%20v2.png" width="600" hight="600"/>
</p>

Note: Undering SFB algorithm. The WoE transformation result of CreditAmount variable. It violates the monotonicity of WoE because SBF will preferentially terminate the merged result according to the limit of bins parameter.<br>
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/SFB%20WoE%20Bar%20chart%20v13.png" width="600" hight="600"/>
</p>

##### Monotonic First Bining(MFB)
Run MainMonotonicFirstBining.sas script <br>
Note: Undering MFB algorithm. The WoE transformation result of DurationInMonth variable. It presents the monotonicity of WoE. <br>
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/MFB%20WoE%20Bar%20chart%20v2.png" width="600" hight="600"/>
</p>

Note: Undering MFB algorithm. The WoE transformation result of DurationInMonth variable. It presents the monotonicity of WoE, but it is likely to lead to issues such as excessive sample proportion and less number of bins size.<br>
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/MFB%20WoE%20Bar%20chart%20v13.png" width="600" hight="600"/>
</p>

#### Categorical variable

## Conclusion
XXXXXXXXXXXXXXXXXXXX

# Appendix

## The MonotonicOptimalBining core class

### Running the MOB algorithm macro
The code below shows the execution of the MFB macro with recommended parameters.
1. %init(data_table, y, x, exclude_condi, min_samples, min_bads, min_pvalue, 
      show_woe_plot, is_using_encoding_var, lib_name); <br>
2. %initMonotonicFirstBining();<br>
3. %runMob();<br>

The code below shows the execution of the SFB macro with recommended parameters.
1. %init(data_table, y, x, exclude_condi, min_samples, min_bads, min_pvalue, 
      show_woe_plot , is_using_encoding_var , lib_name ); </br>
2. %initSizeFirstBining(max_samples , min_bins , max_bins); </br>
3. %runMob(); </br> 

#### Arguments
1. data_table </br>
Default: None </br>
Suggestion: a training data set. </br>
The data_table argument defines the input data set. This set includes all candidate predictor variables and the target variable. For example, in MainMonotonicFirstBining.sas script you can try german_credit_card which is the data table structure after implement %readCsvFile macro.</br>

2. y </br>
Default: None </br>
Suggestion: The label name of response variable.</br>
The y argument defines the label name of response variable. For example, in MainMonotonicFirstBining.sas script you can try CostMatrixRisk under the data of german_credit_card.

3. x </br>
Default: None </br>
Suggestion: The label names of predictor variable.</br>
The x argument defines the label names of predictor variable. For example, in MainMonotonicFirstBining.sas script you can try AgeInYears CreditAmount DurationInMonth under the data of german_credit_card.

4. exclude_condi </br>
Default: None </br>
Suggestion: </br>

5. min_samples </br>
Default: None </br>
Suggestion: </br>

6. min_bads </br>
Default: None </br>
Suggestion: </br>

7. min_pvalue </br>
Default: None </br>
Suggestion: </br>

8. show_woe_plot </br>
Default: None </br>
Suggestion: </br>

9. is_using_encoding_var </br>
Default: None </br>
Suggestion: </br>

10. lib_name </br>
Default: None </br>
Suggestion: </br>

#### Output

### Print WoE result
The code below shows the execution of the printWithoutCname macro with recommended parameters.
1. %printWithoutCname(lib_name = &lib_name.); <br>

#### Arguments
1. lib_name </br>
Default: None </br>
Suggestion: </br>

#### Output

### Generate the IV summary table
The code below shows the execution of the getIvPerVar macro with recommended parameters.
1. %getIvPerVar(lib_name = &lib_name., min_iv = 0.06, min_obs_rate = 0.05, 
             max_obs_rate = 0.8, min_bin_size = 3, max_bin_size = 10, 
             min_bad_count = 1); <br>

#### Arguments
1. lib_name </br>
Default: None </br>
Suggestion: </br>

2. min_iv </br>
Default: None </br>
Suggestion: </br>

3. min_obs_rate </br>
Default: None </br>
Suggestion: </br>

4. max_obs_rate </br>
Default: None </br>
Suggestion: </br>

5. min_bin_size </br>
Default: None </br>
Suggestion: </br>

6. max_bin_size </br>
Default: None </br>
Suggestion: </br>

7. min_bad_count </br>
Default: None </br>
Suggestion: </br>

#### Output

### Print WoE bar chart via IV summary filter
The code below shows the execution of the printWoeBarLineChart macro with recommended parameters.
1. %printWoeBarLineChart(lib_name = &lib_name., min_iv = 0.001); <br>

#### Arguments
1. lib_name </br>
Default: None </br>
Suggestion: </br>

2. min_iv </br>
Default: None </br>
Suggestion: </br>

#### Output

### Generate split rule
The code below shows the execution of the exportSplitRule macro with recommended parameters.
1. %exportSplitRule(lib_name = &lib_name., output_file = /home/u60021675/output/); <br>

#### Arguments
1. lib_name </br>
Default: None </br>
Suggestion: </br>

2. output_file </br>
Default: None </br>
Suggestion: </br>

#### Output

### Clear useless data table
The code below shows the execution of the cleanBinsDetail macro with recommended parameters.
1. %cleanBinsDetail(bins_lib = &lib_name.); <br>

#### Arguments
1. bins_lib </br>
Default: None </br>
Suggestion: </br>

#### Output

## Monotonic Optimal Bining algorithm flow chart

### Numerical variable
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/chart/flow/mob%20algorithm%20flow%20chart%20for%20numerical%20version.jpg" alt="The Algorithm flow chart for numerical MOB"/>
</p>

### Categorical variable
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/chart/flow/mob%20algorithm%20flow%20chart%20for%20categorical%20version.jpg" alt="The Algorithm flow chart for categorical MOB"/>
</p>

## Enviroment
1. SAS Studio 3.8 on SAS 9.4

# References
1. German Credit Risk Analysis : Beginner's Guide . (2022). Retrieved 9 June 2022, from https://www.kaggle.com/code/pahulpreet/german-credit-risk-analysis-beginner-s-guide/notebook <br>
2. Mironchyk, Pavel, and Viktor Tchistiakov. 2017. Monotone Optimal Binning Algorithm for Credit Risk Modeling. <br>
3. SAS OnDemand for Academics. (2022). Retrieved 9 June 2022, from https://www.sas.com/zh_tw/software/on-demand-for-academics.html <br>

# Authors
1. Darren Tsai(https://www.linkedin.com/in/yu-cheng-tsai-40137a117/) <br>
2. Denny Chen() <br>
3. <br>

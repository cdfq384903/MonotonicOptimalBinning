<h1><p align = "center">
 Monotonic Optimal Binning in Credit Risk
</p></h1>


This project mainly implements the Monotonic Optimal Bining(MOB) algorithm in `SAS 9.4`. We extend the application of this algorithm which can be applied to numerical and categorical data. In order to avoid the problem of too many bins, we optimize the p-value and provide `bins size first binning` and `monotonicity first binning` methods for users to discretize data more conveniently.

## How to use
### Step 0. Set up develop environment
1. Make sure you have already signed up a account. If not please sign up as following https://www.sas.com/profile/ui/#/create<br>
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
1. **data_table** </br>
Default: None </br>
Suggestion: a training data set. </br>
The data_table argument defines the input data set. This set includes all candidate predictor variables and the target variable. For example, in MainMonotonicFirstBining.sas script you can try german_credit_card which is the data table structure after implement %readCsvFile macro.</br>

2. **y** </br>
Default: None </br>
Suggestion: The label name of response variable. </br>
The y argument defines the label name of response variable. For example, in MainMonotonicFirstBining.sas script you can try CostMatrixRisk under the data of german_credit_card.

3. **x** </br>
Default: None </br>
Suggestion: The label names of predictor variable. </br>
The x argument defines the label names of predictor variable. For example, in MainMonotonicFirstBining.sas script you can try AgeInYears CreditAmount DurationInMonth under the data of german_credit_card.

4. **exclude_condi** </br>
Default: None </br>
Suggestion: The syntax of exclude condition per each predictor variable. </br>
The exclude_condi argument defines the syntax of exclude condition per each predictor variable. For example, in MainMonotonicFirstBining.sas script you can try <-99999999. It means the algorithm will be excluded when the value of every predictor variable less then -99999999.

5. **min_samples** </br>
Default: None </br>
Suggestion: The minimum sample will be keep per each bins. Usually minimum sample parameter suggest to be 5% of population. </br>
The min_samples argument defines the sample wiil be keep per each bins. For example, in MainMonotonicFirstBining.sas script you can try %sysevalf(1000 * 0.05). It means the minimum samples will be constrain by 5% of population.

6. **min_bads** </br>
Default: None </br>
Suggestion: The minimum bads will be keep per bins. Usually minimum bads parameter suggest to be 1. </br>
The min_bads argument defines the bads will be keep per bins. For example, in MainMonotonicFirstBining.sas script you can try 10. It means the minimum bads will be constrain by 10.

7. **min_pvalue** </br>
Default: None </br>
Suggestion: The minimum threshold of p value is the merge constraints when algorithm doing merge process between bins. Usually more higher minimum p value the algorithm will not merge between bins. </br>
The min_pvalue argument defines the minimum threshold of p value. For eaxmple, in MainMonotonicFirstBining.sas script you can try 0.35. It means when algorithm doing the process of bins merge. The bin will be merge between i and i+1, if the test of statistic value(like z or chi) is higher than 0.35.

8. **show_woe_plot** </br>
Default: None </br>
Suggestion: The boolean(0, 1) of show woe plot result when doing mob algorithm. </br>
The show_woe_plot argument defines the boolean(0, 1) of show woe plot result. For example, in MainMonotonicFirstBining.sas script you can try 1. It means when algorithm doing binning. It will show the woe result per each predictor variable.

9. **is_using_encoding_var** </br>
Default: None </br>
Suggestion: The boolean(0, 1) of using encoding var table. If your length of label name(x or y) is too long for sas macro, suggest you should open this parameter. </br>
The is_using_encoding_var argument defines the boolean(0, 1) of using encoding var table. For example, in MainMonotonicFirstBining.sas script you can try 1. It means the attributes name of data will be changed to be encoding variable.

10. **lib_name** </br>
Default: None </br>
Suggestion: The library name will be output. If you don't have any idea, you can try work. </br>
The lib_name argument defines the output library name will be stroed. For example, in MainMonotonicFirstBining.sas script you can try TMPWOE. It means the output will be stored under the TMPWOE(/home/u60021675/output) of WORK folder.

11. **max_samples** </br>
Default: None </br>
Suggestion: Only for initSizeFirstBining macro. The maximum sample will be keep per each bins. Usually maximum sample parameter suggest to be 40% of population. </br>
The max_samples argument defines the sample wiil be keep per each bins. For example, in MainSizeFirstBining.sas script you can try %sysevalf(1000 * 0.4). It means the maximum samples will be constrain by 40% of population.

12. **min_bins** </br>
Default: None </br>
Suggestion: Only for initSizeFirstBining macro. The minimum bins will be keep in binning process. </br>
The min_bins argument defines the minimum bins will be keep in binning process. For example, in MainSizeFirstBining.sas script you can try 3. It means the minimum bins will constraine to be 3.

13. **max_bins** </br>
Default: None </br>
Suggestion: Only for initSizeFirstBining macro. The maximum bins will be keep in binning process. Note that max_bins must to be higher than min_bins.</br>
The max_bins argument defines the maximum bins will be keep in binning process. For example, in MainSizeFirstBining.sas script you can try 7. It means the maximum bins will constraine to be 7.

#### Output
1. The output file after finished MOB algorithm.
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/mob%20output%20result.jpg" alt=""/>
</p>

2. The woe summary result after finished MOB algorithm
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/woe%20summary%20v2.png" alt=""/>
</p>

### Print WoE result
The code below shows the execution of the printWithoutCname macro with recommended parameters. <br>
%printWithoutCname(lib_name); <br>

#### Arguments
1. **lib_name** </br>
Default: None </br>
Suggestion: The library which will be loaded and show woe summary result. </br>
The lib_name argument defines the library which will be loaded and show woe summary result. For example, in MainMonotonicFirstBining.sas script you can try TMPWOE. It means the printWithoutCname macro will load the TMPWOE(/home/u60021675/output) of WORK folder.

#### Output
The output of runing printWithoutCname macro. It shows the result of all variable which was discretized.
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/printWithoutCname.png" alt=""/>
</p>

### Generate the IV summary table
The code below shows the execution of the getIvPerVar macro with recommended parameters. <br>
%getIvPerVar(lib_name, min_iv, min_obs_rate, max_obs_rate, min_bin_size, max_bin_size, min_bad_count); <br>

#### Arguments
1. **lib_name** </br>
Default: None </br>
Suggestion: The library which will be loaded and show IV summary result. </br>
The lib_name argument defines the library which will be loaded and show IV summary result. For example, in MainMonotonicFirstBining.sas script you can try TMPWOE. It means the getIvPerVar macro will load the TMPWOE(/home/u60021675/output) of WORK folder.

2. **min_iv** </br>
Default: None </br>
Suggestion: The minimum threshold of information value. Usually set more higher than 0.1. </br>
The min_iv argument defines the minimum threshold of information value. For example, in MainMonotonicFirstBining.sas script you can try 0.1. It means the getIvPerVar macro will show IV pass result if IV higher than 0.1.

3. **min_obs_rate** </br>
Default: None </br>
Suggestion: The minimum threshold of observation rate. Usually set at least 0.05. </br>
The min_obs_rate argument defines minimum threshold of observation rate. For example, in MainMonotonicFirstBining.sas script you can try 0.05. It means the getIvPerVar macro will show observation rate pass result if value higher than 0.05 and lower than max_obs_rate.

4. **max_obs_rate** </br>
Default: None </br>
Suggestion: The maximum threshold of observation rate. Usually set around 0.8. </br>
The max_obs_rate argument defines maximum threshold of observation rate. For example, in MainMonotonicFirstBining.sas script you can try 0.8. It means the getIvPerVar macro will show observation rate pass result if value lower than 0.8 and higher than min_obs_rate.

5. **min_bin_size** </br>
Default: None </br>
Suggestion: The minimum threshold of bins size. Usually set at least 3. </br>
The min_bin_size argument defines the minimum threshold of bins size. For example, in MainMonotonicFirstBining.sas script you can try 3. It means the getIvPerVar macro will show bins size pass result if value higher than 3 and lower than max_bin_size.

6. **max_bin_size** </br>
Default: None </br>
Suggestion: The maximum threshold of bins size. Usually set at least 10. </br>
The max_bin_size argument defines the maximum threshold of bins size. For example, in MainMonotonicFirstBining.sas script you can try 10. It means the getIvPerVar macro will show bins size pass result if value lower than 10 and higher than min_bin_size.

7. **min_bad_count** </br>
Default: None </br>
Suggestion: The minimum threshold of bad count. Usually set at least 1. </br>
The min_bad_count argument defines the minimum threshold of bad count. For example, in MainMonotonicFirstBining.sas script you can try 1. It means the getIvPerVar macro will show bad count result if value higher than 1 and higher than min_bad_count.

#### Output
The output of runing getIvPerVar macro. It shows the IV information for all discretized variable. There are some additional notes.
1. iv: the information value per each discretized variable.
2. is_iv_pass: true(1) if IV higher than min_iv else than false(0).
3. is_obs_pass: true(1) if observation rate between min_obs_rate and max_obs_rate else than false(0).
4. is_bad_count_pass: true(1) if bad count higher than min_bad_count else than false(0).
5. is_bin_pass: true(1) if bin size between min_bin_size and max_bin_size else than false(0).
6. is_woe_pass: true(1) if the value of WoE have monotonicity properties else than false(0).
7. woe_dir: asc if the WoE value have monotonically increasing, desc if the WoE value have monotonically decreasing else than null.

<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/getIvPerVar.png" alt=""/>
</p>

### Print WoE bar chart via IV summary filter
The code below shows the execution of the printWoeBarLineChart macro with recommended parameters. <br>
%printWoeBarLineChart(lib_name, min_iv); <br>

#### Arguments
1. **lib_name** </br>
Default: None </br>
Suggestion: The library which will be loaded and print WoE bar chart via IV summary. </br>
The lib_name argument defines the library which will be loaded and print WoE bar chart via IV summary. For example, in MainMonotonicFirstBining.sas script you can try TMPWOE. It means the printWoeBarLineChart macro will load the TMPWOE(/home/u60021675/output) of WORK folder.

2. **min_iv** </br>
Default: None </br>
Suggestion: The minimum threshold of information value. Usually set more higher than 0.1. </br>
The min_iv argument defines the minimum threshold of information value. For example, in MainMonotonicFirstBining.sas script you can try 0.001. It means the printWoeBarLineChart macro will show result if IV higher than 0.001.

#### Output
The output of runing printWoeBarLineChart macro. It shows the variable of woe result under the min_iv constrain.
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/printWoeBarLineChart.png" alt=""/>
</p>

### Generate split rule
The code below shows the execution of the exportSplitRule macro with recommended parameters. <br>
1. %exportSplitRule(lib_name, output_file); <br>

#### Arguments
1. **lib_name** </br>
Default: None </br>
Suggestion: The library which will be loaded and export split rule. </br>
The lib_name argument defines the library which will be loaded and export split rule. For example, in MainMonotonicFirstBining.sas script you can try TMPWOE. It means the exportSplitRule macro will load the TMPWOE(/home/u60021675/output) of WORK folder.

2. **output_file** </br>
Default: None </br>
Suggestion: The output file path which will be export split rule. </br>
The output_file argument defines the output file path which will be export split rule. For example, in MainMonotonicFirstBining.sas script you can try /home/u60021675/output/. It means the exportSplitRule macro will export split rule on /home/u60021675/output/.

#### Output
The output of runing exportSplitRule macro. It shows the binning split rule which was discretized.
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/exportSplitRule.jpg" alt=""/>
</p>

### Clear useless data table
The code below shows the execution of the cleanBinsDetail macro with recommended parameters. <br>
%cleanBinsDetail(bins_lib); <br>

#### Arguments
1. **bins_lib** </br>
Default: None </br>
Suggestion: The library which will be clear useless file. Suggest using the same value with %init macro.</br>
The bins_lib argument defines the library which will be clear useless file. For example, in MainMonotonicFirstBining.sas script you can try TMPWOE. It means bins_summary and exclude file was be deleted on TMPWOE(/home/u60021675/output) of WORK folder.

#### Output
The output of runing cleanBinsDetail macro. It shows the bins_summary and exclude file was be deleted.
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/cleanBinsDetail.png" alt=""/>
</p>

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
2. Denny Chen(https://www.linkedin.com/in/dennychen-tahung/) <br>
3. Thea Chan(yahui0219@gmail.com)<br>

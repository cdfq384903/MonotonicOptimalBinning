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
Run MainSizeFirstBining script <br>
Note: Undering SFB algorithm. The WoE transformation result of DurationInMonth variable. It presents the monotonicity of WoE. <br>
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/SFB%20WoE%20Bar%20chart%20v2.png" width="600" hight="600"/>
</p>

Note: Undering SFB algorithm. The WoE transformation result of CreditAmount variable. It violates the monotonicity of WoE because SBF will preferentially terminate the merged result according to the limit of bins parameter.<br>
<p align="center">
  <img src="https://github.com/cdfq384903/MonotonicOptimalBinning/blob/main/doc/snapshot/SFB%20WoE%20Bar%20chart%20v13.png" width="600" hight="600"/>
</p>

##### Monotonic First Bining(MFB)
Run MainMonotonicFirstBining script <br>
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
The code below shows the execution of the MOB macro with recommended parameters.
1. <br>
2. <br>
3. <br>

#### Arguments
#### Output

### Print WoE result
The code below shows the execution of the printWithoutCname macro with recommended parameters.
1. <br>

#### Arguments
#### Output

### Generate the IV summary table
The code below shows the execution of the getIvPerVar macro with recommended parameters.
1. <br>

#### Arguments
#### Output

### Print WoE bar chart via IV summary filter
The code below shows the execution of the printWoeBarLineChart macro with recommended parameters.
1. <br>

#### Arguments
#### Output

### Generate split rule
The code below shows the execution of the exportSplitRule macro with recommended parameters.
1. <br>

#### Arguments
#### Output

### Clear useless data table
The code below shows the execution of the cleanBinsDetail macro with recommended parameters.
1. <br>

#### Arguments
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

# Reference
1.German Credit Risk Analysis : Beginner's Guide . (2022). Retrieved 9 June 2022, from https://www.kaggle.com/code/pahulpreet/german-credit-risk-analysis-beginner-s-guide/notebook <br>
2.H. Liu, F. Hussain, C.L. Tan, and M. Dash. Discretization: An enabling technique. Data Mining and Knowledge Discovery, 6(4):393–423, 2002. <br>
3.Mironchyk, Pavel, and Viktor Tchistiakov. 2017. Monotone Optimal Binning Algorithm for Credit Risk Modeling. <br>
4.SAS OnDemand for Academics. (2022). Retrieved 9 June 2022, from https://www.sas.com/zh_tw/software/on-demand-for-academics.html <br>

# Author
1.Darren Tsai(https://www.linkedin.com/in/yu-cheng-tsai-40137a117/) <br>
2. <br>
3. <br>

options mprint;
%INCLUDE "E:\UPL_MODEL\PwC_DNTI\src\woe\mob\MonotonicOptimalBining.sas" ;
LIBNAME TMPWOE "E:\UPL_MODEL\PwC_DNTI\data\tmp\woe";

/*-----------------------------以下為使用測試資料進行MOB演算法測試-----------------------------*/
%readCsvFile(inputFileAbsPath = "E:\UPL_MODEL\PwC_DNTI\data\tmp\Training50_example.csv", 
             encoding = "ascii", outputFileAbsPath = work.Training50);

/*for init parameter*/
%let data_table = Training50;
%let y = Creditability;
%let x = AgeYears CreditAmount DurationOfCreditMonth ForeignWorker;
/*%let x = AgeYears;*/
%let exclude_condi = < -99999999;
%let min_samples = %sysevalf(500 * 0.05);
%let min_bads = 10;
%let min_pvalue = 0.35;
%let show_woe_plot = 1;
%let lib_name = TMPWOE;
%let is_using_encoding_var = 1;

/*for SFB*/
%let min_bins = 3;
%let max_samples = %sysevalf(500 * 0.4);

%init(data_table = &data_table., y = &y., x = &x., exclude_condi = &exclude_condi., 
      min_samples = &min_samples., min_bads = &min_bads., min_pvalue = &min_pvalue., 
      show_woe_plot = &show_woe_plot.,
      is_using_encoding_var = &is_using_encoding_var., lib_name = TMPWOE);
%initSizeFirstBining(max_samples = &max_samples., min_bins = &min_bins., max_bins = 7);
%runMob();

/*print woe information for all variable*/
%printWithoutCname(lib_name = &lib_name.);

/*get iv summary table*/
%getIvPerVar(lib_name = &lib_name., min_iv = 0.06, min_obs_rate = 0.05, 
             max_obs_rate = 0.8, min_bin_size = 3, max_bin_size = 10, 
             min_bad_count = 1);

/*print woe plot for iv constrain*/
%printWoeBarLineChart(lib_name = &lib_name., min_iv = 0.04);

/*generate split rule*/
%exportSplitRule(lib_name = &lib_name., output_file = E:\UPL_MODEL\PwC_DNTI\data\tmp\woe);

/*clean data table ex:bins_summary/bins_summary_pvalue/exclude/...etc.*/
%cleanBinsDetail(bins_lib = &lib_name.);


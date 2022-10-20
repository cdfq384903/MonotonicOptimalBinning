options nonotes;
* options mprint; /*open it if you want to debug code*/

%INCLUDE "/home/u60021675/src/main/sas/handler/FileHandler.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/mob/MonotonicOptimalBining.sas" ;
LIBNAME TMPWOE "/home/u60021675/output";

/*-----------------------------for testing case-----------------------------*/
%readCsvFile(inputFileAbsPath = "/home/u60021675/data/german_data_credit_cat.csv", 
             encoding = "ascii", outputFileAbsPath = work.german_credit_card);

/*for init parameter*/
%let data_table = german_credit_card;
%let y = default;
%let x = Age Creditamount Durationinmonth;
%let exclude_condi = < -99999999;
%let init_sign = auto ;
%let min_samples = %sysevalf(1000 * 0.05);
%let min_bads = 10;
%let min_pvalue = 0.35;
%let show_woe_plot = 1;
%let lib_name = TMPWOE;
%let is_using_encoding_var = 1;

/*for SFB*/
%let min_bins = 3;
%let max_samples = %sysevalf(1000 * 0.4);

PROC DATASETS lib = TMPWOE kill ; QUIT ;RUN ;
%init(data_table = &data_table., y = &y., x = &x., exclude_condi = &exclude_condi., init_sign = &init_sign., 
      min_samples = &min_samples., min_bads = &min_bads., min_pvalue = &min_pvalue., 
      show_woe_plot = &show_woe_plot.,
      is_using_encoding_var = &is_using_encoding_var., lib_name = &lib_name.);
%initSizeFirstBining(max_samples = &max_samples., min_bins = &min_bins., max_bins = 7);
%runMob();

/*print woe information for all variable*/
%printWithoutCname(lib_name = &lib_name.);

/*get iv summary table*/
%getIvPerVar(lib_name = &lib_name., min_iv = 0.06, min_obs_rate = 0.05, 
             max_obs_rate = 0.8, min_bin_size = 3, max_bin_size = 10, 
             min_bad_count = 1);

/*print woe plot for iv constrain*/
%printWoeBarLineChart(lib_name = &lib_name., min_iv = 0.001);

/*generate split rule*/
%exportSplitRule(lib_name = &lib_name., output_file = /home/u60021675/output/);

/*clean data table ex:bins_summary/bins_summary_pvalue/exclude/...etc.*/
%cleanBinsDetail(bins_lib = &lib_name.);


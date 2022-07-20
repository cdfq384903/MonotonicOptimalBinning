options mprint mprintnest compress=yes;
/* options nonotes compress=yes; */

/* Init */
LIBNAME TMPWOE "/home/u60021675/output";
%INCLUDE "/home/u60021675/src/main/sas/handler/FileHandler.sas" ;
%include "/home/u60021675/src/main/sas/mob/cat/ChiMerge.sas" ;

/*-----------------------------for testing case-----------------------------*/
%readCsvFile(inputFileAbsPath = "/home/u60021675/data/german_data_credit_cat.csv", 
             encoding = "ascii", outputFileAbsPath = work.german_credit_card);

%let data_table = german_credit_card;
%let y = CostMatrixRisk;
%let x = Purpose;

%RunChiMerge(dataFrame = german_credit_card, x = &x., y = &y., 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = TMPWOE) ;

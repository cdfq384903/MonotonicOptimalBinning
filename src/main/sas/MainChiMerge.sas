options mprint mprintnest compress=yes;
options nonotes compress=yes;
/* Init */
LIBNAME MS "E:\UPL_MODEL\Milestone";
LIBNAME chitest "E:\UPL_MODEL\PwC_DNTI\src\woe\chi_test_lib" ;
%include "E:\UPL_MODEL\PwC_DNTI\src\woe\ChiMerge.sas" ;

%RunChiMerge(dataFrame = MS.c1_train, x = T1_49, y = DELQ_M2_18M_BAD_FLG, 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = chitest) ;

%RunChiMerge(dataFrame = MS.c1_train, x = T2_22, y = DELQ_M2_18M_BAD_FLG, 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = chitest) ;

DATA check ;
	set MS.c1_train ;
	keep T1_49 T2_22 ;
RUN;

/* !=!=!=!=!=!=!=!=!=!=!=! Test Zone !=!=!=!=!=!=!=!=!=!=!=! */
DATA test_t2_22 ;
	set MS.c1_train(keep=DELQ_M2_18M_BAD_FLG T2_22) ;
	length temp $50 ;
	if missing(T2_22) then temp = "missing" ;
		else temp = put(T2_22, $32.) ;
	temp1 = strip(temp) ;
RUN ;



DATA chitest.test_case ;
	set MS.application_longlist_0309 (where=(SAMPLE_M2_18M = "Train")) ;
RUN ;


%RunChiMerge(dataFrame = chitest.test_case, x = T1_49, y = DELQ_M2_18M_BAD_FLG, 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = chitest) ;

%RunChiMerge(dataFrame = chitest.test_case, x = T1_3, y = DELQ_M2_18M_BAD_FLG, 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = chitest) ;

%RunChiMerge(dataFrame = chitest.test_case, x = T1_9, y = DELQ_M2_18M_BAD_FLG, 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = chitest) ;

%RunChiMerge(dataFrame = chitest.test_case, x = T1_14, y = DELQ_M2_18M_BAD_FLG, 
			 max_bins_threshold = 30, min_bins = 4, max_bins = 6, 
			 min_samples = 0.05, max_samples = 0.4, 
			 p_value_threshold = 0.35, 
			 libName = chitest) ;


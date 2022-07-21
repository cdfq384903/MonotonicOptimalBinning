%MACRO RunChiMerge(dataFrame, x, y, max_bins_threshold, min_bins, max_bins, min_samples, max_samples, p_value_threshold, libName) ;
	%put ============================ Variable [&x.] : START ============================ ;
	%Create_Status_Table(&libName.) ;
	%Check_Init_Bins_Cnt(&dataFrame., &y., &x., &max_bins_threshold., &libName.) ;
	%Get_Status(&libName., init_bins_check_status) ;
	%if "&init_bins_check_status." = "Stop" %then /* 不合併 */  
		%do ;
			%put - Too many unique values in Variable [&x.] --> &init_bins_check_status. ;
			%goto end_merge_init_bins_cnt ;
		%end ;	
	%else  /* 開始合併WoE */ 
		%do ;
			%Create_Grp_Summary(&dataFrame., &y., &x., &min_bins., &max_bins., &min_samples., &max_samples., &libName.) ;
			%Get_Status(&libName., grp_summary_status) ;
			%if "&grp_summary_status." = "Stop" %then /* 原始資料欄位組數就不超過 min_bins，不需合併 */
				%do ;
					%put - No need to Merge due to initial bins count is less than &min_bins. ;
					%put - Create WoE Summary Table ;
					%Output_WoE_Summary(&x., &libName.) ;
				%end ;
			%else 
				%do ;
					%Merge_by_Chi_Loop(&dataFrame., &x., &y., &min_bins., &max_bins., &min_samples., &max_samples., &p_value_threshold., &libName.) ;
					%Get_Status(&libName., merged_status) ;
					%if "&merged_status." = "Stop" %then 
						%do ;
							%put - Create WoE Summary Table ;
							%Output_WoE_Summary(&x., &libName.) ;
						%end ;
					%else 
						%do ;
							%Get_WorkFlow(&libName., chi_merge_WorkFlow) ;
							%put  - Early Stop at [%sysfunc(trimn(&chi_merge_WorkFlow.))]. ;
						%end ;
				%end ;
		%end ;
	%end_merge_init_bins_cnt: 
	%Clean_Library(WORK, &x.) ;
	%Reset_Variables() ;
	%put ============================ Variable [&x.] : END ============================ ;
%MEND ;

%MACRO Create_Status_Table(libName) ;
	DATA &libName..Status ;
		format WORK_FLOW $30. STATUS $4. ; stop ;
	RUN ;
	PROC SQL ;
		insert into &libName..Status
		values("initial_create", "Null") ;
	QUIT ;
%MEND ;

%MACRO Get_Status(libName, current_status_var_name) ;
	%global &current_status_var_name. ;
	PROC SQL noprint;
		select trimn(STATUS) into : &current_status_var_name. 
		from &libName..Status ;
	QUIT ;
%MEND ;
%MACRO Get_WorkFlow(libName, current_workflow_var_name) ;
	%global &current_workflow_var_name. ;
	PROC SQL noprint;
		select trimn(WORK_FLOW) into : &current_workflow_var_name. 
		from &libName..Status ;
	QUIT ;
%MEND ;
%MACRO Set_Status_Table(libName, current_work_flow, status) ;
	PROC SQL ;
		update &libName..Status 
		set WORK_FLOW = "&current_work_flow.", STATUS = "&status." ;
	QUIT ;
%MEND ;

%MACRO Check_Init_Bins_Cnt(dataFrame, y, x, max_bins_threshold, libName);
	PROC SQL noprint ;
		select count(distinct &x.) into : init_bins_cnt
		from &dataFrame.;	
	QUIT ;

	%if &init_bins_cnt. >= &max_bins_threshold. %then /* 初始就太多組，不切 */
		%do ;
			%Set_Status_Table(&libName., Init_Bins_Cnt_Check, Stop);
		%end ;
	%else 
		%do ;
			%Set_Status_Table(&libName., Init_Bins_Cnt_Check, Null);
		%end ;
%MEND ;

%MACRO Create_Grp_Summary(dataFrame, y, x, min_bins, max_bins, min_samples, max_samples, libName) ;
	PROC SQL noprint ;
		select count(*), sum(&y.), count(*) - sum(&y.) into :Total_OBS, :ToTal_Bad, :Total_Good
		from &dataFrame. ;
	QUIT ;
	
	%if 0 < &max_samples. <= 1 %then 
		%do  ;
			PROC SQL noprint ;
				select count(*) * &max_samples. into :max_samples_size 
				from &dataFrame. ;
			QUIT ;
		%end ;
	%else 
		%do ;
			%let max_samples_size = &max_samples. ;
		%end ;

	%if 0 < &min_samples. <= 1 %then 
		%do  ;
			PROC SQL noprint ;
				select count(*) * &min_samples. into :min_samples_size 
				from &dataFrame. ;
			QUIT ;
		%end ;
	%else 
		%do ;
			%let min_samples_size = &min_samples. ;
		%end ;
	/*
	Variables :
	- Total_OBS : 總樣本數
	- Total_Bad : 總壞件數
	- Total_Good: 總好件數
	*/	
	PROC SQL ;
		create table &libName..grps_summary_chi_&x. as
		select	&x.,
				count(*) as OBS_CNT,
				count(*) / &Total_OBS. as OBS_DIST,
				sum(&y.) as BAD_CNT,
				sum(&y.) / &Total_Bad as BAD_DIST,
				count(*) - sum(&y.) as GOOD_CNT,
				(count(*) - sum(&y.)) / &Total_Good. as GOOD_DIST
		from &dataFrame.
		group by &x. ;
	QUIT ;

	DATA &libName..grps_summary_chi_&x. ;
		set &libName..grps_summary_chi_&x. ;
		if OBS_CNT < &min_samples_size. then must_merge_flg = 1 ;
			else must_merge_flg = 0 ;
		if OBS_CNT > &max_samples_size. then remain_const_flg = 1 ;
			else remain_const_flg = 0 ;
		GRP_ID = _n_ ;
	RUN ;

	PROC SQL noprint ;	
		select max(GRP_ID) into :max_groups
		from &libName..grps_summary_chi_&x. ;
		
		select sum(must_merge_flg) into :must_merge_flg_sum
		from &libName..grps_summary_chi_&x. ;
	QUIT ;
	/* 一開始組數如果就少於最大組數 或 沒有任何需併組註記，則不用切，維持原本分類即可 */
	%if %eval(&max_groups. <= &min_bins.) or (&must_merge_flg_sum. = 0) %then 
		%do ;
			%Set_Status_Table(&libName., Create_Grp_Summary, Stop) ;
		%end ;
	%else 
		%do ;
			%Set_Status_Table(&libName., Create_Grp_Summary, Null) ;
		%end ;
%MEND ;

%MACRO Output_WoE_Summary(x, libName) ;
	DATA &libName..WoE_summary_&x. ;
		set &libName..grps_summary_chi_&x. (keep= &x. OBS_CNT OBS_DIST GOOD_CNT GOOD_DIST BAD_CNT BAD_DIST ) ;
		BAD_RATE = BAD_CNT / OBS_CNT ;
		if BAD_CNT = 0 then WoE = 0 ;
			else WoE = log(GOOD_DIST / BAD_DIST) ;
		IV_GRP = (GOOD_DIST - BAD_DIST) * WoE ;
	RUN ;
%MEND ;

%MACRO Run_ChiSQ_Test(run_chi_data, attr1, attr2, x, y, libName) ;
	DATA chi_input ;
		set &run_chi_data. (keep=&y. &x.  where=(&x. in ("&attr1.", "&attr2."))) ;
	RUN ;
	%global ChiSQ_signal_n_grps ;
	PROC SQL noprint ;
		select count(distinct &y.) into : ChiSQ_signal_n_grps
		from chi_input ;
	QUIT ;
/*	%put attr1 = [&attr1.], attr2 = [&attr2.],  ChiSQ_signal_n_grps = [%sysfunc(trimn(&ChiSQ_signal_n_grps.))] ;*/
	%if &ChiSQ_signal_n_grps. = 1 %then 
		%do ;
			%goto end_sq_test ;
		%end ;
	%else 
		%do ;
			PROC SQL ;
				create table WORK.temp as
				select &x., &y., count(*) as CNT
				from chi_input
				group by &x., &y.
				order by &x., &y.;
			QUIT ;

			PROC SQL noprint ;
				select (count(distinct &x.)-1) * (count(distinct &y.) - 1) into :DoF
				from WORK.temp ;
			QUIT ;

			PROC TRANSPOSE data=WORK.temp out= init_cross_tbl(drop=_NAME_) PREFIX=BAD_;
				by &x. ;
				id &y. ;
				var CNT ;
			RUN ;

			DATA &libName..&x._cross_tab ;
				set init_cross_tbl;
				array bad BAD: ;
				do over bad ;
					if missing(bad{_i_}) then bad{_i_} = 0 ;
				end ;
				ATTR_Total = sum(of BAD_:) ;
			RUN ;

			PROC SQL noprint;
				select sum(BAD_0) + sum(BAD_1) into :Total_N
				from &libName..&x._cross_tab ;

				select ATTR_Total into :attr1_N
				from &libName..&x._cross_tab
				where &x. = "&attr1." ;

				select ATTR_Total into :attr2_N
				from &libName..&x._cross_tab
				where &x. = "&attr2." ;

				select sum(BAD_0), sum(BAD_1) into :BAD_0_ALL, :BAD_1_ALL
				from &libName..&x._cross_tab ;
			QUIT ;

			%let Exp_attr1_BAD_0_N = %sysevalf(&attr1_N. * %sysevalf(&BAD_0_ALL./&Total_N.)) ;
			%let Exp_attr2_BAD_0_N = %sysevalf(&attr2_N. * %sysevalf(&BAD_0_ALL./&Total_N.)) ;
			%let Exp_attr1_BAD_1_N = %sysevalf(&attr1_N. * %sysevalf(&BAD_1_ALL./&Total_N.)) ;
			%let Exp_attr2_BAD_1_N = %sysevalf(&attr2_N. * %sysevalf(&BAD_1_ALL./&Total_N.)) ;

			DATA cross_tab_exp_value ;
				set &libName..&x._cross_tab ;
				Expected_ATTR1_N = ATTR_Total * (&BAD_0_ALL. / &Total_N.) ;
				Expected_ATTR2_N = ATTR_Total * (&BAD_1_ALL. / &Total_N.) ;
			RUN ;

			PROC SQL noprint;
				select	sum((Bad_0 - Expected_ATTR1_N)**2 / Expected_ATTR1_N) + 
						sum((Bad_1 - Expected_ATTR2_N)**2 / Expected_ATTR2_N) into :chi_statistics
				from cross_tab_exp_value ;
			QUIT ;
			
			DATA WORK.&x._chi_test_&i._&j. ;
				attr1 = "&attr1." ;
				attr2 = "&attr2." ;
				y = "&y." ;
				dof = &DoF. ;
				Statistics = &chi_statistics. ;
				CDF = cdf("CHISQ", Statistics, dof) ;
				p_value = 1 - CDF ;
			RUN ;
		%end ;
	%end_sq_test:
%MEND ;

%MACRO Create_Chi_Matrix(input_confirm_type_table, x, y, libName) ; /* chi_square_test within  */
	PROC SQL noprint ;
		select distinct &x. into : list_sel_attribute separated by " " 
		from &input_confirm_type_table. ;
	QUIT ;
	%let n_var = %sysfunc(countw(&list_sel_attribute.)) ;
	/*	%put loop_i = [&loop_i.] , n_var = [&n_var.] ;*/
	/*Create empty table for storing chi-square test result */
	DATA &libName..Chi_Matrix_result_&x. ;
		format	attr1 $50.
				attr2 $50.
				y $20.
				dof best.
				statistics best.
				p_value 14.12 ;
		stop ;
	RUN ;
	%do i = 1 %to %eval(&n_var. - 1)  ;
		%let attr1 = %scan(&list_sel_attribute., &i.) ;
		%do j = %eval(&i. + 1) %to &n_var. ;
			%let attr2 = %scan(&list_sel_attribute, &j.) ;
			%Run_ChiSQ_Test(run_chi_data = &input_confirm_type_table., attr1 = &attr1., attr2 = &attr2., x = &x., y = &y., libName = &libName.) ;
			%if &ChiSQ_signal_n_grps. > 1 %then 
				%do ;
					DATA &libName..Chi_Matrix_result_&x. ;
						set &libName..Chi_Matrix_result_&x. WORK.&x._chi_test_&i._&j.(drop=CDF) ;
					RUN ;
				%end ;
			%else 
				%do ;
					%goto next_combination ;
				%end ;
		%end ; 
		%next_combination:
	%end ;
	%let i = ;
	%let j = ;
	PROC SORT data=&libName..Chi_Matrix_result_&x. ;
		by descending p_value  ;
	RUN ;	
%MEND ;
%MACRO Merge_by_Chi_Once(input_confirm_type_table, input_Chi_Matrix, x, y, min_bins, max_bins, local_p_threshold, libName) ;
	%global local_once_p_threshold ;
	%let local_once_p_threshold = &local_p_threshold. ;
	DATA matrix_sorted ;
		set &input_Chi_Matrix.  ;
		if p_value > &local_once_p_threshold. then merge_symbol = 1 ;
			else merge_symbol = 0 ;
	RUN ;

	PROC SQL noprint ;
		select sum(merge_symbol) into :merge_symbol_sum
		from matrix_sorted ;
	QUIT ;
	
	%if &merge_symbol_sum. = 0 %then  /* no group need to be merged under current p_value. */
		%do ;
			PROC SQL noprint;
				select count(*) into :total_groups 
				from matrix_sorted ;
			QUIT ;
			%if &total_groups. < &max_bins. %then 
				%do ;
					%Set_Status_Table(&libName., chi_merge_once, Stop) ;
				%end ;
			%else 
				%do ;
					/* if total number of groups is greater than max_bins then reduce p_value_threshold. */
					%if &local_p_threshold. = 0.05 %then
						%do ;
							%put ----- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
							%let local_once_p_threshold = 0.01 ;
							%put ----- New p-value threshold : [&local_once_p_threshold.] ; 
						%end ;
					%else %if &local_p_threshold. <= 0.01 %then 
						%do ;
							%put ----- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
							%let local_once_p_threshold = %sysevalf(&local_once_p_threshold. * 0.1) ;
							%put ----- New p-value threshold : [&local_once_p_threshold.] ;
						%end;
					%else 
						%do ;
							%put ----- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
							%let local_once_p_threshold = %sysevalf(&local_once_p_threshold. - 0.05 ) ;
							%put ----- New p-value threshold : [&local_once_p_threshold.] ;
						%end ;
					%Set_Status_Table(&libName., chi_merge_reduce_p, Null) ;
				%end ;
		%end ;
	%else 
		%do ;
			PROC SQL noprint ;
				select strip(attr1), strip(attr2) into :attr1, :attr2
				from matrix_sorted
				having p_value = max(p_value) and merge_symbol = 1;
			QUIT ;
			%let merge_attr1 = %sysfunc(trimn(&attr1.)) ;
			%let merge_attr2 = %sysfunc(trimn(&attr2.)) ;
			DATA &input_confirm_type_table. ;
				set &input_confirm_type_table. ;
				length temp $300. temp1 $300.;
				if &x. in ("&merge_attr1.", "&merge_attr2.") then temp = "&merge_attr1.or&merge_attr2." ;
					else temp = &x. ;
				temp1 = strip(temp) ;
				drop &x. temp;
				rename temp1 = &x. ;
			RUN ;
			%put --- Merge [&merge_attr1.] & [&merge_attr2.] under p-value threshold :[&local_p_threshold.];
			%Set_Status_Table(&libName., chi_merge_once, Null) ;
		%end ;
%MEND ;
%MACRO Update_P_Value_Threshold() ;
	%if &local_p_threshold. = 0.05 %then
		%do ;
			%put --- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
			%let local_p_threshold = 0.01 ;
			%put --- New p-value threshold : [&local_once_p_threshold.] ; 
		%end ;
	%else %if &local_p_threshold. <= 0.01 %then 
		%do ;
			%put --- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
			%let local_p_threshold = %sysevalf(&local_once_p_threshold. * 0.1) ;
			%put --- New p-value threshold : [&local_once_p_threshold.] ;
		%end;
	%else 
		%do ;
			%put --- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
			%let local_p_threshold = %sysevalf(&local_once_p_threshold. - 0.05 ) ;
			%put --- New p-value threshold : [&local_once_p_threshold.] ;
		%end ;
%MEND ;
%MACRO Merge_by_Chi_Loop(dataframe, x, y, min_bins, max_bins, min_samples, max_samples, init_p_value_threshold, libName) ;
	%global local_p_threshold ;
	%let local_p_threshold = &init_p_value_threshold. ;
	/* Make attributes turn into string format */
	DATA confirm_data_type_&x.  ;
		set &dataframe.(keep=&y. &x.) ;
		length temp $32. temp1 $32.;
		temp = put(&x., 32.) ;
		temp1 = strip(temp) ;
		drop &x. temp; 
		rename temp1 = &x. ;
	RUN ;
	%let loop_i = 0 ;
	%do %while (1) ;
		%let loop_i = %eval(&loop_i. + 1) ;
		%put Loop[&loop_i.] -- Merge at p-value : [&local_p_threshold.];
		%Get_Status(&libName., merging_status) ;
		%if "&merging_status." = "Null" %then 
			%do ;
				%put - Creating Chi Matrix ;
				%Create_Chi_Matrix(	confirm_data_type_&x., &x., &y., &libName.) ;
				%Merge_by_Chi_Once(	confirm_data_type_&x. , &libName..Chi_Matrix_result_&x., 
									&x., &y., 
									&min_bins., &max_bins., 
									&local_p_threshold., 
									&libName.) ;
				%Get_WorkFlow(&libName., after_merge_once) ;
				%let trim_merge_once = %sysfunc(trimn(&after_merge_once.)) ;
				%if "&trim_merge_once." = "chi_merge_reduce_p" %then
					%do ;
						%put --- Enter CHECK POINT : Reduce p threshold ;
						%Update_P_Value_Threshold() ;
						/*
						%if &local_p_threshold. = 0.05 %then
							%do ;
								%put --- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
								%let local_p_threshold = 0.01 ;
								%put --- New p-value threshold : [&local_once_p_threshold.] ; 
							%end ;
						%else %if &local_p_threshold. <= 0.01 %then 
							%do ;
								%put --- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
								%let local_p_threshold = %sysevalf(&local_once_p_threshold. * 0.1) ;
								%put --- New p-value threshold : [&local_once_p_threshold.] ;
							%end;
						%else 
							%do ;
								%put --- Reduce Current p-value threshold : [&local_once_p_threshold.] ;
								%let local_p_threshold = %sysevalf(&local_once_p_threshold. - 0.05 ) ;
								%put --- New p-value threshold : [&local_once_p_threshold.] ;
							%end ;
						*/
					%end ;
				%else 
					%do ;
						%goto out_check_point ;
					%end ;
				%out_check_point :
				%Create_Grp_Summary(confirm_data_type_&x., &y., &x., &min_bins., &max_bins., &min_samples., &max_samples., &libName.) ;
				%Get_status(&libName., chi_merge_status_in_loop) ;
				%if "&chi_merge_status_in_loop." = "Null" %then 
					%do ;
						%goto next_merge_loop ;
					%end ;
				%else 
					%do ;
						%goto leave_merge_loop ;
					%end ;
			%end ;
		%next_merge_loop :
	%end ;
	%leave_merge_loop :
	%put Variable [&x.] : Chi Merge Done! ;
	%let local_p_threshold = ;
	%Set_Status_Table(&libName., Chi_Merge_Done, Stop) ;
%MEND ;

%MACRO Clean_Library(libName, x) ;
	PROC DATASETS LIBRARY= &libName. nolist;
		delete &x.: ;
	RUN ; QUIT ;
%MEND ;

%MACRO Reset_Variables() ;
	%let i = ;
	%let j = ;
	%let loop_i = ;
	%let max_samples_size = ;
	%let min_samples_size = ;
	%let local_p_threshold = ;
	%let attr1 = ;
	%let attr2 = ;
	%let merge_attr1 = ;
	%let merge_attr2 = ;
	%let ChiSQ_signal_n_grps = ;
	%let init_bins_check_status = ;
	%let grp_summary_status = ;
	%let merged_status = ;
	%let chi_merge_WorkFlow = ;
%MEND ;

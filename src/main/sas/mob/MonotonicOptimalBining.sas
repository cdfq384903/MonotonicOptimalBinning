/*load libs*/
%INCLUDE "/home/u60021675/src/main/sas/mob/num/BinsMerge.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/mob/cat/ChiMerge.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/mob/num/BinsSummary.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/mob/tool/WoeSummary.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/mob/tool/WoeHandler.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/mob/tool/IvSummary.sas" ;
%INCLUDE "/home/u60021675/src/main/sas/handler/FileHandler.sas";

/*define global data members*/
%global g_data_table g_y g_x g_exclude_condi g_lib_name g_min_bins g_min_samples 
        g_max_samples g_min_bads g_type g_min_pvalue g_show_woe_plot 
        g_nx g_is_using_encoding_var g_encoding_var g_optimal_p_value 
        g_current_bin_size g_max_bins g_init_sign g_sign g_invalid_var;

/*define constructor*/
%MACRO init(data_table, y, x, exclude_condi, init_sign, min_samples, min_bads, min_pvalue, show_woe_plot, is_using_encoding_var, lib_name);
	/*define data members*/
	%let g_data_table = &data_table.;
	%let g_y = &y.;
	%let g_x = &x.;
	%let g_exclude_condi = &exclude_condi.;
	%let g_init_sign = &init_sign. ;
	%let g_min_samples = &min_samples.;
	%let g_min_bads = &min_bads.;
	%let g_min_pvalue = &min_pvalue.;
	%let g_show_woe_plot = &show_woe_plot.;
	%let g_lib_name = &lib_name.;
	%let g_nx = %sysfunc(countw(&x.));
	%set_g_is_using_encoding_var(is_using_encoding_var = &is_using_encoding_var.);
%MEND;

%MACRO initSizeFirstBining(max_samples, min_bins, max_bins);
	/*define data members*/
	%let g_type = 1;
	%let g_min_bins = &min_bins.;
	%let g_max_samples = &max_samples.;	
	%set_g_max_bins(&max_bins.);
	%set_g_optimal_p_value(max_bins = &g_max_bins.);
%MEND;

%MACRO initMonotonicFirstBining(max_bins);
	/*define data members*/
	%let g_type = 0;
	%set_g_max_bins(&max_bins.);
	%set_g_optimal_p_value(max_bins = &g_max_bins.);
%MEND;

/*define function members*/
%MACRO runMob();
	%if &g_is_using_encoding_var. NE 0 %then 
		%do;
			%setGencodingVar(var_encoding_table = &g_lib_name..var_encoding_table, 
                             old_var = &g_y.);
			%let g_y = &g_encoding_var.;
		%end;

	%if &g_type. EQ 1 %then
		%do;
			/*run SizeFirstBining(SFB) algorithm*/
			%do k = 1 %to &g_nx.;
				%let var = %scan(&g_x., &k, ' ');
				%put Loop[ &k. ] : Variable = [&var.] ;

				%if &g_is_using_encoding_var. NE 0 %then 
					%do;
						%setGencodingVar(var_encoding_table = &g_lib_name..var_encoding_table, 
                                         old_var = &var.);
						%let var = &g_encoding_var.;
					%end;

				%if &g_exclude_condi. NE 0 %then
					%do;
						%let var_exclude_condi = &var. &g_exclude_condi.;
					%end;
				%else
					%do;
						%let var_exclude_condi = &g_exclude_condi.;
					%end;
				%put Variable exclude condition= [&var_exclude_condi.] ;

				%set_g_invalid_var(data_table = &g_data_table., x = &var.);
				%if %sysevalf(&g_invalid_var. = 0) %then
					%do;
						%set_g_sign(init_given_sign = &g_init_sign., x = &var., y = &g_y.) ;
						%createBinsSummaryBySfb(data_table = &g_data_table., y = &g_y., x = &var., 
												exclude_condi = &var_exclude_condi., sign = &g_sign., 
												min_bins = &g_min_bins., 
												max_samples = &g_max_samples., 
												lib_name = &g_lib_name.);
						%runBinsMergeBySfb(x = &var., min_samples = &g_min_samples., 
											min_bads = &g_min_bads., 
											min_pvalue = &g_min_pvalue., 
											min_bins = &g_min_bins., 
											lib_name = &g_lib_name.);

						%if &g_optimal_p_value. EQ 1 %then
							%do;
								/*optimal pvalue*/
								%set_g_current_bin_size(x = &var., lib_name = &lib_name.);
								%do %while(&g_current_bin_size. > &g_max_bins.);
									%set_g_min_pvalue(min_pvalue = %sysevalf(&g_min_pvalue. - 0.03));
									%if %sysevalf(&g_min_pvalue. <= 0) %then %goto break_optimal_pvalue_SFB;
									%runBinsMergeBySfb(x = &var., 
														min_samples = &g_min_samples., 
														min_bads = &g_min_bads., 
														min_pvalue = &g_min_pvalue., 
														min_bins = &g_min_bins., 
														lib_name = &g_lib_name.);
									%set_g_current_bin_size(x = &var., 
															lib_name = &lib_name.);
								%end;
								%break_optimal_pvalue_SFB:
							%end;
						%createWoeSummary(x = &var., lib_name = &g_lib_name., 
											show_plot = &g_show_woe_plot.);
					%end;
			%end;
		%end;
	%else
		%do;
			/*run MonotonicFirstBining(MFB) algorithm*/
			%do k = 1 %to &g_nx.;
				%let var = %scan(&g_x., &k, ' ');
				%put Loop[ &k. ] : Variable = [&var.] ;
				
				%if &g_is_using_encoding_var. NE 0 %then 
					%do;
						%setGencodingVar(var_encoding_table = &g_lib_name..var_encoding_table, 
                                         old_var = &var.);
						%let var = &g_encoding_var.;
					%end;

				%if &g_exclude_condi. NE 0 %then
					%do;
						%let var_exclude_condi = &var. &g_exclude_condi.;
					%end;
				%else
					%do;
						%let var_exclude_condi = &g_exclude_condi.;
					%end;
				%put Variable exclude condition= [&var_exclude_condi.] ;

				%set_g_invalid_var(data_table = &g_data_table., x = &var.);

				%if %sysevalf(&g_invalid_var. = 0) %then
					%do;
						%set_g_sign(init_given_sign = &g_init_sign., x = &var., y = &g_y.) ;
						%createBinsSummaryByMfb(data_table = &g_data_table., y = &g_y., x = &var., 
					                            exclude_condi = &var_exclude_condi., sign = &g_sign., 
					                            lib_name = &g_lib_name.);
					    %runBinsMergeByMfb(x = &var., min_samples = &g_min_samples., 
		                                   min_bads = &g_min_bads., 
			                               min_pvalue = &g_min_pvalue., 
		                                   lib_name = &g_lib_name.);
						%if &g_optimal_p_value. EQ 1 %then
							%do;
								/*optimal pvalue*/
								%set_g_current_bin_size(x = &var., lib_name = &lib_name.);
								%do %while(&g_current_bin_size. > &g_max_bins.);
									%set_g_min_pvalue(min_pvalue = %sysevalf(&g_min_pvalue. - 0.03));
									%if %sysevalf(&g_min_pvalue. <= 0) %then %goto break_optimal_pvalue_MFB;
									%runBinsMergeByMfb(x = &var., 
		                                               min_samples = &g_min_samples., 
					                                   min_bads = &g_min_bads., 
						                               min_pvalue = &g_min_pvalue., 
		                                               lib_name = &g_lib_name.);						
									%set_g_current_bin_size(x = &var., lib_name = &lib_name.);
								%end;
								%break_optimal_pvalue_MFB:
							%end;
						%createWoeSummary(x = &var., lib_name = &g_lib_name., 
			                              show_plot = &g_show_woe_plot.);
					%end;
			%end;
		%end;

	%reverseEncodingVar(var_encoding_table = &g_lib_name..var_encoding_table, 
                        g_data_table = &g_data_table.);
%MEND;

/*======================= for priviate method =======================*/
%MACRO set_g_invalid_var(data_table, x);
	PROC SQL NOPRINT;
		SELECT COUNT(*) AS total_record INTO : total_record
           FROM &data_table.;

		SELECT COUNT(*) AS missing_count INTO : missing_count
           FROM &data_table.
		 WHERE missing(&x.);
	QUIT;

	%let diff = %sysevalf(&missing_count. - &total_record.);
	%if %sysevalf(&diff. NE 0) %then
		%do;
			%let g_invalid_var = 0;
		%end;
	%else
		%do;
			%let g_invalid_var = 1;
		%end;
%MEND;

%MACRO set_g_max_bins(max_bins);
	%if &max_bins. = %then
		%do;
			%let g_max_bins = 0;
		%end;
	%else
		%do;
			%let g_max_bins = &max_bins.;
		%end;
%MEND;

%MACRO set_g_current_bin_size(x, lib_name);
	PROC SQL NOPRINT;
		SELECT COUNT(*) AS bins INTO : current_bins
          FROM &lib_name..bins_summary_pvalue_&x.;
	QUIT;
	%let g_current_bin_size = &current_bins.;
	%put g_current_bin_size = &g_current_bin_size.;
%MEND;

%MACRO set_g_optimal_p_value(max_bins);
	%if &max_bins. > 1 %then
		%do;
			%let g_optimal_p_value = 1;
		%end;
	%else
		%do;
			%let g_optimal_p_value = 0;
		%end;
%MEND;

%MACRO set_g_is_using_encoding_var(is_using_encoding_var);
	%if &is_using_encoding_var NE 0 %then
		%do;
			%let g_is_using_encoding_var = 1;
			%createVarEncodingTable(&g_x., &g_lib_name.);
		%end;
	%else 
		%do;
			%let g_is_using_encoding_var = 0;
		%end;
%MEND;

%MACRO set_g_min_pvalue(min_pvalue);
	%let g_min_pvalue = &min_pvalue.;
	%put g_min_pvalue = &g_min_pvalue.;
%MEND;

%MACRO set_g_sign(init_given_sign, x, y)  ;
	%if %sysfunc(lowcase("&init_given_sign")) = "auto" %then 
		%do ;
			PROC CORR data = &g_data_table. outp = corrOut(where = (_TYPE_ = "CORR")) noprint ;
				var &x. &y. ;
			RUN ;
			PROC SQL noprint ;
				select &y. into :corrSign
				from corrOut 
				where _NAME_ = "&x." ;
			QUIT ;
			%if %sysevalf(&corrSign. >= 0) %then 
				%do ;
					%let g_sign = GE ;
				%end ;
			%else
				%do ;
					%let g_sign = LE ;
				%end;
		%end ; 
	%else %if %sysfunc(lowcase("&init_given_sign")) = "+" %then 
		%do ;
			%let g_sign = GE ;
		%end ;
	%else 
		%do ;
			%let g_sign = LE ;
		%end ;
%MEND ;

%MACRO createTmpTable();
	DATA tmp_tbl ;
	LENGTH id $255.; 
    STOP ;
	RUN; 

	PROC SQL NOPRINT;
	INSERT INTO tmp_tbl (id) VALUES("1");
	QUIT;
%MEND;

%MACRO setGencodingVar(var_encoding_table, old_var);
	PROC SQL NOPRINT;
	SELECT new_var INTO :new_var
	  FROM &var_encoding_table.
	 WHERE lowcase(old_var) = lowcase("&old_var.");
	QUIT;

	%let g_encoding_var = &new_var.;
	%put g_encoding_var = &g_encoding_var.;
%MEND;

%MACRO createVarEncodingTable(g_x, g_lib_name);
	DATA &g_lib_name..var_encoding_table;
	LENGTH id $255. old_var $100. new_var $32.;
	STOP;
	RUN;
	
	/*	create tmp table for rename_syntax*/
	%createTmpTable();

	PROC SQL NOPRINT;
	SELECT NAME AS all_cols INTO :all_cols separated by ' '
	  FROM dictionary.columns 
	 WHERE libname = 'WORK' 
	   AND memname = kupcase("&g_data_table.");

	SELECT COUNT(NAME) AS total_cols INTO :total_cols
	  FROM dictionary.columns 
	 WHERE libname = 'WORK' 
	   AND memname = kupcase("&g_data_table.");
	QUIT;

	%do k = 1 %to &total_cols.;
		%let var = %scan(&all_cols., &k., ' ');	
		%put var = &var.;

		%let new_var = %sysfunc(cats(v, &k.));
		%put new_var = &new_var.;
	
		PROC SQL NOPRINT ;
			SELECT CATS("&var.", "=", "&new_var.") INTO :rename_syntax 
			FROM tmp_tbl ;

			INSERT INTO &g_lib_name..var_encoding_table (id, old_var, new_var) VALUES ("&k.", "&var.", "&new_var.");
		QUIT;

		DATA &g_data_table.;
		SET &g_data_table.;
		rename &rename_syntax.;
		RUN;
	%end;
	
	/*clear tmp table*/
	PROC DELETE DATA=tmp_tbl;
	RUN;
%MEND;

%MACRO reverseEncodingVar(var_encoding_table, g_data_table);
	PROC SQL NOPRINT;
	SELECT COUNT(*) INTO :total_records
      FROM &var_encoding_table.;
	QUIT;
	
	/*	create tmp table for rename_syntax*/
	%createTmpTable();

	%do k = 1 %to &total_records.;
		PROC SQL NOPRINT ;
			SELECT old_var, new_var INTO :old_var, :new_var 
			FROM &var_encoding_table.
			WHERE id = "&k.";

			SELECT CATS("&new_var.", "=", "&old_var.") INTO :rename_syntax 
			FROM tmp_tbl;
			
			DATA &g_data_table.;
			SET &g_data_table.;
			rename &rename_syntax.;
			RUN;
		QUIT;
	%end;

	/*clear tmp table*/
	PROC DELETE DATA=tmp_tbl;
	RUN;
%MEND;

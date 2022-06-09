/*
根據optimal出來的結果計算每個變數的IV值加總
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	min_iv:<float> 最小iv值
	min_obs_rate:<float> 最小樣本比例
	max_obs_rate:<float> 最大樣本比例
	min_bin_size:<int> 最小bins size
	max_bin_size:<int> 最大bins size
	min_bad_count:<int> 最小壞件數
	return void
*/
%MACRO getIvPerVar(lib_name, min_iv, min_obs_rate, max_obs_rate, min_bin_size, max_bin_size, min_bad_count);
	PROC CONTENTS DATA=&lib_name.._ALL_ out=woe_member(WHERE= (MEMTYPE = "DATA")) NOPRINT;
	RUN; 

	PROC SQL NOPRINT;
		SELECT distinct MEMNAME INTO :data_list separated by " "
		  FROM work.woe_member 
		 WHERE MEMNAME like "WOE_SUMMARY%" ;
	QUIT ;
	
	DATA &lib_name..iv_summary;
	FORMAT idx best12. x $20. iv best12. is_iv_pass 1. is_obs_pass 1. is_bad_count_pass 1. is_bin_pass 1. is_woe_pass 1. woe_dir $3. is_strict_pass 1. is_free_pass 1.;
	STOP;
	RUN;

	%let n = %sysfunc(countw(&data_list.)) ;
	%do i = 1 %to &n.;
		%let tbl = %scan(&data_list., &i.) ;
		PROC CONTENTS DATA=&lib_name..&tbl. out= variable(keep=name varnum) noprint;
		RUN;
		
		PROC SQL NOPRINT;
		SELECT name INTO :x
          FROM work.variable 
         WHERE varnum = 1;

		SELECT ROUND(SUM(iv), 0.001), ROUND(MIN(dist_obs), 0.1), 
               ROUND(MAX(dist_obs), 0.1), MIN(bads) 
               INTO :total_iv, :min_dist_obs, :max_dist_obs, :min_bads
		  FROM &lib_name..&tbl.;
		
		SELECT COUNT(*) INTO :total_bins
		  FROM &lib_name..&tbl.;

		%let x_trim = %sysfunc(trimn(&x.)) ;
		%put total_iv. = &total_iv.;
		%put min_id = &min_iv.;

		/*	check min iv*/
		%if &total_iv. >= &min_iv. %then
			%do;
				%let is_iv_pass = 1;
			%end;
		%else
			%do;
				%let is_iv_pass = 0;
			%end;
		%put is_iv_pass = &is_iv_pass.;

		/*	check bin size*/
		%if &total_bins. <= &max_bin_size. AND &total_bins. >= &min_bin_size. %then
			%do;
				%let is_bin_pass = 1;
			%end;
		%else
			%do;
				%let is_bin_pass = 0;
			%end;

		/*	check min max obs*/
		%if &max_dist_obs. <= &max_obs_rate. AND &min_dist_obs. >= &min_obs_rate. %then
			%do;
				%let is_obs_pass = 1;
			%end;
		%else
			%do;
				%let is_obs_pass = 0;
			%end;
	
		/*	check min bads*/
		%if &min_bads. >= &min_bad_count. %then
			%do;
				%let is_bad_pass = 1;
			%end;
		%else
			%do;
				%let is_bad_pass = 0;
			%end;
	
		/*	check monotone woe*/
		PROC SQL NOPRINT;
		SELECT COUNT(*) INTO :total_valid_record
          FROM &lib_name..&tbl.
		 WHERE interval_easy IS NOT MISSING;
		QUIT;

		%let is_woe_pass = 1; /*default label*/
		%if &total_valid_record. >= 2 %then
			%do;
				DATA woe_tmp(KEEP = idx interval_easy woe);
				RETAIN idx interval_easy woe;
				SET &lib_name..&tbl.;
				idx = _n_;
				RUN;
				
				PROC SQL NOPRINT;
					SELECT woe INTO :woe_1
					  FROM woe_tmp
					 WHERE idx = 1;
					SELECT woe INTO :woe_2
					  FROM woe_tmp
					 WHERE idx = 2;
				QUIT;
				%if %sysevalf(&woe_1. > &woe_2.) %then 
					%do;
						%let sort_label = "desc";
					%end;
				%else
					%do;
						%let sort_label = "asc";
					%end;
				%do j = 2 %to %eval(&total_valid_record. + 1);
					PROC SQL NOPRINT;
						SELECT woe INTO :current_woe
						  FROM woe_tmp
						 WHERE idx = &j.;
						%if &j. < &total_valid_record. %then
							%do;
								SELECT woe INTO :next_woe								  
                                  FROM woe_tmp
								 WHERE idx = &j. + 1;
								%if &sort_label. EQ "desc" %then
									%do;
										%if %sysevalf(&current_woe. < &next_woe.) %then
											%do;
												%let is_woe_pass = 0;
												%let sort_label = "";
												%goto finish_woe_check;
											%end;
									%end;
								%else
									%do;
										%if %sysevalf(&current_woe. > &next_woe.) %then
											%do;
												%let is_woe_pass = 0;
												%let sort_label = "";
												%goto finish_woe_check;
											%end;
									%end;
							%end;
						%else 

							%do;
								SELECT woe INTO :brev_woe
	                              FROM woe_tmp
								 WHERE idx = &j. - 1;
								%if &sort_label. EQ "desc" %then
									%do;
										%if %sysevalf(&current_woe. > &brev_woe.) %then
											%do;
												%let is_woe_pass = 0;
												%let sort_label = "";
												%goto finish_woe_check;
											%end;
										%goto finish_woe_check;
									%end;
								%else
									%do;
										%if %sysevalf(&current_woe. < &brev_woe.) %then
											%do;
												%let is_woe_pass = 0;
												%let sort_label = "";
												%goto finish_woe_check;
											%end;
										%goto finish_woe_check;
									%end;
							%end;
					QUIT;
				%end;
			%end;
		%else
			%do;
				%let sort_label = "";
				%let is_woe_pass = 0;
			%end;
		%finish_woe_check:

		/*	check final pass*/
		%if %eval(&is_iv_pass. + &is_obs_pass. + &is_woe_pass. + &is_bin_pass. + &is_bad_pass.) >= 5 %then
			%do;
				%let is_strict_pass = 1;
			%end;
		%else
			%do;
				%let is_strict_pass = 0;
			%end;

		%if %eval(&is_iv_pass. + &is_woe_pass. + &is_bad_pass.) >= 3 %then
			%do;
				%let is_free_pass = 1;
			%end;
		%else
			%do;
				%let is_free_pass = 0;
			%end;
		
		PROC SQL NOPRINT;
		INSERT INTO &lib_name..iv_summary (idx, x, iv, is_iv_pass, is_obs_pass, is_bad_count_pass, is_bin_pass, is_woe_pass, woe_dir, is_strict_pass, is_free_pass) VALUES (&i., "&x_trim.", &total_iv., &is_iv_pass., &is_obs_pass., &is_bad_pass., &is_bin_pass., &is_woe_pass., &sort_label., &is_strict_pass., &is_free_pass.);
		QUIT;
	%end ;
%MEND;

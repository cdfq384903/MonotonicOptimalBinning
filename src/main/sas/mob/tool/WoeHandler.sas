/*
輸出每個bins的程式碼切分邏輯
	lib_name:<string> 欲載入woe切分結果的lib位置
	output_file:<string> 輸出檔案的位置,注意路徑無須用雙引號包覆,例如:E:\UPL_MODEL\PwC_DNTI\data\tmp\woe
	return void
*/
%MACRO exportSplitRule(lib_name, output_file);

	PROC CONTENTS DATA=&lib_name.._ALL_ out=woe_member(WHERE= (MEMTYPE = "DATA")) NOPRINT;
	RUN; 

	PROC SQL noprint ;
		SELECT distinct MEMNAME INTO :data_list separated by " "
		  FROM work.woe_member 
		 WHERE MEMNAME like "WOE_SUMMARY%" ;
	QUIT ;
	%put &data_list. ;

	%let n = %sysfunc(countw(&data_list.)) ;
	%do j = 1 %to &n.;
		%let tbl = %scan(&data_list., &j.) ;
		PROC CONTENTS DATA=&lib_name..&tbl. out= variable(keep=name varnum) noprint;
		RUN;
		
		PROC SQL NOPRINT;
		SELECT name INTO :x
          FROM work.variable 
         WHERE varnum = 1;
		%let x_trim = %sysfunc(trimn(&x.));

		/*export split rule*/
		PROC SQL NOPRINT;
			SELECT COUNT(*) INTO :valid_interval_size
	          FROM &lib_name..woe_summary_&x.
	         WHERE interval_easy IS NOT MISSING;
		RUN;
		
		/*	create woe tmp data with idx*/
		DATA woe_tmp;
		SET &lib_name..woe_summary_&x_trim.;
		idx =_n_;
		RUN;

		/*	set up the file path of splite rule*/
		/*%deletefile(file = ruleFile) ;*/
		filename ruleFile "&output_file.\split_rule_&x_trim..txt";
		
		/*	write the code of checking missing*/
		data _null_;
		FILE ruleFile MOD;
		put "/*==========BINNING SPLIT RULE(&x_trim.) ==========*/";
		%let split_rule = IF MISSING(&x_trim.) THEN &x_trim._WoE_Label = 'null';
		put "&split_rule.;";
	    RUN;
		
		%let label_idx = 1;
		%do i = &valid_interval_size. %to 1 %by -1;
			PROC SQL NOPRINT;
			SELECT interval_easy INTO :interval_i
	          FROM woe_tmp
	         WHERE idx = &i.;
			SELECT &x_trim. INTO :x_lower_bound_i
			  FROM woe_tmp
			 WHERE idx = &i.;
			QUIT;
			%let interval_trim = %sysfunc(trimn(&interval_i.));
			%let x_lower_bound_i = %sysfunc(round(&x_lower_bound_i., 1.0));

			%if &i. = 1 %then
				%do;
					PROC SQL NOPRINT;
					SELECT &x_trim. INTO :x_upper_bound
					  FROM woe_tmp
					 WHERE idx = %eval(&i. + 1);
					QUIT;
					%let x_upper_bound = %sysfunc(round(&x_upper_bound., 1.0));
					%let split_rule = ELSE IF &x_trim. > &x_upper_bound. THEN &x_trim._WoE_Label = '&label_idx.';
				%end;
			%else
				%do;
					%let split_rule = ELSE IF &x_trim. <= &x_lower_bound_i. THEN &x_trim._WoE_Label = '&label_idx.';
				%end;
			
			/*
			此段程式碼的切點是根據easy interval而來，如果要改用這段程式碼須將
			%do i =  %to 1 %by -1;修改為
			%do i = 1 %to &valid_interval_size.;
			*/
			/*
			%if i == 1 %then
				%do;
					%let split_rule = ELSE IF &interval_trim. THEN &x_trim._woe_label = '1';
				%end;
			%else %if &i. <= %eval(&valid_interval_size. - 1) %then
				%do;
					%let split_rule = ELSE IF &interval_trim. THEN &x_trim._woe_label = '&i.';
				%end;
			%else
				%do;
					%let split_rule = ELSE &x_trim._woe_label = '&i.';
				%end;
			*/

			data _null_;
			FILE ruleFile MOD;
			put "&split_rule.;";
			RUN;
		%let label_idx = %eval(&label_idx. + 1);
		%end;
		data _null_;
		FILE ruleFile MOD;
		put "ELSE &x_trim._WoE_Label = 'x';";
		RUN;
	%end;
%MEND;

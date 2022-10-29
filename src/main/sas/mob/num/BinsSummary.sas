/*
執行monotoneOptinalWoE切分前的auto binning處理,並以bin的size為最優先原則進行併組(monotone原則次之)
注意:使用該模組產生出來的bins其結果可能會不符合monotone
	data_table:<string> 進行並組的資料集
	y:<string> 反應變數名稱
	x:<string> 解釋變數名稱
	exclude_condi:<string> 排除特殊值的條件,如果輸入0則表示不予以排除
	min_bins:<int> 整體bins最低總數的限制
	max_samples:<int> 每個bins最大個數限制閥值,建議個數估計最好是總樣本的40%
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	return void
*/
%MACRO createBinsSummaryBySfb(data_table, y, x, exclude_condi, sign, min_bins, max_samples, lib_name);
	%if &exclude_condi. = 0 %then
		%do;
			DATA work.data_table_sub work.data_table_exclude_sub;
			SET &data_table.(KEEP=&y. &x.);
			IF (NOT MISSING(&x.)) THEN OUTPUT work.data_table_sub;
			ELSE OUTPUT work.data_table_exclude_sub;
			RUN;
		%end;
	%else
		%do;
			DATA work.data_table_sub work.data_table_exclude_sub;
			SET &data_table.(KEEP=&y. &x.);
			IF (NOT MISSING(&x.)) AND NOT (&exclude_condi.) THEN OUTPUT work.data_table_sub;
			ELSE OUTPUT work.data_table_exclude_sub;
			RUN;

			/*	replace exclude value to special label	*/
			DATA work.data_table_exclude_sub;
			SET work.data_table_exclude_sub;
			IF (NOT MISSING(&x.)) AND (&exclude_condi.) THEN &x. = -99999999;
			RUN;
		%end;

	/*	calculate group statistic*/
	PROC SQL NOPRINT;
	/*	for sub dataset*/
		CREATE TABLE work.init_summary AS
		SELECT &x., AVG(&y.) AS means, COUNT(*) AS nsamples, STD(&y.) AS std_dev, 0 AS del_flg
	  	FROM work.data_table_sub
	 	GROUP BY &x. 
	 	ORDER BY &x. DESC;
		
		SELECT COUNT(*) INTO :bins_size_org
      	FROM work.init_summary;

	/*	for exclude sub dataset*/
		CREATE TABLE work.init_summary_exclude AS
		SELECT &x., AVG(&y.) AS means, COUNT(*) AS nsamples, STD(&y.) AS std_dev, 0 AS del_flg
	  	FROM work.data_table_exclude_sub
	 	GROUP BY &x. 
	 	ORDER BY &x. DESC;
	QUIT;

	DATA &lib_name..bins_summary_&x.;
	SET work.init_summary;
	std_dev = COALESCE(std_dev, 0);
	idx = _n_ - 1;
	RUN;
	
	%let del_count = 0;
	%do %while(1);
		%let i = 0;
		DATA &lib_name..bins_summary_&x.;
			SET &lib_name..bins_summary_&x.;
			tmpidx = _n_ - 1;
			drop idx ;
			rename tmpidx = idx ;
			WHERE del_flg = 0;
		RUN;
		
		PROC SQL NOPRINT;
			SELECT COUNT(*) INTO :record_size 
			FROM &lib_name..bins_summary_&x.;
		QUIT;

		%do %while(1);
			%let j = %eval(&i.+1) ;

			%if &j. >= &record_size. %then %goto finished_bin_i_check;
			
			PROC SQL NOPRINT;
				SELECT means into :mean_i
				FROM &lib_name..bins_summary_&x. 
				WHERE idx = &i.;
				SELECT means into :mean_j 
				FROM &lib_name..bins_summary_&x. 
				WHERE idx = &j.;
			QUIT;
			
			%if &mean_i. &sign. &mean_j. %then 
			/* 
				if g_sign = + then sign = GT
				since descending sorted -> if j (next smaller group) > i (curr greater group) then merge
				else if j < i then continue next loop
			*/
				%do;
					%let i = %eval(&i.+1);
				%end;
			%else
				%do;
					%do %while(1);
						%let del_count =%eval(&del_count. + 1);
						%let bins_size_est = %eval(&bins_size_org. - &del_count.);
						%if &bins_size_est. < &min_bins. %then %goto finished_bin_i_check;

						PROC SQL NOPRINT;
							SELECT nsamples,means, std_dev INTO :nsamples_i, :nmeans_i, :nstd_i
							FROM &lib_name..bins_summary_&x.
							WHERE idx = &i.;
							SELECT nsamples,means, std_dev INTO :nsamples_j, :nmeans_j, :nstd_j
							FROM &lib_name..bins_summary_&x.
							WHERE idx = &j.;
						QUIT;  

						%let group_samples = %sysevalf(&nsamples_j. + &nsamples_i);
						%let group_means = %sysevalf((%sysevalf(&nsamples_j. * &nmeans_j.) + %sysevalf(&nsamples_i. * &nmeans_i.)) / &group_samples.);

						%if &group_samples. eq 2 %then
							%do;	
								%let group_std = %sysfunc(std(&nmeans_i., &nmeans_j.));
							%end;
						%else
							%do;
								%let group_std = %sysfunc(sqrt(((&nsamples_j. * (&nstd_j. ** 2)) + (&nsamples_i. * (&nstd_i. ** 2))) / &group_samples.));
							%end;
						%if &group_samples. >= &max_samples. %then %goto group_sample_overflow;

						PROC SQL NOPRINT;
							UPDATE &lib_name..bins_summary_&x. 
								SET 
									nsamples = &group_samples.,
									means = &group_means.,
									std_dev = &group_std.
							WHERE idx = &i.;
							UPDATE &lib_name..bins_summary_&x. SET del_flg = 1 WHERE idx = &j.;
						QUIT;
						%let j = %eval(&j.+1);
						
						%if &j. >= &record_size. %then %goto finished_bin_j_check;
						
						PROC SQL NOPRINT;
							SELECT means into :tmpmean_i
							FROM &lib_name..bins_summary_&x. 
							WHERE idx = &i.;
							SELECT means into :tmpmean_j 
							FROM &lib_name..bins_summary_&x. 
							WHERE idx = &j.;
						QUIT;

						%if &tmpmean_i. &sign. &tmpmean_j. %then 
							%group_sample_overflow:
							%do;
								%let i = &j.;
								%goto finished_bin_j_check;
							%end;
					%end;
					%finished_bin_j_check:
				%end;
			%if &j. >= &record_size. %then %goto finished_bin_i_check;
		%end;
		%finished_bin_i_check:

		PROC SQL NOPRINT;
			SELECT SUM(del_flg) into :dels 
		  	FROM &lib_name..bins_summary_&x.;
		QUIT;
		/* %put dels = &dels.; */

		%if &dels. = 0 %then %goto finished_bin;
	%end;
	%finished_bin:
	
	/*combine exclude result*/
	DATA &lib_name..bins_summary_&x.;
		SET &lib_name..bins_summary_&x. work.init_summary_exclude;
	RUN;
%MEND;

/*
執行monotoneOptinalWoE切分前的auto binning處理,並以monotone為最優先原則進行併組(bin size原則次之)
注意:使用該模組產生出來的bins其結果可能會不符合bins建議的組數,例如經驗上分3~5組較佳
	data_table:<string> 進行並組的資料集
	y:<string> 反應變數名稱
	x:<string> 解釋變數名稱
	exclude_condi:<string> 排除特殊值的條件,如果輸入0則表示不予以排除
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	return void
*/
%MACRO createBinsSummaryByMfb(data_table, y, x, exclude_condi, sign, lib_name);
	%if &exclude_condi. = 0 %then
		%do;
			DATA work.data_table_sub work.data_table_exclude_sub;
			SET &data_table.(KEEP=&y. &x.);
			IF (NOT MISSING(&x.)) THEN OUTPUT work.data_table_sub;
			ELSE OUTPUT work.data_table_exclude_sub;
			RUN;
		%end;
	%else
		%do;
			DATA work.data_table_sub work.data_table_exclude_sub;
			SET &data_table.(KEEP=&y. &x.);
			IF (NOT MISSING(&x.)) AND NOT (&exclude_condi.) THEN OUTPUT work.data_table_sub;
			ELSE OUTPUT work.data_table_exclude_sub;
			RUN;

			/*	replace exclude value to special label	*/
			DATA work.data_table_exclude_sub;
			SET work.data_table_exclude_sub;
			IF (NOT MISSING(&x.)) AND (&exclude_condi.) THEN &x. = -99999999;
			RUN;
		%end;

	/*	calculate group statistic*/
	PROC SQL NOPRINT;
	/*	for sub dataset*/
		CREATE TABLE work.init_summary AS
		SELECT &x., AVG(&y.) AS means, COUNT(*) AS nsamples, STD(&y.) AS std_dev, 0 AS del_flg
	  	FROM work.data_table_sub
	 	GROUP BY &x. 
	 	ORDER BY &x. DESC;
		
		SELECT COUNT(*) INTO :bins_size_org
      	FROM work.init_summary;

	/*	for exclude sub dataset*/
		CREATE TABLE work.init_summary_exclude AS
		SELECT &x., AVG(&y.) AS means, COUNT(*) AS nsamples, STD(&y.) AS std_dev, 0 AS del_flg
	  	FROM work.data_table_exclude_sub
	 	GROUP BY &x. 
	 	ORDER BY &x. DESC;
	QUIT;

	DATA &lib_name..bins_summary_&x.;
		SET work.init_summary;
		std_dev = COALESCE(std_dev, 0);
		idx = _n_ - 1;
	RUN;
	
	%let del_count = 0;
	%do %while(1);
		%let i = 0;
		DATA &lib_name..bins_summary_&x.;
			SET &lib_name..bins_summary_&x.;
			tmpidx = _n_ - 1;
			drop idx ;
			rename tmpidx = idx ;
			WHERE del_flg = 0;
		RUN;
		
		PROC SQL NOPRINT;
			SELECT COUNT(*) INTO :record_size 
			FROM &lib_name..bins_summary_&x.;
		QUIT;

		%do %while(1);
			%let j = %eval(&i.+1) ; /* j : next id */

			%if &j. >= &record_size. %then %goto finished_bin_i_check;
			
			PROC SQL NOPRINT;
				SELECT means into :mean_i
				FROM &lib_name..bins_summary_&x. 
				WHERE idx = &i.;
				SELECT means into :mean_j 
				FROM &lib_name..bins_summary_&x. 
				WHERE idx = &j.;
			QUIT;
			
			%if &mean_i. &sign. &mean_j. %then 
				%do;
					%let i = %eval(&i.+1);
				%end;
			%else
				%do;
					%do %while(1);
						%let del_count =%eval(&del_count. + 1);
						%let bins_size_est = %eval(&bins_size_org. - &del_count.);

						PROC SQL NOPRINT;
							SELECT nsamples, means, std_dev INTO :nsamples_i, :nmeans_i, :nstd_i
						  	FROM &lib_name..bins_summary_&x.
			             	WHERE idx = &i.;
							
							SELECT nsamples, means, std_dev INTO :nsamples_j, :nmeans_j, :nstd_j
						  	FROM &lib_name..bins_summary_&x.
			             	WHERE idx = &j.;
						QUIT;  
						%let group_samples = %sysevalf(&nsamples_j. + &nsamples_i);
						%let group_means = %sysevalf((%sysevalf(&nsamples_j. * &nmeans_j.) + %sysevalf(&nsamples_i. * &nmeans_i.)) / &group_samples.);

						%if &group_samples. eq 2 %then
							%do;	
								%let group_std = %sysfunc(std(&nmeans_i., &nmeans_j.));
							%end;
						%else
							%do;
								%let group_std = %sysfunc(sqrt(((&nsamples_j. * (&nstd_j. ** 2)) + (&nsamples_i. * (&nstd_i. ** 2))) / &group_samples.));
							%end;

						PROC SQL NOPRINT;
							UPDATE &lib_name..bins_summary_&x. 
								SET 
									nsamples = &group_samples.,
									means = &group_means.,
									std_dev = &group_std.
							WHERE idx = &i.;
							UPDATE &lib_name..bins_summary_&x. SET del_flg = 1 WHERE idx = &j.;
						QUIT;
						%let j = %eval(&j.+1);
						
						%if &j. >= &record_size. %then %goto finished_bin_j_check;
						
						PROC SQL NOPRINT;
							SELECT means into :tmpmean_i
						  	FROM &lib_name..bins_summary_&x. 
			             	WHERE idx = &i.;
							
							SELECT means into :tmpmean_j 
						  	FROM &lib_name..bins_summary_&x. 
			             	WHERE idx = &j.;
						QUIT;

						%if &tmpmean_i. &sign. &tmpmean_j. %then 
							%group_sample_overflow:
							%do;
								%let i = &j.;
								%goto finished_bin_j_check;
							%end;
					%end;
					%finished_bin_j_check:
				%end;
			%if &j. >= &record_size. %then %goto finished_bin_i_check;
		%end;
		%finished_bin_i_check:

		PROC SQL NOPRINT;
			SELECT SUM(del_flg) into :dels 
			FROM &lib_name..bins_summary_&x.;
		QUIT;
		/* %put dels = &dels.; */

		%if &dels. = 0 %then %goto finished_bin;
	%end;
	%finished_bin:
	
	/*combine exclude result*/
	DATA &lib_name..bins_summary_&x.;
		SET &lib_name..bins_summary_&x. work.init_summary_exclude;
	RUN;
%MEND;

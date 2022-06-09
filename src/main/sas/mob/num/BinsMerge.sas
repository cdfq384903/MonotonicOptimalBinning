/*
根據auto bins出來的結果進行optiomal的chi/z merge,並以bin的size為最優先原則條件的過濾
	x:<string> 解釋變數名稱
	min_samples:<int> 每個bins最低個數限制閥值,建議個數估計最好是總樣本的5%
	min_bads:<int> 每個bins最低壞樣本的限制閥值
	min_pvalue:<float> 執行chi/z merge時,判斷合併p-value的閥值,如果bins之間的檢定值大於最小閥值時則表示群體之間並無差異,會進行該bins之間的合併
	min_bins:<int> 整體bins最低總數的限制
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	return void
*/
%MACRO runBinsMergeBySfb(x, min_samples, min_bads, min_pvalue, min_bins, lib_name);
	/* init bin summary with pvalue */
	DATA &lib_name..bins_summary_pvalue_&x. &lib_name..exclude_&x.;
	SET &lib_name..bins_summary_&x.;
	IF (NOT MISSING(&x.)) AND (&x. NE -99999999) THEN OUTPUT &lib_name..bins_summary_pvalue_&x.;
	ELSE OUTPUT &lib_name..exclude_&x.;
	RUN;

	/*calculate the statistics of exclude group*/
	DATA &lib_name..exclude_&x.;
	SET &lib_name..exclude_&x.;
	means_lead = .;
	nsamples_lead = .;
	std_dev_lead = .;
	nsamples_est = .;
	means_est = .;
	std_dev2_est = .;
	z_value = .;
	p_value = .;
	RUN;
	
	PROC SQL NOPRINT;
	SELECT COUNT(*) INTO :current_bins_size_exclude
      FROM &lib_name..exclude_&x.
	 WHERE (NOT MISSING(&x.) OR (&x. NE -99999999));

	%do %while(1);
		/* 	check bins constrain */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		RUN;
		PROC SQL NOPRINT;
		SELECT COUNT(*) INTO :current_bins_size
		  FROM &lib_name..bins_summary_pvalue_&x.;
		QUIT;
		%let current_bins_size_with_exclude = %eval(&current_bins_size. - &current_bins_size_exclude.);
		%if  &current_bins_size_with_exclude. <= &min_bins. %then %goto finished_bin_i_merge;

		/* 	shift table -1 */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		means_lead = .;
		nsamples_lead = .;
		std_dev_lead = .;
		idx = _n_ - 1;
		RUN;
			
		%do i = 1 %to &current_bins_size.;
			PROC SQL NOPRINT;
			SELECT means, nsamples, std_dev INTO :menas_i, :nsamples_i, :std_dev_i 
			  FROM &lib_name..bins_summary_pvalue_&x. 
			 WHERE idx = &i.;
			%if &i. eq &current_bins_size. %then %goto shift_leave;
			UPDATE &lib_name..bins_summary_pvalue_&x. SET means_lead = &menas_i., nsamples_lead = &nsamples_i., std_dev_lead = &std_dev_i.
			 WHERE idx = %eval(&i. - 1);
			QUIT;
		%end;
		%shift_leave:

		/* 	calculate est value */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		if idx < (&current_bins_size. - 1) then
			do;
				nsamples_est = nsamples_lead + nsamples;
				means_est = (means_lead * nsamples_lead + means * nsamples) / nsamples_est;
				std_dev2_est = (nsamples_lead * (std_dev_lead ** 2) + nsamples * (std_dev ** 2)) / (nsamples_est - 2);
				z_value = (means - means_lead) / sqrt(std_dev2_est * ((1 / nsamples) + (1 / nsamples_lead)));
				p_value = 1 - cdf("Normal", z_value);
			end;
		else
			do;
				nsamples_est = .;
				means_est = .;
				std_dev2_est = .;
				z_value = .;
				p_value = .;
			end;
		RUN;
		
		/* 	check other constrain(min_samples/min_bads) */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		if idx < (&current_bins_size. - 1) then
			do;
				current_bads = round(means * nsamples, 1);
				lead_bads = round(means_lead * nsamples_lead, 1);
				IF &min_samples. > nsamples OR &min_samples.> nsamples_lead OR &min_bads. > current_bads 
			    OR &min_bads. > lead_bads THEN p_value + 1; 
			end;
		else
			do;
				current_bads = .;
				lead_bads = .;
			end;
	    RUN;
	    
		/*  find maximun pvalue/idx/del_idx */
		PROC SQL NOPRINT;
		SELECT idx, p_value INTO :max_pvalue_idx, :max_pvalue
		  FROM &lib_name..bins_summary_pvalue_&x.
		 ORDER BY p_value DESC;
	  	QUIT;

		/* combine significant bins */
		%if &max_pvalue. > &min_pvalue. %then
		  	%do;
		  	  	%let del_idx = %eval(&max_pvalue_idx. + 1);

		  	  	/*  delete bin if bins are not different */
				PROC SQL NOPRINT;
				DELETE FROM &lib_name..bins_summary_pvalue_&x. WHERE idx = &del_idx.;
				QUIT;
				
				/* update bin infomation */
				PROC SQL NOPRINT;
				UPDATE &lib_name..bins_summary_pvalue_&x. SET means = means_est WHERE idx = &max_pvalue_idx.;
				UPDATE &lib_name..bins_summary_pvalue_&x. SET nsamples = nsamples_est WHERE idx = &max_pvalue_idx.;
				UPDATE &lib_name..bins_summary_pvalue_&x. SET std_dev = sqrt(std_dev2_est) WHERE idx = &max_pvalue_idx.;
				QUIT;
		  	%end;
	  	%else 
			%do ;
		  		%goto finished_bin_i_merge;
			%end ;
	%end;
	%finished_bin_i_merge:

	/*combine exclude result*/
	DATA &lib_name..bins_summary_pvalue_&x.;
	SET &lib_name..bins_summary_pvalue_&x. &lib_name..exclude_&x.;
	RUN;

%MEND;

/*
根據auto bins出來的結果進行optiomal的chi/z merge,並以monotone為最優先原則進行併組(bin size原則次之)
	x:<string> 解釋變數名稱
	min_samples:<int> 每個bins最低個數限制閥值,建議個數估計最好是總樣本的5%
	min_bads:<int> 每個bins最低壞樣本的限制閥值
	min_pvalue:<float> 執行chi/z merge時,判斷合併p-value的閥值,如果bins之間的檢定值大於最小閥值時則表示群體之間並無差異,會進行該bins之間的合併
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	return void
*/
%MACRO runBinsMergeByMfb(x, min_samples, min_bads, min_pvalue, lib_name);
	/* init bin summary with pvalue */
	DATA &lib_name..bins_summary_pvalue_&x. &lib_name..exclude_&x.;
	SET &lib_name..bins_summary_&x.;
	IF (NOT MISSING(&x.)) AND (&x. NE -99999999) THEN OUTPUT &lib_name..bins_summary_pvalue_&x.;
	ELSE OUTPUT &lib_name..exclude_&x.;
	RUN;

	/*calculate the statistics of exclude group*/
	DATA &lib_name..exclude_&x.;
	SET &lib_name..exclude_&x.;
	means_lead = .;
	nsamples_lead = .;
	std_dev_lead = .;
	nsamples_est = .;
	means_est = .;
	std_dev2_est = .;
	z_value = .;
	p_value = .;
	RUN;
	
	PROC SQL NOPRINT;
	SELECT COUNT(*) INTO :current_bins_size_exclude
      FROM &lib_name..exclude_&x.
	 WHERE (NOT MISSING(&x.) OR (&x. NE -99999999));

	%do %while(1);
		/* 	check bins constrain */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		RUN;

		PROC SQL NOPRINT;
		SELECT COUNT(*) INTO :current_bins_size
		  FROM &lib_name..bins_summary_pvalue_&x.;
		QUIT;

		%let current_bins_size_with_exclude = %eval(&current_bins_size. - &current_bins_size_exclude.);

		/* 	shift table -1 */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		means_lead = .;
		nsamples_lead = .;
		std_dev_lead = .;
		idx = _n_ - 1;
		RUN;
			
		%do i = 1 %to &current_bins_size.;
			PROC SQL NOPRINT;
			SELECT means, nsamples, std_dev INTO :menas_i, :nsamples_i, :std_dev_i 
			  FROM &lib_name..bins_summary_pvalue_&x. 
			 WHERE idx = &i.;
			%if &i. eq &current_bins_size. %then %goto shift_leave;
			UPDATE &lib_name..bins_summary_pvalue_&x. SET means_lead = &menas_i., nsamples_lead = &nsamples_i., std_dev_lead = &std_dev_i.
			 WHERE idx = %eval(&i. - 1);
			QUIT;
		%end;
		%shift_leave:

		/* 	calculate est value */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		if idx < (&current_bins_size. - 1) then
			do;
				nsamples_est = nsamples_lead + nsamples;
				means_est = (means_lead * nsamples_lead + means * nsamples) / nsamples_est;
				std_dev2_est = (nsamples_lead * (std_dev_lead ** 2) + nsamples * (std_dev ** 2)) / (nsamples_est - 2);
				z_value = (means - means_lead) / sqrt(std_dev2_est * ((1 / nsamples) + (1 / nsamples_lead)));
				p_value = 1 - cdf("Normal", z_value);
			end;
		else
			do;
				nsamples_est = .;
				means_est = .;
				std_dev2_est = .;
				z_value = .;
				p_value = .;
			end;
		RUN;
		
		/* 	check other constrain(min_samples/min_bads) */
		DATA &lib_name..bins_summary_pvalue_&x.;
		SET &lib_name..bins_summary_pvalue_&x.;
		if idx < (&current_bins_size. - 1) then
			do;
				current_bads = round(means * nsamples, 1);
				lead_bads = round(means_lead * nsamples_lead, 1);
				if &min_samples. > nsamples or &min_samples.> nsamples_lead or &min_bads. > current_bads 
			    or &min_bads. > lead_bads then p_value + 1; 
			end;
		else
			do;
				current_bads = .;
				lead_bads = .;
			end;
	    RUN;
	    
		/*  find maximun pvalue/idx/del_idx */
		PROC SQL NOPRINT;
		SELECT idx, p_value INTO :max_pvalue_idx, :max_pvalue
		  FROM &lib_name..bins_summary_pvalue_&x.
		 ORDER BY p_value DESC;
	  	QUIT;

		/* combine significant bins */
		%if &max_pvalue. > &min_pvalue. %then
		  	%do;
		  	  	%let del_idx = %eval(&max_pvalue_idx. + 1);

		  	  	/*  delete bin if bins are not different */
				PROC SQL NOPRINT;
				DELETE FROM &lib_name..bins_summary_pvalue_&x. WHERE idx = &del_idx.;
				QUIT;
				
				/* update bin infomation */
				PROC SQL NOPRINT;
				UPDATE &lib_name..bins_summary_pvalue_&x. SET means = means_est WHERE idx = &max_pvalue_idx.;
				UPDATE &lib_name..bins_summary_pvalue_&x. SET nsamples = nsamples_est WHERE idx = &max_pvalue_idx.;
				UPDATE &lib_name..bins_summary_pvalue_&x. SET std_dev = sqrt(std_dev2_est) WHERE idx = &max_pvalue_idx.;
				QUIT;
		  	%end;
	  	%else 
			%do ;
		  		%goto finished_bin_i_merge;
			%end ;
	%end;
	%finished_bin_i_merge:

	/*combine exclude result*/
	DATA &lib_name..bins_summary_pvalue_&x.;
	SET &lib_name..bins_summary_pvalue_&x. &lib_name..exclude_&x.;
	RUN;
%MEND;

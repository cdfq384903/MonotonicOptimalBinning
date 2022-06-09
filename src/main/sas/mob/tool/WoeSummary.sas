/*load libs*/
%INCLUDE "E:\UPL_MODEL\PwC_DNTI\src\handler\FileHandler.sas" ;

/*
根據optimal出來的結果計算woe/iv
	x:<string> 解釋變數名稱
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	show_plot:<int> 是否以直方圖的方式顯示woe數值
	return void
*/
%MACRO createWoeSummary(x, lib_name, show_plot);
	DATA &lib_name..woe_summary_&x.(KEEP=&x. min max nsamples means bads goods idx);
	SET &lib_name..bins_summary_pvalue_&x.;
	idx = _n_ - 1;
	min = .;
	max = .;
	bads = round(means * nsamples, 1);
	goods = round(nsamples - bads, 1);
	RUN;
	
	PROC SQL NOPRINT;
	SELECT COUNT(*) INTO :record_size
      FROM &lib_name..woe_summary_&x.;
	SELECT COUNT(*) INTO :exclude_record_size
      FROM &lib_name..woe_summary_&x.
	 WHERE (NOT MISSING(&x.) AND (&x. NE -99999999));
	QUIT;

	%do i = 1 %to %eval(&exclude_record_size. - 1);
		PROC SQL NOPRINT;
		SELECT &x. INTO :min_i 
          FROM &lib_name..woe_summary_&x.
         WHERE idx = &i;
		UPDATE &lib_name..woe_summary_&x. SET min = &min_i.
	     WHERE idx = &i - 1;
		QUIT;
	%end;
	
	%do i = 1 %to %eval(&exclude_record_size. - 1);
		PROC SQL NOPRINT;
		SELECT &x. INTO :max_i 
          FROM &lib_name..woe_summary_&x.
         WHERE idx = &i;
		UPDATE &lib_name..woe_summary_&x. SET max = &max_i.
	     WHERE idx = &i;
		QUIT;
	%end;
	
	/*	replace -99999999 label to null*/
	DATA &lib_name..woe_summary_&x.;
	SET &lib_name..woe_summary_&x.;
	IF min = -99999999 THEN min = .;
	IF max = -99999999 THEN max = .;
	RUN;

	/*	add interval label*/
	DATA &lib_name..woe_summary_&x.(KEEP=&x. nsamples goods bads min max  interval_easy means interval idx);
	SET &lib_name..woe_summary_&x.;
	IF (NOT MISSING(min)) AND (NOT MISSING(max)) THEN interval = catx(", ", catx("", "(", min), catx("", max,"]"));
	ELSE IF MISSING(min) AND (NOT MISSING(max)) THEN interval = catx(", ", catx("", "(", "-inf"), catx("", max, "]"));
	ELSE IF MISSING(max) AND (NOT MISSING(min)) THEN interval = catx(", ", catx("", "(", min), catx("", "inf", ")"));

	IF (NOT MISSING(min)) AND (NOT MISSING(max)) THEN interval_easy = catx(" ", catx("", catx("", min, "<"), "&x."), catx("", "<=", max));
	ELSE IF MISSING(min) AND (NOT MISSING(max)) THEN interval_easy = catx("", catx("", "&x.", "<="), max);
	ELSE IF MISSING(max) AND (NOT MISSING(min)) THEN interval_easy = catx("", catx("", "&x.", ">"), min);
	RUN;

	PROC SQL NOPRINT;
	SELECT SUM(goods), SUM(bads), SUM(nsamples) INTO :total_goods, :total_bads, :N
	  FROM &lib_name..woe_summary_&x.;
	QUIT;

	DATA &lib_name..woe_summary_&x.(KEEP=&x. nsamples dist_obs goods dist_good bads dist_bad bad_rate woe iv interval_easy interval);
	RETAIN &x. interval_easy nsamples dist_obs goods dist_good bads dist_bad bad_rate woe iv interval;
	SET &lib_name..woe_summary_&x.;
	bad_rate = bads / nsamples;
	dist_obs = nsamples / &N.;
	dist_good = goods / &total_goods.;
	dist_bad = bads / &total_bads.;
	IF dist_bad = 0 THEN woe = 0 ;
	ELSE woe = log(dist_good / dist_bad);
	iv = round((dist_good - dist_bad) * woe, 0.0001);
	DROP idx;
	RUN;

	%if &show_plot. EQ 1 %then
		%do;
			PROC SGPLOT DATA = &lib_name..woe_summary_&x.;
				TITLE "WoE(&x.) Bar Chart";
				xaxis type=discrete ;
				VBAR &x. / RESPONSE= woe DATALABEL = dist_obs 
						   Datalabelattrs=(Family = "Calibri" Size = 12 Weight = Bold )
						   datalabelpos= bottom
						   missing;
				vline &x. / RESPONSE=bad_rate y2axis datalabel= bad_rate  
						    Datalabelattrs=(Family = "Calibri" Size = 12 Weight = Bold) 
							datalabelpos= top
							missing;
				label &x. = "&x." bad_rate = "Bad Rate" woe = "WoE" ;
				QUIT;	
				title;
		%end;
%MEND;

/*
根據WoE切分出來的結果使用直方圖繪製出來
	lib_name:<string> 存放iv_summary檔案資料夾的目錄名稱
	min_iv:<float> 限制最小IV值以上才輸出圖型,如輸入0以下則不過濾
	return void
*/
%MACRO printWoeBarLineChart(lib_name, min_iv);
	%if &min_iv. > 0 %then
		%do;
			PROC SQL NOPRINT;
			SELECT COUNT(*) INTO :restrict_n 
               FROM &lib_name..iv_summary
			 WHERE iv >= &min_iv.;
			SELECT catx("", "WOE_SUMMARY_", x) INTO :data_list separated by " "
              FROM &lib_name..iv_summary
			 WHERE iv >= &min_iv.;
			QUIT;
		%end;
	%else
		%do;
			PROC CONTENTS DATA=&lib_name.._ALL_ out=woe_member(WHERE= (MEMTYPE = "DATA")) NOPRINT;
			RUN; 

			PROC SQL noprint ;
			SELECT distinct MEMNAME INTO :data_list separated by " "
			  FROM work.woe_member 
			 WHERE MEMNAME like "WOE_SUMMARY%" ;
			QUIT ;
		%end;
	%put data_list = &data_list. ;

	%let n = %sysfunc(countw(&data_list.));
	%if &restrict_n. >= 1 %then
		%do;
			%do i = 1 %to &n.;
				%let tbl = %scan(&data_list., &i.);
				
				PROC CONTENTS DATA=&lib_name..&tbl. out= variable(keep=name varnum) noprint;
				RUN;

				PROC SQL noprint;
				SELECT SUM(nsamples), SUM(bads) INTO : total_samples, :total_bads 
		          FROM &lib_name..&tbl.;

				SELECT trimn(name) INTO :x
		          FROM work.variable 
		         WHERE varnum = 1;
				
				%let x_trim = %sysfunc(trimn(&x.));
				SELECT iv INTO :x_iv
		          FROM &lib_name..iv_summary 
		         WHERE x = "&x_trim.";
				%let iv_trim = %sysfunc(trimn(%str(&x_iv.))) ;
				%let woe_title = "WoE(&x_trim.) Bar Chart with IV = &iv_trim.";

				DATA work.woeBarLineChart(KEEP=&x. woe bad_rate sample_rate);
				SET &lib_name..&tbl.;
				label &x. = "" ;
				total_samples = &total_samples.;
				total_bads = &total_bads.;
				bad_rate = round(bads / total_bads, 0.0001);
				sample_rate = put(round(nsamples / total_samples, 0.0001), 6.4);
				RUN;
				
				PROC SGPLOT DATA = woeBarLineChart;
				TITLE &woe_title.;
				xaxis type=discrete ;
				VBAR &x. / RESPONSE= woe DATALABEL = sample_rate 
						   Datalabelattrs=(Family = "Calibri" Size = 12 Weight = Bold )
						   datalabelpos= bottom
						   missing;
				vline &x. / RESPONSE=bad_rate y2axis datalabel= bad_rate  
						    Datalabelattrs=(Family = "Calibri" Size = 12 Weight = Bold) 
							datalabelpos= top
							missing;
				label &x. = "&x." bad_rate = "Bad Rate" woe = "WoE" ;
				QUIT;	
				title;
			%end ;
		%end;
%MEND;

/*
根據optimal出來的結果和合併成一份檔案顯示出來
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	var_type_file:<string> 長清單變數說明
	var_type_encoding:<string> 長清單資料集編碼
	return void
*/
%MACRO print(lib_name, var_type_file, var_type_encoding);
	%readCsvFile(inputFileAbsPath = &var_type_file., encoding = &var_type_encoding., 
                 outputFileAbsPath = tmp);
	PROC CONTENTS DATA=&lib_name.._ALL_ out=woe_member(WHERE= (MEMTYPE = "DATA")) NOPRINT;
	RUN; 

	PROC SQL noprint ;
		SELECT distinct MEMNAME INTO :data_list separated by " "
		  FROM work.woe_member 
		 WHERE MEMNAME like "WOE_SUMMARY%" ;
	QUIT ;
	%put &data_list. ;

	%let n = %sysfunc(countw(&data_list.));
	%do i = 1 %to &n. ;
		%let tbl = %scan(&data_list., &i.);

		PROC CONTENTS DATA=&lib_name..&tbl. out= variable(keep=name varnum) noprint;
		RUN;

		PROC SQL NOPRINT;
		SELECT trimn(name) INTO :x
          FROM work.variable 
         WHERE varnum = 1;
		%let x_trim = %sysfunc(trimn(&x.));
		SELECT tranwrd(中文欄位名稱, "%", "") INTO : x_cname 
          FROM work.tmp 
         WHERE 變數代碼 = "&x_trim.";
		SELECT ROUND(SUM(iv), 0.0001) INTO :total_iv 
          FROM &lib_name..&tbl.;
		QUIT;
		%let title_tmp = %sysfunc(trimn(&x_cname.));
		%let title_iv = %sysfunc(trimn(&total_iv.));
		PROC PRINT data = &lib_name..&tbl.;
		title "&title_tmp.(IV:[&title_iv.])";
		RUN;

	%end ;
	ods output close;
%MEND;

/*
根據optimal出來的結果和合併成一份檔案顯示出來
	lib_name:<string> 存放woe檔案資料夾的目錄名稱
	return void
*/
%MACRO printWithoutCname(lib_name);
	PROC CONTENTS DATA=&lib_name.._ALL_ out=woe_member(WHERE= (MEMTYPE = "DATA")) NOPRINT;
	RUN; 

	PROC SQL noprint ;
		SELECT distinct MEMNAME INTO :data_list separated by " "
		  FROM work.woe_member 
		 WHERE MEMNAME like "WOE_SUMMARY%" ;
	QUIT ;
	%put &data_list. ;

	%let n = %sysfunc(countw(&data_list.));
	%do i = 1 %to &n. ;
		%let tbl = %scan(&data_list., &i.);

		PROC CONTENTS DATA=&lib_name..&tbl. out= variable(keep=name varnum) noprint;
		RUN;

		PROC SQL NOPRINT;
		SELECT trimn(name) INTO :x
          FROM work.variable 
         WHERE varnum = 1;
		%let x_trim = %sysfunc(trimn(&x.));
		SELECT ROUND(SUM(iv), 0.0001) INTO :total_iv 
          FROM &lib_name..&tbl.;
		QUIT;
		%let title_tmp = &x_trim.;
		%let title_iv = %sysfunc(trimn(&total_iv.));
		PROC PRINT data = &lib_name..&tbl.;
		title "&title_tmp.(IV:[&title_iv.])";
		RUN;

	%end ;
	ods output close;
%MEND;

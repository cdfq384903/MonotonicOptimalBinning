
輸出資料集
	dataframestring 輸出資料集的資料來源
	outfilePathstring 輸出資料集的路徑
    dbmsOptionstring 輸出引擎,例如csv LABEL REPLACE
	otherOptionstring 其他額外參數,例如PUTNAMES=YES;
	return void

%MACRO exportFile(dataframe, outfilePath, dbmsOption, otherOption);
	PROC EXPORT;
	DATA = &dataframe.;
	OUTFILE = &outfilePath.;
	DBMS = &dbmsOption.;
	&otherOption.
	RUN;
%MEND;


讀取CSV資料集
	inputFileAbsPathstring 輸入資料集的路徑
	encodingstring 文件編碼,例如utf-8
	outputFileAbsPathstring 輸出資料集的路徑
	return void

%MACRO readCsvFile(inputFileAbsPath, encoding, outputFileAbsPath);
	FILENAME temp &inputFileAbsPath. ENCODING = &encoding.;
	PROC IMPORT DATAFILE = temp
	OUT = &outputFileAbsPath. REPLACE
	DBMS = csv ;
	DELIMITER = ',';
	GETNAMES = YES;
	GUESSINGROWS = MAX;
	RUN;
%MEND;


取得特定欄位數值
	attributestring 欄位名稱
	sepstring 區隔字串
	orgTablestring 原始資料表格
	whereCondstring where條件
	outVarstring 輸出數值
	return void

%MACRO selectAttribute(attribute, sep, orgTable, whereCond, outVar);
	SELECT &attribute. INTO &outVar. separated by &sep.
	   FROM &orgTable.
	WHERE &whereCond.;
	%put outVar;
%MEND;


刪除檔案
	filestring 刪除檔案的名稱
	return void

%MACRO deletefile(file);
  data _null_;
    rc = fdelete(&file.);
    if rc = 0 then do;
      put @1 50  +;
      put THE EXISTED OUTPUT FILE HAS BEEN DELETED.;
      put @1 50  +;
    end;
  run;
%MEND ;


刪除執行MOB演算法下的三大資料集，例如bins_summarybins_summary_pvalueexclude
	bins_libstring 存放執行mob演算法下產生bins_summarybins_summary_pvalueexclude三大檔案的lib位置
	return void

%MACRO cleanBinsDetail(bins_lib);
	PROC CONTENTS DATA = &bins_lib.._ALL_ OUT = bins_detail(WHERE = (MEMTYPE = DATA)) NOPRINT NODETAILS;
	RUN;
	
	%let clean_list = '';
	PROC SQL noprint ;
		SELECT distinct MEMNAME INTO clean_list separated by  
		  FROM bins_detail 
		 WHERE MEMNAME LIKE BINS_% OR MEMNAME LIKE EXCLUDE_%;

		SELECT COUNT() INTO n_clean_list
          FROM (SELECT distinct MEMNAME INTO clean_list separated by  
		          FROM bins_detail 
		         WHERE MEMNAME LIKE BINS_% OR MEMNAME LIKE EXCLUDE_%);
	QUIT ;
	%if &n_clean_list. = 0 %then
		%do;
			%let clean_list = .;
		%end;

	%put clean_list = &clean_list.;

	%let n = %sysfunc(countw(&clean_list.));
	%do i = 1 %to &n.;
		%let bin_detail_name = %scan(&clean_list., &i.) ;
		%put bin_detail_name = &bin_detail_name.;
		PROC DELETE DATA=&bins_lib..&bin_detail_name.;
		RUN;
	%end;

%MEND;

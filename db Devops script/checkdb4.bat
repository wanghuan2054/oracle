for %%i in (mdwetl) do (
set DBNAME=%%i
set ORACLE_SID=%%i
set NLS_LANG=SIMPLIFIED CHINESE_CHINA.ZHS16GBK 
:: set NLS_LANG=american_america.AL32UTF8 
set CHECK_TOP_DIR=d:\boweston
set CURDATE=%date:~0,4%%date:~5,2%%date:~8,2%
set FILES_DEST=d:\boweston\%date:~0,4%%date:~5,2%%date:~8,2%\%%i
setlocal EnableDelayedExpansion
if not exist !FILES_DEST! mkdir !FILES_DEST!
d:
cd !FILES_DEST!
echo 'exit'|sqlplus / as sysdba  @d:\boweston\db-v3.1.sql
echo 'exit'|sqlplus / as sysdba  @d:\boweston\awrrac.sql
echo 'exit'|sqlplus / as sysdba  @d:\boweston\dbtime.sql
echo 'exit'|sqlplus / as sysdba  @d:\boweston\alog.sql
)
pause

--优化获取字段及重置初始化值
--根据dbtime产生AWR，dbtime单位minu
--按天而不是按时间段产生AWR
--修正snap_id提前一个ID问题 2015-12-06
--修改begin_interval_time为sysdate日期 2015-12-21
--在spool文件上输出db_time 2015-12-22
--输出每个实例dbtime前4的AWR报告
--在RAC中输出4个dbtime最高的相同snap_id的AWR
set serveroutput on;

set termout off;

--SET DEF ^
--SET AUTOPRINT ON
SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF;
SET LONG 20000 LONGCHUNK 20000;

SET TERMOUT OFF;
COLUMN current_instance NEW_VALUE _current_instance NOPRINT;
COLUMN vsysdate NEW_VALUE _vsysdate NOPRINT;
SELECT instance_name current_instance FROM v$instance;
select * from (select to_char(sysdate,'yyyymmdd') vsysdate from dual);
SET TERMOUT ON;


spool my_awr.sql;
set echo off
declare
  i                 integer;
  rebegin_time_date date;
  reend_time_date   date;
  v_dbtime integer     := 0;
  v_rn     integer     := 4;
begin
  dbms_output.put_line('set linesize 2000');
  dbms_output.put_line('set pagesize 50000');
  dbms_output.put_line('set head off');
    for r in (with dbtimesql as 
(SELECT                                                                        
	  b.dbid                                                                              dbid
	, i.instance_number                                                                   instance_number
  , i.instance_name                                                                     instance_name
  , b.snap_id                                                                           snap_id
--  , TO_CHAR(s.startup_time, 'mm/dd/yyyy HH24:MI:SS')                                    startup_time
--  , TO_CHAR(s.begin_interval_time, 'mm/dd/yyyy HH24:MI:SS')                             begin_interval_time
--  , TO_CHAR(s.end_interval_time, 'mm/dd/yyyy HH24:MI:SS')                               end_interval_time
  , ROUND(EXTRACT(DAY FROM  s.end_interval_time - s.begin_interval_time) * 1440 +
          EXTRACT(HOUR FROM s.end_interval_time - s.begin_interval_time) * 60 +
          EXTRACT(MINUTE FROM s.end_interval_time - s.begin_interval_time) +
          EXTRACT(SECOND FROM s.end_interval_time - s.begin_interval_time) / 60, 2)     elapsed_time
  , ROUND((e.value - b.value)/1000000/60, 2)                                            db_time
--  , ROUND(((((e.value - b.value)/1000000/60) / (EXTRACT(DAY FROM  s.end_interval_time - s.begin_interval_time) * 1440 +
--                                                EXTRACT(HOUR FROM s.end_interval_time - s.begin_interval_time) * 60 +
--                                                EXTRACT(MINUTE FROM s.end_interval_time - s.begin_interval_time) +
--                                               EXTRACT(SECOND FROM s.end_interval_time - s.begin_interval_time) / 60) ) * 100), 2)   pct_db_time
FROM
    dba_hist_snapshot       s
  , gv$instance             i
  , dba_hist_sys_time_model e
  , dba_hist_sys_time_model b
  , sys.WRM$_SNAPSHOT t
WHERE
      i.instance_number = s.instance_number
  AND e.snap_id         = s.snap_id
  AND b.snap_id         = s.snap_id - 1
  AND e.stat_id         = b.stat_id
  AND e.instance_number = b.instance_number
  AND e.instance_number = s.instance_number
  AND t.instance_number = i.instance_number
  AND t.snap_id         = s.snap_id
  AND e.stat_name       = 'DB time'
  AND to_char(t.begin_interval_time, 'hh24:mi:ss') BETWEEN '06:00:00' AND '21:30:00'
  AND t.begin_interval_time >= sysdate - 8)
   select dbtimesql.*,dbsnapid.rn from dbtimesql,
   (select * from (SELECT dbtimesql.snap_id,dbtimesql.db_time, row_number() over(partition by instance_number order by db_time desc) rn FROM  dbtimesql )
 where rn <= v_rn and db_time > v_dbtime) dbsnapid
 where dbtimesql.snap_id = dbsnapid.snap_id) loop
      dbms_output.put_line('spool awrrpt_' ||
                           r.instance_name || '_' || r.snap_id || '_' ||
                           (r.snap_id + 1) || '_' ||r.db_time|| '_' ||r.rn||'.html');
      dbms_output.put_line('select * 
from table
(dbms_workload_repository.awr_report_html(' ||
                           r.dbid || ',' || r.instance_number || ',' ||
                           r.snap_id || ',' || (r.snap_id + 1) || ',0));');
      dbms_output.put_line('spool off');
    end loop;
end;
/
spool off;
@my_awr.sql
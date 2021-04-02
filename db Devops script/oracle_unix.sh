#!/usr/bin/ksh
#normal
#get *.sql
#output_path=/home/oracle/boweston/
output_path=$HOME/boweston/
PLATFORM=`/bin/uname`
HOSTN=`hostname`
fun_getcheckdbsql (){
cat >> checkdbsql.sql <<EOF
spool dbtime.csv
set echo off
set termout off
set lines 200 pages 999
select instance_name||','||snap_id||','||snap_time||','||db_time
  from (select instance_name,
               snap_id,
               snap_time,
               round((value - v) / 60 / 1000000, 2) db_time
          from (select instance_name,
                       snap_id,
                       snap_time,
                       value,
                       (lag(value)
                        over(partition by instance_name order by snap_id)) v
                  from (select i.instance_name,
                               sp.snap_id - 1 as snap_id,
                               to_char(begin_interval_time, 'mm-dd hh24:mi:ss') snap_time,
                               value
                          from dba_hist_snapshot       sp,
                               dba_hist_sys_time_model sy,
                               gv\$instance             i
                         where sp.snap_id = sy.snap_id
                           and sp.instance_number = sy.instance_number
                           and sy.instance_number = i.instance_number
                           and sp.BEGIN_INTERVAL_TIME >= sysdate - 8
                           and sy.stat_name = 'DB time'))) dbtimesql
 where dbtimesql.db_time >= 0
 order by instance_name, snap_id;
 spool off
spool dbcheck.log
set termout on
prompt
prompt 系统背景
prompt 数据库及实例名称
set lines 1000
set pages 1000
select name,instance_name,status from v\$database,gv\$instance;
prompt 数据库软件版本
col banner for a70
SELECT * FROM V\$VERSION;
prompt 数据库参数
col name for a30
col value for a50
select NAME,VALUE from v\$parameter where isdefault='FALSE'
union all
select parameter,value from v\$nls_parameters where parameter like '%CHARACTERSET';
prompt 控制文件信息
col type for a10
col value for a30
show parameter control_file
prompt 分析：控制文件正常应为2个以上
prompt
prompt 日志文件大小及位置
col gp# for 99
col th# for 99
col sz for 9999
col status for a8
col mmbrs for 999
col member for a50
select a.THREAD# th#,a.group# gp#,(bytes/1024/1024) sz,members mmbrs,a.STATUS,member from v\$log a,v\$logfile b where a.group#=b.group# order by 1,2;
prompt 分析：日志组文件正常情况应为每组2个
prompt
prompt 数据库资源限制
col resource_name for a25
col current_utilization for 9999999999
col INITIAL_ALLOCATION for a18
col LIMIT_VALUE for a15
select resource_name,current_utilization,max_utilization,initial_allocation,limit_value 
from v\$resource_limit;
prompt 分析：目前各项资源的max value都远低于初始分配值，能满足系统应用
prompt
prompt 数据库的归档模式
archive log list

prompt 检查数据库的存储空间
prompt 数据文件总大小及个数
--select a.used_size,b.file_size,b.ts_counts,b.file_counts from
--(select '1' id ,round(sum(bytes)/1024/1024/1024,2) used_size from dba_segments) a,
--(select '1' id,round(sum(bytes)/1024/1024/1024,2) file_size,count(*) file_counts,count(distinct ts#) ts_counts from v\$datafile) b
--where a.id=b.id;
--prompt 分析：当前数据库数据文件大小为
COLUMN hfile_size  NEW_VALUE _hfile_size NOPRINT
select a.used_size,b.file_size,b.hfile_size,b.ts_counts,b.file_counts from
(select '1' id ,round(sum(bytes)/1024/1024/1024,2) used_size from dba_segments) a,
(select '1' id,round(sum(bytes)/1024/1024/1024,2) file_size,trim(round(sum(bytes)/1024/1024/1024,2))||'GB' hfile_size,count(*) file_counts,count(distinct ts#) ts_counts from v\$datafile) b
where a.id=b.id;
prompt 分析：当前数据库数据文件大小为&_hfile_size
prompt
prompt 检查表空间状态信息
col tablespace_name for a25
col extent_management for a15
col segment_space_management for a15
col CONTENTS for a10
select STATUS,tablespace_name,extent_management,segment_space_management,CONTENTS
from dba_tablespaces;
prompt 分析：表空间管理方式正常
prompt
prompt 检查数据文件状态
select count(*),status from v\$datafile group by status;
prompt 分析：数据文件状态正常
prompt
prompt 临时表空间使用情况
col tablespace_name for a25
col "max_gb" for 9999
col "USED_%" for 99.99
col  "used_gb" for 9999
select t.tablespace_name,t.max_gb,t.used_gb,round(t.used_gb/t.max_gb,2) "USED_%" from
   (select h.tablespace_name tablespace_name,
               round(sum(nvl(p.bytes_used, 0)) / power(2, 30), 2) used_gb,
               round(sum(decode(f.autoextensible,
                                'YES',
                                f.maxbytes,
                                'NO',
                                f.bytes)) / power(2, 30),
                     2) max_gb
          from v\$temp_space_header h, v\$temp_extent_pool p, dba_temp_files f
         where p.file_id(+) = h.file_id
           and p.tablespace_name(+) = h.tablespace_name
           and f.file_id = h.file_id
           and f.tablespace_name = h.tablespace_name
         group by h.tablespace_name) t;
prompt 分析：临时表空间使用率正常。如果长时间使用率为100%，建议增加临时表空间大小
prompt
prompt 数据表空间使用情况
col tablespace_name for a25
col status for a10
SELECT D.TABLESPACE_NAME,
       G.STATUS,
       MAX_SPACE,
       SPACE "SUM_SPACE(M)",
       SPACE - NVL(FREE_SPACE, 0) "USED_SPACE(M)",
       ROUND(((SPACE - NVL(FREE_SPACE, 0)) / MAX_SPACE) * 100, 2) "USED_RATE(%)"
  FROM (SELECT TABLESPACE_NAME,
               SUM(MAX_SPACE) MAX_SPACE,
               SUM(SPACE) SPACE,
               SUM(BLOCKS) BLOCKS
          FROM (SELECT file_id,
                       TABLESPACE_NAME,
                       ROUND(decode(sign(sum(BYTES) - sum(MAXBYTES)),
                                    -1,
                                    SUM(MAXBYTES) / (1024 * 1024),
                                    SUM(BYTES) / (1024 * 1024)),
                             2) MAX_SPACE,
                       ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
                       SUM(BLOCKS) BLOCKS
                  FROM DBA_DATA_FILES
                 GROUP BY file_id, TABLESPACE_NAME)
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) FREE_SPACE
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) F,
       dba_tablespaces G
 WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+)
   AND D.TABLESPACE_NAME = G.TABLESPACE_NAME
 order by 6 desc;
prompt 分析：表空间使用率正常，如果使用率超过85%，请考虑增加表空间大小
prompt
prompt 闪回大小及位置
col name for a40
col used for 9999999
col total for 9999999
col tatio for 99.99
select name,round(space_limit/1024/1024/1024,2) total,round(space_used/1024/1024/1024,2) used,round(space_used/decode(space_limit,0,1),2) ratio from v\$recovery_file_dest;
prompt 分析：闪回空间正常，如果闪回空间使用率大于70，则建议清理
prompt
prompt 检查asm磁盘空间的使用情况
col name for a20
select name,total_mb/1024 total,free_mb/1024 free,state from v\$asm_diskgroup;
prompt 查询哪个表空间中存储了表和相关联的index
col tablespace_name for a40
SELECT DISTINCT (a.tablespace_name)
FROM dba_tables a, dba_indexes b
WHERE a.owner = b.table_owner
AND a.table_name = b.table_name
AND a.tablespace_name = b.tablespace_name
AND a.tablespace_name not in ( 'SYSTEM', 'SYSAUX' );
prompt 分析：表和索引在同一表空间，建议分开存放
prompt
prompt 查询在系统表空间中有对象的普通用户及其对象大小
set linesize 1000
col owner for a15
col segment_name for a20
col tablespace_name for a30
col segment_type for a15
select owner,
       segment_name,
       segment_type,
       bytes / 1024 / 1024,
       tablespace_name
  from dba_segments
 where tablespace_name = 'SYSTEM'
   and owner IN (select username
                   from dba_users
                  where account_status = 'OPEN'
                    and username NOT IN ('ANONYMOUS',
                                         'CTXSYS',
                                         'DIP',
                                         'DBSNMP',
                                         'DMSYS',
                                         'DMSYS',
                                         'MDDATA',
                                         'MDSYS',
                                         'MGMT_VIEW',
                                         'OLAPSYS',
                                         'ORDPLUGINS',
                                         'ORDSYS',
                                         'OUTLN',
                                         'SCOTT',
                                         'SI_INFORMTN_SCHEMA',
                                         'SYS',
                                         'SYSMAN',
                                         'SYSTEM',
                                         'WK_TEST',
                                         'WKPROXY',
                                         'WKSYS',
                                         'WMSYS',
                                         'XDB',
                                         'ORACLE_OCM'));
prompt 检查日志切换频率
col thread# for 99
col firsttime for a20
select thread#, to_char(first_time, 'yyyy-mm-dd hh24') firsttime, count(sequence#)
  from v\$log_history
 where first_time > sysdate - 1
   and first_time < sysdate + 1
 group by thread#, to_char(first_time, 'yyyy-mm-dd hh24')
 order by 1, 2;
prompt 分析：日志切换不规律
prompt

prompt 查看数据库其它性能信息
prompt 查看是否启用默认180天密码修改限制
COL PROFILE FOR A10
COL  RESOURCE_NAME FOR A20
COL LIMIT FOR A10
select PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT FROM DBA_PROFILES WHERE RESOURCE_NAME='PASSWORD_LIFE_TIME' AND LIMIT='180';
prompt 分析：如果存在输出结果，则说明存在默认180天密码修改限制
prompt
prompt 查看是否启用默认密码输错10次锁定用户限制
COL PROFILE FOR A10
COL  RESOURCE_NAME FOR A22
COL LIMIT FOR A10
select PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT FROM DBA_PROFILES WHERE RESOURCE_NAME='FAILED_LOGIN_ATTEMPTS' AND LIMIT='10';
prompt 分析：如果存在输出结果，则说明存在默认连续10次登录失败锁定账户限制
prompt
prompt 查看数据库补丁情况
col ACTION_TIME for a30
col action for a10
col namespace for a10
col version for a12
col BUNDLE_SERIES for a10
col COMMENTS for a20
select * from dba_registry_history order by 5;
prompt 分析：当前数据库没有安装最新补丁集
prompt
prompt 查看数据库审计情况
show parameter audit
prompt
prompt 分析：审计为默认DB级别
prompt
prompt 查看数据库审计表大小
col segment_name for a20
select segment_name,sum(bytes)/1024/1024/1024 from dba_segments where segment_name='AUD\$' group by segment_name;
prompt 分析：如果审计表过大，建议定期truncate
prompt
prompt 查看数据库RMAN备份
col lv for a3
col device_type for a8
col s_time for a10
col e_time for a10
col compressed for a3
select *
  from (select a.RECID key,
               case
                 when a.INCREMENTAL_LEVEL is null and a.backup_type = 'L' then
                  'A'
                 when a.INCREMENTAL_LEVEL is null and a.backup_type = 'D' then
                  'F'
                 ELSE
                  to_char(a.INCREMENTAL_LEVEL)
               END LV,
               b.STATUS,
               b.DEVICE_TYPE,
               to_char(a.START_TIME,'yyyymmdd') s_time,
               to_char(a.COMPLETION_TIME,'yyyymmdd') e_time,
               b.PIECE#,
               b.COMPRESSED,
               b.TAG
          from v\$backup_set a, v\$backup_piece b
         where a.SET_COUNT = b.SET_COUNT
           and b.STATUS = 'A'
         order by 5 desc)
 where rownum < 30;
prompt 分析：
prompt
prompt 大于2G未分区的表
prompt
select owner, segment_name,bytes/1024/1024/1024 "G size" from dba_segments where bytes>2048000000 and segment_name not in(select object_name from dba_recyclebin) and segment_type='TABLE' and partition_name IS NULL;
prompt 分析：对于大于2G未分区的对象，如果影响性能，考虑分区
prompt
prompt 查询数据库中无效对象
prompt
SELECT owner, object_type, count(object_name)
  FROM dba_objects
 WHERE status = 'INVALID'
   and owner not in ('ANONYMOUS',
                     'CTXSYS',
                     'DIP',
                     'DBSNMP',
                     'DMSYS',
                     'DMSYS',
                     'MDDATA',
                     'MDSYS',
                     'MGMT_VIEW',
                     'OLAPSYS',
                     'ORDPLUGINS',
                     'ORDSYS',
                     'OUTLN',
                     'SCOTT',
                     'SI_INFORMTN_SCHEMA',
                     'SYS',
                     'SYSMAN',
                     'SYSTEM',
                     'WK_TEST',
                     'WKPROXY',
                     'WKSYS',
                     'WMSYS',
                     'XDB',
                     'PUBLIC',
                     'ORACLE_OCM')
 group by owner, object_type
UNION
SELECT owner, 'INDEX', count(index_name)
  from dba_indexes
 where status IN ('INVALID', 'UNUSABLE')
   and owner not in ('ANONYMOUS',
                     'CTXSYS',
                     'DIP',
                     'DBSNMP',
                     'DMSYS',
                     'DMSYS',
                     'MDDATA',
                     'MDSYS',
                     'MGMT_VIEW',
                     'OLAPSYS',
                     'ORDPLUGINS',
                     'ORDSYS',
                     'OUTLN',
                     'SCOTT',
                     'SI_INFORMTN_SCHEMA',
                     'SYS',
                     'SYSMAN',
                     'SYSTEM',
                     'WK_TEST',
                     'WKPROXY',
                     'WKSYS',
                     'WMSYS',
                     'XDB',
                     'PUBLIC',
                     'ORACLE_OCM')
 group by owner;
prompt 分析：数据库中存在无效对象，建议处理
prompt
prompt 关于表并行度的检查
col owner for a15
col type  for a10
col Degree for a10
select owner,'TABLE' type,degree,COUNT(*) from dba_tables where degree not in(1,0,'DEFAULT') and owner<>'SYS' group by owner,degree
union all
select owner,'INDEX', degree,count(*) from dba_indexes where degree not in(1,0,'DEFAULT') and owner<>'SYS' group by owner,degree;
prompt 分析：表和索引上没有设置并行
prompt
prompt Fast soft parse
col parameter for a30
col value for a30
select
  'session_cached_cursors'  parameter,
  lpad(value, 5)  value,
  decode(value, 0, '  n/a', to_char(100 * used / value, '9900') || '%')  usage
from
  ( select
      max(s.value)  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'session_cached_cursors'
  )
union all
select
  'open_cursors',
  lpad(value, 5),
  to_char(100 * used / value,  '990') || '%'
from
  ( select
      max(sum(s.value))  used
    from
      v\$statname  n,
      v\$sesstat  s
    where
      n.name in ('opened cursors current', 'session cursor cache count') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      v\$parameter
    where
      name = 'open_cursors'
  );
prompt 检查数据库用户权限
col username for a20
col granted_role for a20
col default_tablespace for a20
col temporary_tablespace for a20
select username, GRANTED_ROLE, default_tablespace, temporary_tablespace
  from dba_users a, dba_role_privs b
 where a.username = b.GRANTEE
   and a.account_status = 'OPEN'
   and b.granted_role = 'DBA'
   and a.username not in ('ANONYMOUS',
                          'CTXSYS',
                          'DIP',
                          'DBSNMP',
                          'DMSYS',
                          'DMSYS',
                          'MDDATA',
                          'MDSYS',
                          'MGMT_VIEW',
                          'OLAPSYS',
                          'ORDPLUGINS',
                          'ORDSYS',
                          'OUTLN',
                          'SCOTT',
                          'SI_INFORMTN_SCHEMA',
                          'SYS',
                          'SYSMAN',
                          'SYSTEM',
                          'WK_TEST',
                          'WKPROXY',
                          'WKSYS',
                          'WMSYS',
                          'XDB',
                          'ORACLE_OCM');
prompt 分析：有用户使用DBA权限，对于一般用户不建议分配dba角色
prompt
prompt 检查数据库中定义的job
col log_user for a15
col last_date for a20
col next_date for a20
col what for a30
select log_user,to_char(last_date,'yyyy-mm-dd hh24:mi:ss') last_date,to_char(next_date,'yyyy-mm-dd hh24:mi:ss') next_date,what from dba_jobs;
prompt

prompt 数据库性能指标
prompt 当前系统连接数情况
select inst_id,count(*) from gv\$session group by inst_id order by 1;
prompt 查看AWR保留信息
col SNAP_INTERVAL for a20
col retention for a20
select * from dba_hist_wr_control;
prompt 查看数据库统计信息JOB执行
col job_name for a30
col s_time for a18
col status for a9
col RUN_DURATION for a20
show parameter statistics_level;
select job_name,
       to_char(actual_start_date, 'yyyymmdd hh24:mi:ss') s_time,
       status,
       run_duration
  from (select *
          from dba_scheduler_job_run_details
         where job_name like 'ORA\$AT_OS_OPT%' or job_name like 'GATHER_STATS_JOB%'
         order by log_date desc)
 where rownum < 10;
prompt 查看阻塞SQL语句信息
col sql_text for a1000
select sql_text from gv\$sql a,gv\$session b where a.sql_id=b.sql_id and b.blocking_session is not null;
prompt 分析：阻塞回话SQL语句可能会存在性能问题
prompt
prompt 查看外键没有索引的表列
col OWNER for a15
col TABLE_NAME for a20
col CONSTRAINT_NAME for a20
col COLUMNS for a20
SELECT OWNER,
       TABLE_NAME,
       CONSTRAINT_NAME,
       CNAME1 || NVL2(CNAME2, ',' || CNAME2, NULL) ||
       NVL2(CNAME3, ',' || CNAME3, NULL) ||
       NVL2(CNAME4, ',' || CNAME4, NULL) ||
       NVL2(CNAME5, ',' || CNAME5, NULL) ||
       NVL2(CNAME6, ',' || CNAME6, NULL) ||
       NVL2(CNAME7, ',' || CNAME7, NULL) ||
       NVL2(CNAME8, ',' || CNAME8, NULL) COLUMNS
  FROM (SELECT B.OWNER,
               B.TABLE_NAME,
               B.CONSTRAINT_NAME,
               MAX(DECODE(POSITION, 1, COLUMN_NAME, NULL)) CNAME1,
               MAX(DECODE(POSITION, 2, COLUMN_NAME, NULL)) CNAME2,
               MAX(DECODE(POSITION, 3, COLUMN_NAME, NULL)) CNAME3,
               MAX(DECODE(POSITION, 4, COLUMN_NAME, NULL)) CNAME4,
               MAX(DECODE(POSITION, 5, COLUMN_NAME, NULL)) CNAME5,
               MAX(DECODE(POSITION, 6, COLUMN_NAME, NULL)) CNAME6,
               MAX(DECODE(POSITION, 7, COLUMN_NAME, NULL)) CNAME7,
               MAX(DECODE(POSITION, 8, COLUMN_NAME, NULL)) CNAME8,
               COUNT(*) COL_CNT
          FROM (SELECT owner,
                       SUBSTR(TABLE_NAME, 1, 30) TABLE_NAME,
                       SUBSTR(CONSTRAINT_NAME, 1, 30) CONSTRAINT_NAME,
                       SUBSTR(COLUMN_NAME, 1, 30) COLUMN_NAME,
                       POSITION
                  FROM DBA_CONS_COLUMNS
                 WHERE OWNER NOT IN ('ANONYMOUS',
                                     'CTXSYS',
                                     'DIP',
                                     'DBSNMP',
                                     'DMSYS',
                                     'DMSYS',
                                     'MDDATA',
                                     'MDSYS',
                                     'MGMT_VIEW',
                                     'OLAPSYS',
                                     'ORDPLUGINS',
                                     'ORDSYS',
                                     'OUTLN',
                                     'SCOTT',
                                     'SI_INFORMTN_SCHEMA',
                                     'SYS',
                                     'SYSMAN',
                                     'XI',
                                     'SH',
                                     'HR',
                                     'SYSTEM',
                                     'WK_TEST',
                                     'WKPROXY',
                                     'WKSYS',
                                     'WMSYS',
                                     'XDB',
                                     'ORDDATA',
                                     'EXFSYS',
                                     'ORACLE_OCM')) A,
               DBA_CONSTRAINTS B
         WHERE A.CONSTRAINT_NAME = B.CONSTRAINT_NAME
           AND B.CONSTRAINT_TYPE = 'R'
           and A.OWNER = B.OWNER
         GROUP BY B.OWNER, B.TABLE_NAME, B.CONSTRAINT_NAME) CONS
 WHERE COL_CNT > ALL (SELECT COUNT(*)
          FROM DBA_IND_COLUMNS I
         WHERE I.TABLE_NAME = CONS.TABLE_NAME
           AND I.TABLE_OWNER = CONS.OWNER
           AND I.COLUMN_NAME IN (CNAME1,
                                 CNAME2,
                                 CNAME3,
                                 CNAME4,
                                 CNAME5,
                                 CNAME6,
                                 CNAME7,
                                 CNAME8)
           AND I.COLUMN_POSITION <= CONS.COL_CNT
         GROUP BY I.INDEX_NAME);
prompt 分析：当更新主表时外键没有索引会导致整个子表被锁，影响系统性能，建议对这些表外键字段添加索引(5.5小节)
prompt
prompt 检查系统回收站对象

select count(*) from dba_recyclebin;
prompt 分析：回收站内容过多会影响数据字典表查询缓慢，如果数量超过1000，建议清理
prompt
prompt TOP 5 等待事件
prompt
prompt buffer 命中率
prompt
prompt PGA调整建议
prompt
prompt 分析：
prompt SGA信息
prompt
prompt 分析：
spool off
EOF
}

fun_getautoawr (){
cat >> awrrac.sql <<EOF
	set serveroutput on;
	set long 99999;
	set heading off;
	set termout off;
	set echo off;
	set feedback off;
	set timing off;
	set lines 400
	set pages 999
	--SET DEF "^" ;
	--SET AUTOPRINT ON;
	SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF;
	SET LONG 20000 LONGCHUNK 20000;
	SET TERMOUT OFF;
	COLUMN current_instance NEW_VALUE _current_instance NOPRINT;
	COLUMN vsysdate NEW_VALUE _vsysdate NOPRINT;
	SELECT instance_name current_instance FROM v\$instance;
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
	, gv\$instance             i
	, dba_hist_sys_time_model e
	, dba_hist_sys_time_model b
	, sys.WRM\$_SNAPSHOT t
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
		dbms_output.put_line('spool '||'$output_path'||'&_vsysdate'||'&_current_instance'||'/awrrpt_' ||
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
EOF
}
 
fun_getdbtime (){
cat >> dbtime.sql <<EOF
	set lines 300 pages 999
	spool dbtime.log               
	select * from (select instance_name,snap_id,snap_time, round((value - v) / 60 / 1000000, 2) db_time
	from (select instance_name,snap_id,snap_time, value, (lag(value) over(partition by instance_name  order  by snap_id)) v
			from (select i.instance_name,sp.snap_id - 1 as snap_id,
						to_char(begin_interval_time, 'mm-dd hh24:mi:ss') snap_time,
						value
					from dba_hist_snapshot sp, dba_hist_sys_time_model sy,gv\$instance  i
					where sp.snap_id = sy.snap_id
					and sp.instance_number = sy.instance_number
					and sy.instance_number = i.instance_number
					and sp.BEGIN_INTERVAL_TIME >= sysdate-8
					and sy.stat_name = 'DB time'
					))) dbtimesql where  dbtimesql.db_time >=0  order by instance_name,snap_id;
	spool off; 
EOF
}

fun_dochecklinuxos (){
echo "操作系统信息" >>dbcheck.log
echo "主机名称">>dbcheck.log
hostname >>dbcheck.log
echo
echo "系统内核版本信息" >>dbcheck.log
uname -a >>dbcheck.log
cat /etc/redhat-release >>dbcheck.log
echo
echo "磁盘空间使用率" >>dbcheck.log
df -h >>dbcheck.log
echo
echo "系统运行时间" >>dbcheck.log
uptime >>dbcheck.log
echo
echo "实时磁盘io" >>dbcheck.log
iostat 2 4 >>dbcheck.log
echo
echo "系统任务计划" >>dbcheck.log
crontab -l >>dbcheck.log
echo
echo "CPU信息" >>dbcheck.log
vmstat 2 4 >>dbcheck.log
echo
echo "内存使用信息" >>dbcheck.log
free -m>>dbcheck.log
more /proc/meminfo >>dbcheck.log
echo
sqlplus "sys/123 as sysdba" <<EOF
set heading off;
set feedback off;
set termout off;
set pagesize 0;
set verify off;
set echo off;
set lines 1000
spool 1.log
select 'tail -2000 '||a.value||'/'||'alert_'||b.value||'.log>alert.log' from v\$parameter a,v\$parameter b where a.name='background_dump_dest' and b.name='instance_name';
spool off
EOF
echo
echo "ALERT 是否文件报错">>dbcheck.log
grep alert 1.log|grep -v SQL>1.sh
sh 1.sh
rm 1.log
rm 1.sh
grep -a -B 2 ORA- alert.log >>dbcheck.log
echo ' '>>dbcheck.log
echo "分析：">>dbcheck.log
echo
echo "操作系统参数">>dbcheck.log
sysctl -a |grep vm.min_free_kbytes>>dbcheck.log
echo
echo "分析：min_free_kbytes设置为操作系统最低保留内存，建议设置为1G">>dbcheck.log
echo
more /proc/meminfo |grep HugePages>>dbcheck.log
echo
echo "分析：当数据库SGA大于8G时建议设置大内存页功能">>dbcheck.log
echo
grep kernel.shmmax /etc/sysctl.conf|grep -v is>>dbcheck.log
var1=`free -m |grep Mem: |awk '{print $2}'`
var2=*1024*1024/2
var3=${var1}${var2}
echo $var3>max.bc
le=`cat max.bc|bc`
echo
echo "分析：系统当前配置shmmax参数值至少为:"$le >>dbcheck.log
echo
rm max.bc
grep kernel.shmall /etc/sysctl.conf|grep -v is>>dbcheck.log
var1=`grep kernel.shmall /etc/sysctl.conf|grep -v is|awk '{print $3}'`
var2=/4/1024
var3=${var1}${var2}
echo $var3>mal.bc
le=`cat mal.bc|bc`
echo
echo "分析：shmall参数值应为shmmax/4k大小:"$le>>dbcheck.log
rm mal.bc
echo
echo "监听文件大小">>dbcheck.log
lsnrctl status|grep Log>2.log
export aa=`cat 2.log |cut -c 20-`
listenersize=${aa%%alert*}
du -sh $listenersize'trace'/*>>dbcheck.log
export bb=`cat 2.log |cut -c 20-`
du -sh $bb>>dbcheck.log
rm 2.log
echo "分析：监听文件过大会影响系统连接，大于1G后建议清理">>dbcheck.log
}

fun_docheckaixos (){
echo "操作系统信息" >>dbcheck.log
echo "主机名称">>dbcheck.log
echo 
hostname >>dbcheck.log
echo 
echo "系统内核版本信息" >>dbcheck.log
echo 
oslevel -s >>dbcheck.log
echo 
echo "磁盘空间使用率" >>dbcheck.log
echo 
df -g >>dbcheck.log
echo 
echo "系统运行时间" >>dbcheck.log
echo 
uptime >>dbcheck.log
echo 
echo "实时磁盘io" >>dbcheck.log
iostat 2 4 >>dbcheck.log
echo 
echo "系统任务计划" >>dbcheck.log
echo 
crontab -l >>dbcheck.log
echo 
echo "CPU信息" >>dbcheck.log
echo 
vmstat 2 4 >>dbcheck.log
echo 
echo 
sqlplus "sys/123 as sysdba" <<EOF
set heading off;
set feedback off;
set termout off;
set pagesize 0;
set verify off;
set echo off;
set lines 1000
set termout off
spool 1.log
select 'tail -2000 '||a.value||'/'||'alert_'||b.value||'.log>alert.log' from v\$parameter a,v\$parameter b where a.name='background_dump_dest' and b.name='instance_name';
spool off
EOF
echo "ALERT 是否文件报错">>dbcheck.log
grep alert 1.log|grep -v SQL>1.sh
sh 1.sh
rm 1.log
rm 1.sh
awk '!/ORA|Errors/{a=$0}/ORA|Errors/{print a,$0}' alert.log >>dbcheck.log
echo ' '>>dbcheck.log
echo "分析：">>dbcheck.log
echo 
echo "操作系统参数" >>dbcheck.log
echo 
vmo -L maxperm% -L maxclient% >> dbcheck.log
echo 
echo "监听文件大小">>dbcheck.log
lsnrctl status|grep Log>2.log
export aa=`cat 2.log |cut -c 20-`
listenersize=${aa%%alert*}
du -sg $listenersize'trace'/*>>dbcheck.log
export bb=`cat 2.log |cut -c 20-`
du -sg $bb>>dbcheck.log
rm 2.log
echo ' '>>dbcheck.log
echo "分析：监听文件过大会影响系统连接，大于1G后建议清理">>dbcheck.log
}

fun_docheckhpos (){
echo "操作系统信息" >>dbcheck.log
echo "主机名称">>dbcheck.log
echo 
hostname >>dbcheck.log
echo 
echo "系统内核版本信息" >>dbcheck.log
echo 
uname -r >>dbcheck.log
echo 
echo "磁盘空间使用率" >>dbcheck.log
echo 
bdf >>dbcheck.log
echo 
echo "系统运行时间" >>dbcheck.log
echo 
uptime >>dbcheck.log
echo 
echo "实时磁盘io" >>dbcheck.log
iostat 2 4 >>dbcheck.log
echo 
echo "系统任务计划" >>dbcheck.log
echo 
crontab -l >>dbcheck.log
echo 
echo "CPU信息" >>dbcheck.log
echo 
vmstat 2 4 >>dbcheck.log
echo 
echo 
sqlplus "sys/123 as sysdba" <<EOF
set heading off;
set feedback off;
set termout off;
set pagesize 0;
set verify off;
set echo off;
set lines 1000
set termout off
spool 1.log
select 'tail -2000 '||a.value||'/'||'alert_'||b.value||'.log>alert.log' from v\$parameter a,v\$parameter b where a.name='background_dump_dest' and b.name='instance_name';
spool off
EOF
echo "ALERT 是否文件报错">>dbcheck.log
grep alert 1.log|grep -v SQL>1.sh
sh 1.sh
rm 1.log
rm 1.sh
awk '!/ORA|Errors/{a=$0}/ORA|Errors/{print a,$0}' alert.log >>dbcheck.log
echo ' '>>dbcheck.log
echo "分析：">>dbcheck.log
echo 
echo "操作系统参数" >>dbcheck.log
echo 
vmo -L maxperm% -L maxclient% >> dbcheck.log
echo 
echo "监听文件大小">>dbcheck.log
lsnrctl status|grep Log>2.log
export aa=`cat 2.log |cut -c 20-`
listenersize=${aa%%alert*}
ls -l $listenersize'trace'/*>>dbcheck.log
export bb=`cat 2.log |cut -c 20-`
ls -l $bb>>dbcheck.log
rm 2.log
echo ' '>>dbcheck.log
echo "分析：监听文件过大会影响系统连接，大于1G后建议清理">>dbcheck.log
}
fun_dochecksunos (){
echo "操作系统信息" >>dbcheck.log
echo "主机名称">>dbcheck.log
echo 
hostname >>dbcheck.log
echo 
echo "系统内核版本信息" >>dbcheck.log
echo 
uname -a >>dbcheck.log
echo 
echo "磁盘空间使用率" >>dbcheck.log
echo 
df -h >>dbcheck.log
echo 
echo "系统运行时间" >>dbcheck.log
echo 
uptime >>dbcheck.log
echo 
echo "实时磁盘io" >>dbcheck.log
iostat 2 4 >>dbcheck.log
echo 
echo "系统任务计划" >>dbcheck.log
echo 
crontab -l >>dbcheck.log
echo 
echo "CPU信息" >>dbcheck.log
echo 
vmstat 2 4 >>dbcheck.log
echo 
echo 
sqlplus "sys/123 as sysdba" <<EOF
set heading off;
set feedback off;
set termout off;
set pagesize 0;
set verify off;
set echo off;
set lines 1000
set termout off
spool 1.log
select 'tail -2000 '||a.value||'/'||'alert_'||b.value||'.log>alert.log' from v\$parameter a,v\$parameter b where a.name='background_dump_dest' and b.name='instance_name';
spool off
EOF
echo "ALERT 是否文件报错">>dbcheck.log
grep alert 1.log|grep -v SQL>1.sh
sh 1.sh
rm 1.log
rm 1.sh
awk '!/ORA|Errors/{a=$0}/ORA|Errors/{print a,$0}' alert.log >>dbcheck.log
echo ' '>>dbcheck.log
echo "分析：">>dbcheck.log
echo "监听文件大小">>dbcheck.log
lsnrctl status|grep Log>2.log
aa=`cat 2.log |cut -c 20-`
export aa
#listenersize=${aa%%alert*}
listenersize=`echo $aa |awk 'BEGIN{res=""; FS="/";}{ for(i=2;i<=NF-2;i++) res=(res"/"$i);} END{print res}'`
export listenersize
du -sh $listenersize'trace'/*>>dbcheck.log
bb=`cat 2.log |cut -c 20-`
export bb
du -sh $bb>>dbcheck.log
rm 2.log
echo ' '>>dbcheck.log
echo "分析：监听文件过大会影响系统连接，大于1G后建议清理">>dbcheck.log
}
fun_dounix2dos (){
if [ $PLATFORM = "Linux" ] 
then 
	sed -i 's/$/\r/g' checkdbsql.sql
else
#	tmpfile=$((RANDOM))
	tmpfile=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
	sed $'s/$/\r/' checkdbsql.sql> .${tmpfile}.sed
	mv .${tmpfile}.sed checkdbsql.sql
fi
}
fun_dounix2dosSolaris (){
	tmpfile=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
	sed $'s/$/\r/' checkdbsql.sql> .${tmpfile}.sed
	mv .${tmpfile}.sed checkdbsql.sql
}
fun_docheckdb (){
sqlplus "sys/123 as sysdba" <<EOF
set echo off
whenever sqlerror continue;
@checkdbsql.sql;
EOF
}

fun_docheckdboth (){
sqlplus "sys/123 as sysdba" <<EOF
set echo off
whenever sqlerror continue;
@dbtime.sql;
@awrrac.sql;
EOF
}

######################################################################
# 根据不同平台设定执行的命令
######################################################################
case $PLATFORM in
  Linux)
	#export SID=`ps -ef |grep "ora_smon" |grep -v "grep" |awk '{print $8}'|awk -F_ '{print $3}'`
	#export SID=`ps -ef |grep "ora_smon" |grep -v "grep" |awk '{print $8}'|awk -F_ '{print substr($0,10,length($0)-9)}'`
	export SID=`ps -eo ruser,pid,args |grep "ora_smon" |grep -v "grep" |awk '{print $3}'|awk -F_ '{print substr($0,10,length($0)-9)}'`
	export ASMSID=`ps -eo ruser,pid,args |grep "asm_smon" |grep -v "grep" |awk '{print $3}'|awk -F_ '{print substr($0,10,length($0)-9)}'`
	for OSID in $SID; do 
#	export $ORACLE_SID
	export ORACLE_SID=$OSID
	TSID=`echo "$OSID"| awk -F_ '{print substr($0,0,length($0)-1)}'`
	#	Get the Oracle Home Path
	ORACLEHOME=$ORACLE_HOME
	export ORACLE_HOME=`egrep -i ":Y|:N" /etc/oratab | grep -v "^#" | grep "$TSID" | grep -v "\*" | cut -d":" -f2 | sort | uniq`
	#if [  -z $ORACLE_HOME -a -z $ASMSID ]; then
	if [[ -z $ORACLE_HOME ]] && [[ -z $ASMSID ]] ;then
	export ORACLE_HOME=`ps -e -o args | grep tnslsnr | grep -v grep | head -1  | awk 'BEGIN{res=""; FS="/";}{ for(i=2;i<=NF-2;i++) res=(res"/"$i);} END{print res}'`
	elif [ -z $ORACLE_HOME ]; then
	#export ORACLE_HOME=`env |grep ORACLE_HOME|grep -v grep |awk -F= '{print $2}'`
	export ORACLE_HOME=$ORACLEHOME
	fi
	export PATH="$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:$PATH"
	echo $PATH
	export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
	export LANG=C
	date_format=`date +%Y%m%d`
	dir_name=${date_format}${ORACLE_SID}
	echo $dir_name
	export output_dir="${output_path}${dir_name}"
	mkdir -p ${output_dir}
	cd ${output_dir}
#	cp -av ${output_path}linuxdbcheck-v3.1.sh ${output_dir}
#	cp -av ${output_path}db-v3.1.sql ${output_dir}
#	sh linuxdbcheck-v3.1.sh
	fun_getcheckdbsql;
	fun_dounix2dos;
	fun_getdbtime;
	fun_getautoawr;
	fun_docheckdb;
	fun_dochecklinuxos;
	fun_docheckdboth;
	rm -rf checkdbsql.sql
	rm -rf dbtime.sql;
	rm -rf awrrac.sql;
	rm -rf my_awr.sql;
	pwd
	cd $output_path 
#	tar -cvf - ${dir_name} | gzip > ${dir_name}.tar.gz
	tar -cvf - ${dir_name} | gzip > ${dir_name}_${HOSTN}.tar.gz  
	done
    ;;
  AIX)
#	export SID=`ps -ef |grep "ora_smon" |grep -v "grep" |awk '{print $9}'|awk -F_ '{print $3}'`
	export SID=`ps -ef -o rssize,pcpu,args |grep "ora_smon" |grep -v "grep" |awk '{print $3}'|awk -F_ '{print $3}'`
	for OSID in $SID; do
#	export $ORACLE_SID
	export ORACLE_SID=$OSID
	export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
	export LANG=C
	date_format=`date +%Y%m%d`
	dir_name=${date_format}${ORACLE_SID}
	echo $dir_name
	output_dir="${output_path}${dir_name}"
	mkdir -p ${output_dir}
	cd ${output_dir}
#	cp -R ${output_path}/aixdbcheck-v3.1.sh ${output_dir}
#	cp -R ${output_path}/db-v3.1.sql ${output_dir}
#	sh aixdbcheck-v3.1.sh
	fun_getcheckdbsql;
	fun_dounix2dos;
	fun_getdbtime;
	fun_getautoawr;
	fun_docheckdb;
	fun_docheckaixos;
	fun_docheckdboth;
	rm -rf checkdbsql.sql
	rm -rf dbtime.sql;
	rm -rf awrrac.sql;
	rm -rf my_awr.sql;
	pwd
	cd $output_path 
#	tar -cvf - ${dir_name} | gzip > ${dir_name}.tar.gz
#	tar -cvf - ${dir_name} | gzip > ${dir_name}_${HOSTN}.tar.gz
	tar -cvf - ${dir_name} | bzip2 > ${dir_name}_${HOSTN}.tar.bz2
	done
    ;;
	HP-UX|HI-UX)
	export SID=`ps -eax |grep "ora_smon" |grep -v "grep" |awk '{print $4}'|awk -F_ '{print $3}'`
	for OSID in $SID; do
	export ORACLE_SID=$OSID
	export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
	export LANG=C
	date_format=`date +%Y%m%d`
	dir_name=${date_format}${ORACLE_SID}
	echo $dir_name
	output_dir="${output_path}${dir_name}"
	mkdir -p ${output_dir}
	cd ${output_dir}
#	cp -pr ${output_path}/hpdbcheck-v3.1.sh ${output_dir}
#	cp -pr ${output_path}/db-v3.1.sql ${output_dir}
#	sh hpdbcheck-v3.1.sh
	fun_getcheckdbsql;
	fun_dounix2dos;
	fun_getdbtime;
#	fun_getautoawr;
	fun_docheckdb;
	fun_docheckhpos;
	fun_docheckdboth;
	rm -rf checkdbsql.sql
	rm -rf dbtime.sql;
	rm -rf awrrac.sql;
	rm -rf my_awr.sql;
	pwd
	cd $output_path 
#	tar -cvf - ${dir_name} | gzip > ${dir_name}.tar.gz
	tar -cvf - ${dir_name} | gzip > ${dir_name}_${HOSTN}.tar.gz
	done
    ;;
  SunOS)
#	export SID=`ps -ef |grep "ora_smon" |grep -v "grep" |awk '{print $8}'|awk -F_ '{print $3}'`
	SID=`ps -ef -o ruser,pid,args |grep "ora_smon" |grep -v "grep" |awk '{print $3}'|awk -F_ '{print $3}'`
	export SID
	for OSID in $SID; do
	ORACLE_SID=$OSID
	NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
	LANG=C	
	export NLS_LANG LANG ORACLE_SID
	date_format=`date +%Y%m%d`
	dir_name=${date_format}${ORACLE_SID}
	echo $dir_name
	output_dir="${output_path}${dir_name}"
	mkdir -p ${output_dir}
	cd ${output_dir}
#	cp -pr ${output_path}/solarisdbcheck-v3.1 ${output_dir}
#	cp -pr ${output_path}/db-v3.1.sql ${output_dir}
#	sh solarisdbcheck-v3.1
	fun_getcheckdbsql;
	fun_dounix2dosSolaris;
	fun_getdbtime;
	fun_getautoawr;
	fun_docheckdb;
	fun_dochecksunos;
	fun_docheckdboth;
	rm -rf checkdbsql.sql
	rm -rf dbtime.sql;
	rm -rf awrrac.sql;
	rm -rf my_awr.sql;
	pwd
	cd $output_path 
#	tar -cvf - ${dir_name} | gzip > ${dir_name}.tar.gz
	tar -cvf - ${dir_name} | gzip > ${dir_name}_${HOSTN}.tar.gz
	done
    ;;
  OSF1)
    OSVERSION='uname -a'
    IOSTAT='iostat 3 3'
    VMSTAT='vmstat 3 3'
    TOP='top -d1'
    PSELF='ps -elf'
    MPSTAT='sar -S'  
#    MEMINFO='echo $PLATFORM'
    IPINFO='cat /etc/hosts'
    PSORA='ps -ef | grep ora_'
#    SWAPINFO='echo $PLATFORM'
    PROFILE='cat .profile'
    ;;
  Tru64)
    OSVERSION='/usr/sbin/sizer -v'
    IOSTAT='iostat 3 3'
    VMSTAT='vmstat 3 3'
    TOP='top -d1'
    PSELF='ps -elf'
    MPSTAT='sar -S'  
    MEMINFO='/bin/vmstat -P'
    IPINFO='cat /etc/hosts'
    PSORA='ps -ef | grep ora_'
    SWAPINFO='/sbin/swapon -s'
    PROFILE='cat .profile'
    ;;
esac

######################################################################
# cp -R ${output_path}/*.zip ${output_dir}
#
#unzip ${output_dir}/orachk.zip
#chown -R oracle.oinstall ${output_dir}/orachk*
#${output_dir}/orachk
#
#unzip ./orachk.zip
#chown -R oracle.oinstall ./orachk*
#./orachk
#
#sqlplus "sys/123 as sysdba" <<EOF
#@dba_snapshot_database_10g.sql
#EOF
#pwd
#
#sqlplus "sys/123 as sysdba" <<EOF
#@dba_snapshot_database_11g.sql
#EOF
#pwd
#
#cp -av ${output_path}linuxdbcheck-v3.1.sh ${output_dir}
#cp -av ${output_path}db-v3.1.sql ${output_dir}
#
#cd $output_path
#tar -cvf $dir_name.tar $dir_name
#gzip $dir_name.tar
#gzip $dir_name.tar
#du -sh $dir_name.tar.gz 
#pwd
#
#sh linuxdbcheck.sh
#
#cd ${output_path}
#tar -zcvf ${dir_name}.tar.gz ${dir_name}
#scp ${output_dir}.tar.gz weblogic@192.168.131.29:/home/weblogic/
#
#mkdir -p /home/oracle/boweston
#chown -R oracle.oinstall /home/oracle/boweston
#chmod -R a+x /home/oracle/boweston/*.sh
#				date_format=`date +%Y%m%d`		
#												
#				dir_name=${date_format}${ORACLE_SID}
#				echo $dir_name
#				output_path=/home/oracle/boweston/
#				output_dir="${output_path}${dir_name}"
#				cd ${output_path}										
#												
#				scp ${output_dir}.tar.gz weblogic@192.168.131.29:/home/weblogic/							
#												
#												
######################################################################

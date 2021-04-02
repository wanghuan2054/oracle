spool dbtime.csv
set echo off
set termout off
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
                               gv$instance             i
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
prompt ϵͳ����
prompt ���ݿ⼰ʵ������
set lines 1000
set pages 1000
select name,instance_name,status from v$database,gv$instance;
prompt ���ݿ�����汾
col banner for a70
SELECT * FROM V$VERSION;
prompt ���ݿ����
col name for a30
col value for a50
select NAME,VALUE from v$parameter where isdefault='FALSE'
union all
select parameter,value from v$nls_parameters where parameter like '%CHARACTERSET';
prompt �����ļ���Ϣ
col type for a10
col value for a30
show parameter control_file
prompt �����������ļ�����ӦΪ2������
prompt
prompt ��־�ļ���С��λ��
col gp# for 99
col th# for 99
col sz for 9999
col status for a8
col mmbrs for 999
col member for a50
select a.THREAD# th#,a.group# gp#,(bytes/1024/1024) sz,members mmbrs,a.STATUS,member from v$log a,v$logfile b where a.group#=b.group# order by 1,2;
prompt ��������־���ļ��������ӦΪÿ��2��
prompt
prompt ���ݿ���Դ����
col resource_name for a25
col current_utilization for 9999999999
col INITIAL_ALLOCATION for a18
col LIMIT_VALUE for a15
select resource_name,current_utilization,max_utilization,initial_allocation,limit_value 
from v$resource_limit;
prompt ������Ŀǰ������Դ��max value��Զ���ڳ�ʼ����ֵ��������ϵͳӦ��
prompt
prompt ���ݿ�Ĺ鵵ģʽ
archive log list

prompt ������ݿ�Ĵ洢�ռ�
prompt �����ļ��ܴ�С������
COLUMN hfile_size  NEW_VALUE _hfile_size NOPRINT
select a.used_size,b.file_size,b.hfile_size,b.ts_counts,b.file_counts from
(select '1' id ,round(sum(bytes)/1024/1024/1024,2) used_size from dba_segments) a,
(select '1' id,round(sum(bytes)/1024/1024/1024,2) file_size,trim(round(sum(bytes)/1024/1024/1024,2))||'GB' hfile_size,count(*) file_counts,count(distinct ts#) ts_counts from v$datafile) b
where a.id=b.id;
prompt ��������ǰ���ݿ������ļ���СΪ&_hfile_size
prompt
prompt ����ռ�״̬��Ϣ
col tablespace_name for a25
col extent_management for a15
col segment_space_management for a15
col CONTENTS for a10
select STATUS,tablespace_name,extent_management,segment_space_management,CONTENTS
from dba_tablespaces;
prompt ��������ռ����ʽ����
prompt
prompt ��������ļ�״̬
select count(*),status from v$datafile group by status;
prompt �����������ļ�״̬����
prompt
prompt ��ʱ��ռ�ʹ�����
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
          from v$temp_space_header h, v$temp_extent_pool p, dba_temp_files f
         where p.file_id(+) = h.file_id
           and p.tablespace_name(+) = h.tablespace_name
           and f.file_id = h.file_id
           and f.tablespace_name = h.tablespace_name
         group by h.tablespace_name) t;
prompt ��������ʱ��ռ�ʹ���������������ʱ��ʹ����Ϊ100%������������ʱ��ռ��С
prompt
prompt ���ݱ�ռ�ʹ�����
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
prompt ��������ռ�ʹ�������������ʹ���ʳ���85%���뿼�����ӱ�ռ��С
prompt
prompt ���ش�С��λ��
col name for a40
col used for 9999999
col total for 9999999
col tatio for 99.99
select name,round(space_limit/1024/1024/1024,2) total,round(space_used/1024/1024/1024,2) used,round(space_used/space_limit,2) ratio from v$recovery_file_dest;
prompt ���������ؿռ�������������ؿռ�ʹ���ʴ���70����������
prompt
prompt ���asm���̿ռ��ʹ�����
col name for a20
select name,total_mb/1024 total,free_mb/1024 free,state from v$asm_diskgroup;
prompt ��ѯ�ĸ���ռ��д洢�˱���������index
col tablespace_name for a40
SELECT DISTINCT (a.tablespace_name)
FROM dba_tables a, dba_indexes b
WHERE a.owner = b.table_owner
AND a.table_name = b.table_name
AND a.tablespace_name = b.tablespace_name
AND a.tablespace_name not in ( 'SYSTEM', 'SYSAUX' );
prompt ���������������ͬһ��ռ䣬����ֿ����
prompt
prompt ��ѯ��ϵͳ��ռ����ж������ͨ�û���������С
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
prompt �����־�л�Ƶ��
col thread# for 99
col firsttime for a20
select thread#, to_char(first_time, 'yyyy-mm-dd hh24') firsttime, count(sequence#)
  from v$log_history
 where first_time > sysdate - 1
   and first_time < sysdate + 1
 group by thread#, to_char(first_time, 'yyyy-mm-dd hh24')
 order by 1, 2;
prompt ��������־�л�������
prompt

prompt �鿴���ݿ�����������Ϣ
prompt �鿴�Ƿ�����Ĭ��180�������޸�����
COL PROFILE FOR A10
COL  RESOURCE_NAME FOR A20
COL LIMIT FOR A10
select PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT FROM DBA_PROFILES WHERE RESOURCE_NAME='PASSWORD_LIFE_TIME' AND LIMIT='180';
prompt �����������������������˵������Ĭ��180�������޸�����
prompt
prompt �鿴�Ƿ�����Ĭ���������10�������û�����
COL PROFILE FOR A10
COL  RESOURCE_NAME FOR A22
COL LIMIT FOR A10
select PROFILE,RESOURCE_NAME,RESOURCE_TYPE,LIMIT FROM DBA_PROFILES WHERE RESOURCE_NAME='FAILED_LOGIN_ATTEMPTS' AND LIMIT='10';
prompt �����������������������˵������Ĭ������10�ε�¼ʧ�������˻�����
prompt
prompt �鿴���ݿⲹ�����
col ACTION_TIME for a30
col action for a10
col namespace for a10
col version for a12
col BUNDLE_SERIES for a10
col COMMENTS for a20
select * from dba_registry_history order by 5;
prompt ��������ǰ���ݿ�û�а�װ���²�����
prompt
prompt �鿴���ݿ�������
show parameter audit
prompt
prompt ���������ΪĬ��DB����
prompt
prompt �鿴���ݿ���Ʊ��С
col segment_name for a20
select segment_name,sum(bytes)/1024/1024/1024 from dba_segments where segment_name='AUD$' group by segment_name;
prompt �����������Ʊ���󣬽��鶨��truncate
prompt
prompt �鿴���ݿ�RMAN����
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
          from v$backup_set a, v$backup_piece b
         where a.SET_COUNT = b.SET_COUNT
           and b.STATUS = 'A'
         order by 5 desc)
 where rownum < 30;
prompt ������
prompt
prompt ����2Gδ�����ı�
select owner, segment_name,bytes/1024/1024/1024 "G size" from dba_segments where bytes>2048000000 and segment_name not in(select object_name from dba_recyclebin) and segment_type='TABLE' and partition_name IS NULL;
prompt ���������ڴ���2Gδ�����Ķ������Ӱ�����ܣ����Ƿ���
prompt
prompt ��ѯ���ݿ�����Ч����
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
prompt ���������ݿ��д�����Ч���󣬽��鴦��
prompt
prompt ���ڱ��жȵļ��
col owner for a15
col type  for a10
col Degree for a10
select owner,'TABLE' type,degree,COUNT(*) from dba_tables where degree not in(1,0,'DEFAULT') and owner<>'SYS' group by owner,degree
union all
select owner,'INDEX', degree,count(*) from dba_indexes where degree not in(1,0,'DEFAULT') and owner<>'SYS' group by owner,degree;
prompt ���������������û�����ò���
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
      v$statname  n,
      v$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select
      value
    from
      v$parameter
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
      v$statname  n,
      v$sesstat  s
    where
      n.name in ('opened cursors current', 'session cursor cache count') and
      s.statistic# = n.statistic#
    group by
      s.sid
  ),
  ( select
      value
    from
      v$parameter
    where
      name = 'open_cursors'
  );
prompt ������ݿ��û�Ȩ��
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
prompt ���������û�ʹ��DBAȨ�ޣ�����һ���û����������dba��ɫ
prompt
prompt ������ݿ��ж����job
col log_user for a15
col last_date for a20
col next_date for a20
col what for a30
select log_user,to_char(last_date,'yyyy-mm-dd hh24:mi:ss') last_date,to_char(next_date,'yyyy-mm-dd hh24:mi:ss') next_date,what from dba_jobs;
prompt

prompt ���ݿ�����ָ��
prompt ��ǰϵͳ���������
select inst_id,count(*) from gv$session group by inst_id order by 1;
prompt �鿴AWR������Ϣ
col SNAP_INTERVAL for a20
col retention for a20
select * from dba_hist_wr_control;
prompt �鿴���ݿ�ͳ����ϢJOBִ��
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
         where job_name like 'ORA$AT_OS_OPT%' or job_name like 'GATHER_STATS_JOB%'
         order by log_date desc)
 where rownum < 10;
prompt �鿴����SQL�����Ϣ
col sql_text for a1000
select sql_text from gv$sql a,gv$session b where a.sql_id=b.sql_id and b.blocking_session is not null;
prompt �����������ػ�SQL�����ܻ������������
prompt
prompt �鿴���û�������ı���
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
prompt ����������������ʱ���û�������ᵼ�������ӱ�����Ӱ��ϵͳ���ܣ��������Щ������ֶ��������(5.5С��)
prompt
prompt ���ϵͳ����վ����
select count(*) from dba_recyclebin;
prompt ����������վ���ݹ����Ӱ�������ֵ���ѯ�����������������1000����������
prompt
prompt TOP 5 �ȴ��¼�
prompt
prompt buffer ������
prompt
prompt PGA��������
prompt
prompt ������
prompt SGA��Ϣ
prompt
prompt ������
spool off



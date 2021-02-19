# Oracle SQL笔记

目录： 

[toc]



## **常用SQL**

### **oracle版本信息**

```plsql
-- 查询版本信息
sqlplus -v

-- 安装包版本：
1、oracle解压包\client\install\oraparam.ini文件记录
2、oracle解压包\welcome.html文件可以查看
```



### **oracle登录及相关基准信息**

```sql
-- 当前数据库实例名查询 
SELECT INSTANCE_NAME FROM V$INSTANCE; 

-- 数据库名查询
SELECT NAME  FROM V$DATABASE; 

-- 当前数据库所有用户查询
SELECT * FROM DBA_USERS;   
SELECT * FROM ALL_USERS;   
SELECT * FROM USER_USERS;


-- 查询当前ORACLE_SID
echo $ORACLE_SID
-- 修改当前ORACLE_SID
export ORACLE_SID='mdwtst'
或者export ORACLE_SID='mestestdb'

-- sqlplus 登录 ， 不记录日志方式
sqlplus /nolog
-- SYSDBA角色登录，输入SYS密码
conn SYS as SYSDBA
-- 普通用户登录
conn edbadm/XXXX

-- SYSDBA角色登录
sqlplus / as sysdba
-- 切换到普通用户登录
conn edbadm/XXXXX

```

### **oracle服务启动停止**

```plsql
-- 关闭数据库实例
shutdown immediate
Oracle shutdown顺序 : 一般使用
    shutdown normal
    shutdown immediate
    shutdown transaction
    shutdown abort 

    shutdown normal:
        阻止任何用户建立新的连接；
        等待当前所有正在连接的用户主动断开连接；
        一旦所有用户断开连接，则关闭数据库；
        数据库下次启动时不需要任何实例的恢复过程。 
    shutdown immediate
        阻止任何用户建立新的连接，也不允许当前连接用户启动任何新的事务；
        回滚所有当前未提交的事务；
        终止所有用户的连接，直接关闭数据库；
        数据库下一次启动时不需要任何实例的恢复过程 
    shutdown transaction
        阻止所有用户建立新的连接，也不允许当前连接用户启动任何新的事务；
        等待用户回滚或提交任何当前未提交的事务，然后立即断开用户连接；
        关闭数据库；
        数据库下一次启动时不需要任何实例的恢复过程。 
    shutdown abort
        阻止任何用户建立新的连接，同时阻止当前连接用户开始任何新的事务。
        立即结束当前正在执行的SQL语句。
        任何未提交的事务不被回滚。
        中断所有的用户连接，立即关闭数据库。
        数据库实例重启后需要恢复。  
        
-- 启动状态由nomount(数据库未装载)——>mount(数据库完成装载)——>open(数据库打开)
 -- 启动数据库实例方法1（重大故障排除问题使用）
 startup nomount;
 --Oracle读参数文件(里面有控制文件目录)，打开实例，启动Oracle后台进程,给Oracle分配SGA。此时数据库状态为未装载。
可以在SQL*Plus会话中使用STARTUP NOMOUNT命令启动实例，这样启动仅有实例运行。如果以这种方式启动，将不读控制文件，而且数据文件也不打开。操作系统启动Oracle后台进程，并且给oracle分配SGA。事实上，只有实例本身在运行。
 startup mount;
 --Oracle 打开并读取控制文件(里面有数据文件和日志文件的目录)，获取数据文件和重做日志文件的名称和位置。此时数据库完成装载。
在启动过程中，oracle把实例与数据库关联。Oracle打开并读取控制文件，获取数据文件和重做日志文件的名称和位置。在进行诸如全数据库恢复、更改数据库的归档日志模式或重命名数据文件这一类的活动时，通常需要以安装模式启动数据库。请注意，这三种操作都要求oracle访问数据文件，但不提供对文件的用户操作。
 alter database open;
 --启动数据库实例方法2 （常用）
 startup;  
 -- open 参数可有可无
Oracle打开数据文件和重做日志文件，才能对外(所有有效用户)提供数据库服务。
启动过程的最后一步是打开数据库。当数据库以打开模式启动时，所有有效用户可以连接到数据库，执行数据库操作。在此步骤之前，一般用户根本就不能连接到数据库。通过发布下面的命令让数据库出于打开模式。
 
-- 查看服务器的lsnrctl服务
lsnrctl status  
--关闭监听
lsnrctl stop listener;
--开启监听
lsnrctl  start  listener  


-- 不常用
dbstart  --开启数据库连接
dbshut --关闭数据库链接；
```

### **hpux操作系统的关机与重启命令**

```shell
# 关机 , halt ， 0代表0s后，即立即关机
shutdown -hy 0

# 强制重启 ，  reboot ， 0代表0s后，即立即重启
shutdown -ry 0 

# shutdown 常用搭配参数
# 惯用的关机指令： shutdown
-t sec ： -t 后面加秒数，过几秒后关机
-k ： 不要真的关机，只是发送警告讯息出去
-r ： reboot , 在将系统的服务停掉之后就重新开机(常用)
-h ： halt关机停机 , 将系统的服务停掉后，立即关机。(常用)
-n ： 不经过init 程序，直接以shutdown 的功能来关机
-f ： 关机并开机之后，强制略过fsck 的磁盘检查
-F ： 系统重新开机之后，强制进行fsck 的磁盘检查
-c ： 取消已经在进行的shutdown 指令内容
-y : 操作过程中的所有查询强制回答"是"。 
```



### **配置参数查询**

```sql
-- 查询db block size
SELECT * FROM V$PARAMETER T WHERE T."NAME" = 'db_block_size';
```

### **系统进程**

```sql
-- 查看系统进程
SELECT SPID, PID, USERNAME, PROGRAM, PNAME, BACKGROUND
  FROM V$PROCESS
 WHERE BACKGROUND = '1';
```

### SQLPLUS set详解

```sql
-- 输出每页行数，缺省为24,为了避免分页，可设定为0。
SQL> set pagesize 0;    
或者
SQL> set pages 0;  
-- 查看当前pagesize
SQL> show pages;
pagesize 25

-- 输出一行字符个数，缺省为80
SQL> set linesize 80;     
或者
SQL> set lines 0;  
-- 查看当前linesize
SQL>  show lines;
linesize 500
-- linesize的大小必须小于命令行可显示的大小，超过命令行的限制了，linesize当然不起作用

SQL> set timing on;          //设置显示“已用时间：XXXX”

SQL> set autotrace on-;    //设置允许对执行的sql进行分析

SQL> set trimout on; //去除标准输出每行的拖尾空格，缺省为off

SQL> set trimspool on; //去除重定向（spool）输出每行的拖尾空格，缺省为off

SQL> set echo on               //设置运行命令是是否显示语句

SQL> set echo off; //显示start启动的脚本中的每个sql命令，缺省为on

SQL> set feedback on;       //设置显示“已选择XX行”

SQL> set feedback off;      //回显本次sql命令处理的记录条数，缺省为on

SQL> set colsep' '; //输出分隔符

SQL> set heading off;    //输出域标题，缺省为on

SQL> set numwidth 12;     //输出number类型域长度，缺省为10

SQL> set termout off;    //显示脚本中的命令的执行结果，缺省为on

SQL> set serveroutput on;  //设置允许显示输出类似dbms_output

SQL> set verify off                     //可以关闭和打开提示确认信息old 1和new 1的显示. 

/*
  查看对应的参数，可使用 show param_name ;
*/

-- 设置列宽 ， col 和 column方式都可以
-- col machine format a12  或 column WINDOW_NAME format a25;
-- col username format a12 或 column username format a25;

```

### **表**

#### 获取表定义

```sql
--获取所有表的表定义，需要挨个表进行执行收集，可采用脚本多行一次性方式批量执行。

SELECT DBMS_METADATA.GET_DDL('TABLE', 'LOTHISTORY', 'EDBADM') FROM DUAL;
```

### **表空间**

#### 表空间名称查询

```sql
-- 按照表名查询表空间
SELECT *
FROM DBA_TABLES T
WHERE T.TABLE_NAME = 'EDS_UNIT_RUN_HIST';

-- 如果TABLESPACE_NAME为空，则为默认表空间
SELECT USERNAME, DEFAULT_TABLESPACE, TEMPORARY_TABLESPACE
FROM DBA_USERS
WHERE USERNAME = 'EDBADM';
```

####  查询所有临时表名字和空间大小 

```sql
    SELECT D.TABLESPACE_NAME,
           SPACE "SUM_SPACE(M)",
           BLOCKS SUM_BLOCKS,
           USED_SPACE "USED_SPACE(M)",
           ROUND(NVL(USED_SPACE, 0) / SPACE * 100, 2) "USED_RATE(%)",
           NVL(FREE_SPACE, 0) "FREE_SPACE(M)"
      FROM (SELECT TABLESPACE_NAME,
                   ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
                   SUM(BLOCKS) BLOCKS
              FROM DBA_TEMP_FILES
             GROUP BY TABLESPACE_NAME) D,
           (SELECT TABLESPACE_NAME,
                   ROUND(SUM(BYTES_USED) / (1024 * 1024), 2) USED_SPACE,
                   ROUND(SUM(BYTES_FREE) / (1024 * 1024), 2) FREE_SPACE
              FROM V$TEMP_SPACE_HEADER
             GROUP BY TABLESPACE_NAME) F
     WHERE D.TABLESPACE_NAME = F.TABLESPACE_NAME(+);

```

####  查询临时表名对应的使用情况 

```sql
SELECT D.TABLESPACE_NAME,
       SPACE "SUM_SPACE(M)",
       BLOCKS "SUM_BLOCKS",
       USED_SPACE "USED_SPACE(M)",
       ROUND(NVL(USED_SPACE, 0) / SPACE * 100, 2) "USED_RATE(%)",
       SPACE - USED_SPACE "FREE_SPACE(M)"
  FROM (SELECT TABLESPACE_NAME,
               ROUND(SUM(BYTES) / (1024 * 1024), 2) SPACE,
               SUM(BLOCKS) BLOCKS
          FROM DBA_TEMP_FILES
         GROUP BY TABLESPACE_NAME) D,
       (SELECT TABLESPACE,
               ROUND(SUM(BLOCKS * 8192) / (1024 * 1024), 2) USED_SPACE
          FROM V$SORT_USAGE
         GROUP BY TABLESPACE) F
 WHERE D.TABLESPACE_NAME = F.TABLESPACE(+)
   AND D.TABLESPACE_NAME IN ('EDASYS_TEMP01', 'EDASYS_TEMP02')

```

####  **查询临时表空间状态** 

```sql
-- 查询临时表空间状态
 SELECT TABLESPACE_NAME,
        FILE_NAME,
        BYTES / 1024 / 1024 FILE_SIZE,
        AUTOEXTENSIBLE
   FROM DBA_TEMP_FILES;
   
-- 查询默认临时表空间：   
   
   SELECT *
  FROM DATABASE_PROPERTIES
 WHERE PROPERTY_NAME = 'DEFAULT_TEMP_TABLESPACE';

```



#### **表空间Rank**

```sql
方法1： 查询DBA_DATA_FILES , DBA_FREE_SPACE 
SELECT TOTAL.TABLESPACE_NAME,
       ROUND(TOTAL.GB, 1) AS TOTAL_GB,
       ROUND(TOTAL.GB - FREE.GB, 1) AS USED_GB,
       ROUND(FREE.GB, 1) AS FREE_GB,
       ROUND((1 - FREE.GB / TOTAL.GB) * 100, 1) AS USED_PCT,
       ROUND((TOTAL.GB - FREE.GB) / MAX.GB * 100, 1) AS PCTMAX,
       ROUND(MAX.GB - (TOTAL.GB - FREE.GB)) AS MAXFREE,
       ROUND(MAX.GB, 1) AS MAX_GB
  FROM (SELECT TABLESPACE_NAME, SUM(BYTES) / 1024 / 1024 / 1024 AS GB
          FROM DBA_FREE_SPACE
         GROUP BY TABLESPACE_NAME) FREE,
       (SELECT TABLESPACE_NAME, SUM(BYTES) / 1024 / 1024 / 1024 AS GB
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) TOTAL,
       (SELECT TABLESPACE_NAME,
               SUM(DECODE(AUTOEXTENSIBLE, 'YES', MAXBYTES, 'NO', BYTES)) / 1024 / 1024 / 1024 AS GB
          FROM DBA_DATA_FILES
         GROUP BY TABLESPACE_NAME) MAX
 WHERE FREE.TABLESPACE_NAME = TOTAL.TABLESPACE_NAME
   AND TOTAL.TABLESPACE_NAME = MAX.TABLESPACE_NAME
   AND NOT EXISTS (SELECT TABLESPACE_NAME
          FROM DBA_TABLESPACES DT
         WHERE DT.TABLESPACE_NAME = TOTAL.TABLESPACE_NAME
           AND CONTENTS = 'UNDO')
 ORDER BY 6 DESC;


方法2： SYS用户 ， 查询SM$TS_AVAIL（DBA_DATA_FILES） , SYS.SM$TS_USED（DBA_SEGMENTS） , SYS.SM$TS_FREE（DBA_FREE_SPACE） 3张视图
-- 查询出表空间总大小、已使用、空闲大小、使用率、空闲率
SELECT A.TABLESPACE_NAME,
       ROUND(A.BYTES / 1024.0 / 1024.0 / 1024.0, 4) "total(G)",
       ROUND(B.BYTES / 1024.0 / 1024.0 / 1024.0, 4) "used(G)",
       ROUND(C.BYTES / 1024.0 / 1024.0 / 1024.0, 4) "free(G)",
       ROUND((B.BYTES * 100) / A.BYTES, 4) || '%' "USED ",
       ROUND((C.BYTES * 100) / A.BYTES, 4) || '%' "FREE "
  FROM SYS.SM$TS_AVAIL A, SYS.SM$TS_USED B, SYS.SM$TS_FREE C
 WHERE A.TABLESPACE_NAME = B.TABLESPACE_NAME
   AND A.TABLESPACE_NAME = C.TABLESPACE_NAME
 ORDER BY 2 DESC; 
```



#### **根据表空间名字查询dbf及Block ID**

```sql
SELECT T.* FROM DBA_DATA_FILES T WHERE T.TABLESPACE_NAME = 'EDS_COM_TBS'

--查询表空间下数据文件及是否自动扩容
SELECT FILE_NAME ,AUTOEXTENSIBLE FROM DBA_DATA_FILES WHERE TABLESPACE_NAME='EDS_EQP_TBS';
```

#### 根据表空间查询子表空间占用

```plsql
-- EDS_EQP_TBS表空间下存放表数据、索引数据、UNDO、LOB等数据 
SELECT A.SEGMENT_NAME,
       A.SEGMENT_TYPE,
       SUM(A.BYTES) / 1024 / 1024 / 1024 AS "TOTAL(G)"
  FROM DBA_SEGMENTS A
 WHERE A.OWNER = 'EDBADM'
   AND A.TABLESPACE_NAME = 'EDS_EQP_TBS'
   AND a.segment_name = 'EDS_BSALARM_HIST'
   AND A.SEGMENT_TYPE LIKE '%TABLE%'
 GROUP BY A.SEGMENT_NAME, A.SEGMENT_TYPE
 ORDER BY 3 DESC;
```

#### 表空间扩容（增加数据文件）

```SQL
-- 对空间不足表空间进行扩容：
-- 方法一：
ALTER TABLESPACE EDS_OGG_TBS ADD DATAFILE '+MDWDBDATA/mdwdb/eds_edc_tbs114.dbf' SIZE 10G AUTOEXTEND ON NEXT 100M MAXSIZE UNLIMITED;
-- 方法二 数据库自己管理文件方式
ALTER TABLESPACE EDS_OGG_TBS ADD DATAFILE '+MDWDBDATA' SIZE 20G AUTOEXTEND ON; 
```

#### 查看分区表统计信息

```plsql
-- 查看分区表的统计信息，DBA_TAB_PARTITIONS 和 USER_TAB_PARTITIONS 都可查询 LAST_ANALYZED
SELECT TABLE_NAME,
       PARTITION_NAME,
       TABLESPACE_NAME,
       A.BLOCKS * 8 / 1024 / 1024 GB,
       A.NUM_ROWS,
       A.LAST_ANALYZED
  FROM DBA_TAB_PARTITIONS A
 WHERE TABLE_NAME = 'PRODUCTHISTORY' 
 ORDER BY A.PARTITION_NAME DESC ;

-- 使用某一特定用户登录时候，使用USER开头视图
SELECT TABLE_NAME,
       PARTITION_NAME,
       TABLESPACE_NAME,
       A.BLOCKS * 8 / 1024 / 1024 GB,
       A.NUM_ROWS,
       A.LAST_ANALYZED
  FROM USER_TAB_PARTITIONS A
 WHERE TABLE_NAME = 'EDS_UNIT_HIST' 
 ORDER BY A.PARTITION_NAME DESC ;

 
 -- 查看分区索引的统计信息更新时间
 SELECT A.INDEX_OWNER,
       A.INDEX_NAME,
       A.TABLESPACE_NAME,
       A.PARTITION_NAME,
       A.LAST_ANALYZED
  FROM DBA_IND_PARTITIONS A
 WHERE A.INDEX_OWNER = 'EDBADM'
   AND A.PARTITION_NAME = 'PD20210110'
   AND A.TABLESPACE_NAME = 'EDS_MAT_TBS'
 ORDER BY A.LAST_ANALYZED DESC;
 
-- 查看具体索引的统计信息更新时间
SELECT A.INDEX_OWNER,
       A.INDEX_NAME,
       A.TABLESPACE_NAME,
       A.PARTITION_NAME,
       A.LAST_ANALYZED
  FROM DBA_IND_PARTITIONS A
 WHERE A.INDEX_OWNER = 'P1MESADM'
   AND A.INDEX_NAME = 'IDX_PRODUCTHISTORY_01'
   AND A.partition_name = 'PW210104'
 ORDER BY A.LAST_ANALYZED DESC;
 
 -- DBA_TAB_PARTITIONS
 SELECT * FROM DBA_TAB_PARTITIONS WHERE TABLE_NAME='LOTHISTORY';
 
 
 -- 使用EXTENT 区下包含的block Nums
 SELECT SEGMENT_NAME, EXTENT_ID, FILE_ID, BLOCK_ID, BLOCKS
  FROM DBA_EXTENTS
 WHERE OWNER = 'EDBADM'
   AND SEGMENT_NAME = 'EDS_GLASS_HIST';
   
 -- 使用EXTENT 区查询表的大小
SELECT SUM(BLOCKS) * 8 / 1024 / 1024 / 1024 AS "SIZE(T)"
  FROM DBA_EXTENTS
 WHERE OWNER = 'EDBADM'
   AND SEGMENT_NAME = 'EDS_GLASS_HIST';
```

#### 查看非分区表统计信息

```SQL
-- 使用DBA_TABLES 也可以查询某个表的统计信息
SELECT T.TABLE_NAME, T.NUM_ROWS, T.BLOCKS, T.LAST_ANALYZED
  FROM USER_TABLES T
 WHERE TABLE_NAME IN ('LOT');
 
-- 查看某个表上索引的统计信息
SELECT TABLE_NAME,
       INDEX_NAME,
       T.BLEVEL,
       T.NUM_ROWS,
       T.LEAF_BLOCKS,
       T.LAST_ANALYZED
  FROM USER_INDEXES T
 WHERE TABLE_NAME IN ('LOT');

```

#### 查看自动收集统计信息功能

```sql
-- 在Oracle的11g版本中提供了统计数据自动收集的功能 , 默认是启用这个功能
-- 查看自动收集统计信息的任务及状态
SQL> select client_name,status from dba_autotask_client;

CLIENT_NAME                                                      STATUS
---------------------------------------------------------------- --------
auto optimizer stats collection                                  ENABLED
auto space advisor                                               ENABLED
sql tuning advisor                                               ENABLED
-- "auto optimizer stats collection"是自动收集统计信息的任务名称，状态目前是启用状态。

-- 禁止自动收集统计信息的任务
SQL> exec DBMS_AUTO_TASK_ADMIN.DISABLE(client_name => 'auto optimizer stats collection',operation => NULL,window_name => NULL);
SQL>  select client_name,status from dba_autotask_client;

CLIENT_NAME                                                      STATUS
---------------------------------------------------------------- --------
auto optimizer stats collection                                  DISABLED
auto space advisor                                               ENABLED
sql tuning advisor                                               ENABLED

-- 启用自动收集统计信息的任务
SQL> exec DBMS_AUTO_TASK_ADMIN.ENABLE(client_name => 'auto optimizer stats collection',operation => NULL,window_name => NULL);
SQL> select client_name,status from dba_autotask_client;

CLIENT_NAME                                                      STATUS
---------------------------------------------------------------- --------
auto optimizer stats collection                                  ENABLED
auto space advisor                                               ENABLED
sql tuning advisor                                               ENABLED

--修改为表级增量统计，
exec dbms_stats.set_table_prefs('EDBADM','ODS_PRODUCTHISTORY_LOC','INCREMENTAL','TRUE');

--查看表级增量统计修改结果
SELECT DBMS_STATS.GET_PREFS(PNAME => 'INCREMENTAL',OWNNAME => 'EDBADM',TABNAME=> 'EDS_LOT') AS IS_INCRESTATS FROM DUAL;

-- 获得当前自动收集统计信息的执行时间 
/*
   WINDOW_NAME：任务名
   REPEAT_INTERVAL：任务重复间隔时间
   DURATION：持续时间
*/
SELECT T1.WINDOW_NAME, T1.REPEAT_INTERVAL, T1.DURATION
  FROM DBA_SCHEDULER_WINDOWS T1, DBA_SCHEDULER_WINGROUP_MEMBERS T2
 WHERE T1.WINDOW_NAME = T2.WINDOW_NAME
   AND T2.WINDOW_GROUP_NAME IN
       ('MAINTENANCE_WINDOW_GROUP', 'BSLN_MAINTAIN_STATS_SCHED');

-- 修改统计信息收集的时间频次
1.停止任务：
SQL> BEGIN
  2    DBMS_SCHEDULER.DISABLE(
  3    name => '"SYS"."FRIDAY_WINDOW"',
  4    force => TRUE);
  5  END;
  6  /

PL/SQL 过程已成功完成。
2.修改任务的持续时间，单位是分钟：
SQL> BEGIN
  2    DBMS_SCHEDULER.SET_ATTRIBUTE(
  3    name => '"SYS"."FRIDAY_WINDOW"',
  4    attribute => 'DURATION',
  5    value => numtodsinterval(180,'minute'));
  6  END;  
  7  /

PL/SQL 过程已成功完成。
3.开始执行时间，BYHOUR=2，表示2点开始执行：
SQL> BEGIN
  2    DBMS_SCHEDULER.SET_ATTRIBUTE(
  3    name => '"SYS"."FRIDAY_WINDOW"',
  4    attribute => 'REPEAT_INTERVAL',
  5    value => 'FREQ=WEEKLY;BYDAY=MON;BYHOUR=2;BYMINUTE=0;BYSECOND=0');
  6  END;
  7  /

PL/SQL 过程已成功完成。
4.开启任务：
SQL> BEGIN
  2    DBMS_SCHEDULER.ENABLE(
  3    name => '"SYS"."FRIDAY_WINDOW"');
  4  END;
  5  /

PL/SQL 过程已成功完成。
5.查看修改后的情况：
SQL> select t1.window_name,t1.repeat_interval,t1.duration from dba_scheduler_windows t1,dba_scheduler_wingroup_members t2
  2  where t1.window_name=t2.window_name and t2.window_group_name in ('MAINTENANCE_WINDOW_GROUP','BSLN_MAINTAIN_STATS_SCHED');
 
WINDOW_NAME                    REPEAT_INTERVAL                                                                  DURATION
------------------------------ -------------------------------------------------------------------------------- -------------------------------------------------------------------------------
WEDNESDAY_WINDOW               freq=daily;byday=WED;byhour=22;byminute=0; bysecond=0                            +000 04:00:00
FRIDAY_WINDOW                  FREQ=WEEKLY;BYDAY=MON;BYHOUR=2;BYMINUTE=0;BYSECOND=0                             +000 03:00:00
SATURDAY_WINDOW                freq=daily;byday=SAT;byhour=6;byminute=0; bysecond=0                             +000 20:00:00
THURSDAY_WINDOW                freq=daily;byday=THU;byhour=22;byminute=0; bysecond=0                            +000 04:00:00
TUESDAY_WINDOW                 freq=daily;byday=TUE;byhour=22;byminute=0; bysecond=0                            +000 04:00:00
SUNDAY_WINDOW                  freq=daily;byday=SUN;byhour=6;byminute=0; bysecond=0                             +000 20:00:00
MONDAY_WINDOW                  freq=daily;byday=MON;byhour=22;byminute=0; bysecond=0                            +000 04:00:00
 
7 rows selected
```

#### 查看某张表统计信息是否过期

```sql
--  过期状态查看 STALE_STATS = YES为统计信息失效，NO为正常
SELECT T.OWNER,
       T.TABLE_NAME,
       T.PARTITION_NAME,
       T.SUBPARTITION_NAME,
       T.OBJECT_TYPE,
       T.NUM_ROWS,
       T.SAMPLE_SIZE,
       T.LAST_ANALYZED,
       T.GLOBAL_STATS,
       T.USER_STATS,
       T.STALE_STATS
  FROM ALL_TAB_STATISTICS T
 WHERE T.OWNER = 'P1MESADM'
   AND T.TABLE_NAME = 'BSGLASSOUTUNITORSUBUNIT'
   AND T.STALE_STATS = 'YES'
   AND T.LAST_ANALYZED IS NOT NULL
 ORDER BY T.PARTITION_NAME;
 
 --过期原因查看 , 截止上次分析时间后产生的增删改等操作(还有TRUNCATED和DROP_SEGMENTS操作)
 SELECT TABLE_OWNER,
       PARTITION_NAME,
       SUBPARTITION_NAME,
       TABLE_NAME,
       INSERTS,
       UPDATES,
       DELETES,
       TIMESTAMP,
       TRUNCATED,
       DROP_SEGMENTS
  FROM ALL_TAB_MODIFICATIONS
 WHERE TABLE_OWNER = 'P1MESADM'
   AND TABLE_NAME = 'PRODUCT';
```

#### 查看SQL中用到的表统计信息是否失效

```sql
-- 根据SQL_ID查询表统计信息是否过期或者失效
SELECT A.OWNER,
       A.TABLE_NAME,
       OBJECT_TYPE,
       STALE_STATS,
       LAST_ANALYZED,
       PARTITION_NAME
  FROM DBA_TAB_STATISTICS A
 WHERE (A.STALE_STATS = 'YES' OR A.LAST_ANALYZED IS NULL)
   AND A.OWNER = 'EDBADM'
   AND A.TABLE_NAME = 'EDS_GLASS_HIST'
   AND (A.OWNER, A.TABLE_NAME) IN
       (SELECT /*+ no_unnest */
         SP.OBJECT_OWNER, SP.OBJECT_NAME
          FROM V$SQL_PLAN SP
         WHERE SP.SQL_ID = 'fdgvyqyj9fdah'
           AND SP.CHILD_NUMBER = 0);
```



#### 查看某张表的统计信息

```sql
-- 查询某表是否开启了增量统计功能
SELECT DBMS_STATS.GET_PREFS(PNAME => 'INCREMENTAL',OWNNAME => 'EDBADM',TABNAME=> 'LOT') AS IS_INCRESTATS FROM DUAL;

-- 方式1（推荐） ， 根据用户表查询表最后统计时间 
SELECT T.OWNER,
       T.TABLE_NAME,
       T.PARTITION_NAME,
       T.SUBPARTITION_NAME,
       T.OBJECT_TYPE,
       T.NUM_ROWS,
       T.SAMPLE_SIZE,
       T.LAST_ANALYZED,
       T.GLOBAL_STATS,
       T.USER_STATS,
       T.STALE_STATS
  FROM ALL_TAB_STATISTICS T
 WHERE T.OWNER = 'EDBADM'
   AND T.TABLE_NAME = 'LOT'
   AND T.LAST_ANALYZED IS NOT NULL
 ORDER BY T.LAST_ANALYZED DESC;


-- 方式2  根据ALL_TAB_STATISTICS统计信息查询表最后统计信息
SELECT TABLE_NAME,NUM_ROWS,BLOCKS,LAST_ANALYZED FROM USER_TABLES WHERE TABLE_NAME='LOT';
```

#### 查看某张表上索引统计信息

```mysql
-- 查看某个表上索引的统计信息
SELECT TABLE_NAME,
       INDEX_NAME,
       T.BLEVEL,
       T.NUM_ROWS,
       T.LEAF_BLOCKS,
       T.LAST_ANALYZED
  FROM USER_INDEXES T
 WHERE TABLE_NAME IN ('EDS_ENERGY_EHS');
```



#### 手动收集统计信息

##### 按照表收集统计信息

```sql
-- 方法1（推荐）  degree 指定收集并行度
-- gather_table_stats:用于收集目标表、列和索引的统计信息
--  具体参数字段参考 https://docs.oracle.com/en/database/oracle/oracle-database/19/arpls/DBMS_STATS.html#GUID-CA6A56B9-0540-45E9-B1D7-D78769B7714C
-- 参考文档2 https://www.modb.pro/db/26653
begin
 dbms_stats.gather_table_stats(ownname=>'EDBADM',
                               tabname=>'LOTHISTORY',
                               estimate_percent=>100,
                               method_opt=>'for all columns size repeat',
                               no_invalidate=>false,
                               degree=>4,
                               cascade=>true);
 end;
 /
 
 --方法2  SQL CMD中执行存储过程， 使用用户名和表名
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('FGMSADM','MMSLOGHISTORY');

/*
需要注意选择的地方是：
estimate_percent：
<1GB 建议采样比100%
1GB～5GB 建议采样比50%
>5GB 建议采样比30%
（朋友们可以自己尝试用存储过程去判断表大小，自定义收集统计信息脚本）
degree：
根据服务器的资源，和业务负载来指定
method_opt：
系统刚上线使用auto，业务系统稳定后使用repeat。
*/
```



##### 按照分区收集统计信息

```sql
-- 收集分区表的某个分区统计信息
BEGIN
  DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;
    DBMS_STATS.GATHER_TABLE_STATS(OWNNAME          => 'EDBADM',
                                  TABNAME          => 'LOTHISTORY',
                                  PARTNAME         => 'LOTHISTORY_202007',
                                  ESTIMATE_PERCENT => 100,
                                  METHOD_OPT       => 'for all columns size repeat',
                                  DEGREE           => 4,
                                  GRANULARITY      => 'ALL',
                                  CASCADE          => TRUE);
END;
```

按照索引收集统计信息

```sql
-- 收集索引统计信息 ， gather_index_stats:用于收集指定统计信息
exec dbms_stats.gather_index_stats(ownname => 'USER',indname => 'IDX_OBJECT_ID',estimate_percent => '10',degree => '4');  
-- 收集表和索引统计信息 
exec dbms_stats.gather_table_stats(ownname => 'USER',tabname => 'TEST',estimate_percent => 10,method_opt=> 'for all indexed columns',cascade=>TRUE);  
```

按照用户收集统计信息

```sql
-- 收集某个用户的统计信息 ， 用于收集指定schema下的所有对象统计信
exec dbms_stats.gather_schema_stats(ownname=>'CS',estimate_percent=>10,degree=>8,cascade=>true,granularity=>'ALL');  
```

按照数据库收集统计信息

```sql
-- 收集整个数据库的统计信息
exec dbms_stats.gather_database_stats(estimate_percent=>10,degree=>8,cascade=>true,granularity=>'ALL');  
```

#### 分区删除

##### 重点

```sql
1. truncate分区
alter table part_table truncate partition p1;	

    全局索引：失效
    分区索引：正常、没影响

如何避免失效：
alter table part_table truncate partition p1 update global indexes;	

2. drop分区
SQL操作命令：

alter table part_table drop partition p1;	

    全局索引：失效
    分区索引：正常、没影响

如何避免失效：

alter table part_table drop partition p1 update global indexes;	 

3. add分区
SQL操作命令：

alter table part_table add partition p5 values less than(37210);	 	

    全局索引：正常、没影响
    分区索引：正常、没影响

4. split分区
SQL操作命令：

alter table part_table split partition p_max at(10086)  into (partition p6,partition p_max); 	 	

    全局索引：失效
    分区索引：如果max区中已经有记录了，这个时候split就会导致有记录的新增分区的局部索引失效。

如何避免失效：

    针对全局索引：

alter table part_table split partition p_max at (10086) into (partition p6,partition p_max) update global indexes;	

    针对分区索引，需要重建局部索引：

alter index idx_part_split_col1 rebuild; 
	 

5. exchange分区
SQL操作命令：

alter table part_table exchange partition p1 with table normal_table including indexes;	 	

    全局索引：失效
    分区索引：正常、没影响

如何避免失效：

alter table part_table exchange partition p1 with table normal_table including indexes update global indexes;	 	 


```

 ![image.png](https://obs-emcsapp-public.obs.cn-north-4.myhwclouds.com:443/image%2Feditor%2Feb93882d-ab2e-4ff6-b01d-4eb8378c3e5c.png) 

##### 正常删除

```sql
/*删除周分区*/
alter table ALARMINTERFACETOPMS drop partition PM2005;
alter table BSGLASSOUTUNITORSUBUNIT drop partition PW200502;
alter table BSGLASSOUTUNITORSUBUNIT drop partition PW200503;
alter table BSGLASSOUTUNITORSUBUNIT drop partition PW200504;

/*删除月分区*/
alter table ALARMINTERFACETOPMS drop partition PM1902;
```

##### 调用存储过程删除

```sql
/*
  PVVI_TABLE_NAME ： 表名
  PVVI_START_PARTITION_NAME ： 开始分区名
  PVVI_END_PARTITION_NAME：结束分区名
*/
-- 调用方式1 
CALL DROP_PARTITION_BY_TABLE('CDS_MATERIALPACKING','PM201901','PM201905')

-- 调用方式2 
begin
  -- Call the procedure
  drop_partition_by_table(pvvi_table_name => 'CDS_MATERIALPACKING',
                          pvvi_start_partition_name => 'PM201901',
                          pvvi_end_partition_name => 'PM201905');
end;

-- DROP_PARTITION_BY_TABLE 源码
CREATE OR REPLACE PROCEDURE DROP_PARTITION_BY_TABLE(PVVI_TABLE_NAME           IN VARCHAR2,
                                                    PVVI_START_PARTITION_NAME IN VARCHAR2,
                                                    PVVI_END_PARTITION_NAME   IN VARCHAR2) AS

  --=================================================================================
  --OBJECT NAME : DROP_PARTITION_BY_TABLE
  --OBJECT TYPE : STORED PROCEDURE
  --DESCRIPTION : DROP PARTITION BY TABLE
  -- PVVI_TABLE_NAME  传入的表名
  -- PVVI_START_PARTITION_NAME  传入要删除的开始分区名
  -- PVVI_END_PARTITION_NAME    传入要删除的结束分区名
  -- PVVO_RETURN_VALUE 返回值
  --=================================================================================
  --
  --=================================================================================
  --YYYY-MM-DD      DESCRIPTOR       DESCRIPTION
  --2021-01-21      WANGHUAN        通过表名、删除介于开始分区和结束分区名之间的分区数据（包含开始结束分区数据）
  --=================================================================================
  --
  --=================================================================================
  --                               VARIALBLE DECLARATION
  --=================================================================================
  LVV_SQLEXEC VARCHAR2(200);
  LVV_TABLE_NAME VARCHAR2(100);
  LVV_START_PARTITION_NAME VARCHAR2(100);
  LVV_END_PARTITION_NAME VARCHAR2(100);
  V_CHOOSE_PARTITION_NAME VARCHAR2(100);

  -- 表分区的游标定义 , 选择出介于PVVI_START_PARTITION_NAME 和 PVVI_END_PARTITION_NAME之间的所有分区名
  CURSOR PARTITION_CURSOR IS
    SELECT PARTITION_NAME
           --,TABLE_NAME,
           --TABLESPACE_NAME,
           --A.BLOCKS * 8 / 1024 / 1024 GB,
           --A.NUM_ROWS,
           --A.LAST_ANALYZED
      FROM USER_TAB_PARTITIONS A
     WHERE TABLE_NAME = LVV_TABLE_NAME -- 'EDS_EDC_BSPRODUCT_DATA_ITEM'
       AND A.PARTITION_NAME >= LVV_START_PARTITION_NAME -- 'PD20181116'
       AND A.PARTITION_NAME <= LVV_END_PARTITION_NAME -- 'PD20181201'
       GROUP BY PARTITION_NAME
     ORDER BY A.PARTITION_NAME;

  --=================================================================================
  --                                 MAIN PROGRAM
  --=================================================================================
  --=============================================================
  -- VARIABLE INITIALIZATION
  --=============================================================
BEGIN
      -- 对传入参数的大小写做统一转换
      LVV_TABLE_NAME := UPPER(PVVI_TABLE_NAME);
      LVV_START_PARTITION_NAME := UPPER(PVVI_START_PARTITION_NAME);
      LVV_END_PARTITION_NAME := UPPER(PVVI_END_PARTITION_NAME);
    -- 设置DBMS打印输出缓冲区大小 字节数
    DBMS_OUTPUT.ENABLE(1000000);
    IF LVV_TABLE_NAME IS NULL THEN 
        DBMS_OUTPUT.PUT_LINE('表名为空');
        --PVVO_RETURN_VALUE := '表名为空' ;
        RETURN ;
    END IF ;
    BEGIN
        OPEN PARTITION_CURSOR;
        LOOP
          FETCH PARTITION_CURSOR
            INTO V_CHOOSE_PARTITION_NAME;
          EXIT WHEN PARTITION_CURSOR%NOTFOUND;
            LVV_SQLEXEC := 'ALTER TABLE ' || LVV_TABLE_NAME || ' DROP PARTITION ' ||
                         V_CHOOSE_PARTITION_NAME;
            DBMS_OUTPUT.PUT_LINE(LVV_SQLEXEC);
            DBMS_UTILITY.EXEC_DDL_STATEMENT(LVV_SQLEXEC);
        END LOOP;
        --PVVO_RETURN_VALUE := '分区删除成功' ;
        CLOSE PARTITION_CURSOR;
     END;
EXCEPTION
  WHEN OTHERS THEN
    --PVVO_RETURN_VALUE := '分区删除失败' ;
    DBMS_OUTPUT.PUT_LINE('分区删除失败');
END DROP_PARTITION_BY_TABLE;
```



#### 查看指定分区数据 

```sql
/*查看分区表数据*/
select * from LOTHISTORY partition(LOTHISTORY_201912)
```

### **索引**

#### **创建函数索引**

```sql
-- 指定indexname ， tablename ， 和函数
-- create index,如果是大表建立索引，切记加上online参数,在线构建索引，不会阻塞DML操作
create index   indexname on table(substr(fileld,0,2)) online nologging   ;

create index EDS_EDC_BSPRODUCT_DATA_IDX_03 on EDBADM.EDS_EDC_BSPRODUCT_DATA (SUBSTR(EDC_COL_TIMEKEY,1,8), OPER_CODE)
  nologging  local;

create index EDS_SPC_CONTROL_SPEC_ITEM_01 on EDBADM.EDS_SPC_CONTROL_SPEC_ITEM (
substr(t.spc_spec_name,1,INSTR(t.spc_spec_name, '-', 1, 1) - 1),substr(t.spc_spec_name,INSTR(t.spc_spec_name, '-', 1, 1) + 1,INSTR(t.spc_spec_name, '_', 1, 1) - INSTR(t.spc_spec_name, '-', 1, 1) - 1)
) nologging  local;
```

#### **创建Normal索引**

```sql
-- 指定index 属性字段
-- 创建索引时使用nologging选项可以加快速度，节省时间，减少产生的日志量。
create index EDS_EQP_RUN_HIST_IDX01 on EDS_EQP_RUN_HIST (EVENT_TIMEKEY) nologging  local;

```

#### **创建Parition索引**

```mysql
-- 创建分区表 ，指定分区字段
-- Create table , 默认为本地分区索引
create table EDS_EQP_RUN_HIST
(
  site                VARCHAR2(40) not null,
  factory             VARCHAR2(40) not null,
  eqp_id              VARCHAR2(40) not null,
  event_timekey       VARCHAR2(40) not null,
  event_shift_timekey VARCHAR2(40) not null,
  eqp_state           VARCHAR2(40) not null,
  start_time          DATE not null,
  end_time            DATE not null,
  start_timekey       VARCHAR2(40),
  end_timekey         VARCHAR2(40),
  old_eqp_state       VARCHAR2(40),
  e10_state           VARCHAR2(40),
  eqp_state_duration  NUMBER,
  event_time          DATE,
  event_name          VARCHAR2(40),
  event_user_id       VARCHAR2(40),
  event_comment       VARCHAR2(400),
  eqp_mode            VARCHAR2(40),
  event_cnt           NUMBER,
  up_cnt              NUMBER,
  reason_code         VARCHAR2(40),
  recipe_id           VARCHAR2(40),
  lot_qty             NUMBER,
  gls_qty             NUMBER,
  qpnl_qty            NUMBER,
  pnl_qty             NUMBER,
  line_name           VARCHAR2(40),
  cut_off_flag        VARCHAR2(40),
  interface_time      DATE default SYSDATE,
  lot_type            VARCHAR2(40) not null
)
partition by range (EVENT_SHIFT_TIMEKEY)
(
  partition PM202011 values less than ('20201201 060000')
    tablespace EDS_EQP_TBS
    pctfree 10
    initrans 1
    maxtrans 255
    storage
    (
      initial 8M
      next 1M
      minextents 1
      maxextents unlimited
    ),
  partition PM202101 values less than ('20210201 060000')
    tablespace EDS_EQP_TBS
    pctfree 10
    initrans 1
    maxtrans 255,
  partition PMMAX values less than (MAXVALUE)
    tablespace EDS_EQP_TBS
    pctfree 10
    initrans 1
    maxtrans 255
);
-- PARTITION RANGE SINGLE
SELECT T.*
  FROM EDS_EQP_RUN_HIST T
 WHERE T.EVENT_SHIFT_TIMEKEY = '20201112 060000'
-- PARTITION RANGE ALL对分区字段查询时，使用函数不会走分区索引，会扫描所有分区



-- 创建全局索引，且索引分区键和表分区键相同
CREATE INDEX ORDERS_GLOBAL_1_IDX ON ORDERS(ORD_DATE) GLOBAL
PARTITION BY RANGE(ORD_DATE)
(PARTITION GLOBAL1 VALUES LESS THAN (TO_DATE('2014-01-01','YYYY-MM-DD'))
,PARTITION GLOBAL2 VALUES LESS THAN (TO_DATE('2014-02-01','YYYY-MM-DD'))
,PARTITION GLOBAL3 VALUES LESS THAN (TO_DATE('2014-03-01','YYYY-MM-DD'))
,PARTITION GLOBAL4 VALUES LESS THAN (TO_DATE('2014-04-01','YYYY-MM-DD'))
,PARTITION GLOBAL5 VALUES LESS THAN (TO_DATE('2014-05-01','YYYY-MM-DD'))
,PARTITION GLOBAL6 VALUES LESS THAN (TO_DATE('2014-06-01','YYYY-MM-DD'))
,PARTITION GLOBAL7 VALUES LESS THAN (TO_DATE('2014-07-01','YYYY-MM-DD'))
,PARTITION GLOBAL8 VALUES LESS THAN (MAXVALUE)
);

-- 创建全局索引，索引的分区键和表分区键不相同
CREATE INDEX ORDERS_GLOBAL_2_IDX 
       ON ORDERS(PART_NO) 
       GLOBAL 
       PARTITION BY RANGE(PART_NO)
       (PARTITION IND1 VALUES LESS THAN (555555)
       ,PARTITION IND2 VALUES LESS THAN (MAXVALUE)
       );
-- Note：全局索引和表没有直接的关联，必须显示的指定maxvalue值。假如表中新加了分区，不会在全局索引中自动增加新的分区，必须手工添加相应的分区

```

#### **索引信息查询**

##### 查看索引是全局索引还是本地索引

```sql
-- Oracle ALL_INDEXES 官方文档https://docs.oracle.com/cd/E11882_01/server.112/e40402/statviews_1109.htm#REFRN20088
-- locality字段 为local和global区分本地和全局索引 ， DBA_PART_INDEXES 、DBA_IND_PARTITIONS
-- ALIGNMENT 区分是前缀索引还是非前缀索引，分区键和索引列一致时为前缀索引
SELECT T.TABLE_NAME, T.INDEX_NAME, T.ALIGNMENT, T.LOCALITY
  FROM USER_PART_INDEXES T
 WHERE T.TABLE_NAME = 'LOTHISTORY';
```

##### 查看索引是否有效

```sql
-- 普通索引是否失效 ， 也可以使用DBA_INDEXES
-- STATUS 可以是Indicates whether a nonpartitioned index is VALID or UNUSABLE
SELECT A.INDEX_NAME, A.INDEX_TYPE, A.TABLE_NAME, A.STATUS, A.PARTITIONED
  FROM USER_INDEXES A
 WHERE TABLE_NAME = 'LOTHISTORY';
 
-- 使用DBA_OBJECTS查询索引是否失效
SELECT OWNER, OBJECT_NAME, STATUS
  FROM DBA_OBJECTS
 WHERE OBJECT_TYPE = 'INDEX'
   AND STATUS = 'VALID' -- INVALID
   AND owner = 'EDBADM'
 
 -- 分区索引是否失效
SELECT *
  FROM DBA_IND_PARTITIONS  L
 WHERE L.INDEX_OWNER IN ('EDBADM')
   AND L.STATUS = 'USABLE';
   
  SELECT L.STATUS , L.*
  FROM DBA_IND_PARTITIONS  L
 WHERE L.Index_Name = 'IDX_LOTHISTORY_01'
   AND L.STATUS = 'USABLE';
```

#### **开启索引监控**

```sql
-- 开启某张表的索引监控
ALTER INDEX BSBULLETINBOARD_PK MONITORING USAGE;  

/*查看索引监控使用情况*/
SELECT *
  FROM V$OBJECT_USAGE T
 WHERE T.TABLE_NAME = 'EDS_SUM_MOVE'
   AND T.INDEX_NAME = 'EDS_SUM_MOVE_IDX_01' ;
```

#### hint 强制索引

```sql
SELECT /*+INDEX(t IDX_LOTHISTORY_02)*/  T.*  FROM LOTHISTORY T 
WHERE t.factoryname = 'LBP'
AND t.eventname = 'TrackIn'
AND t.timekey >= '20210113163000'
AND t.timekey <= '20210113163500';
```

### **SQL查询**

#### **根据spid查询top sql **

```plsql
-- 登陆MDWDB HP-UX Server root用户
su - root
-- 执行top ， 查询执行比较耗CPU的top SQL 
top
-- 执行glance ， 查询Server整体cpu消耗
glance 

-- 根据top查询出来的spid，查询该spid对应SQL 内容
select sql_text
from v$sqlarea
where address in
       (select sql_address
          from v$session
         where paddr in (select addr from v$process where spid =15003));
```

#### 根据绑定变量查询值

```mysql
-- 根据SQL_ID查询SQL语句
SELECT a.SQL_ID, SQL_TEXT, LAST_ACTIVE_TIME, SQL_FULLTEXT
  FROM v$sql a
  where SQL_ID='b50amakf2w00q'
 /*where to_char(a.LAST_ACTIVE_TIME, 'yyyy/mm/dd hh24:mi:ss') >=
       '2020/05/26 19:27:11'*/
 ORDER BY LAST_ACTIVE_TIME DESC;

-- 根据SQL_ID查询对应SQL语句中绑定变量的具体值
SELECT A.SQL_ID, A.NAME, A.POSITION, VALUE_STRING, DATATYPE_STRING
  FROM V$SQL_BIND_CAPTURE A
 WHERE SQL_ID = 'b50amakf2w00q';

```

### **表和数据恢复**

```plsql
-- 查看数据库回收站  
SELECT OBJECT_NAME,
       ORIGINAL_NAME,
       PARTITION_NAME,
       TYPE,
       TS_NAME,
       CREATETIME,
       DROPTIME
  FROM RECYCLEBIN T
 WHERE T.TYPE = 'TABLE'
 AND t.original_name = 'PRODUCT_YIELD'
 ORDER BY T.DROPTIME DESC;
 
 --恢复   
 FLASHBACK TABLE PRODUCT_YIELD TO BEFORE DROP;  
```

### **ASM管理**

```plsql
-- 操作系统登录
su - grid
password:grid

-- 输入asmcmd
asmcmd

-- help查看
help
-- 查看ASM磁盘挂载情况
lsdg


--也可以通过表查询V$ASM_DISKGROUP ，  grid用户下，asmcmd ， lsdg命令查询结果一致 
SELECT STATE,
       NAME,
       TOTAL_MB,
       FREE_MB,
       COMPATIBILITY,
       DATABASE_COMPATIBILITY
  FROM V$ASM_DISKGROUP ;
```



### **归档日志ARCHIVED LOG**

```plsql
-- 查看当前实时归档量
SELECT TRUNC(FIRST_TIME) "TIME",
       SUM(BLOCK_SIZE * BLOCKS) / 1024 / 1024 / 1024 "SIZE(GB)"
  FROM V$ARCHIVED_LOG
 GROUP BY TRUNC(FIRST_TIME) 
 ORDER BY 1 DESC  ;
 
-- 查看每天归档量
SELECT TRUNC(COMPLETION_TIME), SUM(MB) / 1024 DAY_GB
  FROM (SELECT NAME, COMPLETION_TIME, BLOCKS * BLOCK_SIZE / 1024 / 1024 MB
          FROM V$ARCHIVED_LOG
         WHERE COMPLETION_TIME BETWEEN TRUNC(SYSDATE) - 30 AND
               TRUNC(SYSDATE) )
 GROUP BY TRUNC(COMPLETION_TIME)
 ORDER BY 1 DESC;
```

#### 查看ARCHIVED LOG 模式

```mysql
SQL> archive log list
Database log mode              Archive Mode
Automatic archival             Enabled
Archive destination            +MDWDBARCH
Oldest online log sequence     210813
Next log sequence to archive   210816
Current log sequence           210816
```

#### RMAN

```sql
-- rman 登录
$ rman target /

-- 检查一些无用的archivelog
RMAN> crosscheck archivelog all;

-- 删除过期的归档
RMAN> delete expired archivelog all;

-- 删除截止到前一天的所有归档
delete archivelog until time 'sysdate-1' ; 

-- 直接删除当前所有归档
delete archivelog until time 'sysdate';

-- rman 删除归档 （“1”对应是一天，若想删除6小时前的归档日志，则改为0.25）
RMAN> delete archivelog all completed before 'sysdate-1'; 

-- 删除完归档，若有对应的备份策略需要重新启动全备。

```



#### 查看ARCHIVED LOG Free Space

```SQL
-- grid用户下，asmcmd ， lsdg命令查询结果一致 
SELECT STATE,
       NAME,
       TOTAL_MB,
       FREE_MB,
       COMPATIBILITY,
       DATABASE_COMPATIBILITY
  FROM V$ASM_DISKGROUP ;
```

### **日志清理**

#### Alert日志清理

```shell
-- Alert log剪切走后会自动重新生成log.xml
$ cd /oracle/app/diag/rdbms/mdwdb/mdwdb1/alert/
$ ll
total 342942
-rw-r-----   1 oracle     asmadmin   7658268 Jan 25 15:04 log.xml
-rw-r-----   1 oracle     asmadmin   10485868 Dec 15 06:48 log_100.xml
-rw-r-----   1 oracle     asmadmin   10485845 Jan  7 05:48 log_101.xml
-rw-r-----   1 oracle     asmadmin   10485892 Sep 30 19:48 log_96.xml
-rw-r-----   1 oracle     asmadmin   10485930 Oct 26 03:48 log_97.xml
-rw-r-----   1 oracle     asmadmin   10485879 Nov 10 21:48 log_98.xml
-rw-r-----   1 oracle     asmadmin   10485786 Dec  2 02:21 log_99.xml
$ mv log.xml log_102.xml

-- grid 用户下 listerner的alert日志
$ cd /grid/app/diag/tnslsnr/mdwdb1/listener/alert 
$ ll
total 308484
-rw-r-----   1 grid       oinstall    510164 Jan 25 15:31 log.xml
-rw-r-----   1 grid       oinstall   10485787 Dec 23 15:13 log_1.xml
-rw-r-----   1 grid       oinstall   10485859 Jan 12 18:17 log_10.xml
-rw-r-----   1 grid       oinstall   10486109 Jan 16 07:04 log_11.xml
-rw-r-----   1 grid       oinstall   10485912 Jan 19 06:13 log_12.xml
-rw-r-----   1 grid       oinstall   10485997 Jan 21 11:57 log_13.xml
-rw-r-----   1 grid       oinstall   10485984 Jan 23 17:01 log_14.xml
-rw-r-----   1 grid       oinstall   10486125 Jan 25 13:13 log_15.xml
$ mv log.xml log_16.xml
```

#### Trace日志清理

```shell
-- 切换到oracle 用户下trace 目录
$ cd /oracle/app/diag/rdbms/mdwdb/mdwdb1/trace
$ ll *log*
-rw-r-----   1 oracle     asmadmin   6808460 Jun 15  2020 alert_mdwdb1.log.20200615
-rw-r-----   1 oracle     asmadmin   8392065 Aug 14 18:04 alert_mdwdb1.log.20200814
-rw-r-----   1 oracle     asmadmin   4173671 Sep 21 10:58 alert_mdwdb1.log.20200921
-rw-r-----   1 oracle     asmadmin   2333414 Oct  9 18:16 alert_mdwdb1.log.20201009
-rw-r-----   1 oracle     asmadmin   3075995 Nov  2 11:19 alert_mdwdb1.log.20201102
-rw-r-----   1 oracle     asmadmin   5679071 Dec 16 10:15 alert_mdwdb1.log.20201216
-rw-r-----   1 oracle     asmadmin   2326589 Jan  8 10:58 alert_mdwdb1.log.20210108
-rw-r-----   1 oracle     asmadmin    212434 Jan 12 16:16 alert_mdwdb1.log.20210112
-rw-r-----   1 oracle     asmadmin   1490263 Jan 25 15:21 alert_mdwdb1.log.20210124
-rw-r--r--   1 oracle     asmadmin      6468 May 21  2014 sbtio.log

-- grid用户下 ， listerner trace日志清理
$ cd /grid/app/diag/tnslsnr/mdwdb1/listener/trace/

-- 不能使用mv不会自动生成listener.log ，  将log内容打入黑洞
$ cat /dev/null >listener.log
```

#### DailyCheck日志清理

```shell
-- 切换到oracle 用户下 , 执行数据库巡检脚本
-- log存放位置：/home/oracle/daycheck/log
$ cd /home/oracle/daycheck/log
$ ls -lrt

-- 查看指定目录下，指定后缀名的文件数量一共有多少 ( 查看一个月之前的log文件数量)
$ find /home/oracle/daycheck/log -name '*.log' -mtime +30 | wc -l

-- 删除一个月前的log
$ find /home/oracle/daycheck/log -name '*.log'  -mtime +30  | xargs rm -rf  

-- 另外一种写法
/usr/bin/find $LOGDIR -name '*_*_*.log.gz' -mtime +5 -exec rm -f {} \;
```

#### 日志自动清理脚本

##### Unix OS

```shell

```



##### Windows

```shell

```



### **场景运维SQL**

#### Session等待查询

```sql
- sqlplus 设置显示格式
set echo off feedback off timing off pause off
set pages 100 lines 232 trimspool on trimout on space 1 recsep off
col machine format a12
col username format a12
col sid format a12
col ospid format a9
col program format a16
col state  format a18
col event format a30
col sqlid format a15
col block_ss format 9999999

-- sqlplus 中执行或者plsql中执行
-- 查看详细等待事件
select a.machine                                                             machine,
       a.username                                                            username,
       a.sid||','||a.serial#                                                 sid,
       c.spid                                                                ospid,
       substr(a.program,1,19)                                                program,
       a.event                                                               event,
       b.sql_id||','||b.child_number                                         sqlid,
--       b.plan_hash_value                                                     plan_hash_value,
       b.executions                                                          execs,
       (b.elapsed_time/decode(nvl(b.executions,0),0,1,b.executions))/1000000 avg_etime,
       round((b.buffer_gets/decode(nvl(b.executions,0),0,1,b.executions)),2) avg_lios,
       a.blocking_session                                                      block_ss,
       sw.state                                                              state,
       sw.wait_time                                                          wait_time
from v$session a,
     v$session_wait sw,
     v$sql     b,
     v$process c
where 
decode(a.sql_id,null,a.prev_sql_id, a.sql_id)=b.sql_id
and    decode(a.sql_id,null,a.prev_child_number, a.sql_child_number)=b.child_number
--a.sql_id           = b.sql_id and   a.sql_child_number = b.child_number
and	  a.sid              = sw.sid
and   a.paddr            = c.addr
and   a.status           = 'ACTIVE'
and   a.username is not null
and   a.wait_class      <> 'Idle'
and   b.sql_text not like '%v$sql%'
and   a.sid             <> userenv('SID')
order by b.sql_id,b.plan_hash_value;

-- 可以查看SQL_TEXT  , DISK_READS(物理读) , BUFFER_GETS（逻辑读）
SELECT 'alter system kill session ' || '''' || S.SID || ',' || S.SERIAL# || '''' ||
       ' IMMEDIATE' AS KILL_SESSION,
       'kill -9 ' || P.SPID AS KILL_SESSION,
       S.MACHINE,
       S.OSUSER,
       S.PROGRAM,
       S.USERNAME,
       S.LAST_CALL_ET,
       A.SQL_ID,
       S.LOGON_TIME,
       A.SQL_TEXT,
       A.SQL_FULLTEXT,
       W.EVENT,
       A.DISK_READS,
       A.BUFFER_GETS
  FROM V$PROCESS P, V$SESSION S, V$SQLAREA A, V$SESSION_WAIT W
 WHERE P.ADDR = S.PADDR
   AND S.SQL_ID = A.SQL_ID
   AND S.SID = W.SID
   AND S.STATUS = 'ACTIVE'
 ORDER BY S.LAST_CALL_ET DESC;
```

#### sql_id 查询sql_text

```sql
--方式1（推荐）  
SELECT SQL_TEXT FROM V$SQL WHERE SQL_ID = '1z726wtx5dt95';
 
--方式2 SQL_TEXT 是分片显示
SELECT SQL_TEXT
  FROM V$SQLTEXT
 WHERE SQL_ID = '9vx3nrtsc1t6h'
 ORDER BY PIECE;
```

#### Session Kill

##### 正常手动kill session

```sql
1. 方式1 sid  serial#  kill session 
-- 根据 sid  serial#  kill session 
alter system kill session '509,37683' IMMEDIATE ;

2. 方式2 ， 根据OSPID Kill Session
----根据paddr 查询spid（paddr为v$session中字段，addr为v$process中字段）
SELECT SPID FROM V$PROCESS WHERE ADDR = 'C000000FE0DAA480';

----根据spid 杀系统进程
KILL - 9 SPID;
```

调用存储过程批量kill session（有bug ，待完善）

```sql
-- 批量杀死 latch: cache buffers chains事件导致的session
set serveroutput on
declare
v_sql varchar2(4000);

v_username varchar2(50);
v_status varchar2(50);
v_schema# varchar2(50);
v_machine varchar2(50);

cursor c is
select s.inst_id,s.sid,s.serial# from gv$lock l ,gv$session s where l.block!=0 and l.inst_id=s.inst_id and s.sid=l.SID and s.username not in ('SYS','SYSTEM') and s.event='latch: cache buffers chains'  and s.status='ACTIVE'  group by s.inst_id,s.sid,s.serial# ;

v_record c%rowtype;

begin
  open c;
  loop
  fetch c into v_record;
  exit when c%notfound;
 v_sql := 'alter system kill session '||''''||v_record.sid||','||v_record.serial#||',@'||v_record.inst_id||''''||' immediate ';
 dbms_output.put_line(v_sql);
--select username,status ,schema#,machine  into v_username,v_status,v_schema#,v_machine from gv$session
--where sid=v_record.sid and serial#=v_record.serial#;
--dbms_output.put_line('username:'||v_username||',status:'||v_status||',schema#:'||v_schema#||',machine:'||v_machine);
 execute immediate v_sql;
 end loop;
 close c;
 end;
 /
```



#### 查看执行计划

```sql

EXPLAIN PLAN FOR SELECT  /*+INDEX(t EDS_GLASS_HIST_IDX_04)*/ T.*  FROM EDS_GLASS_HIST T 
WHERE T.EVENT_SHIFT_TIMEKEY = '20200101 060000';


 SELECT plan_table_output
FROM TABLE(dbms_xplan.display('plan_table',NULL,'all'));


```



#### AWR收集

```sql
-- windows server 收集方式
D:\app\Oracle\product\11.2.0.4\dbhome_1\RDBMS\ADMIN\awrrpt.sql
C:\Users\Administrator.YSGDCIM>sqlplus / as sysdba
SQL> @?/rdbms/admin/awrrpt.sql
html默认下载路径为当前登录用户home目录下C:\Users\Administrator.YSGDCIM>

-- Unix Server 收集方式
$ echo $ORACLE_SID
mdwdb2
$ sqlplus / as sysdba

SQL*Plus: Release 11.2.0.4.0 Production on Thu Jan 21 10:36:30 2021

Copyright (c) 1982, 2013, Oracle.  All rights reserved.


Connected to:
Oracle Database 11g Enterprise Edition Release 11.2.0.4.0 - 64bit Production
With the Partitioning, Real Application Clusters, Automatic Storage Management, OLAP,
Data Mining and Real Application Testing options

SQL> @?/rdbms/admin/awrrpt.sql

Current Instance
~~~~~~~~~~~~~~~~

   DB Id    DB Name      Inst Num Instance
----------- ------------ -------- ------------
 4080708746 MDWDB               2 mdwdb2


Specify the Report Type
~~~~~~~~~~~~~~~~~~~~~~~
Would you like an HTML report, or a plain text report?
Enter 'html' for an HTML report, or 'text' for plain text
Defaults to 'html'
Enter value for report_type: html

Type Specified:  html


Instances in this Workload Repository schema
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   DB Id     Inst Num DB Name      Instance     Host
------------ -------- ------------ ------------ ------------
* 4080708746        2 MDWDB        mdwdb2       mdwdb2
  4080708746        4 MDWDB        mdwdb4       mdwdb4
  4080708746        1 MDWDB        mdwdb1       mdwdb1
  4080708746        3 MDWDB        mdwdb3       mdwdb3

Using 4080708746 for database Id
Using          2 for instance number


Specify the number of days of snapshots to choose from
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Entering the number of days (n) will result in the most recent
(n) days of snapshots being listed.  Pressing <return> without
specifying a number lists all completed snapshots.


Enter value for num_days: 1

Listing the last day's Completed Snapshots

                                                        Snap
Instance     DB Name        Snap Id    Snap Started    Level
------------ ------------ --------- ------------------ -----
mdwdb2       MDWDB            65318 21 Jan 2021 00:00      1
                              65319 21 Jan 2021 01:00      1
                              65320 21 Jan 2021 02:00      1
                              65321 21 Jan 2021 03:00      1
                              65322 21 Jan 2021 04:00      1
                              65323 21 Jan 2021 05:00      1
                              65324 21 Jan 2021 06:00      1
                              65325 21 Jan 2021 07:00      1
                              65326 21 Jan 2021 08:00      1
                              65327 21 Jan 2021 09:00      1
                              65328 21 Jan 2021 10:00      1



Specify the Begin and End Snapshot Ids
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Enter value for begin_snap: 65327
Begin Snapshot Id specified: 65327

Enter value for end_snap: 65328
End   Snapshot Id specified: 65328



Specify the Report Name
~~~~~~~~~~~~~~~~~~~~~~~
The default report file name is awrrpt_2_65327_65328.html.  To use this name,
press <return> to continue, otherwise enter an alternative.

Enter value for report_name: /tmp/awrrpt_2_65327_65328.html

html默认下载路径为/tmp/awrrpt_2_65327_65328.html (awr报告存放路径可以指定)
```

####  DB Time

```sql
-- 查询指定INSTANCE实例的DB Time
SELECT *
  FROM (SELECT INSTANCE_NAME,
               SNAP_ID,
               SNAP_TIME,
               ROUND((VALUE - V) / 60 / 1000000, 2) DB_TIME
          FROM (SELECT INSTANCE_NAME,
                       SNAP_ID,
                       SNAP_TIME,
                       VALUE,
                       (LAG(VALUE)
                        OVER(PARTITION BY INSTANCE_NAME ORDER BY SNAP_ID)) V
                  FROM (SELECT I.INSTANCE_NAME,
                               SP.SNAP_ID - 1 AS SNAP_ID,
                               TO_CHAR(BEGIN_INTERVAL_TIME, 'mm-dd hh24:mi:ss') SNAP_TIME,
                               VALUE
                          FROM DBA_HIST_SNAPSHOT       SP,
                               DBA_HIST_SYS_TIME_MODEL SY,
                               GV$INSTANCE             I
                         WHERE SP.SNAP_ID = SY.SNAP_ID
                           AND SP.INSTANCE_NUMBER = SY.INSTANCE_NUMBER
                           AND SY.INSTANCE_NUMBER = I.INSTANCE_NUMBER
                           AND SP.BEGIN_INTERVAL_TIME >= SYSDATE - 8
                              --and to_char(sp.begin_interval_time, 'hh24:mi:ss') BETWEEN '06:00:00' AND '21:30:00'
                           AND SY.STAT_NAME = 'DB time'))) DBTIMESQL
 WHERE DBTIMESQL.DB_TIME >= 0
 AND INSTANCE_NAME = 'mdwdb3'
 ORDER BY INSTANCE_NAME, SNAP_ID DESC;
```



#### DBLink&同义词创建

```sql
-- 查看当前用户下有哪些DBLINK
SELECT OWNER, OBJECT_NAME
  FROM DBA_OBJECTS
 WHERE OBJECT_TYPE = 'DATABASE LINK';

-- 查看指定用户下有哪些同义词
SELECT * FROM ALL_SYNONYMS t WHERE t.owner in ('SYS','T1MESADM')

--创建公共DBlink
create public database link MWMS
  connect to T1WMSADM identified by password
  using '(DESCRIPTION =
(ADDRESS_LIST =
(ADDRESS = (PROTOCOL = TCP)(HOST = XX.XX.XX.XX)(PORT = 1521))
)
(CONNECT_DATA =
(SERVICE_NAME = fgmtst)
)
)';

--创建非公共DBlink
create database link MWMS
  connect to P1WMSADM identified by password
  using '(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)(HOST=XX.XX.XX.XX)(PORT=1521))
                                    (ADDRESS=(PROTOCOL=TCP)(HOST=XX.XX.XX.XX)(PORT=1521)))
									(CONNECT_DATA=(SERVER=default)(SERVICE_NAME=fgmsdb)))';
--创建dblink同义词
create SYNONYM MATERIALPACKINGMWMS for T1WMSADM.MATERIALPACKING@T1WMSADM;

-- 创建同义词语法
CREATE [ PUBLIC ] SYNONYM synonym_name FOR [ schema .] object[@db_link];
create or replace synonym 同义词名 for 表名;  
create or replace synonym 同义词名 for 用户.表名;  
create or replace synonym 同义词名 for 表名@数据库链接名;  

-- 删除私有同义词
drop synonym 同义词名;  

-- 删除公共同义词
DROP PUBLIC SYNONYM public_emp;

SELECT * FROM MATERIALPACKING@MWMS  --DBlink方式查询
SELECT * FROM MATERIALPACKINGMWMS  --同义词方式查询

Notes:如果DBLINK访问的表属于DBLINK用户，则不需要创建同义词可以MATERIALPACKING@MWMS方式直接访问，
如果DBLINK访问的表属于DBLINK EDBETL用户 ， 访问的表属于EBDADM，需要建同义词才能使用MATERIALPACKING@MWMS方式访问。
```

#### 大表创建索引

```sql
-- 查询某张表下的所有索引
SELECT A.INDEX_NAME, A.INDEX_TYPE, A.TABLE_NAME, A.STATUS, A.PARTITIONED
  FROM USER_INDEXES A
 WHERE TABLE_NAME = 'PRODUCTHISTORY';
 
-- 查看索引占用空间大小
SELECT SEGMENT_NAME, SUM(BYTES / 1024 / 1024 / 1024) AS "SIZE(G)"
  FROM DBA_SEGMENTS
 WHERE OWNER = 'EDBADM'
   AND SEGMENT_NAME = 'IDX_PRODUCTHISTORY_01'
 GROUP BY SEGMENT_NAME;

-- 查询某张表下的所有索引
SELECT A.INDEX_NAME, A.INDEX_TYPE, A.TABLE_NAME, A.STATUS, A.PARTITIONED
  FROM USER_INDEXES A
 WHERE TABLE_NAME = 'PRODUCTHISTORY';
 
-- 查看索引占用空间大小
SELECT SEGMENT_NAME, SUM(BYTES / 1024 / 1024 / 1024) AS "SIZE(G)"
  FROM DBA_SEGMENTS
 WHERE OWNER = 'EDBADM'
   AND SEGMENT_NAME = 'IDX_PRODUCTHISTORY_01'
 GROUP BY SEGMENT_NAME;

--查看索引并行度 , 1是正常
SELECT DEGREE FROM DBA_INDEXES WHERE INDEX_NAME='IDX_PRODUCTHISTORY_01';

-- 修改索引并行度
ALTER INDEX  EDBADM.EDS_EDC_BSPRODUCT_DATA_IDX_05 PARALLEL 1;

-- 在线创建本地索引 ， 开启并行
CREATE INDEX EDBADM.EDS_EDC_BSPRODUCT_DATA_IDX_05 ON EDBADM.EDS_EDC_BSPRODUCT_DATA (LOT_ID) NOLOGGING LOCAL PARALLEL 4 ONLINE;

--建完索引需要关闭索引并行度
ALTER INDEX  EDBADM.EDS_EDC_BSPRODUCT_DATA_IDX_05 NOPARALLEL;

--删除索引
DROP INDEX EDBADM.EDS_EDC_BSPRODUCT_DATA_IDX_05;

--在线重建索引
ALTER INDEX EDBADM.EDS_BSALARM_HIST_PK REBUILD PARALLEL 12 NOLOGGING ONLINE ;
ALTER INDEX P1MESADM.BSLOTPROCESSDATAITEM_PK REBUILD PARALLEL 2;

```

#### OGG 单向同步

##### 同步前准备

同步列表清单

```sql
-- 源 MES XX.XX.XX.XX ， 目标表MDW XX.XX.XX.XX
/*
BSALARM
BSALARMHISTORY
SPCCONTROLDATARESULT
SPCCONTROLDATACUMULATIVERESULT
SPCCONTROLDATARULEOUT
DATACOLLECTRESULT
DATACOLLECT
```

确认同步表的所属用户均为： P1MESADM

```sql
源 MES XX.XX.XX.XX   MESDB 和 FGMSDB共用
需要先切换环境变量：export  ORACLE_SID=mesdb2
-- 方式1 批量查询
SQL> set lines 222 pages 100
SQL> col OWNER for a15
SQL> col OBJECT_NAME for a40
SQL> col OBJECT_TYPE for a15
SQL> SELECT OWNER, OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM DBA_OBJECTS
 WHERE OWNER = 'P1MESADM'
   AND OBJECT_TYPE = 'TABLE'
   AND OBJECT_NAME IN ('BSALARM',
                       'BSALARMHISTORY',
                       'SPCCONTROLDATARESULT',
                       'SPCCONTROLDATACUMULATIVERESULT',
                       'SPCCONTROLDATARULEOUT',
                       'DATACOLLECTRESULT',
                       'DATACOLLECT');

OWNER           OBJECT_NAME                              OBJECT_TYPE     STATUS
--------------- ---------------------------------------- --------------- -------
P1MESADM        BSALARM                                  TABLE           VALID
P1MESADM        BSALARMHISTORY                           TABLE           VALID
P1MESADM        DATACOLLECT                              TABLE           VALID
P1MESADM        DATACOLLECTRESULT                        TABLE           VALID
P1MESADM        SPCCONTROLDATACUMULATIVERESULT           TABLE           VALID
P1MESADM        SPCCONTROLDATARESULT                     TABLE           VALID
P1MESADM        SPCCONTROLDATARULEOUT                    TABLE           VALID

-- 方式2 SQLPLUS 输入查询
select owner,object_name,object_type,status from dba_objects where object_name='&1';
```

确认表大小

```sql
SQL> col SEGMENT_NAME format a35
SQL> col TABLESPACE_NAME format a30
SQL> SELECT A.SEGMENT_NAME,
       A.TABLESPACE_NAME,
       SUM(A.BYTES) / 1024 / 1024 / 1024 AS "TOTAL(G)"
  FROM DBA_SEGMENTS A
 WHERE A.OWNER = 'P1MESADM'
   AND A.SEGMENT_NAME IN ('BSALARM',
                          'BSALARMHISTORY',
                          'SPCCONTROLDATARESULT',
                          'SPCCONTROLDATACUMULATIVERESULT',
                          'SPCCONTROLDATARULEOUT',
                          'DATACOLLECTRESULT',
                          'DATACOLLECT')
 GROUP BY A.SEGMENT_NAME, A.TABLESPACE_NAME
 ORDER BY 3;
 
SEGMENT_NAME                        TABLESPACE_NAME                  TOTAL(G)
----------------------------------- ------------------------------ ----------
DATACOLLECT                         FEM_DCOLRES_DAT                .187683105
SPCCONTROLDATARESULT                FEM_DCOLRES_DAT                 .38671875
SPCCONTROLDATARULEOUT               FEM_DCOLRES_DAT                   .390625
SPCCONTROLDATACUMULATIVERESULT      FEM_DCOLRES_DAT                .537963867
BSALARMHISTORY                      FEM_CUSTOMS_DAT                2.14941406
DATACOLLECTRESULT                   FEM_DCOLRES_DAT                4.71289063
BSALARM                             FEM_CUSTOMS_DAT                8.01074219
```

确认目标端数据库是否存在重名表

```sql
-- 确认MDW EDBADM 用户下是否存在重名表
SELECT OWNER, OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM DBA_OBJECTS
 WHERE OWNER = 'EDBADM'
   AND OBJECT_TYPE = 'TABLE'
   AND OBJECT_NAME IN ('BSALARM',
                       'BSALARMHISTORY',
                       'SPCCONTROLDATARESULT',
                       'SPCCONTROLDATACUMULATIVERESULT',
                       'SPCCONTROLDATARULEOUT',
                       'DATACOLLECTRESULT',
                       'DATACOLLECT');

```

##### 源库检查操作

```sql
-- 查看补充日志是否打开 , YES表示打开
SQL>  select inst_id,supplemental_log_data_min from gv$database;
   INST_ID SUPPLEME
---------- --------
         1 YES
         2 YES
-- 查看强制日志是否打开 , YES 表示打开
SQL> SELECT INST_ID, FORCE_LOGGING FROM GV$DATABASE;

   INST_ID FOR
---------- ---
         2 YES
         1 YES
-- 打开强制日志
SQL> alter database force logging;

-- Goldengate是否显示参数
SQL> show parameter goldengate;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
enable_goldengate_replication        boolean     TRUE
-- 设置ENABLE_GOLDENGATE_REPLICATION参数为true
-- 该参数在使用OGG时开启
-- 查询文档发现oracle 11204不支持replicat进程中的DBOPTIONS DEFERREFCONST参数。如果要使这个参数正常生效必须在数据库中配置ENABLE_GOLDENGATE_REPLICATION = TRUE。 
-- https://docs.oracle.com/cd/E11882_01/server.112/e40402/initparams086.htm#REFRN10346
 ALTER SYSTEM SET ENABLE_GOLDENGATE_REPLICATION = TRUE SCOPE=BOTH;
 
-- 查看OPEN的用户信息
select username,account_status from dba_users where account_status='OPEN';
```

##### 源端添加表的附加日志

```sql
-- 从GoldenGate安装目录进入GoldenGate软件命令行界面。
$ cd /oracle/ogg
$ ./ggsci

-- 使用 goldengate用户连接
dblogin USERID goldengate,PASSWORD goldengate
-- sqlplus 段可以使用conn 连接到goldengate用户
conn goldengate/goldengate
-- 查看表级别数据库附加日志是否开启
info trandata 用户名.表名
未开启提示：logging of supplemental redo log data is disabled for tabel 用户名.表名
开启提示：logging of supplemental redo log data is enabled for table 用户名.表名
-- 示例如下：
GGSCI (fabdb2 as goldengate@mesdb2) 4> info trandata p1mesadm.BSALARM

Logging of supplemental redo log data is disabled for table P1MESADM.BSALARM.

GGSCI (fabdb2 as goldengate@mesdb2) 5> info trandata p1mesadm.port

Logging of supplemental redo log data is enabled for table P1MESADM.PORT.

Columns supplementally logged for table P1MESADM.PORT: MACHINENAME, PORTNAME.

Prepared CSN for table P1MESADM.PORT: 13255637198470

-- 添加附加日志 （前提是登录到了数据库） 而且只在源端添加附加日志
ADD trandata P1MESADM.BSALARM
ADD trandata P1MESADM.BSALARMHISTORY
ADD trandata P1MESADM.SPCCONTROLDATARESULT
ADD trandata P1MESADM.SPCCONTROLDATACUMULATIVERESULT
ADD trandata P1MESADM.SPCCONTROLDATARULEOUT
ADD trandata P1MESADM.DATACOLLECTRESULT
ADD trandata P1MESADM.DATACOLLECT

GGSCI (fabdb2 as goldengate@mesdb2) 4> ADD trandata P1MESADM.BSALARM

Logging of supplemental redo data enabled for table P1MESADM.BSALARM.
TRANDATA for scheduling columns has been added on table 'P1MESADM.BSALARM'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.BSALARM'.
GGSCI (fabdb2 as goldengate@mesdb2) 5> ADD trandata P1MESADM.BSALARMHISTORY

Logging of supplemental redo data enabled for table P1MESADM.BSALARMHISTORY.
TRANDATA for scheduling columns has been added on table 'P1MESADM.BSALARMHISTORY'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.BSALARMHISTORY'.
GGSCI (fabdb2 as goldengate@mesdb2) 6> ADD trandata P1MESADM.SPCCONTROLDATARESULT

Logging of supplemental redo data enabled for table P1MESADM.SPCCONTROLDATARESULT.
TRANDATA for scheduling columns has been added on table 'P1MESADM.SPCCONTROLDATARESULT'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.SPCCONTROLDATARESULT'.
GGSCI (fabdb2 as goldengate@mesdb2) 7> ADD trandata P1MESADM.SPCCONTROLDATACUMULATIVERESULT

Logging of supplemental redo data enabled for table P1MESADM.SPCCONTROLDATACUMULATIVERESULT.
TRANDATA for scheduling columns has been added on table 'P1MESADM.SPCCONTROLDATACUMULATIVERESULT'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.SPCCONTROLDATACUMULATIVERESULT'.
GGSCI (fabdb2 as goldengate@mesdb2) 8> ADD trandata P1MESADM.SPCCONTROLDATARULEOUT

Logging of supplemental redo data enabled for table P1MESADM.SPCCONTROLDATARULEOUT.
TRANDATA for scheduling columns has been added on table 'P1MESADM.SPCCONTROLDATARULEOUT'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.SPCCONTROLDATARULEOUT'.
GGSCI (fabdb2 as goldengate@mesdb2) 9> ADD trandata P1MESADM.DATACOLLECTRESULT

Logging of supplemental redo data enabled for table P1MESADM.DATACOLLECTRESULT.
TRANDATA for scheduling columns has been added on table 'P1MESADM.DATACOLLECTRESULT'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.DATACOLLECTRESULT'.
GGSCI (fabdb2 as goldengate@mesdb2) 10> ADD trandata P1MESADM.DATACOLLECT

Logging of supplemental redo data enabled for table P1MESADM.DATACOLLECT.
TRANDATA for scheduling columns has been added on table 'P1MESADM.DATACOLLECT'.
TRANDATA for instantiation CSN has been added on table 'P1MESADM.DATACOLLECT'.

-- 再次确认表级日志是否开启
info trandata P1MESADM.BSALARM
info trandata P1MESADM.BSALARMHISTORY
info trandata P1MESADM.SPCCONTROLDATARESULT
info trandata P1MESADM.SPCCONTROLDATACUMULATIVERESULT
info trandata P1MESADM.SPCCONTROLDATARULEOUT
info trandata P1MESADM.DATACOLLECTRESULT
info trandata P1MESADM.DATACOLLECT
```

##### 源端mgr

```sql
PORT 7809
DYNAMICPORTLIST 7840-7850
purgeoldextracts ./dirdat/*, usecheckpoints, minkeepdays 2
autorestart er *, retries 1, waitminutes 10, resetminutes 120
lagreporthours 1
laginfominutes 30
lagcriticalminutes 45
```



##### 添加并配置抽取进程

```sql
-- 添加并配置抽取进程
add extract EXT_SPC,tranlog,begin now,threads 2
-- dirdat 下的file portion must be two characters
add exttrail ./dirdat/sp,extract EXT_SPC

-- 编辑配置文件
edit param EXT_SPC

-- 配置文件内容
extract EXT_SPC
setenv (NLS_LANG=AMERICAN_AMERICA.AL32UTF8)
setenv (ORACLE_HOME="/oracle/app/product/11.2.0.4")
setenv (ORACLE_SID=mesdb2)
userid goldengate@mesdb,password goldengate
TRANLOGOPTIONS ASMUSER sys@asm,ASMPASSWORD SYS
--tranlogoptions dblogreader
--tranlogoptions altarchivelogdest instance mesdb1 +MESDBARCH,ALTARCHIVELOGDEST INSTANCE mesdb2 +MESDBARCH
REPORTCOUNT EVERY 1 MINUTES,RATE
numfiles 5000
--THREADOPTIONS MAXCOMMITPROPAGATIONDELAY 90000 IOLATENCY 180000
DISCARDFILE ./dirrpt/ext_spc.dsc,APPEND,megabytes 1000
--DISCARDROLLOVER AT 3:00
exttrail ./dirdat/sp
--dynamicresolution
--tranlogoptions rawdeviceoffset 0
--tranlogoptions excludeuser goldengate
--tranlogoptions convertucs2clobs
table P1MESADM.BSALARM;
table P1MESADM.BSALARMHISTORY;
table P1MESADM.SPCCONTROLDATARESULT;
table P1MESADM.SPCCONTROLDATACUMULATIVERESULT;
table P1MESADM.SPCCONTROLDATARULEOUT;
table P1MESADM.DATACOLLECTRESULT;
table P1MESADM.DATACOLLECT;

```

##### 添加并配置投递进程

```sql
-- 添加并配置投递进程
GGSCI (fabdb2) 30> add extract DP_SPC,exttrailsource ./dirdat/sp
EXTRACT added.

-- 编辑配置文件
GGSCI (fabdb2) 31> edit param DP_SPC


-- 配置文件内容
extract DP_SPC
dynamicresolution
passthru
rmthost 10.120.8.17, mgrport 7809, compress
rmttrail ./dirdat/sp
numfiles 5000
table P1MESADM.BSALARM;
table P1MESADM.BSALARMHISTORY;
table P1MESADM.SPCCONTROLDATARESULT;
table P1MESADM.SPCCONTROLDATACUMULATIVERESULT;
table P1MESADM.SPCCONTROLDATARULEOUT;
table P1MESADM.DATACOLLECTRESULT;
table P1MESADM.DATACOLLECT;


-- 添加远程trail文件，指定远程trail文件
add rmttrail ./dirdat/sp,extract DP_SPC
```

##### 启动EXT、DP进程

```sql
GGSCI (fabdb2) 35> start EXT_SPC

Sending START request to MANAGER ...
EXTRACT EXT_SPC starting


GGSCI (fabdb2) 36> start DP_SPC

Sending START request to MANAGER ...
EXTRACT DP_SPC starting

-- 查看extract 和 dump进程是否启动正常
info all
```

##### 切换归档

```sql
-- 查看归档日志列表
SQL> archive log list
Database log mode              Archive Mode
Automatic archival             Enabled
Archive destination            +MESDBARCH
Oldest online log sequence     90169
Next log sequence to archive   90172
Current log sequence           90172
--  切换归档
SQL> alter system archive log current;

System altered.
```

##### 获取SCN 

```sql
-- 方式1 （推荐）获取当前SCN
SQL> select to_char(dbms_flashback.get_system_change_number)  from dual;

TO_CHAR(DBMS_FLASHBACK.GET_SYSTEM_CHANGE
----------------------------------------
13308529873891
        
-- 方式2 
select current_scn from v$database;
```

##### 查看当前目录

```sql
-- 查看当前用户目录
 SQL> set lines 222 pages 888
SQL> col OWNER for a10
SQL> col DIRECTORY_NAME for a25
SQL> col DIRECTORY_PATH for a45
SQL> select * from dba_directories;

OWNER      DIRECTORY_NAME            DIRECTORY_PATH
---------- ------------------------- ---------------------------------------------
SYS        DMPDIR                    /dump_tst
SYS        DUMPDIR                   /home/oracle/dumpdir
SYS        DUMP_DIR                  /oracle/expdp
SYS        MESDB_PART_PURGE_DIR      /PURGE_DIR/Purge/Partition_Purge
SYS        PURGE_DIR                 /PURGE_DIR/Purge
SYS        ORACLE_OCM_CONFIG_DIR2    /oracle/app/product/11.2.0.4/ccr/state
SYS        TOAD_BDUMP_DIR_1          /oracle/app/diag/rdbms/mesdb/mesdb1/trace
SYS        XMLDIR                    /oracle/app/product/11.2.0/rdbms/xml
SYS        TOAD_BDUMP_DIR_2          /oracle/app/diag/rdbms/mesdb/mesdb2/trace
SYS        DATA_PUMP_DIR             /oracle/app/product/11.2.0.4/rdbms/log/
SYS        ORACLE_OCM_CONFIG_DIR     /oracle/app/product/11.2.0.4/ccr/state

-- 创建数据泵导出用户
create user dpuser identified by dpuser default tablespace users;
grant connect,resource,exp_full_database,imp_full_database,dba to dpuser;
alter user dpuser quota unlimited on users;

-- 在数据库中，使用数据泵需要先建directory ,并赋予权限：
SQL>CREATE OR REPLACE DIRECTORY DATA_PUMP AS '/oracle/expdp';
SQL>grant read,write on directory PURGE_DIR to dpuser;
```

##### expdp

```sql
-- 方式1(推荐) expdp使用参数文件方式 （一般导出参数文件放在导出目录下）
-- 在/PURGE_DIR/Purge 目录下 touch  expdp_mesdb2_spc.par  参数文件配置如下
dumpfile=expdp_mesdb2_spc_%U.dmp
DIRECTORY=PURGE_DIR
parallel=2
cluster=N
exclude=statistics,package
tables=P1MESADM.BSALARM,P1MESADM.BSALARMHISTORY,P1MESADM.SPCCONTROLDATARESULT,P1MESADM.SPCCONTROLDATACUMULATIVERESULT,P1MESADM.SPCCONTROLDATARULEOUT,P1MESADM.DATACOLLECTRESULT,P1MESADM.DATACOLLECT
flashback_scn=13308553935238

-- OS 中，在/PURGE_DIR/Purge 目录下 执行如下命令
-- 需要根据之前查看的导出表的总大小，判断/PURGE_DIR/Purge目录下空间是否足够
$ expdp dpuser/dpuser parfile=expdp_mesdb2_spc.par logfile=expdp_mesdb2_spc_20210204.log

$ ls expdp_mesdb2_spc*
expdp_mesdb2_spc.par           expdp_mesdb2_spc_01.dmp        
expdp_mesdb2_spc_02.dmp        expdp_mesdb2_spc_20210204.log

-- 方式2 expdp使用参数直接导出
expdp dpuser/dpuser DIRECTORY=PURGE_DIR dumpfile=123.dmp logfile=123.log 
tables="P1MESADM"."DATACOLLECT","P1MESADM"."CONSUMABLE"
exclude=statistics,package parallel=2 cluster=N flashback_scn=13308529873891


-------可选择配置参数--------
--指定导出文件大小为20G
filesize=20G


-- 导出案例1，按表导出
expdp wanghuan/wanghuan directory=DATA_PUMP_DIR dumpfile=xe.dmp logfile=xe.log tables=eds_glass_location FLASHBACK_SCN=893769
 
 
-- 导出案例2，按用户导出
expdp scott/tiger directory=dump_scott dumpfile=dumpscott.dmp schemas=scott
 
-- 导出案例3，全库导出，且并行导出
expdp scott/tiger directory=dump_scottdumpfile=full.dmp parallel=4 full=y
 
-- 导出某个用户下某张表的分区数据
expdp dpuser/dpuser DIRECTORY=DUMP_DIR DUMPFILE=PW200404.dmp TABLES="P1MESADM"."PRODUCTHISTORY":'PW200404' logfile=PW200404.log 
expdp dpuser/dpuser DIRECTORY=PURGE_DIR DUMPFILE=PW200402.dmp TABLES="P1MESADM"."PRODUCTHISTORY":'PW200402' logfile=PW200402.log
expdp dpuser/dpuser DIRECTORY=PURGE_DIR DUMPFILE=PW200403.dmp TABLES="P1MESADM"."PRODUCTHISTORY":'PW200403' logfile=PW200403.log

-- 导入分区表的数据到目标库
impdp dpuser/dpuser  directory=DUMPDIR dumpfile=PW200402.dmp remap_schema=P1MESADM:edbadm  remap_tablespace=FEM_PRDHIST_DAT:EDS_OGG_TBS logfile=PW200402.log table_exists_action=append

impdp dpuser/dpuser  directory=DUMPDIR dumpfile=PW200403.dmp remap_schema=P1MESADM:edbadm  remap_tablespace=FEM_PRDHIST_DAT:EDS_OGG_TBS logfile=PW200403.log table_exists_action=append

impdp dpuser/dpuser  directory=DUMPDIR dumpfile=PW200404.dmp remap_schema=P1MESADM:edbadm  remap_tablespace=FEM_PRDHIST_DAT:EDS_OGG_TBS logfile=PW200404.log table_exists_action=append
```

##### 目标端mgr

```sql
PORT 7809
DYNAMICPORTLIST 7840-7850
purgeoldextracts ./dirdat/*, usecheckpoints, minkeepdays 2
autorestart er *, retries 1, waitminutes 10, resetminutes 120
lagreporthours 1
laginfominutes 30
lagcriticalminutes 45
```



##### 目标端配置复制进程

```sql
-- 目标端配置复制进程
./ggsci
dblogin USERID goldengate,PASSWORD goldengate
add checkpointtable goldengate.checkpoint
add replicat REP_SPC,exttrail ./dirdat/sp,checkpointtable goldengate.checkpoint

-- 配置REP_SPC 文件
GGSCI (mdwdb2) 1> edit param REP_SPC

-- 详细配置
replicat REP_SPC
setenv (NLS_LANG=AMERICAN_AMERICA.AL32UTF8)
SETENV (ORACLE_SID=mdwdb2)
USERID goldengate,PASSWORD goldengate
REPORTCOUNT EVERY 30 MINUTES,RATE
REPERROR DEFAULT,ABEND
GROUPTRANSOPS 1
MAXTRANSOPS 1
numfiles 5000
--HANDLECOLLISIONS
assumetargetdefs
DISCARDFILE ./dirrpt/rep_spc.dsc,APPEND,megabytes 1000
ALLOWNOOPUPDATES
map p1mesadm.BSALARM,target edbadm.BSALARM;
map p1mesadm.BSALARMHISTORY,target edbadm.BSALARMHISTORY;
map p1mesadm.SPCCONTROLDATARESULT,target edbadm.SPCCONTROLDATARESULT;
map p1mesadm.SPCCONTROLDATACUMULATIVERESULT,target edbadm.SPCCONTROLDATACUMULATIVERESULT;
map p1mesadm.SPCCONTROLDATARULEOUT,target edbadm.SPCCONTROLDATARULEOUT;
map p1mesadm.DATACOLLECTRESULT,target edbadm.DATACOLLECTRESULT;
map p1mesadm.DATACOLLECT,target edbadm.DATACOLLECT;

```

##### dmp 文件由源端传送到目的端

```sql
-- scp 拷贝，或者使用共享存储挂载实现dmp文件传输
$ scp expdp_mesdb2_spc_*.dmp oracle@XX.XX.XX.XX:/dump_tst
Password: 
expdp_mesdb2_spc_01.dmp                                                                                                        100%  155MB  51.7MB/s  52.9MB/s   00:03    
expdp_mesdb2_spc_02.dmp                                                                                                        100%   28KB  28.0KB/s  52.9MB/s   00:00  

-- 需要确认目标端/oracle/expdp是否有足够的空间
```

##### 导入目标端数据

```sql
 -- 查看目标端目录
SQL> set lines 222 pages 888
SQL> col OWNER for a10
SQL> col DIRECTORY_NAME for a25
SQL> col DIRECTORY_PATH for a45
SQL> select * from dba_directories;

OWNER      DIRECTORY_NAME            DIRECTORY_PATH
---------- ------------------------- ---------------------------------------------
SYS        DUMPDIR                   /dump_tst
SYS        DMPDIR                    /oracle/ogg/dirdat
SYS        DUMP_WANG                 /oracle/expdp
SYS        CDS_OEM_BMDT              /oracle/ljw_backup_table
SYS        DUMP_DIR                  /oracle/impdp
SYS        MYDIR                     /home/oracle/daycheck/b7
SYS        DMPDIR1                   /home/bo_bak
SYS        ORACLE_OCM_CONFIG_DIR2    /oracle/app/product/11.2.0.4/ccr/state
SYS        TOAD_BDUMP_DIR_4          /oracle/app/diag/rdbms/mdwdb/mdwdb4/trace
SYS        TOAD_BDUMP_DIR_3          /oracle/app/diag/rdbms/mdwdb/mdwdb3/trace
SYS        TOAD_BDUMP_DIR_1          /oracle/app/diag/rdbms/mdwdb/mdwdb1/trace
SYS        XMLDIR                    /oracle/app/product/11.2.0/rdbms/xml
SYS        TOAD_BDUMP_DIR_2          /oracle/app/diag/rdbms/mdwdb/mdwdb2/trace
SYS        DATA_PUMP_DIR             /oracle/app/product/11.2.0.4/rdbms/log/
SYS        ORACLE_OCM_CONFIG_DIR     /oracle/app/product/11.2.0.4/ccr/state

-- 若是第一次导入需要创建专用导入用户和密码，创建DIRECTORY并赋权限 （不是第一次，则跳过此步骤）
create user dpuser identified by dpuser default tablespace users;
grant connect,resource,exp_full_database,imp_full_database,dba to dpuser;
alter user dpuser quota unlimited on users;
grant read,write on directory DUMP_WANG to dpuser;

--查看目录及权限
SELECT privilege, directory_name, DIRECTORY_PATH FROM user_tab_privs t, all_directories d
 WHERE t.table_name(+) = d.directory_name ORDER BY 2, 1;
```

##### impdp

```sql
-- 方式1(推荐) impdp使用参数文件方式 （一般导出参数文件放在导入目录下）
-- 在/oracle/expdp 目录下 $ touch impdp_spc.par  参数文件配置如下

directory=DUMPDIR 
dumpfile=expdp_mesdb2_spc_%U.dmp     
remap_schema=P1MESADM:EDBADM 
remap_tablespace=FEM_DEFUSER_DAT:EDS_OGG_TBS,FEM_DCOLRES_DAT:EDS_OGG_TBS,FEM_CUSTOMS_DAT:EDS_OGG_TBS,FEM_CUSTOMS_IDX:EDS_OGG_TBS,FEM_DCOLRES_IDX:EDS_OGG_TBS
remap_table=P1MESADM.BSALARM:BSALARM,P1MESADM.BSALARMHISTORY:BSALARMHISTORY,P1MESADM.SPCCONTROLDATARESULT:SPCCONTROLDATARESULT,P1MESADM.SPCCONTROLDATACUMULATIVERESULT:SPCCONTROLDATACUMULATIVERESULT,
P1MESADM.SPCCONTROLDATARULEOUT:SPCCONTROLDATARULEOUT,P1MESADM.DATACOLLECTRESULT:DATACOLLECTRESULT,P1MESADM.DATACOLLECT:DATACOLLECT
parallel=4 
cluster=N
exclude=PROCACT_INSTANCE 
TABLE_EXISTS_ACTION=replace

-- OS 中，在/PURGE_DIR/Purge 目录下 执行如下命令
$ impdp dpuser/dpuser parfile=impdp_spc.par logfile=impdp_spc.log 

-----------------参考-----------------
单独导入一个表：
directory=DUMP_DIR  
dumpfile=expdp_mesdb2_mac_%U.dmp    
remap_schema=P1MESADM:edbadm 
remap_tablespace=FEM_RUNTIME_DAT:EDS_OGG_TBS,FEM_MACHIST_DAT:EDS_OGG_TBS,FEM_LOTHIST_DAT:EDS_OGG_TBS  
remap_table=p1mesadm.PRODUCT:WEB_PRODUCT 
parallel=4  
cluster=N
exclude=PROCACT_INSTANCE,table:"in ('MACHINE','MACHINEHISTORY','LOTHISTORY')"
table_exists_aciton=replace

 
--导入案例1，按表导入，从scott到scott2
impdp wanghuan/wanghuan directory=DATA_PUMP_DIR dumpfile=XE.dmp tables=eds_glass_location remap_schema=scott:scott2
impdp wanghuan/wanghuan directory=DATA_PUMP_DIR dumpfile=glass.dmp tables=eds_glass_location remap_schema=wanghuan:wanghuan
impdp wanghuan/wanghuan directory=DATA_PUMP_DIR dumpfile=glass.dmp remap_table=eds_glass_location table_exists_action=replace
/*
使用impdp工具完成数据导入时，会按照dump文件中有关的存储的参数信息完成数据的导入。很多情况下我们希望按照被导入用户的默认参数完成数据的导入，
此时我们可以使用impdp的transform参数辅助完成
*/

 impdp system/oracle  directory=mydump dumpfile=newllmj.dmp remap_tablespace=llmj_db:gold_mj_tab   remap_schema=newllmj:gold_mj schemas=newllmj table_exists_action=replace transform=segment_attributes:n
 remap_tablespace=llmj_db:gold_mj_tab  原来表空间:新的表空间
 remap_schema=newllmj:gold_mj          原来的schema:现在的schema
 transform=segment_attributes:n 去掉表空间和存储子句，加上这个参数后，remap_tablesapce参数就会失效，就会倒进用户默认的表空间，

 
-- 导入案例2，按用户导入，从scott到scott2
impdp wanghuan/wanghuan directory=DATA_PUMP_DIR dumpfile=glass.dmp remap_schema=wanghuan/wanghuan
 
-- 导入案例3，全库导入
impdp scott/tiger directory=dump_scott dumpfile=full.dmp full=y
 
-- 导入案例4，无落地文件的用户拷贝，需要建立db link
impdp scott/tiger directory=dump_scott network_link=remote_link remap_schema=scott:scott2 

```

##### 启动Replicat进程

```sql
-- 启动REP_SPC 进程 ， 并指定SCN号
start REP_SPC,aftercsn 13308553935238
```

##### 删除进程

```sql
-- 删除进程：extract dump replicat
delete ext_lot
```

##### OGG常用命令

```sql
-- 查看OGG所有进程的状态 ， 及延时等
info all  
--  查看OGG指定进程的参数文件
VIEW PARAM 链路名字 
或者
VIEW PARAMS 链路名字   
-- 编辑OGG指定进程的参数文件
EDIT PARAMS 链路名字 
或者
EDIT PARAM 链路名字 
--查看指定进程的详情
INFO 链路名字  
```

##### OGG 异常查看

```sql
-- 进入到 OGG BASE 目录 ， 如 /oracle/ogg
$ cd /oracle/ogg
-- 查看最后30行日志
$ tail -30 ggserr.log 


---------查看discardfile----------
$ cd /oracle/ogg/dirrpt
$ more rep_spc.dsc
```





##### 参考文档

```html
-- 最全Oracle数据泵常用命令
https://blog.csdn.net/enmotech/article/details/102848825
--  OGG基础原理知识
https://blog.csdn.net/enmotech/article/details/89324396

PURGEOLDEXTRACTS ./dirdat/*, USECHECKPOINTS, MINKEEPHOURS 1   
--此行解释：表示超过一小时且超过读检查点的数据自动删除
PURGEOLDEXTRACTS ./dirdat/*, USECHECKPOINTS, MINKEEPDAYS 2   
--此行解释：表示超过两天且超过读检查点的数据自动删除
PURGEOLDEXTRACTS ./dirdat/*, USECHECKPOINTS, MINKEEPFILES 50
参考文档：
http://blog.itpub.net/26736162/viewspace-1691236/

OGG的PURGEOLDEXTRACTS不能工作问题的解决
https://www.linuxidc.com/Linux/2019-04/158001.htm

参考文档：
OGG 进程清除、重建 ：https://yq.aliyun.com/articles/566626?spm=a2c4e.11163080.searchblog.58.1df82ec1sbOz8y
Oracle OGG 单表重新初始化同步的两种思路：https://yq.aliyun.com/articles/391410?spm=a2c4e.11163080.searchblog.9.4e3a2ec1vO5yPo
Oracle GoldenGate常用监控运维命令：https://yq.aliyun.com/articles/445551?spm=a2c4e.11163080.searchblog.19.a3f62ec1dkSw7z
goldengate参数整理：https://yq.aliyun.com/articles/311086?spm=a2c4e.11163080.searchblog.85.a3f62ec1dkSw7z
GoldenGate的单向同步环境搭建：https://www.cnblogs.com/ivictor/p/4747887.html

数据泵相关知识：impdp导入时将指定表更名(Remap_table、remap_tablespace、tables在impdp关于只导特定表的注意事项
https://blog.csdn.net/e_wsq/article/details/78374020
如果两边表结构一致，使用数据泵导入数据语句
源端：expdp EDBADM/edbadm directory=dump_wang dumpfile=INFOTT.dmp logfile=INFOTT.log tables=EDBADM.EDS_EQP_TACT_TIME_IE
目的端：impdp EDBADM/edbadm DIRECTORY=dump_wang DUMPFILE=INFOTT.dmp TABLE_EXISTS_ACTION=replace
table_exists_action选项：
skip是如果已存在表，则跳过并处理下一个对象；
append是为表增加数据；
truncate是截断表，然后为其增加新数据；
replace是删除已存在表，重新建表并追加数据
```



## **问题报错现象**

### **一、oracle 用户授权问题，提示授权成功，但是还是访问不到表**

```plsql
-- 用system账号创建A用户，然后用A用户创建表（N个）
-- 用system账号创建B用户，然后授权A的一个表的查询权限给B，提示授权成功，没有报错也没有警告
-- 但是用B连接数据库之后还是查询不到这个表（提示表或者视图不存在）

-- 使用EDBADM 用户创建的表OUT_OEM_PRODUCTSPEC ，赋权限给EDBETL 、 GMMS之后
grant select, insert, update, delete on OUT_OEM_PRODUCTSPEC to EDBETL;
grant select, insert, update on OUT_OEM_PRODUCTSPEC to GMMS; 

-- 使用EDBETL 、 GMMS用户不能直接select 表OUT_OEM_PRODUCTSPEC ，
例如如下语句：select * from OUT_OEM_PRODUCTSPEC
解决办法：
1. 要用EDBADM.OUT_OEM_PRODUCTSPEC 进行查询，因为表属于EDBADM不属于EDBETL 、 GMMS
2. 定义同义词才可不加EDBADM.OUT_OEM_PRODUCTSPEC进行查询
  (1) SYS 用户登录 MDWDB ， 授权某个用户crate synonym的权限，若用户名为EDBADM
       grant create synonym to EDBADM

  (2) 创建同义词 
      create or replace public synonym OUT_OEM_PRODUCTSPEC
      for EDBADM.OUT_OEM_PRODUCTSPEC（用户名.表名）;
	  这样创建成功后就可以直接在副表select
  (3) 撤销EDBADM创建同义词的权限
      revoke create synonym from EDBADM;
  (4) 删除同义词
      Drop synonym OUT_OEM_PRODUCTSPEC
```


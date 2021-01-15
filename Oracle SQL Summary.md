

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





### **表空间**

#### 表空间名称查询**

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
   --AND A.SEGMENT_TYPE LIKE '%TABLE%'
 GROUP BY A.SEGMENT_NAME, A.SEGMENT_TYPE
 ORDER BY 3 DESC;
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
  FROM USER_TAB_PARTITIONS A
 WHERE TABLE_NAME = 'EDS_UNIT_HIST' 
 ORDER BY A.PARTITION_NAME DESC ;
 
 -- DBA_TAB_PARTITIONS
 SELECT * FROM DBA_TAB_PARTITIONS WHERE TABLE_NAME='LOTHISTORY';
```

#### 分区删除

```sql
/*删除周分区*/
alter table ALARMINTERFACETOPMS drop partition PM2005;
alter table BSGLASSOUTUNITORSUBUNIT drop partition PW200502;
alter table BSGLASSOUTUNITORSUBUNIT drop partition PW200503;
alter table BSGLASSOUTUNITORSUBUNIT drop partition PW200504;

/*删除月分区*/
alter table ALARMINTERFACETOPMS drop partition PM1902;

/*查看分区表数据*/
select * from LOTHISTORY partition(LOTHISTORY_201912)
```



### **索引**

#### **创建函数索引**

```sql
-- 指定indexname ， tablename ， 和函数
-- create index,如果是大表建立索引，切记加上online参数,在线构建索引，不会阻塞DML操作
create index   indexname on table(substr(fileld,0,2)) online nologging   ;
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
-- 普通索引是否失效
-- STATUS 可以是Indicates whether a nonpartitioned index is VALID or UNUSABLE
SELECT A.INDEX_NAME, A.INDEX_TYPE, A.TABLE_NAME, A.STATUS, A.PARTITIONED
  FROM USER_INDEXES A
 WHERE TABLE_NAME = 'LOTHISTORY';
 
 -- 分区索引是否失效
SELECT *
  FROM DBA_IND_PARTITIONS  L
 WHERE L.INDEX_OWNER IN ('EDBADM')
   AND L.STATUS != 'USABLE';
   
  SELECT L.STATUS , L.*
  FROM DBA_IND_PARTITIONS  L
 WHERE L.Index_Name = 'IDX_LOTHISTORY_01'
   AND L.STATUS != 'USABLE';
```

#### hint 强制索引

```sql
SELECT /*+INDEX(t IDX_LOTHISTORY_02)*/  T.*  FROM LOTHISTORY T 
WHERE t.factoryname = 'LBP'
AND t.eventname = 'TrackIn'
AND t.timekey >= '20210113163000'
AND t.timekey <= '20210113163500';
```







### **Top SQL查询**

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



### **场景运维SQL**

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

create or replace synonym 同义词名 for 表名;  
create or replace synonym 同义词名 for 用户.表名;  
create or replace synonym 同义词名 for 表名@数据库链接名;  
drop synonym 同义词名;  

SELECT * FROM MATERIALPACKING@MWMS  --DBlink方式查询
SELECT * FROM MATERIALPACKINGMWMS  --同义词方式查询

Notes:如果DBLINK访问的表属于DBLINK用户，则不需要创建同义词可以MATERIALPACKING@MWMS方式直接访问，
如果DBLINK访问的表属于DBLINK EDBETL用户 ， 访问的表属于EBDADM，需要建同义词才能使用MATERIALPACKING@MWMS方式访问。
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


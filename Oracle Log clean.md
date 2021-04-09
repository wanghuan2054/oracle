### **oracle日志清理**

#### Alert日志清理

```shell
# Alert log move走后会自动重新生成log.xml
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

# 进入到log.xml alert目录下执行
$ find . -mtime +7 -name "*.xml" | xargs rm -rf  

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
-rw-r-----   1 grid       o

# 进入到log.xml alert目录下执行
$ find . -mtime +7 -name "*.xml" | xargs rm -rf 

```

#### Trace日志清理

```shell
# 切换到oracle 用户下trace 目录
$ cd /oracle/app/diag/rdbms/mdwdb/mdwdb1/trace
$ ls alert*log*
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


# 先备份alert log , 需要进入到alert对应目录下
$ cp alert_${ORACLE_SID}.log ./alert_${ORACLE_SID}_`date +%Y%m%d%H%M%S`.log

# 再清空alert_${ORACLE_SID}.log
# 方式1 （推荐）
$ cat /dev/null > alert_${ORACLE_SID}.log
# 方式2
$ truncate -s 0 alert_${ORACLE_SID}.log

# 清理备份的alert log
$ find . -mtime +30 -name "*.log*" | xargs rm -rf

# 清理trc trm 文件
$ find . -mtime +7 -name "*.trc" | xargs rm -rf  
$ find . -mtime +7 -name "*.trm" | xargs rm -rf


###重点关注
监听登录数据库，向监听日志文件写日志，并且使用动态监听，pmon进程会动态将注册连接信息写到日志文件中
日志文件达到4G ，部分OS>4G后，不会向监听日志文件写新的内容，需要定期清理
###
# grid用户下 ， listerner trace日志清理
$ cd /grid/app/diag/tnslsnr/mdwdb1/listener/trace/

# 推荐方式1
# 查看状态
$ lsnrctl status

# 写日志关闭
$  lsnrctl set log_status off

# 日志重命名备份
$ mv listener.log listener_`date +%Y%m%d`.log

# 写日志打开
$ lsnrctl set log_status on

# 删除 备份的listener_`date +%Y%m%d`.log
$ rm -f listener_20210329.log

# 查看RAC 集群listener 状态
$  srvctl status listener


# 推荐方式2
# 进入 监听CMD
$ lsnrctl

LSNRCTL for HPUX: Version 11.2.0.4.0 - Production on 29-MAR-2021 11:28:56

Copyright (c) 1991, 2013, Oracle.  All rights reserved.

Welcome to LSNRCTL, type "help" for information.
# 查看监听状态，以及listerner 日志文件路径
LSNRCTL> status
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for HPUX: Version 11.2.0.4.0 - Production
Start Date                05-NOV-2019 16:33:05
Uptime                    12 days 16 hr. 27 min. 59 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /grid/11.2.0.4/grid/network/admin/listener.ora
Listener Log File         /grid/app/diag/tnslsnr/mdwdb1/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=LISTENER)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=10.120.8.16)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=10.120.8.20)(PORT=1521)))
Services Summary...
Service "+ASM" has 1 instance(s).
  Instance "+ASM1", status READY, has 1 handler(s) for this service...
Service "mdwdb" has 1 instance(s).
  Instance "mdwdb1", status READY, has 1 handler(s) for this service...
Service "mdwdbXDB" has 1 instance(s).
  Instance "mdwdb1", status READY, has 1 handler(s) for this service...
The command completed successfully

# 写日志关闭
LSNRCTL> set log_status off
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER)))
LISTENER parameter "log_status" set to OFF
The command completed successfully

# 查看写日志是否关闭，查看状态 
LSNRCTL> status
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for HPUX: Version 11.2.0.4.0 - Production
Start Date                05-NOV-2019 16:33:05
Uptime                    12 days 16 hr. 35 min. 32 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /grid/11.2.0.4/grid/network/admin/listener.ora
### 关了后，Listener Log File信息就没有了
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=LISTENER)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=10.120.8.16)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=10.120.8.20)(PORT=1521)))
Services Summary...
Service "+ASM" has 1 instance(s).
  Instance "+ASM1", status READY, has 1 handler(s) for this service...
Service "mdwdb" has 1 instance(s).
  Instance "mdwdb1", status READY, has 1 handler(s) for this service...
Service "mdwdbXDB" has 1 instance(s).
  Instance "mdwdb1", status READY, has 1 handler(s) for this service...
The command completed successfully

# 退出 LSNRCTL CMD 窗口
LSNRCTL> q

# 日志重命名备份
$ mv listener.log listener_`date +%Y%m%d`.log

# 写日志打开
LSNRCTL> set log_status on
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER)))
LISTENER parameter "log_status" set to ON
The command completed successfully

#  查看日志是否打开，查看状态 ， 出现Listener Log File
LSNRCTL> status
Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=IPC)(KEY=LISTENER)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for HPUX: Version 11.2.0.4.0 - Production
Start Date                05-NOV-2019 16:33:05
Uptime                    12 days 16 hr. 38 min. 6 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /grid/11.2.0.4/grid/network/admin/listener.ora
Listener Log File         /grid/app/diag/tnslsnr/mdwdb1/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=LISTENER)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=10.120.8.16)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=10.120.8.20)(PORT=1521)))
Services Summary...
Service "+ASM" has 1 instance(s).
  Instance "+ASM1", status READY, has 1 handler(s) for this service...
Service "mdwdb" has 1 instance(s).
  Instance "mdwdb1", status READY, has 1 handler(s) for this service...
Service "mdwdbXDB" has 1 instance(s).
  Instance "mdwdb1", status READY, has 1 handler(s) for this service...
The command completed successfully

# 退出CMD终端
LSNRCTL> q

# 删除 备份的listener_`date +%Y%m%d`.log
$ rm -f listener_20210329.log

# 查看rac 集群listener 状态
$  srvctl status listener
Listener LISTENER is enabled
Listener LISTENER is running on node(s): mdwdb3,mdwdb1,mdwdb4,mdwdb2
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
# rac 集群下， 需要在root用户下执行， 需要清除oracle  和  grid 用户的数据
  # rac 集群下，可能 LSNRCTL 读写日志关闭存在一点问题root不能正常调用，但是应该不影响listerner log清理
# 非rac 集群下，oracle 用户创建调度任务即可，清除oracle用户的数据
# 每天中午12：30 
[unixtst:oracle:/home/oracle/cmd] crontab -e
30 12 * * * /home/oracle/daycheck/clean_log.sh

# 查询当前的定时调度任务
[unixtst:oracle:/home/oracle/cmd] crontab -l
09 14 1 * * /home/oracle/PURGE_DIR/cmd/purge_batch.sh
30 12 * * * /home/oracle/daycheck/clean_log.sh
```

###### clean_log.sh

```shell
#!/bin/ksh
# Unix OR Linux 下 Oracle log clean script

TODAY=`date "+%Y%m%d"`
MONTH_DAYS=30
WEEK_DAYS=7
DAY_CHECK_DIR=/home/oracle/daycheck/log

################# daycheck  log
# 清理每天巡检产生的log , 保留1个月时长
# 这里的-d 参数判断DAY_CHECK_DIR目录是否存在 
if [ -d $DAY_CHECK_DIR ]; then 
 # 若存在，则删除一个月前的log 
 find $DAY_CHECK_DIR/ -mtime +$MONTH_DAYS -name "*.log" | xargs rm -rf 
 # echo $DAY_CHECK_DIR + ' 目录下log clean completed'
fi 
################# daycheck  log end 

# oracle 用户下操作
ORACLE_ROOT=/oracle/app/diag

################# RDBMS  alert  trace log

ORACLE_RDBMSDIRS=$ORACLE_ROOT/rdbms/*/*
# 进入到oracle 用户下alert目录下执行 ， 删除log.xml 备份文件
find $ORACLE_RDBMSDIRS/alert/ -mtime +$WEEK_DAYS -name "*.xml" | xargs rm -rf 

log_list=`ls $ORACLE_RDBMSDIRS/trace/alert_*.log`
# ls /oracle/app/diag/rdbms/*/*/trace/alert_*.log
for log_name in $log_list
  do
   
   export SIZE=`du -sk $log_name | cut -f1`
   
   # alert 大于 10M
   if [ ${SIZE} -ge 10*1024 ]; then
       # 先备份alert log , 需要进入到trace对应目录下
       cp $log_name $log_name.$TODAY
       # 再清空alert_${ORACLE_SID}.log
       cat /dev/null > $log_name
   fi
done
# 清理备份的trace log
find $ORACLE_RDBMSDIRS/trace/ -mtime +$MONTH_DAYS -name "*.log*" | xargs rm -rf
# 清理trc trm 文件
find $ORACLE_RDBMSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.trc" | xargs rm -rf  
find $ORACLE_RDBMSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.trm" | xargs rm -rf

################# RDBMS  alert  trace log

#################tnslsnr listener trace alert log
# rac 集群下， tnslsnr listener log 保存到 /grid/app/diag/tnslsnr/DB NAME/listener目录下
# 单机版下，会保存到如下路径
ORACLE_LNSDIRS=$ORACLE_ROOT/tnslsnr/*/*


if [ -d $ORACLE_LNSDIRS ]; then 
   # alert目录下执行 ， 删除log.xml 备份文件
  find $ORACLE_LNSDIRS/alert/ -mtime +$WEEK_DAYS -name "*.xml" | xargs rm -rf 
  
  # listener 目录 , 先判断是否存在listerner log 文件 , rac集群下listener log记录在grid下
  if [ -d $ORACLE_LNSDIRS/trace/listener*.log ]; then 
     log_list=`ls $ORACLE_LNSDIRS/trace/listener*.log`
     for log_name in $log_list
      do
       export SIZE=`du -sk $log_name | cut -f1`
       
       # listener 大于 100M
       if [ ${SIZE} -ge 100*1024 ]; then
           # 写日志关闭
           lsnrctl set log_status off
           
           # 先备份listener log
           cp $log_name $log_name.$TODAY
           # 再清空listener log
           cat /dev/null > $log_name
           
           # 写日志打开
           lsnrctl set log_status on
       fi
  
     done
  fi 
  
  # 清理备份的listener log
  find $ORACLE_LNSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.log*" | xargs rm -rf
  # 清理listener trc trm 文件
  find $ORACLE_LNSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.trc" | xargs rm -rf  
  find $ORACLE_LNSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.trm" | xargs rm -rf
fi 

#################tnslsnr listener trace alert log



# rac grid 用户下操作
#################tnslsnr listener trace alert log
# rac 集群下， tnslsnr listener log 保存到 /grid/app/diag/tnslsnr/DB NAME/listener目录下
GRID_ROOT=/grid/app/diag/tnslsnr
GRID_LNSDIRS=$GRID_ROOT/*/*


if [ -d $GRID_LNSDIRS ]; then 
   # alert目录下执行 ， 删除log.xml 备份文件
  find $GRID_LNSDIRS/alert/ -mtime +$WEEK_DAYS -name "*.xml" | xargs rm -rf 
  
  # listener 目录
  log_list=`ls $GRID_LNSDIRS/trace/listener*.log`
  
  for log_name in $log_list
    do
     export SIZE=`du -sk $log_name | cut -f1`
     
     # listener 大于 100M
     if [ ${SIZE} -ge 100*1024 ]; then
         # 写日志关闭
         lsnrctl set log_status off
         
         # 先备份listener log
         cp $log_name $log_name.$TODAY
         # 再清空listener log
         cat /dev/null > $log_name
         
         # 写日志打开
         lsnrctl set log_status on
     fi
  done
  
  # 清理备份的listener log
  find $GRID_LNSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.log*" | xargs rm -rf
  # 清理listener trc trm 文件
  find $GRID_LNSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.trc" | xargs rm -rf  
  find $GRID_LNSDIRS/trace/ -mtime +$WEEK_DAYS -name "*.trm" | xargs rm -rf
fi 

#################tnslsnr listener trace alert log
```

##### Windows

```she
window 脚本暂时没开发
```


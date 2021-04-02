## Oracle OSWatcher

## OSWatcher下载

### github地址

```
https://github.com/wanghuan2054/oracle
```

### 简介

```
①　OSWbb：一个Unix的SHELL脚本集合，其用来收集和归档数据，从而帮助定位问题。

②　OSWbba：一个Java工具，用来自动分析数据，提供建议，并且生成一个包含图形的html文档。
```

### 远程服务器拷贝tar

```shell
# 创建安装目录
$ mkdir /home/oracle/oswbb

# 替换为具体iP地址
$ scp oswbb734.tar oracle@XX.XX.XX.XX:/home/oracle/oswbb
```

### 解压tar包

```shell
# 进入安装目录
$ cd /home/oracle/oswbb
# 解压
$ tar -xvf oswbb734.tar
```

### 启动脚本

```shell
# 一般使用nohup启动，这样可以让OSW能够在后台持续运行并在当前会话终止后不会被挂断
# 默认每30秒采集一次数据，只保留最后48小时的数据到归档文件当中
$ nohup ./startOSWbb.sh 30 48 &


# 如果您想自动压缩生成的文件，请使用下面的命令来启动OSWatcher： 
$ nohup ./startOSWbb.sh 5 120 gzip & 
# 会每隔5秒搜集一次数据，将结果保留120 小时(5 天)。请根据您的需求，调整这保留参数。（建议5s间隔,天数根据实际情况设置，预估每天也就1-2G的数据）
# 生成的结果会存储在一个叫archive的目录中。 
# 请确保您的磁盘空间足够容纳这些数据。 

其实startOSWbb.sh可以定义四个参数：

①　参数1：指定多少秒采集一次数据。

②　参数2：指定采集的数据文件在归档路径保留多少个小时。

③　参数3：可选参数，打包压缩工具，在完成收集后OSW将使用其来打包压缩归档文件。

④　参数4：可选参数，指定采集归档数据的输出目录，默认为系统变量OSWBB_ARCHIVE_DEST的值。

第一次启动OSWbb会在oswbb目录下创建gif、archive、tmp、locks目录，其归档文件夹和osw<工具名>子文件夹会被创建。采集的数据文件命名格式为：<节点名>_<操作系统工具名>_YY.MM.DD.HH24.dat。
```

### 查看进程

```shell
# 查看 启动进程
$ ps -ef | grep OSWatcher
  oracle 14305 13900  0 13:22:49 pts/0     0:00 /bin/sh ./OSWatcherFM.sh 48 /home/oracle/oswbb/oswbb/archive
  oracle 13900     1  9 13:22:14 pts/0     0:00 /bin/sh ./OSWatcher.sh 30 48
  oracle 20752 13150  1 13:31:22 pts/0     0:00 grep OSWatcher

```

### 停止脚本

```shell
# OSWbb在系统重启过后，是无法自动重启的。如果需要设置OSWbb开机自启动，那么需要安装oswbb-service这个RPM包，并且需要配置/etc/oswbb.conf文件。停止OSWbb的命令为：
$ ./stopOSWbb.sh
```

### 开机自启动

```shell
# 编辑系统/etc/rc.local文件，在文件最后添加配置行，配置oswatch任务开机自启动。
[root@dbn01 oswbb]# vi /etc/rc.local
nohup ./startOSWbb.sh 30 48 /u01/app/archive &
```

##  **OSWatcher bba** 

#### 简介

```shell
OSWatcher bba 是一个Java语言写的应用程序，需要安装Java 1.4.2 或更高的版本。oswbba能够在任何有X Windows的Unix平台或Windows平台上运行， X Windows环境是必须的，因为oswbba需要用到Oracle Chartbuilder组件，而这个组件需要它。
```

#### 操作

```shell
[unixtst:oracle:/home/oracle/oswbb/oswbb] java -jar oswbba.jar -i /home/oracle/oswbb/oswbb/archive

# 如果你只想生成某个时间段的报表，你可以使用参数-B  -E 如下案例所示

[root@DB-Server oswbb]#java -jar  -Xmx256m oswbba.jar -i /home/oracle/scripts/oswbb/archive  -B Dec  7 15:30:00 2016  -E Dec 7 17:00:00 2016

具体参考： http://blog.itpub.net/26736162/viewspace-2142613/
```





### 参考文档 

1. http://blog.itpub.net/26736162/viewspace-2142613/
2. https://www.modb.pro/db/14230
3. 华为官方文档： https://support.huawei.com/enterprise/zh/doc/EDOC1100035763/9e6f6d6d
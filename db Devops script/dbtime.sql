                
--显示instance_name 显示  过虑掉小于一定时间的
set lines 300 pages 999
spool dbtime.log               
select * from (select instance_name,snap_id,snap_time, round((value - v) / 60 / 1000000, 2) db_time
  from (select instance_name,snap_id,snap_time, value, (lag(value) over(partition by instance_name  order  by snap_id)) v
          from (select i.instance_name,sp.snap_id - 1 as snap_id,
                       to_char(begin_interval_time, 'mm-dd hh24:mi:ss') snap_time,
                       value
                  from dba_hist_snapshot sp, dba_hist_sys_time_model sy,gv$instance  i
                 where sp.snap_id = sy.snap_id
                   and sp.instance_number = sy.instance_number
                   and sy.instance_number = i.instance_number
                   and sp.BEGIN_INTERVAL_TIME >= sysdate-8
                   and sy.stat_name = 'DB time'
                 ))) dbtimesql where  dbtimesql.db_time >=0  order by instance_name,snap_id;
spool off; 
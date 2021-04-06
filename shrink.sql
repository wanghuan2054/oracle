alter table "P1MESADM"."BSPRODUCTPROCESSDATAITEM" enable row movement;
alter table "P1MESADM"."BSPRODUCTPROCESSDATAITEM" modify partition "PW180102" shrink space cascade;
alter table "P1MESADM"."BSPRODUCTPROCESSDATAITEM" modify partition "PW180104" shrink space cascade;
alter table "P1MESADM"."BSPRODUCTPROCESSDATAITEM" modify partition "PW180103" shrink space cascade;
alter table "P1MESADM"."BSPRODUCTPROCESSDATAITEM" modify partition "PW180101" shrink space cascade;
alter table "P1MESADM"."BSPRODUCTPROCESSDATAITEM" disable row movement;





alter table "P1MESADM"."DATACOLLECT" enable row movement;
alter table "P1MESADM"."DATACOLLECT" shrink space cascade;
alter table "P1MESADM"."DATACOLLECT" disable row movement;



alter table "P1MESADM"."DATACOLLECTITEM" enable row movement;
alter table "P1MESADM"."DATACOLLECTITEM" shrink space cascade;
alter table "P1MESADM"."DATACOLLECTITEM" disable row movement;



alter table "P1MESADM"."DATACOLLECTRESULT" enable row movement;
alter table "P1MESADM"."DATACOLLECTRESULT" modify partition "DATACOLLECTRESULT_2" shrink space cascade;
alter table "P1MESADM"."DATACOLLECTRESULT" modify partition "DATACOLLECTRESULT_3" shrink space cascade;
alter table "P1MESADM"."DATACOLLECTRESULT" modify partition "DATACOLLECTRESULT_4" shrink space cascade;
alter table "P1MESADM"."DATACOLLECTRESULT" modify partition "DATACOLLECTRESULT_1" shrink space cascade;
alter table "P1MESADM"."DATACOLLECTRESULT" disable row movement;



alter table "P1MESADM"."DSPCOMMANDHISTORY" enable row movement;
alter table "P1RTDADM"."DSPCOMMANDHISTORY" modify partition "DSPCOMMANDHISTORY_201712" shrink space cascade;
alter table "P1MESADM"."DSPCOMMANDHISTORY" disable row movement;


alter table "P1RTDADM"."DSPMESSAGEHISTORY"  enable row movement;
alter table "P1RTDADM"."DSPMESSAGEHISTORY" modify partition "DSPMESSAGEHISTORY_201712" shrink space cascade;
alter table "P1RTDADM"."DSPMESSAGEHISTORY"  disable row movement;


alter table "P1RTDADM"."DSPRULETRACEHISTORY" enable row movement;
alter table "P1RTDADM"."DSPRULETRACEHISTORY" modify partition "DSPRULETRACEHISTORY_201801" shrink space cascade;
alter table "P1RTDADM"."DSPRULETRACEHISTORY" modify partition "DSPRULETRACEHISTORY_201712" shrink space cascade;
alter table "P1RTDADM"."DSPRULETRACEHISTORY" disable row movement;


alter index "P1RTDADM"."DSPRULETRACEHISTORY1_PK" modify partition "DSPRULETRACEHISTORY_201712" shrink space;
alter index "P1MESADM"."LOTHISTORY_PK" modify partition "LOTHISTORY_201801" shrink space;
alter index "P1MESADM"."LOTHISTORY_PK" modify partition "LOTHISTORY_201712" shrink space;
alter index "P1MESADM"."LOTHISTORY_PK" modify partition "LOTHISTORY_201709" shrink space;
alter index "P1MESADM"."LOTHISTORY_PK" modify partition "LOTHISTORY_201710" shrink space;
alter index "P1MESADM"."LOTHISTORY_PK" modify partition "LOTHISTORY_201711" shrink space;
alter index "P1MESADM"."MACHINEHISTORY_PK" modify partition "MACHINEHISTORY_201801" shrink space;
alter index "P1MESADM"."MACHINEHISTORY_PK" modify partition "MACHINEHISTORY_201711" shrink space;
alter index "P1MESADM"."MACHINEHISTORY_PK" modify partition "MACHINEHISTORY_201712" shrink space;
alter index "P1MESADM"."BSGLASSINUNITORSUBUNIT_PK" modify partition "PW180104" shrink space;
alter index "P1MESADM"."BSGLASSINUNITORSUBUNIT_PK" modify partition "PW180103" shrink space;
alter index "P1MESADM"."BSGLASSINUNITORSUBUNIT_PK" modify partition "PW180102" shrink space;






alter index "P1MESADM"."BSGLASSOUTUNITORSUBUNIT_PK" modify partition "PW180103" shrink space;
alter index "P1MESADM"."BSGLASSOUTUNITORSUBUNIT_PK" modify partition "PW180104" shrink space;
alter index "P1MESADM"."BSGLASSOUTUNITORSUBUNIT_PK" modify partition "PW180102" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171103" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171203" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171101" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "PW180101" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "PW180102" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171003" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171002" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171001" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171102" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171202" shrink space;
alter index "P1MESADM"."GLASSINOUTUNITSUBUNIT_PK" modify partition "GLASSINOUTUNITSUBUNIT_20171201" shrink space;
alter index "P1MESADM"."IDX_BSGLASSINUNITORSUBUNIT_01" modify partition "PW180102" shrink space;
alter index "P1MESADM"."IDX_BSGLASSINUNITORSUBUNIT_01" modify partition "PW180103" shrink space;
alter index "P1MESADM"."IDX_BSGLASSINUNITORSUBUNIT_01" modify partition "PW180104" shrink space;
alter index "P1MESADM"."IDX_BSGLASSOUTUNITORSUBUNIT_01" modify partition "PW180104" shrink space;
alter index "P1MESADM"."IDX_BSGLASSOUTUNITORSUBUNIT_01" modify partition "PW180103" shrink space;
alter index "P1MESADM"."IDX_BSGLASSOUTUNITORSUBUNIT_01" modify partition "PW180102" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171101" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171102" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171103" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171201" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171202" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "PW180101" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "PW180102" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171203" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171001" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171002" shrink space;
alter index "P1MESADM"."IDX_GLASSINOUTUNITSUBUNIT_01" modify partition "GLASSINOUTUNITSUBUNIT_20171003" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PW180101" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PW180104" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PW180103" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PW180102" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017123" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017113" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017121" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017122" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017111" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017103" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017102" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_2017101" shrink space;
alter index "P1MESADM"."IDX_PRODUCTHISTORY_01" modify partition "PRODUCTHISTORY_201711" shrink space;



alter table "P1RTDADM"."DSPRULETRACEHISTORY_BAK"  enable row movement;
alter table "P1RTDADM"."DSPRULETRACEHISTORY_BAK" modify partition "DSPMESSAGEHISTORY_MAXVALUE" shrink space cascade;
alter table "P1RTDADM"."DSPRULETRACEHISTORY_BAK"  disable row movement;

alter table "P1MESADM"."LOTHISTORY" enable row movement;
alter table "P1MESADM"."LOTHISTORY" modify partition "LOTHISTORY_201801" shrink space cascade;
alter table "P1MESADM"."LOTHISTORY" modify partition "LOTHISTORY_201709" shrink space cascade;
alter table "P1MESADM"."LOTHISTORY" disable row movement;

alter table "P1MESADM"."MACHINEHISTORY"  enable row movement;
alter table "P1MESADM"."MACHINEHISTORY" modify partition "MACHINEHISTORY_201711" shrink space cascade;
alter table "P1MESADM"."MACHINEHISTORY" modify partition "MACHINEHISTORY_201712" shrink space cascade;
alter table "P1MESADM"."MACHINEHISTORY" modify partition "MACHINEHISTORY_201801" shrink space cascade;
alter table "P1MESADM"."MACHINEHISTORY"  disable row movement;




alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" enable row movement;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "PW180101" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "PW180102" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171001" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171002" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171003" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171101" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171102" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171103" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171201" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171202" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" modify partition "GLASSINOUTUNITSUBUNIT_20171203" shrink space cascade;
alter table "P1MESADM"."BSGLASSINOUTUNITORSUBUNITINFO" disable row movement;





alter table "P1MESADM"."BSGLASSINUNITORSUBUNIT" enable row movement;
alter table "P1MESADM"."BSGLASSINUNITORSUBUNIT" modify partition "PW180104" shrink space cascade;
alter table "P1MESADM"."BSGLASSINUNITORSUBUNIT" modify partition "PW180103" shrink space cascade;
alter table "P1MESADM"."BSGLASSINUNITORSUBUNIT" disable row movement;


alter table "P1MESADM"."BSGLASSOUTUNITORSUBUNIT" enable row movement;
alter table "P1MESADM"."BSGLASSOUTUNITORSUBUNIT" modify partition "PW180104" shrink space cascade;
alter table "P1MESADM"."BSGLASSOUTUNITORSUBUNIT" modify partition "PW180103" shrink space cascade;
alter table "P1MESADM"."BSGLASSOUTUNITORSUBUNIT" modify partition "PW180102" shrink space cascade;
alter table "P1MESADM"."BSGLASSOUTUNITORSUBUNIT" disable row movement;

alter table "P1MESADM"."PRODUCTHISTORY" enable row movement;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PW180103" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PW180102" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PW180104" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PW180101" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017123" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017101" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017102" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017103" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017111" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017112" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017113" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017122" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" modify partition "PRODUCTHISTORY_2017121" shrink space cascade;
alter table "P1MESADM"."PRODUCTHISTORY" disable row movement;




alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017122" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017121" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017113" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_201711" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PW180104" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PW180103" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PW180102" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PW180101" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017111" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017103" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017123" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017101" shrink space;
alter index "P1MESADM"."PRODUCTHISTORY_PK" modify partition "PRODUCTHISTORY_2017102" shrink space;
alter index "P1MESADM"."BSOLEDDEFECTCODEDATA_PK" shrink space;
alter index "P1MESADM"."PORTHISTORY_PK" modify partition "PORTHISTORY_201801" shrink space;
alter index "P1MESADM"."PORTHISTORY_PK" modify partition "PORTHISTORY_201712" shrink space;


alter table "P1MESADM"."DURABLEHISTORY" enable row movement;
alter table "P1MESADM"."DURABLEHISTORY" modify partition "PM1801" shrink space cascade;
alter table "P1MESADM"."DURABLEHISTORY" modify partition "DURABLEHISTORY_1711" shrink space cascade;
alter table "P1MESADM"."DURABLEHISTORY" modify partition "DURABLEHISTORY_1712" shrink space cascade;
alter table "P1MESADM"."DURABLEHISTORY" disable row movement;


alter table "P1MESADM"."LOT" enable row movement;
alter table "P1MESADM"."LOT" shrink space cascade;
alter table "P1MESADM"."LOT" disable row movement;

alter table "P1MESADM"."PORTHISTORY" enable row movement;
alter table "P1MESADM"."PORTHISTORY" modify partition "PORTHISTORY_201801" shrink space cascade;
alter table "P1MESADM"."PORTHISTORY" disable row movement;


alter table "P1MESADM"."PRODUCT" enable row movement;
alter table "P1MESADM"."PRODUCT" shrink space cascade;
alter table "P1MESADM"."PRODUCT" disable row movement;


alter table "P1MESADM"."ARCHIVEHISTORY" enable row movement;
alter table "P1MESADM"."ARCHIVEHISTORY" shrink space cascade;
alter table "P1MESADM"."ARCHIVEHISTORY" disable row movement;


CREATE OR REPLACE PROCEDURE PRC_EDS_GLASS_INFO_FOR_TT(PVVI_START_DATE   IN VARCHAR2,
                                                      PVVI_END_DATE     IN VARCHAR2,
                                                      PVVI_TSK_ID       IN VARCHAR2,
                                                      PVVO_RETURN_VALUE OUT VARCHAR2) IS
  --=================================================================================
  --OBJECT NAME : PRC_EDS_GLASS_INFO_FOR_TT
  --OBJECT TYPE : STORED PROCEDURE
  --DESCRIPTION : Glass History Information I/F from ODS to EDS
  --=================================================================================
  --
  --=================================================================================
  --YYYY-MM-DD      DESCRIPTOR       DESCRIPTION
  --2018-08-27      Gxx          Initial Release
  --2018-10-09     HuanWang   增加判断同款产品 连续 LOT 投入情况
  -- 2018-10-15    HuanWang 修改逻辑  PI 、OA 8 台设备 不能按照Product opercode分组，需要按照 ModelType 、 opercode分组
  -- 2019.02.12    HuanWang  删除EDS_GLASS_INFO_FOR_TT表中 60 天前的数据
  -- 2020.12.21    HuanWang  TRUNCATE EDS_GLASS_INFO_FOR_TT
  --=================================================================================
  --
  --=================================================================================
  --                               VARIALBLE DECLARATION
  --=================================================================================
  LVV_EVENT_NAME VARCHAR2(10);
  LVN_ERROR_CNT  NUMBER;
  LVV_MESSAGE    VARCHAR2(1000);
  LVV_ETL        VARCHAR2(10);

  LVV_TOTAL VARCHAR2(100);

  LVV_TABLE1 VARCHAR2(40);

  LVN_TCOUNT1 NUMBER;

  LVV_SP            VARCHAR2(5);
  LVV_PROGRAM       VARCHAR2(50);
  LVV_DURATION      VARCHAR2(50);
  LVV_START_TIMEKEY VARCHAR2(40);
  LVV_END_TIMEKEY   VARCHAR2(40);
  LVV_START_DATE    VARCHAR2(50);
  LVV_END_DATE      VARCHAR2(50);

  L_USER_EXCEPTION EXCEPTION;

  LVD_INTERFACE_TIME DATE;
  LVN_RESTART        NUMBER;
  LVN_GRPCNT         NUMBER;
  LVV_PRODUCT        VARCHAR2(20);
  LVV_MODELTYPE      VARCHAR2(10);
  LVV_OPERCODE       VARCHAR2(10);
  LVV_SQL            VARCHAR2(100);

  CURSOR CUR_ERROR_MONITOR IS
    SELECT NO, ORA FROM ODS_ORA_ERROR_MONITOR;
  --=================================================================================
  --              Get Shift Timekey
  --=================================================================================
  CURSOR CUR_SHIFT_TIMEKEY(LVV_TIMEKEY1 VARCHAR2,
                           LVV_FACTORY1 VARCHAR2,
                           LVV_TIMEKEY2 VARCHAR2,
                           LVV_FACTORY2 VARCHAR2) IS
    SELECT ETLADM.GET_SHIFT_TIMEKEY(LVV_TIMEKEY1) AS FROM_SHIFT_TIMEKEY,
           ETLADM.GET_SHIFT_TIMEKEY(LVV_TIMEKEY2) AS TO_SHIFT_TIMEKEY
      FROM DUAL;
  --=================================================================================
  --=================================================================================
  --                  Glass Cursor
  --=================================================================================
  CURSOR CUR_GLASS IS
    SELECT T1.FACTORY,
           T1.EQP_ID,
           T1.UNIT_ID,
           T1.PRODUCT,
           T1.OPER_CODE,
           T1.LOT_ID,
           T1.GLS_ID,
           T1.EVENT_NAME,
           T1.EVENT_TIME,
           T1.EVENT_TIMEKEY,
           ETLADM.GET_SHIFT_TIMEKEY(T1.EVENT_TIMEKEY) AS SHIFT_TIMEKEY,
           LVD_INTERFACE_TIME AS INTERFACE_TIME,
           0 AS GROUP_ID,
           A.MODELTYPE
      FROM ETLADM.ODS_GLASS_INFO_FOR_TT T1, EDBADM.EDS_PRODUCT@EDB2ETL A
     WHERE A.PRODUCTION_TYPE = 'Production'
       AND T1.FACTORY = A.FACTORY
       AND T1.PRODUCT = A.PRODUCT
    --WHERE EQP_ID = '6LTSP03'
    ;

  -- 计算出每一天工艺的所有设备
  -- CF F6000 工艺添加， 导致EQP 和 UNIT  不是一一对应
  -- 6FPHT% 设备会对应 6FPHT%-EXPO 和  6FPHT%-UNIT 两个UNIT
  CURSOR CUR_EQP IS
    SELECT T.EQP_ID, T.UNIT_ID
      FROM ODS_GLASS_INFO_FOR_TT T
     GROUP BY T.EQP_ID, T.UNIT_ID
     ORDER BY T.EQP_ID ASC;
  --=================================================================================
  --
  --                       SUB PROGRAM : PROCEDURE
  --
  --=================================================================================
  PROCEDURE LOG_TABLE_INSERT IS
    --
  BEGIN
    --
    INSERT INTO ETL_PROCEDURE_HIST
      (NO,
       TASK_ID,
       PROCEDURE_ID,
       EVENT_TIMEKEY,
       EVENT_TIME,
       EVENT_NAME,
       LOG1,
       START_TIME,
       END_TIME,
       PROCESS_TIME,
       PERIOD,
       CNT)
    VALUES
      (ODS_LOG_NO.NEXTVAL,
       PVVI_TSK_ID,
       LVV_PROGRAM,
       TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3'),
       SYSDATE,
       LVV_EVENT_NAME,
       LVV_MESSAGE,
       LVV_START_DATE,
       LVV_END_DATE,
       LVV_DURATION,
       PVVI_START_DATE || ' ~ ' || PVVI_END_DATE,
       TO_NUMBER(LVV_TOTAL));
    --
    COMMIT;
    --
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('LOG TABLE INSERT ERROR : ' || SQLERRM);
  END;
  --=================================================================================
  --
  --=================================================================================
  --
  --                                 MAIN BLOCK
  --
  --=================================================================================
BEGIN

  --=============================================================
  -- Variable Initialization
  --=============================================================
  LVN_RESTART := 5;

  <<GOTO_RESTART>>
  LVV_START_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');

  LVV_TOTAL     := 0;
  LVN_ERROR_CNT := 0;

  LVV_ETL      := 'LOAD';
  LVV_PROGRAM  := 'PRC_EDS_GLASS_INFO_FOR_TT';
  LVV_SP       := '::D::';
  LVV_TABLE1   := 'EDS_GLASS_INFO_FOR_TT';
  LVN_TCOUNT1  := 0;
  LVN_GRPCNT   := 0;
  LVV_DURATION := NULL;

  LVV_START_TIMEKEY := SUBSTR(PVVI_START_DATE, 1, 8) ||
                       SUBSTR(PVVI_START_DATE, 10, 6);
  LVV_END_TIMEKEY   := SUBSTR(PVVI_END_DATE, 1, 8) ||
                       SUBSTR(PVVI_END_DATE, 10, 6);

  SELECT SYSDATE INTO LVD_INTERFACE_TIME FROM DUAL;

  LVV_PRODUCT   := ' '; -- 初始化为空格字符串
  LVV_MODELTYPE := ' ';
  LVV_OPERCODE  := ' ';

  --==============================
  -- EDS_GLASS_INFO_FOR_TT TABLE MERGE
  --==============================
  --
  DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE1 || ' DELETE');
  DECLARE
    LVV_FROM VARCHAR2(40);
    LVV_TO   VARCHAR2(40);
    /*  BEGIN
      -- 删除当天开始和结束时间段之内的数据
      delete from edbadm.EDS_GLASS_INFO_FOR_TT@EDB2ETL
       where event_timekey >= LVV_START_TIMEKEY
         and event_timekey < LVV_END_TIMEKEY;
    EXCEPTION
      when no_data_found then
        ROLLBACK;
    END;
    --
    COMMIT;*/
    --
  
    -- 删除EDS_GLASS_INFO_FOR_TT表中 7 天前的数据
    /* DECLARE
      LVV_DEL_SHIFTTIMEKEY VARCHAR2(20);
    BEGIN
      LVV_DEL_SHIFTTIMEKEY :=  TO_CHAR(SYSDATE-7,'yyyyMMdd') || ' 060000' ;
      delete from edbadm.EDS_GLASS_INFO_FOR_TT@EDB2ETL
        where shift_timekey <= LVV_DEL_SHIFTTIMEKEY ;
    EXCEPTION
      when no_data_found then
        ROLLBACK ;
    END;
    --
    COMMIT;*/
  
  BEGIN
    --DELETE FROM EDS_GLASS_INFO_FOR_TT;
    LVV_SQL := 'BEGIN EDBADM.PRC_TABLE_TRUNC@EDB2ETL(:1); END;';

     EXECUTE IMMEDIATE LVV_SQL USING LVV_TABLE1;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;

  BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM,
                                     LVV_TABLE1 || ' ' || LVV_ETL);
  
    BEGIN
      INSERT INTO EDBADM.EDS_GLASS_INFO_FOR_TT@EDB2ETL
        (FACTORY,
         --eqp_group           ,
         EQP_ID,
         UNIT_ID,
         PRODUCT,
         OPER_CODE,
         LOT_ID,
         GLS_ID,
         EVENT_NAME,
         EVENT_TIME,
         EVENT_TIMEKEY,
         SHIFT_TIMEKEY,
         INTERFACE_TIME,
         GROUP_ID,
         MODELTYPE)
        (SELECT T1.FACTORY,
                T1.EQP_ID,
                T1.UNIT_ID,
                T1.PRODUCT,
                T1.OPER_CODE,
                T1.LOT_ID,
                T1.GLS_ID,
                T1.EVENT_NAME,
                T1.EVENT_TIME,
                T1.EVENT_TIMEKEY,
                EDBADM.GET_SHIFT_TIMEKEY@EDB2ETL(T1.EVENT_TIMEKEY) AS SHIFT_TIMEKEY,
                SYSDATE AS INTERFACE_TIME,
                ROW_NUMBER() OVER(PARTITION BY T1.EQP_ID, T1.UNIT_ID ORDER BY T1.EVENT_TIME) - ROW_NUMBER() OVER(PARTITION BY T1.EQP_ID, T1.UNIT_ID, A.MODELTYPE, T1.OPER_CODE ORDER BY T1.EVENT_TIME) AS GROUP_ID,
                A.MODELTYPE
           FROM ETLADM.ODS_GLASS_INFO_FOR_TT T1,
                EDBADM.EDS_PRODUCT@EDB2ETL   A
          WHERE A.PRODUCTION_TYPE = 'Production'
            AND T1.FACTORY = A.FACTORY
            AND T1.PRODUCT = A.PRODUCT);
    
    EXCEPTION
      WHEN OTHERS THEN
        LVV_MESSAGE := LVV_PROGRAM || ' : ' || LVV_TABLE1 || ' ' || LVV_ETL ||
                       ' ERROR! => ' || SUBSTR(SQLERRM, 1, 300);
        RAISE L_USER_EXCEPTION;
    END;
  
    LVN_TCOUNT1 := LVN_TCOUNT1 + 1;
  
  END;

  COMMIT;
  --

  --  找出每个设备每天的流片数 ， 从小到大排序并根据product 、opercode 进行分组  确认是否是连续的产品投入
  --  统一采用MODELTYPE 来进行同组产品的判断 , 可以涵盖Array、CF 和Cell 几台特殊的设备所有的情况
  /* BEGIN
  DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE1 || ' ' || LVV_ETL);
    FOR  C1  IN  CUR_EQP LOOP
       LVN_GRPCNT := 0 ;   -- 每一台设备开始都要初始化为 0
       LVV_PRODUCT := ' ' ;  -- 初始化为空格字符串
       LVV_MODELTYPE := ' ' ; 
       LVV_OPERCODE := ' ' ;
       FOR  C2  IN  (SELECT 
          ROW_NUMBER() OVER(ORDER BY EVENT_TIME) RN,
          T1.FACTORY ,
          --T1.EQP_GROUP ,
          T1.EQP_ID,
          T1.UNIT_ID ,
          T1.PRODUCT,
          T1.OPER_CODE,
          T1.LOT_ID ,
          T1.GLS_ID,
          T1.EVENT_NAME,
          T1.EVENT_TIME,
          T1.EVENT_TIMEKEY ,
          T1.SHIFT_TIMEKEY ,
          T1.INTERFACE_TIME ,
          T1.GROUP_ID ,
          T1.MODELTYPE
     FROM EDBADM.EDS_GLASS_INFO_FOR_TT@EDB2ETL T1 WHERE T1.EQP_ID = C1.EQP_ID
         -- AND T1.UNIT_ID = C1.UNIT_ID  -- 添加UNIT 对应， 防止设备ID 对应的瓶颈UNIT不唯一
         AND  T1.EVENT_TIMEKEY >= LVV_START_TIMEKEY
        AND T1.EVENT_TIMEKEY < LVV_END_TIMEKEY ORDER BY T1.EVENT_TIME ) LOOP
           IF (LVV_MODELTYPE <> C2.MODELTYPE OR  LVV_OPERCODE <> C2.OPER_CODE) THEN 
             LVN_GRPCNT := LVN_GRPCNT + 1 ;
            END IF ;
            LVV_MODELTYPE :=  C2.MODELTYPE ;
            LVV_OPERCODE := C2.OPER_CODE ;
       
       BEGIN 
       MERGE INTO EDBADM.EDS_GLASS_INFO_FOR_TT@EDB2ETL T1
       USING (SELECT  C2.FACTORY   FACTORY,
                             --C2.EQP_GROUP EQP_GROUP ,
                             C2.EQP_ID   EQP_ID,
                             C2.UNIT_ID UNIT_ID ,
                             C2.PRODUCT  PRODUCT, 
                             C2.OPER_CODE  OPER_CODE , 
                             C2.LOT_ID LOT_ID ,
                             C2.GLS_ID GLS_ID , 
                             C2.EVENT_NAME EVENT_NAME,
                             C2.EVENT_TIME EVENT_TIME,
                             C2.EVENT_TIMEKEY   EVENT_TIMEKEY ,
                             C2.SHIFT_TIMEKEY  SHIFT_TIMEKEY,
                             LVD_INTERFACE_TIME  INTERFACE_TIME ,
                             LVN_GRPCNT GROUP_ID ,
                             C2.MODELTYPE   MODELTYPE
                FROM DUAL) T2
       on (T1.FACTORY = T2.FACTORY AND T1.EQP_ID = T2.EQP_ID AND T1.PRODUCT = T2.PRODUCT AND T1.OPER_CODE = T2.OPER_CODE AND T1.GLS_ID = T2.GLS_ID AND T1.EVENT_TIMEKEY = T2.EVENT_TIMEKEY
       ) -- AND T1.UNIT_ID = T2.UNIT_ID 
       WHEN MATCHED THEN
         UPDATE
            -- 更新Group_ID
            SET T1.GROUP_ID = T2.GROUP_ID 
            --, T1.DATE_TIMEKEY = T2.LVV_DATE_TIMEKEY
          --WHERE T1.GROUP_ID = 0 
       WHEN NOT MATCHED THEN
         INSERT
           ( FACTORY,
                             --EQP_GROUP ,
                             EQP_ID,
                             UNIT_ID ,
                             PRODUCT, 
                             OPER_CODE , 
                             LOT_ID ,
                             GLS_ID , 
                             EVENT_NAME,
                             EVENT_TIME,
                             EVENT_TIMEKEY ,
                             SHIFT_TIMEKEY,
                              INTERFACE_TIME ,
                             GROUP_ID ,
                             MODELTYPE )
         VALUES
           (
           T2.FACTORY,
                             --T2.EQP_GROUP ,
                             T2.EQP_ID,
                             T2.UNIT_ID ,
                             T2.PRODUCT, 
                             T2.OPER_CODE , 
                             T2.LOT_ID ,
                             T2.GLS_ID , 
                             T2.EVENT_NAME,
                             T2.EVENT_TIME,
                             T2.EVENT_TIMEKEY ,
                             T2.SHIFT_TIMEKEY,
                             T2.INTERFACE_TIME ,
                             T2.GROUP_ID ,
                             T2.MODELTYPE
           );
          EXCEPTION
                         WHEN OTHERS
                         THEN
                            LVV_MESSAGE := 'Insert EDS_GLASS_INFO_FOR_TT ST ERROR : ' || SQLERRM;
                            RAISE L_USER_EXCEPTION;         
           END;
    END LOOP;
    COMMIT;
  END LOOP ;
  END;*/

  --=============================================================
  -- LOAD COUNT CALCULATION
  --=============================================================

  BEGIN
    SELECT COUNT(*) INTO LVN_TCOUNT1 FROM ETLADM.ODS_GLASS_INFO_FOR_TT T1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      LVN_TCOUNT1 := 0;
  END;
  --=================================================================================
  --
  --=================================================================================

  LVV_END_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
  LVV_TOTAL    := TO_CHAR(LVN_TCOUNT1);
  LVV_DURATION := TO_CHAR((TO_DATE(LVV_END_DATE, 'YYYY-MM-DD HH24:MI:SS') -
                          TO_DATE(LVV_START_DATE, 'YYYY-MM-DD HH24:MI:SS')) *
                          86400);

  PVVO_RETURN_VALUE := SUBSTR(LVV_ETL, 1, 1) || LVV_SP ||
                       LTRIM(TO_CHAR(LVV_TOTAL, '0000000000'), ' ') ||
                       LVV_SP || LVV_PROGRAM || LVV_SP || LVV_DURATION ||
                       LVV_SP || LVV_TABLE1 || LVV_SP ||
                       TO_CHAR(LVN_TCOUNT1) || LVV_SP;

  LVV_EVENT_NAME := 'END';
  LVV_MESSAGE    := LVV_PROGRAM || ' : ' || LVV_TABLE1 || ' ' || LVV_ETL ||
                    ' COMPLETE!';

  LOG_TABLE_INSERT;

  DBMS_APPLICATION_INFO.SET_MODULE('', '');

EXCEPTION
  WHEN L_USER_EXCEPTION THEN
    ROLLBACK;
  
    LVV_EVENT_NAME := 'ERROR';
    LVV_END_DATE   := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
    LVV_DURATION   := TO_CHAR((TO_DATE(LVV_END_DATE,
                                       'YYYY-MM-DD HH24:MI:SS') -
                              TO_DATE(LVV_START_DATE,
                                       'YYYY-MM-DD HH24:MI:SS')) * 86400);
  
    LOG_TABLE_INSERT;
  
    DBMS_OUTPUT.PUT_LINE(LVV_MESSAGE);
  
    DBMS_APPLICATION_INFO.SET_MODULE('', '');
  
    RAISE_APPLICATION_ERROR(-20200, LVV_MESSAGE);
  
  WHEN OTHERS THEN
    ROLLBACK;
  
    LVV_EVENT_NAME := 'ERROR';
    LVV_END_DATE   := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
    LVV_DURATION   := TO_CHAR((TO_DATE(LVV_END_DATE,
                                       'YYYY-MM-DD HH24:MI:SS') -
                              TO_DATE(LVV_START_DATE,
                                       'YYYY-MM-DD HH24:MI:SS')) * 86400);
  
    LVV_MESSAGE := LVV_PROGRAM || ' : ' || 'ORACLE ERROR => ' ||
                   SUBSTR(SQLERRM, 1, 300);
  
    LOG_TABLE_INSERT;
  
    DBMS_OUTPUT.PUT_LINE(LVV_MESSAGE);
  
    DBMS_APPLICATION_INFO.SET_MODULE('', '');
  
    RAISE_APPLICATION_ERROR(-20200, LVV_MESSAGE);
  
END;
--=================================================================================
/

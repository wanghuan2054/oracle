CREATE OR REPLACE PROCEDURE PRC_EDS_EQP_MULTISTATE_HIST
   (PVVI_START_DATE IN VARCHAR2, PVVI_END_DATE IN VARCHAR2,
   PVVI_TSK_ID IN VARCHAR2, PVVO_RETURN_VALUE OUT VARCHAR2)
   IS
--=================================================================================
--OBJECT NAME :PRC_EDS_EQP_MULTISTATE_HIST
--OBJECT TYPE : STORED Machine  State
--DESCRIPTION : Machine Second\Third State  Information I/F from ODS to EDS
--=================================================================================
--
--=================================================================================
--YYYY-MM-DD      DESCRIPTOR       DESCRIPTION
--2018-12-24          HuanWang          Initial Release

--=================================================================================
--
--=================================================================================
--                               VARIALBLE DECLARATION
--=================================================================================
  LVV_EVENT_NAME          VARCHAR2(10);
  LVN_ERROR_CNT           NUMBER;
  LVV_MESSAGE             VARCHAR2(1000);
  LVV_ETL                 VARCHAR2(10);
  LVV_TOTAL               VARCHAR2(100);
  LVV_TABLE1              VARCHAR2(40);
  LVN_TCOUNT1             NUMBER;

  LVV_SP                  VARCHAR2(5);
  LVV_PROGRAM             VARCHAR2(50);
  LVV_DURATION            VARCHAR2(50);
  LVV_START_TIMEKEY       VARCHAR2(40);
  LVV_END_TIMEKEY         VARCHAR2(40);
  LVV_START_TIMEKEY1       VARCHAR2(40);
  LVV_END_TIMEKEY1         VARCHAR2(40);
  LVV_START_DATE          VARCHAR2(50);
  LVV_END_DATE            VARCHAR2(50);
  L_USER_EXCEPTION        EXCEPTION;

  LVD_INTERFACE_TIME      DATE;
--=================================================================================
  --=================================================================================
   --     EDS_EQP_MULTISTATE_HIST  Table
   --     获取指定时间内设备状态发生变化的设备名称
   --=================================================================================
  CURSOR CUR_STATEFUL_EQP
     IS
          SELECT DISTINCT MACHINENAME AS EQP_ID
            FROM ODS_EQP_MULTISTATE_HIST T
           ORDER BY MACHINENAME ;

   --=================================================================================
   --     获取指定时间内设备状态没有变更的设备名称 ， 在IE 给定的设备范围内寻找
   --=================================================================================
  CURSOR CUR_STATELESS_EQP
     IS
            (select distinct machinename as EQP_ID from EDBADM.EDS_MACHINESPEC@EDB2ETL where machinename IN  ('6LPCV01', '6LPCV02', '6LPTK02', '6LPTK03', '6LPTK04',
                   '6LPTK05', '6LPTK06', '6LPTK07', '6LPTK08', '6LPTK09','6LPTK10', '6LPCV21', '6LPTK22', '6LPTK23', '6LPTK24',
                   '6LPTK25', '6LPTK26', '6LPTK27', '6LPTK28', '6LPTK29', '6LPTK30', '6LMPT01', '6LEWE01', '6LEWE02', '6LEWE03',
                   '6LEWE04', '6LEWE05', '6LEWS01', '6LEWS02', '6LEWS03','6LEWS04', '6LEWS05', '6LEWS06', '6LEWS07', '6LTIC01',
                   '6LTPC01', '6LTPC02', '6LTPC03', '6LTPC04', '6LMPT21','6LEWE21', '6LEWE22', '6LEWE23', '6LEWE24', '6LEWE25','6LEWS21', '6LEWS22', '6LEWS23', '6LEWS25', '6LEWS26','6LTIC21', '6LTPC21', '6LTPC22', '6LTPC23', '6LTPC24',
                   '6LEDE01', '6LEDE02', '6LEDE03', '6LEDE04', '6LEDE05', '6LEDE06', '6LEDE07', '6LEDE08', '6LEDS01', '6LEDS02',
                   '6LEDS03', '6LEDS04', '6LEDE21', '6LEDE22', '6LEDE23','6LEDE24', '6LEDE25', '6LEDE26', '6LEDS21', '6LEDS22','6LEDS23', '6LEDS24', '6LTEL01', '6LTEL02', '6LTEL03','6LTEL04', '6LTEL05', '6LTEL21', '6LTEL22', '6LTEL23', '6LTEL24', '6LTEL25', '6LTEL26', '6LTIM01', '6LTIM02', '6LTIM03', '6LTIM04', '6LTVT01', '6LTVT02', '6LTIM21','6LTIM22', '6LTIM23', '6LTIM24', '6LTVT21', '6LTDH01','6LTDH02', '6LTHD01', '6LTHD02', '6LTPE01', '6LTPE02',
                   '6LTPE03', '6LTPE04', '6LTPE05', '6LTDH21', '6LTDH22', '6LTHD21', '6LTHD22', '6LTPE21', '6LTPE22', '6LTPE23', '6LTPE24', '6LTPE25', '6LTPE26', '6LTSP01', '6LTSP02','6LTSP03', '6LTSP04', '6LTSP05', '6LTSP06', '6LTAN01','6LTSP21', '6LTSP22', '6LTSP23', '6LTSP24', '6LTSP25',
                   '6LTSP26', '6LTAN21', '6LTAN22', '6FPHT01', '6FPHT02', '6FPHT03', '6FPHT04', '6FPHT05', '6FPHT21', '6FPHT22','6FPHT23', '6FPHT24', '6FPHT25', '6CIPI01', '6CIPI02', '6CIPI03', '6CIPI04', '6CIOA01', '6CIOA02', '6CIMC01','6CIOA03', '6CIOA04', '6CCSB01', '6CCSB02', '6CCQC01',
                   '6CCQC02', '6CCSB03', '6CCSB04', '6CXQI01', '6CXQI02','6CXQI03', '6CXQI04', '6CIAS01', '6CIAS02', '6CIAS03','6CIAS04') )
           minus
           (SELECT DISTINCT MACHINENAME as EQP_ID FROM ODS_EQP_MULTISTATE_HIST) ORDER BY EQP_ID ;
   --=================================================================================
   --       查询指定时间内 factory  eqp 别的最新设备二级状态
   --=================================================================================
   --
   CURSOR CUR_MAINEQP_PRESTATE (
      lvv_start_timekey    VARCHAR2,
      lvv_end_timekey      VARCHAR2 , lvv_eqp varchar2)
   IS
              --  最新状态查找  EDS_EQP_MULTISTATE_HIST 表取前班次设备最后一条状态
              SELECT  FACTORY ,
                   MACHINESTATENAME,
                   REASONCODE,
                   EVENTNAME,
                   REASONCODETYPE,
                   EVENTUSER,
                   EVENTCOMMENT
              FROM (SELECT 
                           NVL (T1.FACTORY, '*')  AS FACTORY,
                           T1.EQP_STATE AS  MACHINESTATENAME,
                           T1.EQP_STATE_CODE AS REASONCODE,
                           T1.EVENT_NAME AS EVENTNAME,
                           T1.EQP_STATE_CODE_TYPE AS REASONCODETYPE,
                           T1.EVENT_USER_ID AS  EVENTUSER,
                           T1.EVENT_COMMENT AS EVENTCOMMENT
                      FROM EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL T1
                     WHERE T1.EQP_STATE_CODE_TYPE = 'EQPStatus'
                       AND T1.EQP_STATE_CODE IS NOT NULL
                       AND T1.EQP_ID = lvv_eqp -- '6CCLS01'
                       AND T1.EVENT_TIMEKEY >= lvv_start_timekey --'20181222060000'
                       AND T1.EVENT_TIMEKEY < lvv_end_timekey --'20181222180000' -- '20181208060000'
                     ORDER BY T1.EVENT_TIMEKEY DESC)
             WHERE ROWNUM = 1;
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
   VALUES(ODS_LOG_NO.NEXTVAL,
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
    LVV_TOTAL  := 0;
    LVN_ERROR_CNT      := 0;

    LVV_ETL       := 'LOAD';
    LVV_PROGRAM   := 'PRC_EDS_EQP_MULTISTATE_HIST';
    LVV_SP        := '::D::';
    LVV_TABLE1    := 'EDS_EQP_MULTISTATE_HIST';
    LVN_TCOUNT1   := 0;

    LVV_DURATION  := null;

    LVV_START_TIMEKEY := SUBSTR(PVVI_START_DATE, 1, 8) || SUBSTR(PVVI_START_DATE, 10, 6) ;
    LVV_END_TIMEKEY   := SUBSTR(PVVI_END_DATE, 1, 8) || SUBSTR(PVVI_END_DATE, 10, 6) ;

    SELECT SYSDATE INTO LVD_INTERFACE_TIME FROM DUAL;

   --==============================
   -- EDS_EQP_MULTISTATE_HIST TABLE DELETE
   --==============================
   DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE1 || ' DELETE');
   BEGIN
      DELETE EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL
       WHERE EVENT_TIMEKEY >= LVV_START_TIMEKEY
       AND EVENT_TIMEKEY < LVV_END_TIMEKEY   ;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         ROLLBACK ;
   END;
   COMMIT;
--
   --==============================
   -- EDS_EQP_MULTISTATE_HIST TABLE INSERT
   --==============================
 DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE1 || ' ' || LVV_ETL);
 BEGIN 
 FOR  C1 IN CUR_STATEFUL_EQP   LOOP 
    BEGIN
       INSERT INTO EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL
                                        (     SITE   ,
                                              FACTORY     ,
                                              EQP_ID           ,
                                              EVENT_TIMEKEY    ,
                                              EVENT_SHIFT_TIMEKEY  ,
                                              EQP_STATE         ,
                                              START_TIME      ,
                                             END_TIME            ,
                                              START_TIMEKEY       ,
                                              END_TIMEKEY    ,
                                              EVENT_TIME       ,
                                              EVENT_NAME        ,
                                              EVENT_USER_ID   ,
                                              EVENT_COMMENT     ,
                                              EQP_MODE         ,
                                              EVENT_CNT    ,
                                              EQP_STATE_CODE_TYPE ,
                                              EQP_STATE_CODE  )
                                         ( 
                                               SELECT 'B6' AS SITE,
                                                      T.FACTORY,
                                                      T.MACHINENAME AS EQP_ID,
                                                      T.TIMEKEY AS EVENT_TIMEKEY,
                                                      EDBADM.GET_SHIFT_TIMEKEY@EDB2ETL(T.TIMEKEY) AS EVENT_SHIFT_TIMEKEY,
                                                      T.MACHINESTATENAME AS EQP_STATE,
                                                      TO_DATE(SUBSTR(T.TIMEKEY, 1, 14), 'yyyyMMdd HH24MISS') AS START_TIME,
                                                      TO_DATE(SUBSTR(LEAD(T.TIMEKEY)
                                                                     OVER(PARTITION BY T.FACTORY,
                                                                          t.MACHINENAME ORDER BY T.TIMEKEY),
                                                                     1,
                                                                     14),
                                                              'yyyyMMdd HH24MISS') AS END_TIME,
                                                      T.TIMEKEY AS START_TIMEKEY,
                                                      LEAD(T.TIMEKEY) OVER(PARTITION BY T.FACTORY, t.MACHINENAME ORDER BY T.TIMEKEY) AS END_TIMEKEY,
                                                      T.EVENTTIME,
                                                      T.EVENTNAME,
                                                      T.EVENTUSER,
                                                      T.EVENTCOMMENT,
                                                      NULL AS EQP_MODE,
                                                      0 AS EVENT_CNT,
                                                      T.REASONCODETYPE AS EQP_STATE_CODE_TYPE ,
                                                      T.REASONCODE AS EQP_STATE_CODE
                                                 FROM ODS_EQP_MULTISTATE_HIST T
                                                WHERE T.MACHINENAME =  C1.EQP_ID   --' 6LPTK29'
                                                    AND T.OLDREASONCODE <> T.REASONCODE )    -- 去除二级状态前后无变化的数据
                                                   ;--ORDER BY T.TIMEKEY ;
    EXCEPTION
        WHEN OTHERS
        THEN
            LVV_MESSAGE  := LVV_PROGRAM || ' : '
                                        || LVV_TABLE1 || ' '
                                        || LVV_ETL || ' ERROR! => '
                                        || SUBSTR(SQLERRM, 1, 300);
            RAISE L_USER_EXCEPTION;
    END;
    COMMIT;
    END LOOP ;
    END ;
    
       --==============================
   --   EDS_EQP_MULTISTATE_HIST TABLE Update
    -- 查找最后一条设备状态，并将ENDTIME 和ENDTIMEKEY 补充为 LVV_END_TIMEKEY 结束时间 
   --==============================
   DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE1 || ' ' || LVV_ETL);

   BEGIN
     UPDATE EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL
        SET END_TIMEKEY = LVV_END_TIMEKEY  ,
               END_TIME      = TO_DATE(LVV_END_TIMEKEY,'yyyyMMdd hh24miss')
      WHERE END_TIMEKEY IS NULL 
             AND EVENT_TIMEKEY >= LVV_START_TIMEKEY
             AND EVENT_TIMEKEY < LVV_END_TIMEKEY   ;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       lvv_message := 'EDS_EQP_MULTISTATE_HIST: END_TIME END_TIMEKEY , UPDATE ERROR! => ' ||
                      SQLERRM;
       RAISE l_user_exception;
     
   END;
   COMMIT;

       --==============================
   --   EDS_EQP_MULTISTATE_HIST TABLE INSERT
    --  指定时间内没有状态变化的设备，找到离指定时间最近的一条设备状态
    -- 并将指定时间的开始-结束 ，更新为该设备的该状态延续整个班次(班次开始-班次结束) 
   --==============================
 DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE1 || ' ' || LVV_ETL);
 BEGIN 
/*      LVV_START_TIMEKEY1 := TO_CHAR(TO_DATE(LVV_START_TIMEKEY,'yyyyMMdd hh24miss')-23,'yyyyMMddhh24miss') ;
      LVV_END_TIMEKEY1   := LVV_START_TIMEKEY ;*/
      --  去 MULTIState_HIST 历史表， 向前推一个班次 0.5  天 寻找缺失设备的最后一条切换状态
      LVV_START_TIMEKEY1 := TO_CHAR(TO_DATE(LVV_START_TIMEKEY,'yyyyMMdd hh24miss')-0.5,'yyyyMMddhh24miss') ;
      LVV_END_TIMEKEY1   := LVV_START_TIMEKEY ;
     FOR  C1 IN CUR_STATELESS_EQP   LOOP 
             FOR c2  IN CUR_MAINEQP_PRESTATE(LVV_START_TIMEKEY1, LVV_END_TIMEKEY1 ,  C1.EQP_ID) loop 
          -- 循环找到最近最新设备状态信息 INSERT 整条记录到 ODS_EQP_MULTISTATE_HIST表中
              BEGIN
                 INSERT INTO EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL
                                                  (   SITE   ,
                                                      FACTORY     ,
                                                      EQP_ID           ,
                                                      EVENT_TIMEKEY    ,
                                                      EVENT_SHIFT_TIMEKEY  ,
                                                      EQP_STATE         ,
                                                      START_TIME      ,
                                                      END_TIME            ,
                                                      START_TIMEKEY       ,
                                                      END_TIMEKEY    ,
                                                      EVENT_TIME       ,
                                                      EVENT_NAME        ,
                                                      EVENT_USER_ID   ,
                                                      EVENT_COMMENT     ,
                                                      EQP_MODE         ,
                                                      EVENT_CNT    ,
                                                      EQP_STATE_CODE_TYPE ,
                                                      EQP_STATE_CODE  )
                                                  values (
                                                  'B6'  ,
                                                   C2.FACTORY,
                                                   C1.EQP_ID,
                                                   LVV_START_TIMEKEY,
                                                   EDBADM.GET_SHIFT_TIMEKEY@EDB2ETL(LVV_START_TIMEKEY) ,
                                                   c2.MACHINESTATENAME ,
                                                   To_date(LVV_START_TIMEKEY,'yyyyMMdd hh24miss'),
                                                   To_date(LVV_END_TIMEKEY,'yyyyMMdd hh24miss'),
                                                   LVV_START_TIMEKEY ,
                                                   LVV_END_TIMEKEY ,
                                                   To_date(LVV_START_TIMEKEY,'yyyyMMdd hh24miss'),
                                                   c2.EVENTNAME,
                                                   c2.EVENTUSER,
                                                   c2.EVENTCOMMENT,
                                                   NULL ,
                                                   0 ,
                                                   c2.REASONCODETYPE,
                                                   c2.REASONCODE ) ;

              EXCEPTION
                  WHEN OTHERS
                  THEN
                      LVV_MESSAGE  := LVV_PROGRAM || ' : '
                                                  || LVV_TABLE1 || ' '
                                                  || LVV_ETL || ' ERROR! => '
                                                  || SUBSTR(SQLERRM, 1, 300);
                      RAISE L_USER_EXCEPTION;
              END;
               
            END LOOP;
     END LOOP ;
     COMMIT ;
 END ;
       
 
     -- 对EVENT_CNT 字段 Update
     -- 若开始时间  StartTimekey  等于开始班次运行时间 LVV_START_TIMEKEY 
     BEGIN
                    UPDATE EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL
                       SET  EVENT_CNT = 1
                     WHERE   START_TIMEKEY <> LVV_START_TIMEKEY
                           AND EVENT_TIMEKEY >= LVV_START_TIMEKEY
                           AND EVENT_TIMEKEY < LVV_END_TIMEKEY   ;
                 EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                       ROLLBACK ;
                    WHEN OTHERS
                    THEN
                       lvv_message := 'PRC_EDS_EQP_MULTISTATE_HIST: EVENT_CNT , UPDATE ERROR! => ' || SQLERRM;
                       RAISE l_user_exception;
       END;
       COMMIT;

   
    --=============================================================
    -- LOAD COUNT CALCULATION
    --=============================================================

    BEGIN
        SELECT  COUNT ( * ) INTO LVN_TCOUNT1 FROM EDBADM.EDS_EQP_MULTISTATE_HIST@EDB2ETL 
        WHERE  EVENT_TIMEKEY >= LVV_START_TIMEKEY
               AND EVENT_TIMEKEY < LVV_END_TIMEKEY ;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            LVN_TCOUNT1  := 0;
    END;

--=================================================================================
--
--=================================================================================
    LVV_END_DATE  := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
    LVV_TOTAL     := TO_CHAR(  LVN_TCOUNT1
                            );
    LVV_DURATION  := TO_CHAR( (TO_DATE(LVV_END_DATE, 'YYYY-MM-DD HH24:MI:SS')
                             - TO_DATE(LVV_START_DATE, 'YYYY-MM-DD HH24:MI:SS'))
                             * 86400);

    PVVO_RETURN_VALUE := SUBSTR(LVV_ETL, 1, 1)
                        || LVV_SP
                        || LTRIM(TO_CHAR(LVV_TOTAL,'0000000000'), ' ')
                        || LVV_SP
                        || LVV_PROGRAM
                        || LVV_SP
                        || LVV_DURATION
                       || LVV_SP
                       || LVV_TABLE1
                       || LVV_SP     
                       || LVN_TCOUNT1 ; 

    LVV_EVENT_NAME   := 'END';
    LVV_MESSAGE  := LVV_PROGRAM || ' : '
                                || LVV_TABLE1 || ' '
                                || LVV_ETL || ' COMPLETE!';

    LOG_TABLE_INSERT;

    DBMS_APPLICATION_INFO.SET_MODULE('', '');


EXCEPTION
    WHEN L_USER_EXCEPTION THEN
        ROLLBACK;

        LVV_EVENT_NAME   := 'ERROR';
        LVV_END_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
        LVV_DURATION  := TO_CHAR( (TO_DATE(LVV_END_DATE, 'YYYY-MM-DD HH24:MI:SS')
                                 - TO_DATE(LVV_START_DATE, 'YYYY-MM-DD HH24:MI:SS'))
                                 * 86400);

        LOG_TABLE_INSERT;

        DBMS_OUTPUT.PUT_LINE(LVV_MESSAGE);

        DBMS_APPLICATION_INFO.SET_MODULE('', '');

        RAISE_APPLICATION_ERROR (-20200, LVV_MESSAGE);

    WHEN OTHERS THEN
        ROLLBACK;

        LVV_EVENT_NAME   := 'ERROR';
        LVV_END_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
        LVV_DURATION  := TO_CHAR( (TO_DATE(LVV_END_DATE, 'YYYY-MM-DD HH24:MI:SS')
                                 - TO_DATE(LVV_START_DATE, 'YYYY-MM-DD HH24:MI:SS'))
                                 * 86400);

        LVV_MESSAGE  := LVV_PROGRAM || ' : ' || 'ORACLE ERROR => '
                                             || SUBSTR(SQLERRM, 1, 300);

        LOG_TABLE_INSERT;

        DBMS_OUTPUT.PUT_LINE(LVV_MESSAGE);

        DBMS_APPLICATION_INFO.SET_MODULE('', '');

        RAISE_APPLICATION_ERROR (-20200, LVV_MESSAGE);



end;
--=================================================================================
/

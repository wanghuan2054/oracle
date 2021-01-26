CREATE OR REPLACE PROCEDURE PRC_EDS_EQP_MULTISTATE_RATE (
   pvvi_start_date     IN     VARCHAR2,
   pvvi_end_date       IN     VARCHAR2,
   pvvi_tsk_id         IN     VARCHAR2,
   pvvo_return_value      OUT VARCHAR2)
IS
   --=================================================================================
   --OBJECT NAME : prc_EDS_EQP_MULTISTATE_RATE
   --OBJECT TYPE : STORED PROCEDURE
   --DESCRIPTION : Equipment Status Change Summary Information I/F from EDS to EDS
   --=================================================================================
   --
   --=================================================================================
   --YYYY-MM-DD      DESCRIPTOR       DESCRIPTION
   --2018-12-26           HuanWang       Initial Release
   --=================================================================================
   --
   --=================================================================================
   --                               VARIALBLE DECLARATION
   --=================================================================================
   --
   l_user_exception     EXCEPTION;
   LVV_ETL              VARCHAR2 (15) ;
   lvv_message          VARCHAR2 (500);
   lvv_start_date       VARCHAR2 (40);
   lvv_end_date         VARCHAR2 (40);
   lvv_event_name       VARCHAR2 (10);
   lvn_error_cnt        NUMBER;
   --
   lvn_count1           NUMBER;
   lvv_total            VARCHAR2 (100);
   lvd_interface_time   DATE;

   lvv_table1           VARCHAR2 (40);
   lvn_tcount1          NUMBER;
   lvv_sp               VARCHAR2 (5);
   lvv_program          VARCHAR2 (50);
   lvv_duration         VARCHAR2 (50);
   lvn_eqp_count        NUMBER;
   --
   lvv_ped_shift        VARCHAR2 (40);
   lvv_psd_shift        VARCHAR2 (40);
   
   --  MES 中 ReasonCode 中二三级状态存放在一个字段
   -- 根据 ReasonCode 即 EQP_STATE_CODE 字段，在基准表查找二级以及对应的三级状态
   CURSOR CUR_EQP_STANDARD_STATE( lvv_eqp_state_code varchar2 )
   IS 
       SELECT DISTINCT SECOND_LEVEL_STATE , THIRD_LEVEL_STATE
         FROM EDBADM.EDS_EQP_STANDARD_STATE@EDB2ETL T
        WHERE T.THIRD_LEVEL_STATE = LVV_EQP_STATE_CODE ;
    
   --  查询一个班次的所有数据  , 只筛选出EDS_EQP_STANDARD_STATE 表中的所有三级状态
      CURSOR CUR_EQP_RATE
   IS 
         SELECT T.FACTORY,
                T.EQP_ID,
                T.SHIFT_TIMEKEY,
                T.EQP_STATE,
                T.EQP_STATE_CODE
           FROM EDBADM.EDS_EQP_MULTISTATE_RATE@EDB2ETL T
          WHERE T.SHIFT_TIMEKEY = LVV_PSD_SHIFT   -- '20181220 060000' 
            AND T.EQP_STATE_CODE IN
                (SELECT DISTINCT THIRD_LEVEL_STATE
                   FROM EDBADM.EDS_EQP_STANDARD_STATE@EDB2ETL T
                  WHERE T.THIRD_LEVEL_STATE IS NOT NULL);
   --=================================================================================
   --
   --=================================================================================
   --
   --                       SUB PROGRAM : PROCEDURE
   --
   --=================================================================================
   PROCEDURE log_table_insert
   IS
   BEGIN
      INSERT INTO etl_procedure_hist (
                     no,
                     task_id,
                     procedure_id,
                     event_timekey,
                     event_time,
                     event_name,
                     log1,
                     start_time,
                     end_time,
                     process_time,
                     period,
                     cnt)
           VALUES (
                     ods_log_no.NEXTVAL,
                     pvvi_tsk_id,
                     lvv_program,
                     TO_CHAR (SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3'),
                     SYSDATE,
                     lvv_event_name,
                     lvv_message,
                     lvv_start_date,
                     lvv_end_date,
                     lvv_duration,
                     pvvi_start_date || ' ~ ' || pvvi_end_date,
                     TO_NUMBER (lvv_total));

      --
      COMMIT;
   --
   EXCEPTION
      WHEN OTHERS
      THEN
         DBMS_OUTPUT.put_line ('LOG TABLE INSERT ERROR : ' || SQLERRM);
   END;
--=================================================================================
--
--=================================================================================
--
--                                 MAIN BLOCK
--
--=================================================================================
BEGIN
   --
   DBMS_APPLICATION_INFO.set_module ('PRC_EDS_EQP_MULTISTATE_RATE', 'MAIN BLOCK');
   --
   lvv_start_date := TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
   --
   --
   --==========================
   -- VARIABLE INITIALIZATION
   --==========================
   lvv_total := NULL;
   LVV_ETL := 'LOAD';
   lvv_program := 'prc_EDS_EQP_MULTISTATE_RATE';

   lvn_error_cnt := 0;

   lvv_sp := '::D::';
   lvv_table1 := 'EDS_EQP_MULTISTATE_RATE';
   lvn_tcount1 := 0;
   lvv_duration := NULL;
   lvn_eqp_count := 0;

   --

   BEGIN
      SELECT SYSDATE INTO lvd_interface_time FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : LVD_INTERFACE_TIME SELECT ERROR! => ' || SQLERRM;
         DBMS_OUTPUT.put_line ('prc_EDS_EQP_MULTISTATE_RATE : LVD_INTERFACE_TIME SELECT ERROR! => ' || SQLERRM);
         RAISE l_user_exception;
   END;

   --
   --
   BEGIN
      lvn_count1 := 0;
      BEGIN
         lvv_psd_shift := get_shift_time (pvvi_start_date,'', 'C', '15');
         lvv_ped_shift := get_shift_time (pvvi_end_date, '', 'C','15');
      EXCEPTION
         WHEN OTHERS
         THEN
            lvv_message := 'PRC_EDS_EQP_MULTISTATE_RATE : lvv_psd_shift lvv_ped_shift SELECT ERROR! => ' || SQLERRM;
            RAISE l_user_exception;
      END;
     
    IF pvvi_start_date < lvv_ped_shift
      THEN
         BEGIN
            lvv_psd_shift :=get_shift_time (pvvi_start_date,'', 'C', '15');
         EXCEPTION
            WHEN OTHERS
            THEN
               lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : lvv_ped_shift SELECT ERROR! => ' || SQLERRM;
               RAISE l_user_exception;
         END;

         BEGIN
            DELETE EDBADM.EDS_EQP_MULTISTATE_RATE@edb2etl
             WHERE shift_timekey = lvv_psd_shift;
         EXCEPTION
            WHEN OTHERS
            THEN
               lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : EDS_EQP_MULTISTATE_RATE@edb2etl DELETE ERROR! => ' || SQLERRM;
               RAISE l_user_exception;
         END;

         LOOP
            EXIT WHEN lvv_psd_shift >= lvv_ped_shift;
            --
            BEGIN
               --
               DBMS_APPLICATION_INFO.set_module ('prc_EDS_EQP_MULTISTATE_RATE', 'INSERT');
               INSERT INTO EDBADM.EDS_EQP_MULTISTATE_RATE@edb2etl
               ( SITE       ,
                 FACTORY   ,
                 SHIFT_TIMEKEY  ,
                 EQP_ID      ,
                 EQP_STATE    ,
                 EQP_STATE_CODE   ,
                 EQP_STATE_CODE1   ,
                 EVENT_CNT        ,
                 DURATION  )
                ( 
        SELECT 
        SITE,
        FACTORY,
        EVENT_SHIFT_TIMEKEY,
        EQP_ID,
       EQP_STATE,
       EQP_STATE_CODE,
       EQP_STATE_CODE1,
       EVENT_CNT,
       DURATION 
from
       (  SELECT SITE,
       FACTORY,
        EQP_ID,
       EVENT_SHIFT_TIMEKEY,
       EQP_STATE,
       EQP_STATE_CODE ,
       EQP_STATE_CODE1,
       SUM (EVENT_CNT) AS EVENT_CNT,
       SUM (DURATION) AS DURATION
  FROM (SELECT T1.SITE,
               T1.FACTORY,
               T1.EQP_ID,
               T1.EVENT_SHIFT_TIMEKEY,
               CASE WHEN T2.THIRD_LEVEL_STATE = 'RE'
                   THEN 'RUN'
                     ELSE  T1.EQP_STATE 
                       END AS EQP_STATE ,
               T2.SECOND_LEVEL_STATE AS EQP_STATE_CODE ,
               T2.THIRD_LEVEL_STATE  AS EQP_STATE_CODE1,
               T1.EVENT_CNT,
               (T1.END_TIME - T1.START_TIME) * 86400 AS DURATION
              FROM EDS_EQP_MULTISTATE_HIST@EDB2ETL T1 , EDBADM.EDS_EQP_STANDARD_STATE@EDB2ETL T2
             WHERE /*T1.EQP_STATE = T2.FIRST_LEVEL_STATE
             AND   */T1.EQP_STATE_CODE = T2.THIRD_LEVEL_STATE
             AND   T1.EVENT_SHIFT_TIMEKEY = LVV_PSD_SHIFT  -- '20181227 180000'
           ) 
         GROUP BY SITE,
                  FACTORY,
                  EQP_ID,
                  EVENT_SHIFT_TIMEKEY,
                  EQP_STATE,
                  EQP_STATE_CODE,
                  EQP_STATE_CODE1 ) )
         ORDER BY EQP_ID, EVENT_SHIFT_TIMEKEY ;
            EXCEPTION
/*               WHEN DUP_VAL_ON_INDEX
               THEN
                  lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : EDS_EQP_MULTISTATE_RATE DUPLICATE ERROR! => ' || SQLERRM;
                  lvn_error_cnt := lvn_error_cnt + 1;
                  NULL;*/
               WHEN OTHERS
               THEN
                  lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : EDS_EQP_MULTISTATE_RATE INSERT ERROR! => ' || SQLERRM;
                  lvn_error_cnt := lvn_error_cnt + 1;
                  DBMS_OUTPUT.put_line ('prc_EDS_EQP_MULTISTATE_RATE : EDS_EQP_MULTISTATE_RATE INSERT ERROR! => ' || SQLERRM);
                  RAISE l_user_exception;
            END;

            BEGIN
               --
               DBMS_APPLICATION_INFO.set_module ('prc_EDS_EQP_MULTISTATE_RATE', 'SELECT');

               SELECT COUNT (eqp_id)
                 INTO lvn_eqp_count
                 FROM EDBADM.EDS_EQP_MULTISTATE_RATE@edb2etl
                WHERE shift_timekey = lvv_psd_shift;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  lvn_eqp_count := 0;
                  NULL;
               WHEN OTHERS
               THEN
                  lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : EDS_EQP_MULTISTATE_RATE INSERT ERROR! => ' || SQLERRM;
                  DBMS_OUTPUT.put_line ('prc_EDS_EQP_MULTISTATE_RATE : EDS_EQP_MULTISTATE_RATE INSERT ERROR! => ' || SQLERRM);
                  RAISE l_user_exception;
            END;

            lvn_tcount1 := lvn_tcount1 + lvn_eqp_count;

            BEGIN
               LVV_PSD_SHIFT :=GET_SHIFT_TIME (lvv_psd_shift, '','N','15');
            EXCEPTION
               WHEN OTHERS
               THEN
                  LVV_MESSAGE := 'prc_EDS_EQP_MULTISTATE_HIST : lvv_fst_shift  ERROR! => ' || SQLERRM;
                  RAISE l_user_exception;
            END;
         END LOOP;
      END IF;
   END;
   COMMIT;
   
   --  根据ReasonCode中为三级状态的，去查找二级状态 ， 补全二三级状态
   /*BEGIN
     FOR C1 IN CUR_EQP_RATE LOOP
       FOR C2 IN CUR_EQP_STANDARD_STATE(C1.EQP_STATE_CODE) loop
         BEGIN
           UPDATE EDBADM.EDS_EQP_MULTISTATE_RATE@EDB2ETL T
              SET --T.EQP_STATE_CODE  = C2.SECOND_LEVEL_STATE,
                  T.EQP_STATE_CODE1 = C2.THIRD_LEVEL_STATE
            WHERE T.FACTORY = C1.FACTORY
              AND T.EQP_ID = C1.EQP_ID
              AND T.SHIFT_TIMEKEY = C1.SHIFT_TIMEKEY
              AND EQP_STATE = C1.EQP_STATE
              AND EQP_STATE_CODE = C1.EQP_STATE_CODE
              AND SHIFT_TIMEKEY = LVV_PSD_SHIFT;
         EXCEPTION
           WHEN OTHERS THEN
             lvv_message := 'PRC_EDS_EQP_MULTISTATE_RATE : Update EQPStateCode ERROR! => ' ||
                            SQLERRM;
             RAISE l_user_exception;
         END;
       END LOOP;
     END LOOP;
   END;
   COMMIT;*/

   --
   lvv_end_date := TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
   lvv_duration :=
      TO_CHAR (
         (TO_DATE (lvv_end_date, 'YYYY-MM-DD HH24:MI:SS') - TO_DATE (lvv_start_date, 'YYYY-MM-DD HH24:MI:SS')) * 86400);
   lvv_total := TO_CHAR (lvn_tcount1);
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
   
   --
   DBMS_OUTPUT.put_line ('RETURN OUT VALUE => ' || lvv_total);
   --
   lvv_event_name := 'END';
   lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE' || ' LOAD COMPLETE!';
   --
   log_table_insert;
   --
   DBMS_OUTPUT.put_line ('prc_EDS_EQP_MULTISTATE_RATE LOAD COMPLETE!');
   --
   DBMS_APPLICATION_INFO.set_module ('', '');
--

EXCEPTION
   WHEN l_user_exception
   THEN
      ROLLBACK;
      --
      lvv_event_name := 'ERROR';
      lvv_end_date := TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
      --
      log_table_insert;
      --
      DBMS_OUTPUT.put_line ('prc_EDS_EQP_MULTISTATE_RATE! => ' || lvv_message);
      --
      DBMS_APPLICATION_INFO.set_module ('', '');
      --
      raise_application_error (-20200, 'prc_EDS_EQP_MULTISTATE_RATE : ' || lvv_message);
   --
   WHEN OTHERS
   THEN
      ROLLBACK;
      --
      lvv_event_name := 'ERROR';
      lvv_end_date := TO_CHAR (SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
      lvv_message := 'prc_EDS_EQP_MULTISTATE_RATE : ' || 'Oracle Error => ' || SQLERRM;
      --
      log_table_insert;
      --
      DBMS_OUTPUT.put_line ('prc_EDS_EQP_MULTISTATE_RATE ORACLE ERROR! => ' || SQLERRM);
      --
      DBMS_APPLICATION_INFO.set_module ('', '');
      --
      raise_application_error (-20200, 'prc_EDS_EQP_MULTISTATE_RATE ORACLE ERROR! : ' || SUBSTR (SQLERRM, 1, 150));
--
END;
/

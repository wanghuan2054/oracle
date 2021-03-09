CREATE OR REPLACE PROCEDURE PRC_EDS_PE_DETAIL_DIALY(PVVI_START_DATE   IN VARCHAR2,
                                             PVVI_END_DATE     IN VARCHAR2,
                                             PVVI_TSK_ID       IN VARCHAR2,
                                             PVVO_RETURN_VALUE OUT VARCHAR2) IS
  --=================================================================================
  --OBJECT NAME : PRC_EDS_PE_DETAIL_DIALY
  --OBJECT TYPE : STORED PROCEDURE
  --DESCRIPTION :  �洢PE  detail  Movement ����׼��ʱ
  --=================================================================================
  --
  --=================================================================================
  --YYYY-MM-DD      DESCRIPTOR       DESCRIPTION
  --2020.02.24      HuanWang        ��PE����� �������ֳ�ȡ����
                     -- �洢��������  �� 20190801 LBP 6LEDE01 2 B6A060WK5L901 L2800 588 60.11
                     -- IE������󣬰���¥���ѯ�������ڷ�Χ�ڵİ���¥������OEE PE ֵ
  -- 2020.06.04  ��ȫ��LBP�����߼����� , �Ȱ���EQPID���ң� ����FLoorName���ң�����������0 
  --=================================================================================
  --
  --=================================================================================
  --                               VARIALBLE DECLARATION
  --=================================================================================
  LVV_EVENT_NAME VARCHAR2(10);
  LVV_MESSAGE    VARCHAR2(1000);
  LVV_ETL        VARCHAR2(10);

  LVV_TOTAL VARCHAR2(100);

  LVV_TABLE VARCHAR2(40);

  LVN_TCOUNT NUMBER;

  LVV_SP                  VARCHAR2(5);
  LVV_PROGRAM             VARCHAR2(50);
  LVV_DURATION            VARCHAR2(50);
  LVD_REPORT_DATE         Date;
  LVV_START_DATE          VARCHAR2(20);
  LVV_END_DATE            VARCHAR2(20);
  LVN_STANDARD_TIME       NUMBER;
  LVV_MODEL_PRODUCT       VARCHAR2(20);
  LVV_EVENTUSER           VARCHAR2(15);
  LVV_BEGIN_DAY_OF_MONTH  VARCHAR2(15);
  LVV_BEGIN_DAY_OF_LASTMONTH  VARCHAR2(15);
  LVV_YEAR         VARCHAR2(5);

  L_USER_EXCEPTION EXCEPTION;

  LVD_INTERFACE_TIME DATE;
  --=================================================================================-
  --                       SUB PROGRAM : PROCEDURE
  --===========================================================

  --============================================================================
  -- PE  ���ܼڶ��� = �������ڸ��ͺű�׼ TT i  *  ���ͺ� Move i ��  /  Productive Time
  --===========================================================================
  --     ��ȡ���� OEE ����Ļ�׼�豸
  --=================================================================================
  CURSOR CUR_OEE_BENCHMARK_EQP IS
    SELECT T.FACTORY, T.EQP_GROUP, T.EQP_ID�� T.FLOORNAME, ISKEY
          FROM EDBADM.WEB_OEE_EQP_GROUP@EDB2ETL T
         GROUP BY T.FACTORY, T.EQP_GROUP, T.EQP_ID, T.FLOORNAME, ISKEY;


  -- ���� PE �е� MOVEMENT,ȡ��PRC_OPER_OUT_GLS_QTY�ֶ�
  CURSOR CUR_OEE_PE_MOVEMENT(LVV_START_DATE VARCHAR2,
                             LVV_END_DATE   VARCHAR2,
                             LVV_EQP        VARCHAR2) IS
    SELECT T.SITE,
           T.FACTORY,
           --LVD_REPORT_DATE AS REPORTDATE,
           TO_DATE(SUBSTR(T.SHIFT_TIMEKEY,1,8),'YYYYMMDD') AS REPORTDATE,
           T.PRODUCT,
           T.OPER_CODE,
           T.EQP_ID,
           CASE
             WHEN T.EQP_ID IN ('6CCSB01', '6CCSB02', '6CCSB03', '6CCSB04') THEN
              SUM(T.PRC_OPER_OUT_GLS_QTY / 4) -- Cut Inline����ΪQ
             ELSE
              SUM(T.PRC_OPER_OUT_GLS_QTY)
           END AS TTLMOVEMENT
      FROM EDBADM.EDS_SUM_MOVE@EDB2ETL T, EDBADM.EDS_OPER@EDB2ETL T1
     WHERE T.OPER_CODE = T1.OPER_CODE
       AND T1.OPER_NAME NOT LIKE '%-C'
       --AND T.LOT_TYPE = 'Production'
       AND T.LOT_TYPE IN ('Production','Engineer')
       AND T.PRC_OPER_OUT_GLS_QTY IS NOT NULL
       AND T.EQP_ID = LVV_EQP -- '6LPTK02'
       AND T.SHIFT_TIMEKEY >= LVV_START_DATE -- '20190328 060000'
       AND T.SHIFT_TIMEKEY < LVV_END_DATE -- '20190329 060000'
     GROUP BY T.SITE,
              T.FACTORY,
              TO_DATE(SUBSTR(T.SHIFT_TIMEKEY,1,8),'YYYYMMDD') ,
              T.PRODUCT,
              T.OPER_CODE,
              T.EQP_ID;

  -- ���� PE �е�ʵʱ��׼ TT   �� ���MOVEMENT ���ϼ����׼��ʱ���� ��  ȡ QUARTER_STANDARD_TT  ���ȱ�
  CURSOR CUR_OEE_PE_REALST(LVV_FACTORY   VARCHAR2,
                           LVV_EQP       VARCHAR2,
                           LVV_PRODUCT   VARCHAR2,
                           LVV_OPERATION VARCHAR2) IS
    SELECT DISTINCT T.STANDARD_TIME
      FROM EDBADM.QUARTER_STANDARD_TT@EDB2ETL T
     WHERE T.SNAPDATE = LVV_BEGIN_DAY_OF_MONTH --
           --(SELECT MAX(SNAPDATE) FROM EDBADM.QUARTER_STANDARD_TT@EDB2ETL)
       AND T.FACTORY = LVV_FACTORY -- 'LBP'
       AND T.PRODUCT = LVV_PRODUCT -- 'B6A062YQ5L901'
       AND T.EQP_ID = LVV_EQP -- '6LPTK02'
       AND T.Oper_Code = LVV_OPERATION -- 'LA500-1'  --'LA500'
    ;
    
   -- ���� PE �е�ʵʱ��׼ TT   �� ���MOVEMENT ���ϼ����׼��ʱ���� ��  ȡ QUARTER_STANDARD_TT  ���ȱ�
  CURSOR CUR_OEE_PE_KEYST(LVV_FACTORY   VARCHAR2,
                           LVV_EQP       VARCHAR2,
                           LVV_PRODUCT   VARCHAR2,
                           LVV_OPERATION VARCHAR2) IS
    SELECT MAX(T.STANDARD_TIME) AS STANDARD_TIME
      FROM EDBADM.DWS_KEYEQP_DIM_ST@EDB2ETL T
     WHERE T.YEAR = LVV_YEAR
       AND T.FACTORY = LVV_FACTORY -- 'LBP'
       AND T.PRODUCT = LVV_PRODUCT -- 'B6A062YQ5L901'
       AND T.EQP_ID = LVV_EQP -- '6LTSP04'
       AND T.OPER_CODE = LVV_OPERATION -- 'LA500-1'
       GROUP BY T.YEAR , T.FACTORY ,T.PRODUCT , T.EQP_ID , T.OPER_CODE
    ;

  -- ���� PE �е�ʵʱ��׼ TT   �� ���MOVEMENT ��С�������ϱ�׼��ʱ��������
  -- ��ȡ EDS_EQP_STANDARD_TT ����׼��ʱ�ⲹȫ�ο���׼
   -- 2020.06.04  ��ȫ��LBP�����߼����� 
  CURSOR CUR_OEE_PE_ST(LVV_FACTORY   VARCHAR2,
                       LVV_EQP       VARCHAR2,
                       LVV_FLOORNAME VARCHAR2,
                       LVV_OPERATION VARCHAR2) IS
/*    SELECT T.TT AS STANDARD_TIME
      FROM EDBADM.EDS_EQP_STANDARD_TT@EDB2ETL T
     WHERE T.FACTORY = LVV_FACTORY
          -- EQP ��  FLOORNAME ����ͬʱ����
       AND ((T.OPER_CODE = LVV_OPERATION AND FLOORNAME = LVV_FLOORNAME) OR
           (T.OPER_CODE = LVV_OPERATION AND T.EQP_ID = LVV_EQP));*/
           
           
   SELECT COALESCE(TT, 0) AS STANDARD_TIME
      FROM (SELECT T.TT
              FROM EDBADM.EDS_EQP_STANDARD_TT@EDB2ETL T
             WHERE (T.FACTORY = LVV_FACTORY AND T.OPER_CODE = LVV_OPERATION AND
                   T.EQP_ID = LVV_EQP)
            UNION ALL
            SELECT T1.TT
              FROM EDBADM.EDS_EQP_STANDARD_TT@EDB2ETL T1
             WHERE (T1.FACTORY = LVV_FACTORY AND T1.OPER_CODE = LVV_OPERATION AND
                   T1.FLOORNAME = LVV_FLOORNAME))
     WHERE ROWNUM = 1 ;
          

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
  --                                 MAIN BLOCK
  --=================================================================================
BEGIN
  --=============================================================
  -- Variable Initialization
  --============================================================
  LVV_TOTAL := 0;

  LVV_ETL       := 'LOAD';
  LVV_PROGRAM   := 'PRC_EDS_PE_DETAIL_DIALY';
  LVV_SP        := '::D::';
  LVV_TABLE     := 'EDS_PE_DETAIL_DIALY';
  LVN_TCOUNT    := 0;
  LVV_DURATION  := NULL;
  LVV_EVENTUSER := 'B6Interface';


  LVD_REPORT_DATE         := TO_DATE(SUBSTR(PVVI_START_DATE, 1, 8),
                                     'yyyyMMdd');
  LVV_START_DATE          := PVVI_START_DATE;
  LVV_END_DATE            := PVVI_END_DATE;
  -- ��׼��ʱ��ÿ�����һ��ȡ����һ�ŵĿ��գ�������ȡ��ǰ��1�ŵĿ���
  LVV_BEGIN_DAY_OF_MONTH  := SUBSTR(PVVI_START_DATE, 1, 6) || '01';
  
  -- ÿ�±�׼��ʱ���õ����³���׼��ʱ���ձ������Ϊ��ʱֵ�� �������³����ձ����ʱ����Ҫ��������ȫ��ÿ�칤ʱ
  LVV_BEGIN_DAY_OF_LASTMONTH := TO_CHAR(ADD_MONTHS(LVD_REPORT_DATE,-1),'YYYYMM')||'01' ;
  
  LVV_YEAR         := SUBSTR(LVV_START_DATE, 1, 4);

  LVN_STANDARD_TIME := 0; -- ��ʼ��׼��ʱ����Ϊ0 �� ���� LA500-1 ������������ʵʱ���ǲ�ȫ��׼�� ��û�� ��Ӧ��ST

  SELECT SYSDATE INTO LVD_INTERFACE_TIME FROM DUAL;

  --==============================
  -- EDS_PE_DETAIL_DIALY TABLE DELETE
  --==============================
  --
  DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM, LVV_TABLE || ' DELETE');
  DECLARE
  BEGIN
    -- ɾ�����쿪ʼ�ͽ���ʱ���֮�ڵ����� , ֱ�Ӱ��� REPORT_DATE ɾ��һ�������
    DELETE FROM EDBADM.EDS_PE_DETAIL_DIALY@EDB2ETL
     WHERE REPORTDATE = LVD_REPORT_DATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ROLLBACK;
  END;
  COMMIT;

  DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM,
                                   LVV_TABLE || ' ' || LVV_ETL);

  --==================================================================================================
  -- EDS_PE_DETAIL_DIALY TABLE PE_DAILY �����ܼڶ��ʣ��ֶεļ��� �� Productive Time ȡ�� RUNTIME , �ݴ�OEE_MONTH�ֶ�
  --=================================================================================================
  DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM,
                                   LVV_TABLE || ' ' || LVV_ETL);
  BEGIN
      FOR C1 IN CUR_OEE_BENCHMARK_EQP LOOP
        -- ������³�1�ţ���Ҫʹ��1�ſ��������ϸ�������
        IF (SUBSTR(PVVI_START_DATE, 7, 2) = '01' ) THEN
           LVV_START_DATE := LVV_BEGIN_DAY_OF_LASTMONTH ;
        END IF;
        FOR C2 IN CUR_OEE_PE_MOVEMENT(LVV_START_DATE,
                                      LVV_END_DATE,
                                      C1.EQP_ID) LOOP
          LVN_STANDARD_TIME := 0;
          IF (C1.EQP_GROUP = 'Cell PI' OR C1.EQP_GROUP = 'Cell OA') THEN
            SELECT DISTINCT A.MODELTYPE
              INTO LVV_MODEL_PRODUCT
              FROM EDBADM.EDS_PRODUCT@EDB2ETL A
             WHERE A.PRODUCT = C2.PRODUCT
               AND A.FACTORY = 'CELL';
          ELSE
            LVV_MODEL_PRODUCT := C2.PRODUCT;
          END IF;
          -- �����ƿ���豸�� ȥDWS_KEYEQP_DIM_ST�����ST
           IF (C1.ISKEY = 'Y') THEN
              FOR C3 IN CUR_OEE_PE_KEYST(C2.FACTORY,
                                      C2.EQP_ID,
                                      LVV_MODEL_PRODUCT,
                                      C2.OPER_CODE) LOOP
                IF (C3.STANDARD_TIME IS NOT NULL) THEN
                    LVN_STANDARD_TIME := C3.STANDARD_TIME;
                END IF;
              END LOOP;
          ELSE
              -- �������ƿ���豸�� ȥ�³����ձ����ST
              FOR C3 IN CUR_OEE_PE_REALST(C2.FACTORY,
                                      C2.EQP_ID,
                                      LVV_MODEL_PRODUCT,
                                      C2.OPER_CODE) LOOP
                IF (C3.STANDARD_TIME IS NOT NULL) THEN
                    LVN_STANDARD_TIME := C3.STANDARD_TIME;
                END IF;
              END LOOP;
          END IF;
          
          IF (LVN_STANDARD_TIME = 0 OR LVN_STANDARD_TIME IS NULL) THEN
            -- ʵʱ�ⲻ����  �� ���ǲ�ȫ��׼����� ST
            FOR C4 IN CUR_OEE_PE_ST(C2.FACTORY,
                                    C2.EQP_ID,
                                    C1.FLOORNAME,
                                    C2.OPER_CODE) LOOP
               IF (C4.STANDARD_TIME IS NOT NULL) THEN
                  LVN_STANDARD_TIME := C4.STANDARD_TIME;
               END IF;
            END LOOP;
            IF (LVN_STANDARD_TIME = 0 OR LVN_STANDARD_TIME IS NULL) THEN
              LVV_MESSAGE := LVV_PROGRAM || ' : ' || LVV_TABLE || ' ' ||
                             LVV_ETL || ' ERROR! => ' ||
                             '�ù���ʱ��Ͳ�ȫ��ʱ�ⶼû����';
            END IF;
          END IF;
                             
          /*BEGIN
          INSERT INTO EDBADM.EDS_PE_DETAIL_DIALY@EDB2ETL
            (REPORTDATE ,
             FACTORY,
             EQP_ID,
             FLOORNAME,
             PRODUCT,
             OPER_CODE,
             OUT_GLSQTY,
             STANDARDTT)
          VALUES
            (LVD_REPORT_DATE,
             C2.FACTORY,
             C2.EQP_ID ,
             C1.FLOORNAME , 
             C2.PRODUCT,
             C2.OPER_CODE,
             C2.TTLMOVEMENT,
             LVN_STANDARD_TIME );
        EXCEPTION
          WHEN OTHERS THEN
            LVV_MESSAGE := LVV_PROGRAM || ' : ' || LVV_TABLE || ' ' ||
                           LVV_ETL || ' EDS_PE_DETAIL_DIALY INSERT ERROR! => ' ||
                           SUBSTR(SQLERRM, 1, 300);
            RAISE L_USER_EXCEPTION;
        END;  */  
        
          BEGIN 
          MERGE INTO EDBADM.EDS_PE_DETAIL_DIALY@EDB2ETL T1
          USING (SELECT  C2.REPORTDATE LVD_REPORT_DATE,
                         C2.FACTORY FACTORY,
                         C2.EQP_ID  EQP_ID,
                         C1.FLOORNAME FLOORNAME, 
                         C2.PRODUCT PRODUCT,
                         C2.OPER_CODE OPER_CODE,
                         C2.TTLMOVEMENT TTLMOVEMENT,
                         LVN_STANDARD_TIME LVN_STANDARD_TIME
                               FROM DUAL) T2
          on (T1.REPORTDATE = T2.LVD_REPORT_DATE AND T1.FACTORY = T2.FACTORY AND T1.EQP_ID = T2.EQP_ID 
          AND T1.FLOORNAME = T2.FLOORNAME AND T1.PRODUCT = T2.PRODUCT AND T1.OPER_CODE = T2.OPER_CODE 
          )
          WHEN MATCHED THEN
            UPDATE
               -- ����1�ſ��գ��������±�׼��ʱ
               SET T1.STANDARDTT = T2.LVN_STANDARD_TIME
          WHEN NOT MATCHED THEN
            INSERT
              (REPORTDATE ,
               FACTORY,
               EQP_ID,
               FLOORNAME,
               PRODUCT,
               OPER_CODE,
               OUT_GLSQTY,
               STANDARDTT)
            VALUES
              (T2.LVD_REPORT_DATE,
               T2.FACTORY,
               T2.EQP_ID ,
               T2.FLOORNAME , 
               T2.PRODUCT,
               T2.OPER_CODE,
               T2.TTLMOVEMENT,
               T2.LVN_STANDARD_TIME);
             EXCEPTION
                  WHEN OTHERS
                  THEN
                     LVV_MESSAGE := LVV_PROGRAM || ' : ' || LVV_TABLE || ' ' ||
                           LVV_ETL || ' EDS_PE_DETAIL_DIALY INSERT ERROR! => ' ||
                           SUBSTR(SQLERRM, 1, 300);
                     RAISE L_USER_EXCEPTION;         
              END;                
                             
        END LOOP;
      END LOOP;
  END;
  COMMIT ;
  --=============================================================
  -- LOAD COUNT CALCULATION
  --=============================================================

  BEGIN
    SELECT COUNT(*)
      INTO LVN_TCOUNT
      FROM EDBADM.EDS_PE_DETAIL_DIALY@EDB2ETL t1
     WHERE REPORTDATE = LVD_REPORT_DATE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      LVN_TCOUNT := 0;
  END;
  --=================================================================================
  --
  --=================================================================================

  LVV_END_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
  LVV_TOTAL    := TO_CHAR(LVN_TCOUNT);
  LVV_DURATION := TO_CHAR((SYSDATE - LVD_INTERFACE_TIME) * 86400);

  PVVO_RETURN_VALUE := SUBSTR(LVV_ETL, 1, 1) || LVV_SP ||
                       LTRIM(TO_CHAR(LVV_TOTAL, '0000000000'), ' ') ||
                       LVV_SP || LVV_PROGRAM || LVV_SP || LVV_DURATION ||
                       LVV_SP || LVV_TABLE || LVV_SP || TO_CHAR(LVN_TCOUNT) ||
                       LVV_SP;

  LVV_EVENT_NAME := 'END';
  LVV_MESSAGE    := LVV_PROGRAM || ' : ' || LVV_TABLE || ' ' || LVV_ETL ||
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

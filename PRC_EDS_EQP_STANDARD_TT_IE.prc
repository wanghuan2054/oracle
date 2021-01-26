CREATE OR REPLACE PROCEDURE PRC_EDS_EQP_STANDARD_TT_IE(PVVI_START_DATE   IN VARCHAR2,
                                                       PVVI_END_DATE     IN VARCHAR2,
                                                       PVVI_TSK_ID       IN VARCHAR2,
                                                       PVVO_RETURN_VALUE OUT VARCHAR2) IS
  --=================================================================================
  --OBJECT NAME : PRC_EDS_EQP_STANDARD_TT_IE
  --OBJECT TYPE : STORED PROCEDURE
  --DESCRIPTION : STANDARD TIME  INFORMATION I/F FROM EDS TO EDS
  -- OEE ��׼��ʱ����
  -- CELL PI  OA �����豸TFT/CF Glass �����߼����� ��ͬͶ����㣬�����豸�������㣨�����豸����Ʒ���������ͳ�ƣ�
  -- ACF  ������������� < N ʱ�������� 
  --=================================================================================
  --
  --=================================================================================
  --YYYY-MM-DD      DESCRIPTOR       DESCRIPTION
  --2018-08-28      WANGHUAN         INITIAL RELEASE
  --2018-10-10      WANGHUAN         ����� Group_ID �ֶ� 
  --2019.01.24      WANGHUAN          ST ���·�Χ  ��ֵ�Ƿ��ڹ�ʱ�⵱ǰֵ��0.8-1��֮��
  --2020.03.27      WANGHUAN         ��׼��ʱ��������ֵ�Ƿ��ڲ���������������0.8-1.25����Χ��
                                --   ���������������׼��ʱΪ0�ļ�¼����׼��ʱ��
  -- 2020.06.04  ��ȫ��LBP�����߼����� , �Ȱ���EQPID���ң� ����FLoorName���ң�����������0 
  -- 2020.12.17   ��׼�����ϣ�����Unit Subunit �� ����ʱ��Ҫʹ��Flag = Y ��Ϊ���豸ƿ��Unit
  --  Photo�����豸ʵ��TT����ֵ��Ϊ45S ��������Ϊ1.25���������豸����ֵ��Ϊ0.8��������ֵ1.25��
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
  LVV_TABLE2 VARCHAR2(40);

  LVN_TCOUNT1 NUMBER;
  LVN_TCOUNT2 NUMBER;

  LVV_SP            VARCHAR2(5);
  LVV_PROGRAM       VARCHAR2(50);
  LVV_DURATION      VARCHAR2(50);
  LVV_START_TIMEKEY VARCHAR2(40);
  LVV_END_TIMEKEY   VARCHAR2(40);
  LVV_DATE_TIMEKEY VARCHAR2(40);
  LVV_DATETIMEKEY  VARCHAR2(40);
  LVV_START_DATE    VARCHAR2(50);
  LVV_END_DATE      VARCHAR2(50);

  L_USER_EXCEPTION EXCEPTION;

  LVD_INTERFACE_TIME DATE;
  LVN_RESTART        NUMBER;
  LVN_TIME_BASE      NUMBER;
  LVN_GROUP_CNT      NUMBER;
  LVN_TOTAL_GLASS    NUMBER;
  LVN_STANDARD_TIME  NUMBER;
  LVN_IS_ABNORMAL  NUMBER;
  --=================================================================================
  --=================================================================================
  --                 ���� ���� �豸 ��Ʒ�� ���� ���з��飬��ͳ�Ƴ������ڵ� Total Glass �� CURSOR
  --=================================================================================
  CURSOR CUR_EQP_TT_GROUP IS
    SELECT DISTINCT T.EQP_ID,
                    --T.UNIT_ID ,
                    T.PRODUCT,
                    T.OPER_CODE,
                    T.GROUP_ID ,  -- ������ͬ����PRODUCT ��OPER_CODE�� �� ����ĵڼ��� ����ͶƬ 
                    COUNT(GLS_ID) AS TTL_GLS  -- ��ȥ 1 ��Ҫȥ��ָ��ʱ��η�Χ�ڵ� ��һ����¼����û����һ��OUT ʱ�䣬û�в���TT����
      FROM EDBADM.EDS_EQP_TACT_TIME_IE@EDB2ETL T
      -- ȥ�� CELL 8 ̨�豸��һƬArray �� һƬ CF ���� Out   
      WHERE T.EQP_ID NOT IN('6CIPI01','6CIPI02','6CIPI03','6CIPI04','6CIOA01','6CIOA02','6CIOA03','6CIOA04','6CIMC01')
                  AND T.TACT_TIME IS NOT NULL 
                  AND SHIFT_TIMEKEY > = LVV_START_TIMEKEY
                  AND SHIFT_TIMEKEY < LVV_END_TIMEKEY
     GROUP BY T.EQP_ID, T.PRODUCT, T.OPER_CODE , T.GROUP_ID --, T.UNIT_ID 
     ORDER BY T.EQP_ID;
  --=================================================================================
  --                 ���� ���� �豸 ModelType ���� ���з��飬��ͳ�Ƴ������ڵ� Total Glass �� CURSOR
  --  ֻ��� CELL �� 8 ̨�豸 , Out TTL_GLS ���� ������ Array �� CF ����    
  --  ��Ҫ���� EDS_PRODUCT ��׼����� Array ��CF ��Ʒ �� MODELTYPE �Ƿ�һ�� 
  --=================================================================================
  CURSOR CUR_EQP_TT_GROUP_PIOA IS
    SELECT DISTINCT T.EQP_ID,
                    --T.UNIT_ID ,
                    A.MODELTYPE,
                    T.OPER_CODE,
                    T.GROUP_ID ,
                    --MAX(T.PRODUCT)  AS PRODUCT,  -- Array  CF  GLS ͬʱ��������� ��PRODUCT ��ͬһ��MODELTYPE�� ��������Ƭ����  
                    COUNT(GLS_ID) AS TTL_GLS -- ��ȥ 1 ��Ҫȥ��ָ��ʱ��η�Χ�ڵ� ��һ����¼����û����һ��OUT ʱ�䣬û�в���TT����
      FROM EDBADM.EDS_EQP_TACT_TIME_IE@EDB2ETL T , EDBADM.EDS_PRODUCT@EDB2ETL A
      WHERE T.EQP_ID IN('6CIPI01','6CIPI02','6CIPI03','6CIPI04','6CIOA01','6CIOA02','6CIOA03','6CIOA04','6CIMC01')
      AND  A.PRODUCTION_TYPE = 'Production'
      AND T.TACT_TIME IS NOT NULL
      AND  A.FACTORY = 'CELL'
       AND T.FACTORY = A.FACTORY
       AND T.PRODUCT = A.PRODUCT
       AND SHIFT_TIMEKEY > = LVV_START_TIMEKEY
       AND SHIFT_TIMEKEY < LVV_END_TIMEKEY
     GROUP BY T.EQP_ID , A.MODELTYPE, T.OPER_CODE ,  T.GROUP_ID --, T.UNIT_ID
     ORDER BY T.EQP_ID;

-- �ӱ�׼��ʱ��ʷ����ˢȡʵʱ ��׼��ʱ ��ע��С��׼��ʱ �ó���ʱ��
 -- 2018 12 29 11:52 Ѱ����СTT �㷨 ����
 -- 2020.03.27  Ѱ����СTT�����㷨����
 -- 2020.06.04  ��ȫ��LBP�����߼����� 
CURSOR CUR_EQP_ST_REAL IS
/*         SELECT T.FACTORY,
           T.EQP_ID,
           T2.FLOORNAME,
           T.OPER_CODE,
           T.PRODUCT,
           T.STANDARD_TIME AS TODAY_MIN_ST  ,
           T.DATE_TIMEKEY AS TODAY_MIN_DATE ,
           NVL(T1.STANDARD_TIME,0)  AS HIST_MIN_ST ,
           T1.DATE_TIMEKEY   AS HIST_MIN_DATE ,
           NVL(T3.TT,0) AS COMPLETION_ST
      FROM EDBADM.EDS_EQP_STANDARD_TT_IE_HIST@EDB2ETL T
      LEFT JOIN EDBADM.EDS_EQP_STANDARD_TT_IE@EDB2ETL T1
        ON (T.FACTORY = T1.FACTORY AND T.EQP_ID = T1.EQP_ID AND
           T.OPER_CODE = T1.OPER_CODE AND T.PRODUCT = T1.PRODUCT)
     INNER JOIN EDBADM.EDS_EQP@EDB2ETL T2
        ON (T.FACTORY = T2.FACTORY AND T.EQP_ID = T2.EQP_ID)
      LEFT JOIN EDBADM.EDS_EQP_STANDARD_TT@EDB2ETL T3
        ON (T.FACTORY = T3.FACTORY AND T.OPER_CODE = T3.OPER_CODE AND
           (T.EQP_ID = T3.EQP_ID OR T2.FLOORNAME = T3.FLOORNAME))
     WHERE T.DATE_TIMEKEY = LVV_DATE_TIMEKEY ;*/
   
   SELECT T.FACTORY,
           T.EQP_ID,
           T2.FLOORNAME,
           T.OPER_CODE,
           T.PRODUCT,
           T.STANDARD_TIME AS TODAY_MIN_ST  ,
           T.DATE_TIMEKEY AS TODAY_MIN_DATE ,
           NVL(T1.STANDARD_TIME,0)  AS HIST_MIN_ST ,
           T1.DATE_TIMEKEY   AS HIST_MIN_DATE ,
           T3.TT AS EQPTT ,
           T4.TT AS FLOORTT,
           COALESCE(T3.TT, T4.TT, 0) AS COMPLETION_ST
      FROM EDBADM.EDS_EQP_STANDARD_TT_IE_HIST@EDB2ETL T
      LEFT JOIN EDBADM.EDS_EQP_STANDARD_TT_IE@EDB2ETL T1
        ON (T.FACTORY = T1.FACTORY AND T.EQP_ID = T1.EQP_ID AND
           T.OPER_CODE = T1.OPER_CODE AND T.PRODUCT = T1.PRODUCT)
     INNER JOIN EDBADM.EDS_EQP@EDB2ETL T2
        ON (T.FACTORY = T2.FACTORY AND T.EQP_ID = T2.EQP_ID)
      LEFT JOIN EDBADM.EDS_EQP_STANDARD_TT@EDB2ETL T3
        ON (T.FACTORY = T3.FACTORY AND T.OPER_CODE = T3.OPER_CODE AND T.EQP_ID = T3.EQP_ID)
        LEFT JOIN EDBADM.EDS_EQP_STANDARD_TT@EDB2ETL T4
       ON (T.FACTORY = T4.FACTORY AND T.OPER_CODE = T4.OPER_CODE AND T2.FLOORNAME = T4.FLOORNAME)
     WHERE T.DATE_TIMEKEY = LVV_DATE_TIMEKEY --'20200609'
      ;
     
  --=================================================================================
  --                       SUB PROGRAM : PROCEDURE (Log  ��־ ��¼ )
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
  --                                 MAIN BLOCK
  --=================================================================================
BEGIN

  --=============================================================
  -- VARIABLE INITIALIZATION
  --=============================================================

  LVV_START_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');

  LVV_TOTAL     := 0;
  LVN_ERROR_CNT := 0;

  LVV_ETL     := 'LOAD';
  LVV_PROGRAM := 'PRC_EDS_EQP_STANDARD_TT_IE';
  LVV_SP      := '::D::';
  LVV_TABLE1  :=  'EDS_EQP_STANDARD_TT_IE_HIST';
  LVV_TABLE2  :=  'EDS_EQP_STANDARD_TT_IE';

  LVN_TCOUNT1 := 0;
  LVN_TCOUNT2 := 0;

  LVV_DURATION := NULL;

  LVN_GROUP_CNT := 0;

  LVN_TOTAL_GLASS := 0;

  LVN_STANDARD_TIME := 0;

  LVN_TIME_BASE := 24 * 60 * 60 ;     -- DATE ���Ϊ�죬ת���� S

    
    LVV_START_TIMEKEY := PVVI_START_DATE ; --SUBSTR(PVVI_START_DATE, 1, 8) || SUBSTR(PVVI_START_DATE, 10, 6) ;
    -- ����ʱ��ȡ����ʱ������� 
    LVV_END_TIMEKEY :=  PVVI_END_DATE ; --SUBSTR(PVVI_END_DATE, 1, 8) || SUBSTR(PVVI_END_DATE, 10, 6);
    
    -- ȡ�ϸ��µ� 1 ��
    -- 2018.12.29    IE Ҫ����Ҫ����ȡ��ʷֵ�ķ�Χ �� ֱ��ȡ����ʱ�� ��ʵʱ����бȽ�
    -- ��Ϊʵʱ���е�ֵ����֮ǰ��ʷ����С��ֵ������Ҫ�ظ��Ƚϣ� ֻ��Ҫ�뵱�����ֵ�Ƚϼ���
    -- LVV_DATE_TIMEKEY :=  TO_CHAR(TRUNC(ADD_MONTHS(SYSDATE,-1),'mm'), 'yyyymmdd') ;
    LVV_DATE_TIMEKEY := SUBSTR(PVVI_START_DATE, 1, 8) ;
    
    LVV_DATETIMEKEY := LVV_DATE_TIMEKEY ;
    
    LVN_IS_ABNORMAL := 0 ;
    
  --SELECT TO_DATE(PVVI_END_DATE,'yyyy/MM/dd hh24:mi:ss')  INTO LVD_INTERFACE_TIME FROM DUAL;
  --=====================Main Procedure============================
  -- �����豸����Ʒ����������� �� �����߼�����ı�׼��ʱ �������� CELL PI �� OA  8 ̨�豸
  BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM,
                                     LVV_TABLE2 || ' ' || LVV_ETL);
    FOR C1 IN CUR_EQP_TT_GROUP LOOP
      SELECT ITER_INTERVAL
        INTO LVN_GROUP_CNT
        FROM EDBADM.EDS_EQP_ITER_INTERVAL@EDB2ETL
       WHERE EQP_ID = C1.EQP_ID
       AND FLAG = 'Y'
       --AND UNIT_ID = C1.UNIT_ID 
       ;
      SELECT C1.TTL_GLS INTO LVN_TOTAL_GLASS FROM DUAL;
      IF (LVN_TOTAL_GLASS >= LVN_GROUP_CNT) THEN
        FOR C2 IN (SELECT  FACTORY , EQP_ID,
                          PRODUCT,
                          OPER_CODE,
                          GROUP_ID,
                          MIN(AVG_TT) AS STANDARD_TIME
                     FROM (SELECT  FACTORY ,
                                  EQP_ID,
                                  RN,
                                  PRODUCT,
                                  OPER_CODE,
                                  GROUP_ID ,
                                  AVG(TACT_TIME) OVER(ORDER BY RN RANGE BETWEEN 0 PRECEDING AND LVN_GROUP_CNT-1 FOLLOWING) AVG_TT
                             FROM (SELECT ROW_NUMBER() OVER(ORDER BY EVENT_TIMEKEY) RN,
                                          T.FACTORY , 
                                          T.EQP_ID,
                                          T.PRODUCT,
                                          T.OPER_CODE,
                                          T.GROUP_ID ,
                                          T.TACT_TIME
                                     FROM EDBADM.EDS_EQP_TACT_TIME_IE@EDB2ETL T
                                    WHERE T.EQP_ID = C1.EQP_ID --'6CCQC01'
                                      AND T.PRODUCT = C1.PRODUCT --'B6P055FH5LP16'
                                      AND T.OPER_CODE = C1.OPER_CODE --'C5500'
                                      AND T.GROUP_ID = C1.GROUP_ID
                                      AND T.TACT_TIME IS NOT NULL  -- T.TACT_TIME IS NOT NULL  ȥ��ָ��ʱ��η�Χ�ڵ� ��һ����¼����û����һ��OUT ʱ�䣬û�в���TT����
                                      AND T.SHIFT_TIMEKEY > = LVV_START_TIMEKEY
                                      AND T.SHIFT_TIMEKEY < LVV_END_TIMEKEY
                                      ) 
                           )
                            WHERE RN <= (LVN_TOTAL_GLASS - LVN_GROUP_CNT + 1) -- ��λѭ����������һ���������� 
                    GROUP BY FACTORY , EQP_ID, PRODUCT, OPER_CODE,GROUP_ID) LOOP
                    
         begin 
          MERGE INTO EDBADM.EDS_EQP_STANDARD_TT_IE_HIST@EDB2ETL T1
          USING (SELECT  C2.FACTORY   FACTORY,
                                C2.EQP_ID   EQP_ID,
                                C2.PRODUCT  PRODUCT, 
                                C2.OPER_CODE  OPER_CODE , 
                                C2.STANDARD_TIME   STANDARD_TIME,
                                LVV_DATETIMEKEY  LVV_START_TIMEKEY
                   FROM DUAL) T2
          on (T1.EQP_ID = T2.EQP_ID AND T1.PRODUCT = T2.PRODUCT AND T1.OPER_CODE = T2.OPER_CODE AND T1.DATE_TIMEKEY = T2.LVV_START_TIMEKEY
          )
          WHEN MATCHED THEN
            -- EDS_EQP_STANDARD_TT_IE_HIST ��ʷ����ÿ����С STANDARD_TIME
            -- ÿ�찴�ռ�¼ ( FACTORY, EQP_ID, OPER_CODE, PRODUCT )
            -- DATE_TIMEKEY ȡ����С��׼��ʱ������� 
            UPDATE
               SET T1.STANDARD_TIME = T2.STANDARD_TIME
             WHERE T2.STANDARD_TIME < T1.STANDARD_TIME          
          WHEN NOT MATCHED THEN
            INSERT
              (FACTORY ,
               EQP_ID,
               PRODUCT,
               OPER_CODE,
               STANDARD_TIME,
               DATE_TIMEKEY)
            VALUES
              (T2.FACTORY ,
               T2.EQP_ID,
               T2.PRODUCT,
               T2.OPER_CODE,
               T2.STANDARD_TIME,
               T2.LVV_START_TIMEKEY);
             EXCEPTION
                            WHEN OTHERS
                            THEN
                               LVV_MESSAGE := 'Insert EDS_EQP_STANDARD_TT_IE_HIST ST ERROR : ' || SQLERRM;
                               RAISE L_USER_EXCEPTION;         
              END; 
          COMMIT;
           LVN_TCOUNT1 := LVN_TCOUNT1 + 1 ;
        END LOOP;
      END IF;
    END LOOP;
  END;
  
  -- ���� �豸��MODELTYPE ������ ���� �߼�����ı�׼��ʱ ��ֻ���� CELL PI �� OA  8 ̨�豸
  -- PRODUCT һ�а��� MODELTYPE ����������
  -- PI OA �豸��OUT ʱ�䲻��ֱ��ʹ�� EDS_EQP_TACT_TIME_IE �е� TACT_TIME ����Ϊ��ʱ���ǻ���PRODUCT����ͳ�Ƶ�
  -- PI OA �豸��Ҫ���� EDS_PRODUCT �� �� ���� MODELTYPE ����֮�󣬽��нضϣ���OUTʱ��������������õ� TACT_TIME
  BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM,
                                     LVV_TABLE2 || ' ' || LVV_ETL);
    FOR C1 IN CUR_EQP_TT_GROUP_PIOA LOOP
      SELECT ITER_INTERVAL
        INTO LVN_GROUP_CNT
        FROM EDBADM.EDS_EQP_ITER_INTERVAL@EDB2ETL
       WHERE EQP_ID = C1.EQP_ID
       AND FLAG = 'Y' ;
      SELECT C1.TTL_GLS INTO LVN_TOTAL_GLASS FROM DUAL;
      IF (LVN_TOTAL_GLASS >= LVN_GROUP_CNT) THEN
        FOR C2 IN (SELECT FACTORY , EQP_ID, MODELTYPE, OPER_CODE, GROUP_ID ,MIN(AVG_TT) AS STANDARD_TIME
  FROM(
        SELECT RN,
               FACTORY ,
               EQP_ID,
               MODELTYPE,
               OPER_CODE,
               GROUP_ID ,
               GLS_ID,
               AVG(TACT_TIME) OVER(ORDER BY RN RANGE BETWEEN 0 PRECEDING AND LVN_GROUP_CNT - 1 FOLLOWING) AVG_TT
          FROM (SELECT ROW_NUMBER() OVER(ORDER BY EVENT_TIMEKEY) RN,
                       T.FACTORY ,
                       T.EQP_ID,
                       T.PRODUCT,
                       T.GLS_ID,
                       A.MODELTYPE,
                       T.OPER_CODE,
                       T.GROUP_ID ,
                       LAG(EVENT_TIME) OVER(ORDER BY EVENT_TIMEKEY) AS LAST_EVENT_TIME,
                       T.EVENT_TIME,
                       (T.EVENT_TIME - LAG(EVENT_TIME)
                        OVER(ORDER BY EVENT_TIMEKEY)) * LVN_TIME_BASE AS TACT_TIME,
                       T.EVENT_TIMEKEY
                  FROM EDBADM.EDS_EQP_TACT_TIME_IE@EDB2ETL T,
                       EDBADM.EDS_PRODUCT@EDB2ETL          A
                 WHERE T.EQP_ID = C1.EQP_ID  -- '6CIPI01'                 
                   AND A.PRODUCT = T.PRODUCT
                   AND A.PRODUCTION_TYPE = 'Production'
                   AND A.FACTORY = 'CELL'
                   AND A.FACTORY = T.FACTORY
                   AND A.MODELTYPE = C1.MODELTYPE
                   AND T.OPER_CODE = C1.OPER_CODE
                   AND T.GROUP_ID = C1.GROUP_ID
                   AND T.SHIFT_TIMEKEY > = LVV_START_TIMEKEY
                   AND T.SHIFT_TIMEKEY < LVV_END_TIMEKEY
                  order by EVENT_TIMEKEY )
         WHERE TACT_TIME IS NOT NULL )
         WHERE RN <= (LVN_TOTAL_GLASS - LVN_GROUP_CNT + 1)  -- RN ����λ�� һ��Ҫע��
         GROUP BY FACTORY , EQP_ID, MODELTYPE, OPER_CODE ,GROUP_ID ) LOOP
                    
         BEGIN 
          MERGE INTO EDBADM.EDS_EQP_STANDARD_TT_IE_HIST@EDB2ETL T1
          USING (SELECT  C2.FACTORY  FACTORY ,
                                C2.EQP_ID   EQP_ID,
                                C2.MODELTYPE  MODELTYPE, 
                                C2.OPER_CODE  OPER_CODE , 
                                C2.STANDARD_TIME   STANDARD_TIME,
                                LVV_DATETIMEKEY  LVV_START_TIMEKEY
                   FROM DUAL) T2
          on (T1.EQP_ID = T2.EQP_ID AND T1.PRODUCT = T2.MODELTYPE AND T1.OPER_CODE = T2.OPER_CODE AND T1.DATE_TIMEKEY = T2.LVV_START_TIMEKEY
          )
          WHEN MATCHED THEN
            UPDATE
               SET T1.STANDARD_TIME = T2.STANDARD_TIME
                --, T1.DATE_TIMEKEY = T2.LVV_DATE_TIMEKEY
                -- һ��֮��������ֶ�α�׼��ʱ����׼��ʱ��ʷ����ֻ������С��һ��ʱ��
             WHERE T2.STANDARD_TIME <  T1.STANDARD_TIME
          WHEN NOT MATCHED THEN
            INSERT
              (FACTORY ,
               EQP_ID,
               PRODUCT,
               OPER_CODE,
               STANDARD_TIME,
               DATE_TIMEKEY)
            VALUES
              (T2.FACTORY ,
               T2.EQP_ID,
               T2.MODELTYPE,
               T2.OPER_CODE,
               T2.STANDARD_TIME,
               T2.LVV_START_TIMEKEY);
             EXCEPTION
                  WHEN OTHERS
                  THEN
                     LVV_MESSAGE := 'Insert EDS_EQP_STANDARD_TT_IE_HIST ST ERROR : ' || SQLERRM;
                     RAISE L_USER_EXCEPTION;         
              END; 
          COMMIT;
         LVN_TCOUNT1 := LVN_TCOUNT1 + 1 ;
        END LOOP;
      END IF;
    END LOOP;
  END;
  
  
  BEGIN
    DBMS_APPLICATION_INFO.SET_MODULE(LVV_PROGRAM,
                                     LVV_TABLE1 || ' ' || LVV_ETL);
    FOR C2 in CUR_EQP_ST_REAL LOOP
        -- ��׼��ʱ�����߼� 20200327
        LVN_IS_ABNORMAL := 0 ;
        -- �ȳ�ʼ��ֵ �� �������������޸�

        BEGIN 
            IF (C2.HIST_MIN_ST = 0) THEN 
              IF (C2.EQP_ID LIKE '6LPTK%') THEN
                    IF ( C2.TODAY_MIN_ST <= C2.COMPLETION_ST*1.25
                            AND C2.TODAY_MIN_ST >= 45 
                            ) THEN 
                           LVN_STANDARD_TIME := C2.TODAY_MIN_ST ;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                    ELSIF ( C2.TODAY_MIN_ST > C2.COMPLETION_ST*1.25
                            OR C2.TODAY_MIN_ST < 45 ) THEN 
                           LVN_STANDARD_TIME := C2.COMPLETION_ST ;
                           -- �쳣ֵ���Ϊʵ�ʲ�����ֵ
                           LVN_IS_ABNORMAL :=   C2.TODAY_MIN_ST;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                     ELSE 
                           LVN_STANDARD_TIME := 0  ;
                           -- �쳣ֵ���Ϊʵ�ʲ�����ֵ
                           LVN_IS_ABNORMAL :=   C2.TODAY_MIN_ST;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                     END IF ;
               ELSE 
                    IF ( C2.TODAY_MIN_ST <= C2.COMPLETION_ST*1.25
                            AND C2.TODAY_MIN_ST >= C2.COMPLETION_ST*0.8 
                            ) THEN 
                           LVN_STANDARD_TIME := C2.TODAY_MIN_ST ;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                    ELSIF ( C2.TODAY_MIN_ST > C2.COMPLETION_ST*1.25
                            OR C2.TODAY_MIN_ST < C2.COMPLETION_ST*0.8 ) THEN 
                           LVN_STANDARD_TIME := C2.COMPLETION_ST ;
                           -- �쳣ֵ���Ϊʵ�ʲ�����ֵ
                           LVN_IS_ABNORMAL :=   C2.TODAY_MIN_ST;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                     ELSE 
                           LVN_STANDARD_TIME := 0  ;
                           -- �쳣ֵ���Ϊʵ�ʲ�����ֵ
                           LVN_IS_ABNORMAL :=   C2.TODAY_MIN_ST;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                     END IF ;
               END IF ;
            ELSE
                 IF (C2.EQP_ID LIKE '6LPTK%') THEN 
                       IF (C2.TODAY_MIN_ST < C2.HIST_MIN_ST 
                         AND C2.TODAY_MIN_ST >= 45 ) THEN 
                           LVN_STANDARD_TIME := C2.TODAY_MIN_ST ;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                       ELSE 
                           LVN_STANDARD_TIME := C2.HIST_MIN_ST  ;
                           LVV_DATETIMEKEY :=   C2.HIST_MIN_DATE ;
                       END IF ;
                  ELSE 
                      IF (C2.TODAY_MIN_ST < C2.HIST_MIN_ST 
                         AND C2.TODAY_MIN_ST >= C2.HIST_MIN_ST*0.8 ) THEN 
                           LVN_STANDARD_TIME := C2.TODAY_MIN_ST ;
                           LVV_DATETIMEKEY :=   C2.TODAY_MIN_DATE ;
                       ELSE 
                           LVN_STANDARD_TIME := C2.HIST_MIN_ST  ;
                           LVV_DATETIMEKEY :=   C2.HIST_MIN_DATE ;
                       END IF ;
                  END IF ;
           END IF ;
        END;
      BEGIN
        MERGE INTO EDBADM.EDS_EQP_STANDARD_TT_IE@EDB2ETL T1
        USING (SELECT C2.FACTORY       FACTORY,
                      C2.EQP_ID        EQP_ID,
                      C2.PRODUCT       PRODUCT,
                      C2.OPER_CODE     OPER_CODE,
                      LVN_STANDARD_TIME STANDARD_TIME,
                      LVV_DATETIMEKEY  DATE_TIMEKEY , 
                      LVN_IS_ABNORMAL   IS_ABNORMAL
                 FROM DUAL) T2
        on (T1.FACTORY = T2.FACTORY AND T1.EQP_ID = T2.EQP_ID AND T1.PRODUCT = T2.PRODUCT 
             AND T1.OPER_CODE = T2.OPER_CODE  )
        WHEN MATCHED THEN
             -- ���±�׼��ʱ����Сֵ����ʱ��
          UPDATE
             SET T1.STANDARD_TIME = T2.STANDARD_TIME ,
                 T1.DATE_TIMEKEY  = T2.DATE_TIMEKEY ,
                 T1.ISABNORMAL   = T2.IS_ABNORMAL
        WHEN NOT MATCHED THEN
          INSERT
            (FACTORY,
             EQP_ID,
             PRODUCT,
             OPER_CODE,
             STANDARD_TIME,
             DATE_TIMEKEY ,
             ISABNORMAL)
          VALUES
            (T2.FACTORY,
             T2.EQP_ID,
             T2.PRODUCT,
             T2.OPER_CODE,
             T2.STANDARD_TIME,
             T2.DATE_TIMEKEY , 
             T2.IS_ABNORMAL );
        
      EXCEPTION
        WHEN OTHERS THEN
          LVV_MESSAGE := 'Insert EDS_EQP_STANDARD_TT_IE ST ERROR : ' ||
                         SQLERRM;
          RAISE L_USER_EXCEPTION;
      END;
      COMMIT;
      LVN_TCOUNT2 := LVN_TCOUNT2 + 1;
    END LOOP;
  END;

  
  --=============================================================
  -- COMMON  END    
  --============================================

  LVV_END_DATE := TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS');
  LVV_TOTAL    := TO_CHAR(LVN_TCOUNT1+LVN_TCOUNT2);
  LVV_DURATION := TO_CHAR((TO_DATE(LVV_END_DATE, 'YYYY-MM-DD HH24:MI:SS') -
                          TO_DATE(LVV_START_DATE, 'YYYY-MM-DD HH24:MI:SS')) *
                          86400);

  PVVO_RETURN_VALUE := SUBSTR(LVV_ETL, 1, 1) || LVV_SP ||
                       LTRIM(TO_CHAR(LVV_TOTAL, '0000000000'), ' ') ||
                       LVV_SP || LVV_PROGRAM || LVV_SP || LVV_DURATION ||
                       LVV_SP || LVV_TABLE1 || LVV_SP ||
                       TO_CHAR(LVN_TCOUNT1) || LVV_SP||LVV_TABLE2 || LVV_SP ||
                       TO_CHAR(LVN_TCOUNT2);

  LVV_EVENT_NAME := 'END';
  LVV_MESSAGE    := LVV_PROGRAM || ' : ' || LVV_TABLE1 || ' ' || LVV_ETL ||' '|| LVV_TABLE2 || LVV_ETL ||
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
--=========================================================================================
/

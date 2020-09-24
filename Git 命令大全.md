# Group by 函数使用总结

 Oracle的group by除了基本使用方法以外，还有3种扩展使用方法，各自是rollup、cube、grouping sets。介绍例如以下： 

[toc]

## **数据源**

<table>
   <th>SEQ</th>
   <th>FACTORY</th>
   <th>EQP_ID</th>
   <th>EQP_STATE</th>
   <th>DURATION</th>
   <tr>
      <td>1</td>
      <td>002</td>
      <td>MACHINE002</td>
      <td>IDLE</td>
      <td>19401</td>
   </tr>
   <tr>
      <td>2</td>
      <td>002</td>
      <td>MACHINE002</td>
      <td>RUN</td>
      <td>3922</td>
   </tr>
   <tr>
      <td>3</td>
      <td>002</td>
      <td>MACHINE002</td>
      <td>RUN</td>
      <td>66498</td>
   </tr>
   <tr>
      <td>4</td>
      <td>002</td>
      <td>MACHINE002</td>
      <td>RUN</td>
      <td>70323</td>
   </tr>
   <tr>
      <td>5</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>IDLE</td>
      <td>66</td>
   </tr>
   <tr>
      <td>6</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>IDLE</td>
      <td>140</td>
   </tr>
   <tr>
      <td>7</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>RUN</td>
      <td>9685</td>
   </tr>
   <tr>
      <td>8</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>RUN</td>
      <td>46124</td>
   </tr>
   <tr>
      <td>9</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>IDLE</td>
      <td>27</td>
   </tr>
   <tr>
      <td>10</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>RUN</td>
      <td>1224</td>
   </tr>
   <tr>
      <td>11</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>RUN</td>
      <td>77681</td>
   </tr>
   <tr>
      <td>12</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>IDLE</td>
      <td>7020</td>
   </tr>
   <tr>
      <td>13</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>IDLE</td>
      <td>7702</td>
   </tr>
   <tr>
      <td>14</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>RUN</td>
      <td>4157</td>
   </tr>
   <tr>
      <td>15</td>
      <td>001</td>
      <td>MACHINE001</td>
      <td>RUN</td>
      <td>62161</td>
   </tr>
</table>

```mysql
-- 数据源查询语句 , 表信息已脱敏
WITH EQP_RUN_INFO AS
 (SELECT T.FACTORY, T.EQP_ID, T.EQPSTATE, DURATION
    FROM ***_****_STATE_DAILY T
   WHERE T.EQP_ID IN ('6CIPI03','6LPTK10')
     AND T.EQPSTATE IN ('RUN','IDLE')
     AND T.REPORTDATE >= TO_DATE('20200915', 'YYYYMM
                                 DD'))
```

在线Excel数据转HTML工具：http://pressbin.com/tools/excel_to_html_table/index.html

### **一、rollup**

使用group by rollup(T.FACTORY, T.EQP_ID, T.EQPSTATE)，首先会对(T.FACTORY, T.EQP_ID, T.EQPSTATE)进行group by ，然后对 T.FACTORY, T.EQP_ID 进行 group by ， 再对T.FACTORY进行 group by。最后对全表进行 group by 操作。

例如以下查询结果：

| FACTORY | EQP_ID    | EQP_STATE | A    | B    | C    | DURATION |
| ------- | --------- | --------- | ---- | ---- | ---- | -------- |
| 001     | MACHINE01 | RUN       | 0    | 0    | 0    | 201032   |
| 001     | MACHINE01 | IDLE      | 0    | 0    | 0    | 14955    |
| 001     | MACHINE01 |           | 0    | 0    | 1    | 215987   |
| 001     |           |           | 0    | 1    | 1    | 215987   |
| 002     | MACHINE02 | RUN       | 0    | 0    | 0    | 140743   |
| 002     | MACHINE02 | IDLE      | 0    | 0    | 0    | 19401    |
| 002     | MACHINE02 |           | 0    | 0    | 1    | 160144   |
| 002     |           |           | 0    | 1    | 1    | 160144   |
|         |           |           | 1    | 1    | 1    | 376131   |

```plsql
-- 查询数据库表EQP_RUN_INFO
SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       GROUPING(T.FACTORY) AS A,
       GROUPING(T.EQP_ID) AS B,
       GROUPING(T.EQPSTATE) AS C,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY ROLLUP(T.FACTORY, T.EQP_ID, T.EQPSTATE);
 
 -- 原始写法：
  SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY T.FACTORY, T.EQP_ID, T.EQPSTATE 
 UNION ALL
 SELECT T.FACTORY,
       T.EQP_ID,
       NULL EQPSTATE,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY T.FACTORY, T.EQP_ID 
  UNION ALL
 SELECT T.FACTORY,
       NULL EQP_ID,
       NULL EQPSTATE,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY T.FACTORY
  UNION ALL
 SELECT NULL FACTORY,
       NULL EQP_ID,
       NULL EQPSTATE,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T ;
```

总结：

ROLLUP(A,B,C)的话，GROUP BY顺序
 (A,B,C)
 (A,B)
 (A)
 最后对全表进行GROUP BY操作。 

### **二、cube**

使用group by cube(T.FACTORY, T.EQP_ID, T.EQPSTATE)，等同于GROUP BY CUBE(A, B, C)

 GROUP BY CUBE(A, B, C)，GROUP BY顺序
 (A,B,C)
 (A,B)
 (A,C)

 (B,C)

 (A)，

 (B)
 (C)，
 最后对全表进行GROUP BY操作。  一共是2^3 = 8次grouping

GROUP BY 参数为N，则GROUP BY的次数为 2^N次grouping

例如以下查询结果：

<table>
   <tr>
      <td>1</td>
      <td>CELL</td>
      <td>6CIPI03</td>
      <td>IDLE</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>19401</td>
   </tr>
   <tr>
      <td>2</td>
      <td>CELL</td>
      <td>6CIPI03</td>
      <td>RUN</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>140743</td>
   </tr>
   <tr>
      <td>3</td>
      <td>CELL</td>
      <td>6CIPI03</td>
      <td></td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>160144</td>
   </tr>
   <tr>
      <td>4</td>
      <td>CELL</td>
      <td></td>
      <td>IDLE</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>19401</td>
   </tr>
   <tr>
      <td>5</td>
      <td>CELL</td>
      <td></td>
      <td>RUN</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>140743</td>
   </tr>
   <tr>
      <td>6</td>
      <td>CELL</td>
      <td></td>
      <td></td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>160144</td>
   </tr>
   <tr>
      <td>7</td>
      <td>LBP</td>
      <td>6LPTK10</td>
      <td>IDLE</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>14955</td>
   </tr>
   <tr>
      <td>8</td>
      <td>LBP</td>
      <td>6LPTK10</td>
      <td>RUN</td>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>201032</td>
   </tr>
   <tr>
      <td>9</td>
      <td>LBP</td>
      <td>6LPTK10</td>
      <td></td>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>215987</td>
   </tr>
   <tr>
      <td>10</td>
      <td>LBP</td>
      <td></td>
      <td>IDLE</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>14955</td>
   </tr>
   <tr>
      <td>11</td>
      <td>LBP</td>
      <td></td>
      <td>RUN</td>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>201032</td>
   </tr>
   <tr>
      <td>12</td>
      <td>LBP</td>
      <td></td>
      <td></td>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>215987</td>
   </tr>
   <tr>
      <td>13</td>
      <td></td>
      <td>6CIPI03</td>
      <td>IDLE</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>19401</td>
   </tr>
   <tr>
      <td>14</td>
      <td></td>
      <td>6CIPI03</td>
      <td>RUN</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>140743</td>
   </tr>
   <tr>
      <td>15</td>
      <td></td>
      <td>6CIPI03</td>
      <td></td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>160144</td>
   </tr>
   <tr>
      <td>16</td>
      <td></td>
      <td>6LPTK10</td>
      <td>IDLE</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>14955</td>
   </tr>
   <tr>
      <td>17</td>
      <td></td>
      <td>6LPTK10</td>
      <td>RUN</td>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>201032</td>
   </tr>
   <tr>
      <td>18</td>
      <td></td>
      <td>6LPTK10</td>
      <td></td>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>215987</td>
   </tr>
   <tr>
      <td>19</td>
      <td></td>
      <td></td>
      <td>IDLE</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>34356</td>
   </tr>
   <tr>
      <td>20</td>
      <td></td>
      <td></td>
      <td>RUN</td>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>341775</td>
   </tr>
   <tr>
      <td>21</td>
      <td></td>
      <td></td>
      <td></td>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>376131</td>
   </tr>
</table>

```plsql
-- 查询数据库表EQP_RUN_INFO
SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       GROUPING(T.FACTORY) AS A,
       GROUPING(T.EQP_ID) AS B,
       GROUPING(T.EQPSTATE) AS C,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY CUBE(T.FACTORY, T.EQP_ID, T.EQPSTATE) 
 ORDER BY T.FACTORY , T.EQP_ID , T.EQPSTATE  ;
```

### **三、 **grouping 

使用grouping能够推断该行是数据库中本来的行，还是有统计产生的行。grouping值为0时说明这个值是数据库中本来的值。为1说明是统计的结果，參数仅仅有一个,并且必须为group by中出现的某一列

```plsql
-- ROLLUP 结合 grouping 使用
SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       GROUPING(T.FACTORY) AS A,
       GROUPING(T.EQP_ID) AS B,
       GROUPING(T.EQPSTATE) AS C,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY ROLLUP(T.FACTORY, T.EQP_ID, T.EQPSTATE) 
 ORDER BY T.FACTORY , T.EQP_ID , T.EQPSTATE  ;
```

例如以下查询结果：

| FACTORY | EQP_ID    | EQP_STATE | A    | B    | C    | DURATION |
| ------- | --------- | --------- | ---- | ---- | ---- | -------- |
| 001     | MACHINE01 | RUN       | 0    | 0    | 0    | 201032   |
| 001     | MACHINE01 | IDLE      | 0    | 0    | 0    | 14955    |
| 001     | MACHINE01 |           | 0    | 0    | 1    | 215987   |
| 001     |           |           | 0    | 1    | 1    | 215987   |
| 002     | MACHINE02 | RUN       | 0    | 0    | 0    | 140743   |
| 002     | MACHINE02 | IDLE      | 0    | 0    | 0    | 19401    |
| 002     | MACHINE02 |           | 0    | 0    | 1    | 160144   |
| 002     |           |           | 0    | 1    | 1    | 160144   |
|         |           |           | 1    | 1    | 1    | 376131   |

总结：GROUPING(T.EQPSTATE) 即A列值为0 ， 表示该行数据统计结果，使用了EQPSTATE字段进行分组

GROUPING(T.FACTORY) AS A, GROUPING(T.EQP_ID) AS B 两列同时为0，说明FACTORY 和EQP_ID 同时出现在group by 字段后，即该行统计结果是基于这两个字段

GROUPING(T.FACTORY) AS A, GROUPING(T.EQP_ID) AS B ，GROUPING(T.EQPSTATE) AS C

A,B,C三列同时为0 ，说明该行统计结果基于group by A,B,C 分组的

A,B,C三列同时为1 ，说明该行统计结果group by null， 不使用任何rollup中出现的字段进行分组，等同于全局分组

### **五、 **   group_id  

 GROUP_ID()唯一标识反复组，能够通过group_id去除反复组 

 无参数，group  by对某些列的集合会进行重复的grouping，而实际上绝大多数情况下对结果集中的这些重复行是不需要的，那就必须有办法剔出这些重复grouping的行。当结果集中有n条重复grouping而形成的行时，每行的group_id()分别是0,1,…,n,这样我们在条件中加入一个group_id()<1就可以剔出这些重复grouping的行了。 

```plsql
-- ROLLUP 结合 GROUP_ID 使用
SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       GROUP_ID() AS D,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY ROLLUP(T.FACTORY, T.EQP_ID, T.EQPSTATE) 
 HAVING GROUP_ID()=0 ;
```

例如以下查询结果：



| FACTORY | EQP_ID    | EQP_STATE | D    | DURATION |
| ------- | --------- | --------- | ---- | -------- |
| 001     | MACHINE01 | RUN       | 0    | 201032   |
| 001     | MACHINE01 | IDLE      | 0    | 14955    |
| 001     | MACHINE01 |           | 0    | 215987   |
| 001     |           |           | 0    | 215987   |
| 002     | MACHINE02 | RUN       | 0    | 140743   |
| 002     | MACHINE02 | IDLE      | 0    | 19401    |
| 002     | MACHINE02 |           | 0    | 160144   |
| 002     |           |           | 0    | 160144   |
|         |           |           | 0    | 376131   |

案例：如果需要显示FACTORY、EQP_ID、EQPSTATE、DURATION , 同时显示按照FACTORY、EQP_ID汇总的小计DURATION

```plsql
-- ROOLUP + GROUPING_ID ，筛选想要的汇总行
SELECT *  FROM ( 
SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       GROUPING_ID(T.FACTORY,T.EQP_ID,T.EQPSTATE) AS D,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY ROLLUP(T.FACTORY, T.EQP_ID, T.EQPSTATE) 
 ORDER BY T.FACTORY , T.EQP_ID , T.EQPSTATE ) 
 WHERE D = 0 OR D = 1  ;
```



-- ROOLUP + GROUPING_ID ，筛选想要的汇总行
SELECT *  FROM ( 
SELECT T.FACTORY,
       T.EQP_ID,
       T.EQPSTATE,
       GROUPING_ID(T.FACTORY,T.EQP_ID,T.EQPSTATE) AS D,
       SUM(DURATION) AS DURATION
  FROM EQP_RUN_INFO T
 GROUP BY ROLLUP(T.FACTORY, T.EQP_ID, T.EQPSTATE) 
 ORDER BY T.FACTORY , T.EQP_ID , T.EQPSTATE ) 
 WHERE D = 0 OR D = 1  ;




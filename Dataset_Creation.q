--Creating the train table
CREATE EXTERNAL TABLE train (
msno String,
is_churn int
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE
LOCATION 's3://dubey031//Big_data_project//train';

--This table has header as first row of the dataset so creating a new table removing the header row

CREATE TABLE train_2 (
msno String,
is_churn int
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE train_2 
SELECT msno,is_churn 
FROM train
WHERE msno!='msno';

--992931 rows

--Creating the transactions table
CREATE EXTERNAL TABLE transactions (
msno String,
payment_method_id String,
payment_plan_days int,
plan_list_price int,
actual_amount_paid int,
is_auto_renew String,
transaction_date Date,
membership_expire_date Date,
is_cancel String
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE
LOCATION 's3://dubey031//Big_data_project//transactions';

--21547747 rows

CREATE EXTERNAL TABLE transactions_2 (
msno String,
payment_method_id String,
payment_plan_days int,
plan_list_price int,
actual_amount_paid int,
is_auto_renew int,
transaction_date Date,
membership_expire_date Date,
is_cancel int
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE;


INSERT OVERWRITE TABLE transactions_2 
SELECT msno,payment_method_id, cast(payment_plan_days as int) as payment_plan_days,
cast(plan_list_price as int) as plan_list_price,cast(actual_amount_paid as int) as actual_amount_paid,
cast(is_auto_renew as int) as is_auto_renew, to_date(from_unixtime(unix_timestamp(transaction_date, 'yyyy-MM-dd'))) as transaction_date ,
to_date(from_unixtime(unix_timestamp(membership_expire_date, 'yyyy-MM-dd'))) as membership_expire_date, cast(is_cancel as int) as is_cancel
FROM transactions
WHERE msno!='msno';

--21547746 rows

select *,case when msno is null 
OR payment_method_id is null OR payment_plan_days is null plan_list_price is null
OR actual_amount_paid is null OR is_auto_renew is null OR transaction_date is null 
OR membership_expire_date is null OR is_cancel is null THEN 1 ELSE 0 END as Null_flag
from transactions_2;


--Creating usage_logs table

CREATE EXTERNAL TABLE user_logs (
msno String,
usage_date Date,	
num_25  int,
num_50  int,
num_75	 int,
num_985	 int,
num_100	 int,
num_unq	 int,
total_secs float
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE
LOCATION 's3://dubey031//Big_data_project//user_logs';

CREATE EXTERNAL TABLE user_logs_2 (
msno String,
usage_date Date,	
num_25  int,
num_50  int,
num_75	 int,
num_985	 int,
num_100	 int,
num_unq	 int,
total_secs float
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE user_logs_2 
SELECT msno,to_date(from_unixtime(unix_timestamp(usage_date, 'yyyy-MM-dd'))) as usage_date, cast(num_25 as int) as num_25,
cast(num_50 as int) as num_50,cast(num_75 as int) as num_75,
cast(num_985 as int) as num_985, cast(num_100 as int) as num_100,
cast(num_unq as int) as num_unq, cast(total_secs as float) as total_secs
FROM user_logs
WHERE msno!='msno';

--392106543

--QC

 select count(*) from train_2 where msno is NULL;
 select count(*) from train_2 where is_churn is NULL;

 select count(*) from transactions_2 where msno is NULL;
 select count(*) from transactions_2 where payment_method_id is NULL;
 select count(*) from transactions_2 where payment_plan_days is NULL;
 select count(*) from transactions_2 where plan_list_price is NULL;
 select count(*) from transactions_2 where actual_amount_paid is NULL;
 select count(*) from transactions_2 where is_auto_renew is NULL;
 select count(*) from transactions_2 where transaction_date is NULL; 
 select count(*) from transactions_2 where membership_expire_date is NULL; 
 select count(*) from transactions_2 where is_cancel is NULL; 

 select count(*) from user_logs_2 where msno is NULL;
 select count(*) from user_logs_2 where usage_date is NULL;
 select count(*) from user_logs_2 where num_25 is NULL; 
 select count(*) from user_logs_2 where num_75 is NULL; 
 select count(*) from user_logs_2 where num_985 is NULL;
 select count(*) from user_logs_2 where num_100 is NULL;
 select count(*) from user_logs_2 where num_unq is NULL;
 select count(*) from user_logs_2 where total_secs is NULL;

 --aggregating user_logs table and fetching the latest records
 
 create table user_log_max_date as select msno, max(usage_date) as latest_date from user_logs group by msno;
--5234112

 create table user_logs_latest as select a.* from user_logs_2 a inner join user_log_max_date b on a.msno=b.msno and cast(a.usage_date as date)=cast(b.latest_date as date);
 
 create table user_logs_temp as
 select *, row_number() over (partition by msno order by usage_date desc) as row_num from user_logs_2;
 
 create table user_logs_2_1 as select * from user_logs_temp where row_num==1;
 --5234111 5234111

 create table user_logs_2_2 as select * from user_logs_temp where row_num==2;
 --3820211 3820211
 
 create table user_logs_f as select a.msno, a.usage_date,a.num_25,a.num_50,a.num_75,a.num_985,a.num_100	,a.num_unq,a.total_secs,
 b.usage_date as sec_last_usage_date,b.num_25 as sec_last_num_25,b.num_50 as sec_last_num_50,b.num_75 as sec_last_num_75,b.num_985 as sec_last_num_985,b.num_100 as sec_last_num_100,b.num_unq as sec_last_num_unq,b.total_secs as sec_last_total_secs from user_logs_2_1 as a left join user_logs_2_2 as b on a.msno=b.msno;
 
 --QC
 select count(*), sum(case when sec_last_num_25  is NULL then 1 else 0 end) from user_logs_f;
-- 5234111 1413900

--treating missing values
create table user_logs_fin as
select msno ,      
usage_date,            
num_25 ,           
num_50 ,               
num_75 ,              
num_985,              
num_100,               
num_unq,               
total_secs,            
COALESCE(sec_last_usage_date,0) as sec_last_usage_date,
COALESCE(sec_last_num_25,0) as sec_last_num_25,
COALESCE(sec_last_num_50,0) as sec_last_num_50,       
COALESCE(sec_last_num_75,0) as sec_last_num_75,    
COALESCE(sec_last_num_985,0) as sec_last_num_985,      
COALESCE(sec_last_num_100,0) as sec_last_num_100,      
COALESCE(sec_last_num_unq,0) as sec_last_num_unq,     
COALESCE(sec_last_total_secs,0) as sec_last_total_secs  
from user_logs_f;

 --aggregating transaction table

 create table trans_latest as 
 select a.msno , a.payment_method_id ,payment_plan_days ,plan_list_price ,actual_amount_paid ,is_auto_renew ,transaction_date ,membership_expire_date,is_cancel from 
(select *,  row_number() over (partition by msno order by transaction_date desc) as row_num from transactions_2) as a
 where a.row_num=1;
 
 --final aggregation
create table trans_usage as
 select a.*,usage_date,        
num_25,        
num_50 ,            
num_75  ,           
num_985  ,          
num_100   ,         
num_unq    ,        
total_secs  ,       
sec_last_usage_date,
sec_last_num_25,
sec_last_num_50,    
sec_last_num_75,    
sec_last_num_985,   
sec_last_num_100,   
sec_last_num_unq,   
sec_last_total_secs
from trans_latest a inner join
user_logs_f b
on a.msno=b.msno;
--1878611

CREATE TABLE Master_Dataset_v1 (
msno string,
payment_method_id string,
payment_plan_days float,
plan_list_price float,
actual_amount_paid float,
is_auto_renew int,
is_cancel int,
num_25 int,
num_50 int,
num_75 int,
num_985 int,
num_100 int,
num_unq int,
total_secs float,
sec_last_num_25 int,
sec_last_num_50 int,
sec_last_num_75 int,
sec_last_num_985 int,
sec_last_num_100 int,
sec_last_num_unq int,
sec_last_total_secs float,
is_churn int
) 
ROW FORMAT delimited by ','
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE  Master_Dataset_v1

create table Master_Dataset_v1 as
select a.msno,a.payment_method_id ,a.payment_plan_days, a.plan_list_price, a.actual_amount_paid, a.is_auto_renew,a.is_cancel,a.num_25,
a.num_50,a.num_75,a.num_985, a.num_100, a.num_unq, a.total_secs,a.sec_last_num_25, a.sec_last_num_50,a.sec_last_num_75,
a.sec_last_num_985,a.sec_last_num_100, a.sec_last_num_unq,a.sec_last_total_secs,
b.is_churn
from trans_usage as a inner join train_2 as b 
on a.msno=b.msno;

select count(*), count(distinct msno), sum(is_churn) from Dataset_final;
--869926  869926  57157.0

hadoop distcp hdfs://ip-172-31-44-188.ec2.internal:8020/user/hive/warehouse/master_dataset_v1  s3://dubey031//Big_data_project//
 
 --Creating the train table
CREATE EXTERNAL TABLE test (
msno String,
is_churn int
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE
LOCATION 's3://dubey031//Big_data_project//test';

--This table has header as first row of the dataset so creating a new table removing the header row

CREATE TABLE test_2 (
msno String,
is_churn int
) 
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde' WITH SERDEPROPERTIES 
("separatorChar" = "," , "quoteChar"="\"" ) 
STORED AS TEXTFILE;

INSERT OVERWRITE TABLE test_2 
SELECT msno,is_churn 
FROM test
WHERE msno!='msno';

 
 
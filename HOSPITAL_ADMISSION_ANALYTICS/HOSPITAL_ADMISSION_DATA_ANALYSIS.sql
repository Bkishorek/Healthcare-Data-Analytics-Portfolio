USE hospital_admission;

-- CHECKING OF COUNT OF DATA   -- 14620

SELECT * FROM hospital_data
LIMIT 100;


-- CHECKING DATA TYPE 
DESCRIBE hospital_data;

-- Changing the Admission and Discharge dates from string to date format

ALTER TABLE hospital_data
ADD COLUMN  clean_D_O_A DATE;

ALTER TABLE hospital_data
ADD COLUMN clean_D_O_D DATE;


-- Changing format of date to YYYY-mm-dd FORMAT(Date of Admission)

SET SQL_SAFE_UPDATES =0;

UPDATE hospital_data
SET clean_D_O_A =
CASE
    WHEN MONTH(
        STR_TO_DATE(CONCAT('01-', `month year`), '%d-%b-%y')
    ) =
    CAST(SUBSTRING_INDEX(D_O_A,'/',1) AS UNSIGNED)
    THEN STR_TO_DATE(D_O_A,'%m/%d/%Y')

    WHEN MONTH(
        STR_TO_DATE(CONCAT('01-', `month year`), '%d-%b-%y')
    ) =
    CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(D_O_A,'/',2), '/', -1) AS UNSIGNED)
    THEN STR_TO_DATE(D_O_A,'%d/%m/%Y')

    ELSE NULL
END;

-- changing discharge date to date format

UPDATE hospital_data
SET clean_D_O_D =
DATE_ADD(clean_D_O_A,
    INTERVAL (`Duration of Stay` - 1) DAY
);

-- Altering column name of some important columns

ALTER TABLE hospital_data
RENAME COLUMN `MRD No.` TO MRD_NO;

ALTER TABLE hospital_data
RENAME COLUMN `D_O_A` TO D_O_A;

ALTER TABLE hospital_data
RENAME COLUMN `D.O.D` TO D_O_D;


-- checking duplicate patient records and cleaning
-- Creating view to store cleaned data without duplicates

CREATE OR REPLACE VIEW V_admissiondata AS
-- Creating CTE cleanData inorder to extract non-duplicate data.

WITH cleanData AS (
SELECT * ,ROW_NUMBER() OVER(PARTITION BY MRD_NO,clean_D_O_A, clean_D_O_D  ORDER BY MRD_NO) AS DUPLICATES
FROM hospital_data)

-- EXTRACTING NON-DUPLICATES
SELECT * FROM cleanData
WHERE DUPLICATES = 1 AND MRD_NO IS NOT NULL;


SELECT count(*) FROM V_admissiondata;  
-- 13339 data after cleaning.


-- Q1 Total Discharges 

SELECT COUNT(*) FROM V_admissiondata 
WHERE OUTCOME = 'DISCHARGE' ;  
 -- 12008 


-- Q2 Average daily discharge rate

SELECT CAST( 
( (SELECT COUNT(*) FROM V_admissiondata 
WHERE OUTCOME = 'DISCHARGE' ) / (SELECT SUM(`DURATION OF STAY`) FROM V_admissiondata ) )  AS DECIMAL (10,2) ) * 100 AS AVG_DAILY_DISCHARGE;
-- 14

-- Average discharge calculated without using subquery --
SELECT 
    ROUND(SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1.0 ELSE 0.0 END )/ 
    SUM(`DURATION OF STAY`),2)* 100 AS AVG_DAILY_DISCHARGE FROM V_admissiondata;
 -- avg_discharge - 14
 
 -- Q3 - Average Length of Stay(ALOS)
 -- WEN CALCULATED FOR WHOLE OUTCOME
 SELECT CAST(AVG(`DURATION OF STAY`) AS DECIMAL(10,0)) AS Avg_Length_Stay FROM V_admissiondata;
 -- 6
 
 -- Total length of stay / total discharge (if calculated only for discharged patient)
 SELECT 
    ROUND(SUM(`DURATION OF STAY`)/ SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1.0 ELSE 0.0 END)
    ,2) AS Avg_Length_Stay FROM V_admissiondata;
-- 7

-- Q4 -Distribution of discharges by age group
-- grouping by paediatric, adult, senior
-- <16 - paeditric
-- 16 < age > 65 - adult
-- <= 65 - senior

SELECT COUNT(MRD_NO) AS TOTAL_PATIENTS,
 CASE WHEN 
       AGE < 16 THEN 'paediatric'
    WHEN 
       AGE < 65 THEN 'Adult'
	WHEN 
       AGE >= 65 THEN 'Senior'
    ELSE 
	   'Unknown' END AS AGE_GROUP , SUM(CASE WHEN OUTCOME = 'DISCHARGE' THEN 1.0 ELSE 0.0 END) AS TOTAL_DISCHARGE
FROM V_admissiondata 
GROUP BY AGE_GROUP;

-- Q5 Distribution of discharge by gender

SELECT GENDER , COUNT(*) AS GENDER_DISCHARGE
FROM V_admissiondata 
WHERE OUTCOME = 'DISCHARGE'
GROUP BY GENDER
ORDER BY 2 DESC;

-- Q6 Distribution of discharge by week day name

SELECT DAYNAME(clean_D_O_D) AS weekday_name, COUNT(OUTCOME) AS Total_Discharge FROM V_admissiondata 
WHERE OUTCOME = 'DISCHARGE'
GROUP BY weekday_name;

-- Q7 Distribution of discharge by day of week

SELECT DAYOFWEEK(clean_D_O_D) AS weekdays, COUNT(OUTCOME) AS Total_Discharge FROM V_admissiondata 
WHERE OUTCOME = 'DISCHARGE'
GROUP BY weekdays
ORDER BY weekdays;


 






    
     
	
    
   
    
 
 
   





   




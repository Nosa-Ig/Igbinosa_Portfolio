CREATE DATABASE IF NOT EXISTS healthcare_capstone
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE healthcare_capstone;
-- Raw staging: everything as TEXT so import doesn’t fail
DROP TABLE IF EXISTS stg_hospitalisation;
CREATE TABLE stg_hospitalisation (
  Customer_ID              TEXT,
  year                     TEXT,
  month                    TEXT,
  date                     TEXT,
  Hospital_tier            TEXT,
  City_tier                TEXT,
  State_ID                 TEXT,
  children                 TEXT,
  charges                  TEXT
  -- add other columns from your file if needed (e.g., 'name', etc.)
);

DROP TABLE IF EXISTS stg_medical;
CREATE TABLE stg_medical (
  Customer_ID              TEXT,
  BMI                      TEXT,
  HBA1C                    TEXT,
  Heart_Issues             TEXT,
  Any_Transplants          TEXT,
  Cancer_history           TEXT,
  NumberOfMajorSurgeries   TEXT
  -- add other columns from your file if needed
);
DROP TABLE IF EXISTS Hospitalisation;
CREATE TABLE Hospitalisation (
  Customer_ID            BIGINT PRIMARY KEY,
  year                   INT NULL,
  month                  INT NULL,
  date                   INT NULL,
  Hospital_tier          VARCHAR(20) NULL,
  City_tier              VARCHAR(20) NULL,
  State_ID               VARCHAR(20) NULL,
  children               INT NULL,
  charges                DECIMAL(12,2) NOT NULL
);
DROP TABLE IF EXISTS MedicalExams;
CREATE TABLE MedicalExams (
  Customer_ID            BIGINT PRIMARY KEY,
  BMI                    DECIMAL(6,2) NULL,
  HBA1C                  DECIMAL(4,2) NULL,
  Heart_Issues           TINYINT NULL,
  Any_Transplants        TINYINT NULL,
  Cancer_history         TINYINT NULL,
  NumberOfMajorSurgeries INT NULL
);
-- Helper: map yes/no strings to 1/0
-- We'll inline CASE expressions in INSERT SELECT

-- Hospitalisation
INSERT INTO Hospitalisation (
  Customer_ID, year, month, date, Hospital_tier, City_tier, State_ID, children, charges
)
SELECT
  CAST(NULLIF(TRIM(Customer_ID), '') AS UNSIGNED)                                            AS Customer_ID,
  CAST(NULLIF(TRIM(year), '') AS SIGNED)                                                     AS year,
  CAST(NULLIF(TRIM(month), '') AS SIGNED)                                                    AS month,
  CAST(NULLIF(TRIM(date), '') AS SIGNED)                                                     AS date,
  -- normalize "tier 1" -> "tier-1", lowercase
  LOWER(REPLACE(TRIM(Hospital_tier), 'tier ', 'tier-'))                                      AS Hospital_tier,
  LOWER(REPLACE(TRIM(City_tier),     'tier ', 'tier-'))                                      AS City_tier,
  UPPER(TRIM(State_ID))                                                                       AS State_ID,
  CAST(NULLIF(TRIM(children), '') AS SIGNED)                                                 AS children,
  CAST(NULLIF(REPLACE(TRIM(charges), ',', ''), '') AS DECIMAL(12,2))                         AS charges
FROM stg_hospitalisation
WHERE NULLIF(TRIM(Customer_ID),'') IS NOT NULL
  AND NULLIF(TRIM(charges),'') IS NOT NULL;
-- Deduplicate by Customer_ID if the CSV contained duplicates (keep one deterministic row)
-- (MySQL 8 supports window functions)
WITH ranked AS (
  SELECT h.*,
         ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Customer_ID) AS rn
  FROM Hospitalisation h
)
DELETE FROM Hospitalisation
WHERE (Customer_ID) IN (
  SELECT Customer_ID FROM ranked WHERE rn > 1
);
-- MedicalExams
INSERT INTO MedicalExams (
  Customer_ID, BMI, HBA1C, Heart_Issues, Any_Transplants, Cancer_history, NumberOfMajorSurgeries
)
SELECT
  CAST(NULLIF(TRIM(Customer_ID), '') AS UNSIGNED)                                            AS Customer_ID,
  CAST(NULLIF(TRIM(BMI),   '') AS DECIMAL(6,2))                                              AS BMI,
  CAST(NULLIF(TRIM(HBA1C), '') AS DECIMAL(4,2))                                              AS HBA1C,
  CASE LOWER(TRIM(Heart_Issues))
       WHEN 'yes' THEN 1 WHEN 'true' THEN 1 WHEN 'y' THEN 1 WHEN '1' THEN 1
       WHEN 'no'  THEN 0 WHEN 'false' THEN 0 WHEN 'n' THEN 0 WHEN '0' THEN 0
       ELSE NULL END                                                                          AS Heart_Issues,
  CASE LOWER(TRIM(Any_Transplants))
       WHEN 'yes' THEN 1 WHEN 'true' THEN 1 WHEN 'y' THEN 1 WHEN '1' THEN 1
       WHEN 'no'  THEN 0 WHEN 'false' THEN 0 WHEN 'n' THEN 0 WHEN '0' THEN 0
       ELSE NULL END                                                                          AS Any_Transplants,
  CASE LOWER(TRIM(Cancer_history))
       WHEN 'yes' THEN 1 WHEN 'true' THEN 1 WHEN 'y' THEN 1 WHEN '1' THEN 1
       WHEN 'no'  THEN 0 WHEN 'false' THEN 0 WHEN 'n' THEN 0 WHEN '0' THEN 0
       ELSE NULL END                                                                          AS Cancer_history,
  -- extract first integer from strings like '2 surgeries', '3+', '0'
  CAST(
    NULLIF(
      REGEXP_REPLACE(TRIM(NumberOfMajorSurgeries), '[^0-9]', ''),
      ''
    ) AS SIGNED
  )                                                                                           AS NumberOfMajorSurgeries
FROM stg_medical
WHERE NULLIF(TRIM(Customer_ID),'') IS NOT NULL;
-- Deduplicate MedicalExams as well
WITH ranked AS (
  SELECT m.*,
         ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Customer_ID) AS rn
  FROM MedicalExams m
)
DELETE FROM MedicalExams
WHERE (Customer_ID) IN (
  SELECT Customer_ID FROM ranked WHERE rn > 1
);
CREATE INDEX ix_hosp_tiers ON Hospitalisation (Hospital_tier, City_tier);
CREATE INDEX ix_hosp_state ON Hospitalisation (State_ID);
CREATE INDEX ix_med_hba1c ON MedicalExams (HBA1C);
CREATE INDEX ix_med_flags ON MedicalExams (Heart_Issues, Cancer_history);
SELECT 
  AVG(YEAR(CURDATE()) - NULLIF(year, 0))               AS avg_age_approx,
  AVG(children)                                        AS avg_children,
  AVG(MedicalExams.BMI)                                AS avg_BMI,
  AVG(Hospitalisation.charges)                         AS avg_charges
FROM Hospitalisation
JOIN MedicalExams USING (Customer_ID)
WHERE MedicalExams.HBA1C >= 6.5
  AND MedicalExams.Heart_Issues = 1;
  SELECT 
  Hospital_tier,
  City_tier,
  AVG(charges) AS avg_charges,
  COUNT(*)     AS patients
FROM Hospitalisation
GROUP BY Hospital_tier, City_tier
ORDER BY Hospital_tier, City_tier;
SELECT 
  COUNT(*) AS count_with_major_surgery_and_cancer_history
FROM MedicalExams
WHERE COALESCE(NumberOfMajorSurgeries, 0) > 0
  AND Cancer_history = 1;
SELECT 
  State_ID, 
  COUNT(*) AS tier1_hosp_count
FROM Hospitalisation
WHERE Hospital_tier = 'tier-1'
GROUP BY State_ID
ORDER BY tier1_hosp_count DESC;
UPDATE Hospitalisation
SET Hospital_tier = LOWER(REPLACE(Hospital_tier, 'tier ', 'tier-'));
UPDATE Hospitalisation
SET City_tier = LOWER(REPLACE(City_tier, 'tier ', 'tier-'));
UPDATE MedicalExams
SET Heart_Issues = CASE
  WHEN LOWER(Heart_Issues) IN ('yes','true','y','1') THEN 1
  WHEN LOWER(Heart_Issues) IN ('no','false','n','0') THEN 0
  ELSE NULL END
WHERE Heart_Issues IS NULL OR Heart_Issues NOT IN (0,1);
SELECT 
  AVG(YEAR(CURDATE()) - NULLIF(h.year, 0))       AS avg_age_approx,
  AVG(h.children)                                 AS avg_children,
  AVG(m.BMI)                                      AS avg_BMI,
  AVG(h.charges)                                  AS avg_charges
FROM Hospitalisation h
JOIN MedicalExams m USING (Customer_ID)
WHERE m.HBA1C >= 6.5   -- diabetic threshold
  AND m.Heart_Issues = 1;
SELECT 
  AVG(TIMESTAMPDIFF(
      YEAR,
      STR_TO_DATE(CONCAT(h.year,'-',h.month,'-',h.date), '%Y-%m-%d'),
      CURDATE()
  ))                                              AS avg_age,
  AVG(h.children)                                 AS avg_children,
  AVG(m.BMI)                                      AS avg_BMI,
  AVG(h.charges)                                  AS avg_charges
FROM Hospitalisation h
JOIN MedicalExams m USING (Customer_ID)
WHERE m.HBA1C >= 6.5
  AND m.Heart_Issues = 1;
SELECT 
  h.Hospital_tier,
  h.City_tier,
  AVG(h.charges) AS avg_charges,
  COUNT(*)       AS patients
FROM Hospitalisation h
GROUP BY h.Hospital_tier, h.City_tier
ORDER BY h.Hospital_tier, h.City_tier;
-- If NumberOfMajorSurgeries is numeric already:
SELECT 
  COUNT(*) AS count_with_major_surgery_and_cancer_history
FROM MedicalExams m
WHERE COALESCE(m.NumberOfMajorSurgeries, 0) > 0
  AND m.Cancer_history = 1;
SELECT 
  COUNT(*) AS count_with_major_surgery_and_cancer_history
FROM MedicalExams m
WHERE CAST(REGEXP_SUBSTR(m.NumberOfMajorSurgeries, '[0-9]+') AS UNSIGNED) > 0
  AND m.Cancer_history = 1;
SELECT 
  h.State_ID,
  COUNT(*) AS tier1_hosp_count
FROM Hospitalisation h
WHERE LOWER(h.Hospital_tier) = 'tier-1'
GROUP BY h.State_ID
ORDER BY tier1_hosp_count DESC;
UPDATE Hospitalisation
SET Hospital_tier = LOWER(REPLACE(Hospital_tier, 'tier ', 'tier-'));

create database Employee;

Select EMP_ID,FIRST_NAME,LAST_NAME,GENDER,DEPT  from emp_record_table order by EMP_ID ;

SELECT EMP_ID,
       FIRST_NAME,
       LAST_NAME,
       GENDER,
       DEPT,
       EMP_RATING,
       CASE
           WHEN EMP_RATING < 2 THEN 'Below 2'
           WHEN EMP_RATING BETWEEN 2 AND 4 THEN 'Between 2 and 4'
           WHEN EMP_RATING > 4 THEN 'Above 4'
       END AS RATING_CATEGORY
FROM emp_record_table order by  RATING_CATEGORY;

SELECT 
    CONCAT(FIRST_NAME, ' ', LAST_NAME) AS NAME
FROM 
   emp_record_table 
WHERE 
    DEPT = 'Finance';
    
   SELECT 
    m.EMP_ID,
    CONCAT(m.FIRST_NAME, ' ', m.LAST_NAME) AS NAME,
    COUNT(e.EMP_ID) AS NumberOfReporters
FROM emp_record_table AS m
JOIN emp_record_table AS e
    ON m.EMP_ID = e.MANAGER_ID
GROUP BY 
    m.EMP_ID,
    m.FIRST_NAME,
    m.LAST_NAME
ORDER BY 
    NumberOfReporters DESC;
    
 SELECT 
    m.EMP_ID,
    CONCAT(m.FIRST_NAME, ' ', m.LAST_NAME) AS NAME,
    COUNT(e.EMP_ID) AS NumberOfReporters
FROM emp_record_table AS m
JOIN emp_record_table AS e
    ON m.EMP_ID = e.MANAGER_ID
GROUP BY 
    m.EMP_ID,
    m.FIRST_NAME,
    m.LAST_NAME
ORDER BY 
    NumberOfReporters DESC;
    SELECT *
FROM emp_record_table
WHERE DEPT = 'Healthcare'

UNION

SELECT *
FROM emp_record_table
WHERE DEPT='Finance'
order by EMP_ID;
SELECT 
    e.EMP_ID,
    e.FIRST_NAME,
    e.LAST_NAME,
    e.ROLE,
    e.DEPT,
    e.EMP_RATING,
    d.Max_Rating_In_Dept
FROM emp_record_table e
JOIN (
    SELECT 
        DEPT, 
        MAX(EMP_RATING) AS Max_Rating_In_Dept
    FROM emp_record_table
    GROUP BY DEPT
) d
ON e.DEPT= d.DEPT
ORDER BY e.DEPT, e.EMP_RATING DESC;
SELECT 
    ROLE,
    MIN(SALARY) AS Min_Salary,
    MAX(SALARY) AS Max_Salary
FROM emp_record_table
GROUP BY ROLE
ORDER BY ROLE;
SELECT 
    EMP_ID,
    FIRST_NAME,
    LAST_NAME,
    ROLE,
    DEPT,
    EXP,
    RANK() OVER (ORDER BY EXP DESC) AS Experience_Rank
FROM emp_record_table
ORDER BY Experience_Rank;
CREATE VIEW High_Salary_Employees AS
SELECT 
    EMP_ID,
    FIRST_NAME,
    LAST_NAME,
    ROLE,
    DEPT,
    COUNTRY,
    SALARY
FROM emp_record_table
WHERE SALARY > 6000;
SELECT EMP_ID, FIRST_NAME, LAST_NAME, ROLE, DEPT, EXP
FROM emp_record_table
WHERE EXP > (
    SELECT MIN(EXP)
    FROM emp_record_table
    WHERE EXP> 10
);
DELIMITER $$

CREATE PROCEDURE Get_Experienced_Employees()
BEGIN
    SELECT 
        EMP_ID,
        FIRST_NAME,
        LAST_NAME,
        ROLE,
        DEPT,
        EXPERIENCE
    FROM emp_record_table
    WHERE EXPERIENCE > 3;
END $$

DELIMITER ;

DELIMITER $$

CREATE FUNCTION Get_Standard_Job_Title (exp INT)
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE standard_title VARCHAR(50);

    IF exp <= 2 THEN
        SET standard_title = 'JUNIOR DATA SCIENTIST';
    ELSEIF exp > 2 AND exp <= 5 THEN
        SET standard_title = 'ASSOCIATE DATA SCIENTIST';
    ELSEIF exp > 5 AND exp <= 10 THEN
        SET standard_title = 'SENIOR DATA SCIENTIST';
    ELSEIF exp > 10 AND exp <= 12 THEN
        SET standard_title = 'LEAD DATA SCIENTIST';
    ELSEIF exp > 12 AND exp <= 16 THEN
        SET standard_title = 'MANAGER';
    ELSE
        SET standard_title = 'NO STANDARD ROLE DEFINED';
    END IF;

    RETURN standard_title;
END$$

DELIMITER ;
EXPLAIN SELECT * 
FROM emp_record_table
WHERE FIRST_NAME = 'Eric';

CREATE INDEX idx_first_name 
ON emp_record_table (FIRST_NAME);
CREATE INDEX idx_first_name
ON emp_record_table (FIRST_NAME(20));
EXPLAIN SELECT *
FROM emp_record_table
WHERE FIRST_NAME = 'Eric';
SELECT 
    EMP_ID,
    FIRST_NAME,
    LAST_NAME,
    SALARY,
    EMP_RATING,
    (0.05 * SALARY * EMP_RATING) AS BONUS
FROM emp_record_table;
SELECT 
    CONTINENT,
    COUNTRY,
    AVG(SALARY) AS Avg_Salary
FROM emp_record_table
GROUP BY 
    CONTINENT,
    COUNTRY
ORDER BY 
    CONTINENT,
    COUNTRY;

/*******************************************************
Script: co859.txt - Lab 7
Author: Justin Donaldson
Date: November 29, 2023
Description: Add a trigger to update the year to date sales values
********************************************************/

-- Setting NOCOUNT ON suppresses completion messages for each INSERT
SET NOCOUNT ON

-- Set date format to year, month, day
SET DATEFORMAT ymd;

-- Make the master database the current database
USE master

-- If database co859 exists, drop it
IF EXISTS (SELECT * FROM sysdatabases WHERE name = 'co859')
BEGIN
  ALTER DATABASE co859 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE co859;
END
GO

-- Create the co859 database
CREATE DATABASE co859;
GO

-- Make the co859 database the current database
USE co859;

-- Create a customers Table?
CREATE TABLE jjs_customers (
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(30));

-- Create jjs_services table
CREATE TABLE jjs_services (
  service_id INT PRIMARY KEY, 
  service_description VARCHAR(30), 
  service_type CHAR(1) CHECK (service_type IN ('M', 'S', 'R')), 
  hourly_rate MONEY,
  sales_ytd MONEY); 

-- Create sales table
CREATE TABLE jjs_sales (
	sales_id INT PRIMARY KEY, 
	sales_date DATE, 
	amount MONEY, 
	service_id INT FOREIGN KEY REFERENCES jjs_services(service_id),
	customer_id INT FOREIGN KEY REFERENCES jjs_customers(customer_id));
GO



-- Insert Custoemr records
INSERT INTO jjs_customers VALUES(1, 'Jack');
INSERT INTO jjs_customers VALUES(2, 'John');
INSERT INTO jjs_customers VALUES(3, 'Jeff');
INSERT INTO jjs_customers VALUES(4, 'Jake');
INSERT INTO jjs_customers VALUES(5, 'Joseph');
INSERT INTO jjs_customers VALUES(6, 'Jacob');

-- Insert Services records
INSERT INTO jjs_services VALUES(100, 'Maintenance','M', 100, 300);
INSERT INTO jjs_services VALUES(200, 'Service',    'S',  75, 300);
INSERT INTO jjs_services VALUES(300, 'Repair',     'R',  75, 225);

-- Insert Sales records
INSERT INTO jjs_sales VALUES(1, '2023-7-6',       75,    100, 1); -- Month and day don't have to be 2 digits
INSERT INTO jjs_sales VALUES(2, '2023-07-08',    100,    200, 3); -- But they typically are
INSERT INTO jjs_sales VALUES(3, '2023-07-11',    500,    100, 4);
INSERT INTO jjs_sales VALUES(4, '2023-07-15',    150,    100, 2);
INSERT INTO jjs_sales VALUES(5, '2023-07-21',    100,    300, 1);
INSERT INTO jjs_sales VALUES(6, '2023-07-28',     75,    100, 5);
INSERT INTO jjs_sales VALUES(7, '2023-08-02',    125,    300, 6);
INSERT INTO jjs_sales VALUES(8, '2023-08-05',    300,    200, 2);
INSERT INTO jjs_sales VALUES(9, '2023-08-10',    125,    200, 1);
INSERT INTO jjs_sales VALUES(10, '2023-08-18',    50,    300, 4);
INSERT INTO jjs_sales VALUES(11, '2023-08-24',    85,    200, 4);
INSERT INTO jjs_sales VALUES(12, '2023-08-30',   115,    300, 6);
INSERT INTO jjs_sales VALUES(13, '2023-09-03',    75,    200, 5);
INSERT INTO jjs_sales VALUES(14, '2023-09-07',   150,    100, 2);
INSERT INTO jjs_sales VALUES(15, '2023-09-09',    75,    300, 3);
GO

-- Create the index
CREATE INDEX customer_id
ON jjs_customers (customer_name);


-- Verify inserts ?? - is this testing to see what items are available within a specific table?
CREATE TABLE verify (
  table_name varchar(30), 
  actual INT, 
  expected INT);
GO

INSERT INTO verify VALUES('jjs_customers', (SELECT COUNT(*) FROM jjs_customers), 6);
INSERT INTO verify VALUES('jjs_services', (SELECT COUNT(*) FROM jjs_services), 3);
INSERT INTO verify VALUES('jjs_sales', (SELECT COUNT(*) FROM jjs_sales), 15);
PRINT 'Verification';
SELECT table_name, actual, expected, expected - actual discrepancy FROM verify;
DROP TABLE verify;
GO

-- A query to view the most recent Sales Data.
CREATE VIEW Most_relevant_data
AS
SELECT sales_date, sales_id, customer_id, service_id
FROM jjs_sales
WHERE sales_date > '2023-08-15'
GO





--Trigger to update the year to date sales amount after a UPDATE/INSERT/DELETE on the sales table
CREATE TRIGGER Year_To_Date_Sales_Update ON jjs_sales
	AFTER INSERT, UPDATE, DELETE   
AS
	UPDATE services 
	SET sales_ytd = sales.total
	FROM jjs_services services
	INNER JOIN 
		(
			SELECT SUM(amount) total, service_id
			FROM jjs_sales
			WHERE sales_date >= DATEADD(year, -1, GETDATE())
			GROUP BY service_id
		) sales
		ON sales.service_id = services.service_id
GO

-- Verification
PRINT 'Verify triggers'
PRINT 'Master Table Before Changes'
SELECT * from jjs_services
INSERT INTO jjs_sales VALUES(16, '2023-09-07',   15000,    100, 2);

PRINT 'After INSERT'
SELECT * from jjs_services
DELETE FROM jjs_sales WHERE jjs_sales.sales_id = 16;

PRINT 'After DELETE'
SELECT * from jjs_services
UPDATE jjs_sales SET amount = 15 WHERE amount = 150;
PRINT 'After UPDATE'
SELECT * from jjs_services
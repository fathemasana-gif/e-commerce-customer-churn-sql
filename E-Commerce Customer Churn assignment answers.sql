USE ecomm;
SELECT*FROM customer_churn;

-- 1)DATA CLEANING

-- IMPUTING MEAN
-- FINDING ROUNDED AVERAGE
SELECT
  ROUND(AVG(WarehouseToHome)) AS avg_WarehouseToHome,
  ROUND(AVG(HourSpendOnApp))  AS avg_HourSpendOnApp,
  ROUND(AVG(OrderAmountHikeFromlastYear)) AS avg_OrderHike,
  ROUND(AVG(DaySinceLastOrder))   AS avg_DaySinceLastOrder
FROM customer_churn;
-- REPLACING NULL WITH AVG VALUES
UPDATE customer_churn SET WarehouseToHome = 16 WHERE WarehouseToHome IS NULL;
UPDATE customer_churn SET HourSpendOnApp =3 WHERE HourSpendOnApp IS NULL;
UPDATE customer_churn SET OrderAmountHikeFromlastYear = 16 WHERE OrderAmountHikeFromlastYear IS NULL;
UPDATE customer_churn SET DaySinceLastOrder =5 WHERE DaySinceLastOrder IS NULL;

SET SQL_SAFE_UPDATES = 0;

-- IMPUTE MODE 
SELECT Tenure, 
COUNT(*) AS count_ten FROM customer_churn
 GROUP BY Tenure
 ORDER BY count_ten DESC
 LIMIT 1;
SELECT CouponUsed, 
COUNT(*) AS count_coup FROM customer_churn 
GROUP BY CouponUsed
 ORDER BY count_coup DESC 
 LIMIT 1;
SELECT OrderCount,
COUNT(*) AS count_order FROM customer_churn 
 GROUP BY OrderCount
 ORDER BY count_order DESC
 LIMIT 1;
 
 -- filling mode

UPDATE customer_churn SET Tenure = 1 WHERE Tenure IS NULL;
UPDATE customer_churn SET CouponUsed = 1 WHERE CouponUsed IS NULL;
UPDATE customer_churn SET OrderCount = 2 WHERE OrderCount IS NULL;

-- HANDLING OutLIERS
DELETE FROM customer_churn WHERE WarehouseToHome > 100;

-- 2) Dealing with Inconsistencies  
UPDATE customer_churn SET PreferredLoginDevice = 'Mobile phone' WHERE PreferredLoginDevice = 'Phone';
UPDATE customer_churn SET PreferedOrderCat = 'Mobile Phone' WHERE PreferedOrderCat = 'Mobile';

UPDATE customer_churn SET PreferredPaymentMode = 'Cash on Delivery' WHERE PreferredPaymentMode = 'COD';
UPDATE customer_churn SET PreferredPaymentMode = 'Credit Card' WHERE PreferredPaymentMode = 'CC';

-- 3) Data transformation

-- column renaming
ALTER TABLE customer_churn RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;
ALTER TABLE customer_churn RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;

-- creating new columns
ALTER TABLE customer_churn 
ADD COLUMN ComplaintReceived VARCHAR(50);
UPDATE customer_churn 
SET ComplaintReceived = CASE WHEN Complain = 1 THEN 'Yes' ELSE 'No' 
END;
ALTER TABLE customer_churn 
ADD COLUMN ChurnStatus VARCHAR(10);
UPDATE customer_churn
SET ChurnStatus = CASE WHEN Churn = 1 THEN 'Churned' ELSE 'Active' 
END;
 
 -- column dropping
 ALTER TABLE customer_churn DROP COLUMN Churn, DROP COLUMN Complain;
 
-- 4) Data exploration and analysis

-- count of churned and active customers
SELECT ChurnStatus,COUNT(*) AS customer_count
FROM customer_churn GROUP BY churnstatus;

-- average tenure and total cashback amount who churned
SELECT AVG(Tenure) AS AvgTenure, 
SUM(CashbackAmount) AS TotalCashback
FROM customer_churn WHERE ChurnStatus = 'Churned';

-- percentage of churned customers who complained
SELECT ROUND(SUM(ComplaintReceived = 'Yes') / COUNT(*) * 100) AS PctComplained
FROM customer_churn WHERE ChurnStatus = 'Churned';

-- city tier with highest no of churned customers ->laptop and accessory
SELECT CityTier, COUNT(*) AS ChurnedCustomers
FROM customer_churn
WHERE ChurnStatus = 'Churned' AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier ORDER BY ChurnedCustomers DESC LIMIT 1;

-- most preffered payment mode ->active customeers
SELECT PreferredPaymentMode, COUNT(*) AS preferedmode
FROM customer_churn WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode ORDER BY preferedmode DESC LIMIT 1;

-- Total order amount hike for single customers -> prefer mobile phones
SELECT SUM(OrderAmountHikeFromlastYear) AS TotalHike
FROM customer_churn
WHERE MaritalStatus = 'Single' AND PreferredOrderCat = 'Mobile Phone';

-- Average devices registered for UPI users
SELECT ROUND(AVG(NumberOfDeviceRegistered)) AS AvgDevices
FROM customer_churn WHERE PreferredPaymentMode = 'UPI';

-- City tier with the most customers
SELECT Citytier, COUNT(*) AS most_customers
FROM customer_churn GROUP BY CityTier ORDER BY most_customers DESC LIMIT 1;

-- gender that used most coupond
SELECT Gender, SUM(CouponUsed) AS Totalcoupons
FROM customer_churn GROUP BY Gender ORDER BY Totalcoupons DESC LIMIT 1;

-- Customers and max hours on app ->r category
SELECT PreferredOrderCat, COUNT(*) AS Customers, MAX(HoursSpentOnApp) AS Maxhours
FROM customer_churn GROUP BY PreferredOrderCat;

-- total order count with cc and max satisfaction
SELECT SUM(OrderCount) AS Totalorders
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- Average satisfaction score of customers who complained
SELECT ROUND(AVG(SatisfactionScore)) AS Avgsatisfied
FROM customer_churn WHERE Complaintreceived = 'Yes';

-- order category among who has more than 5 coupons
SELECT distinct PreferredOrderCat
FROM customer_churn WHERE Couponused > 5;

-- top 3 order with avd cashback high
SELECT PreferredOrderCat, AVG(CashbackAmount) AS AvgCashback
FROM customer_churn
GROUP BY PreferredOrderCat ORDER BY AvgCashback DESC LIMIT 3;

-- modes with average tenure of 10 mnths and more than 500 orde
SELECT PreferredPaymentMode
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING AVG(Tenure) = 10 AND SUM(OrderCount) > 500;

-- churn status breakdown
SELECT
  CASE
    WHEN WarehouseToHome <= 5  THEN 'Very Close Distance'
    WHEN WarehouseToHome <= 10 THEN 'Close Distance'
    WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
    ELSE 'Far Distance'
   end AS DistanceCategory,ChurnStatus,COUNT(*) AS Customers
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

-- CUSTOMER DETAILS
SELECT *
FROM customer_churn
WHERE MaritalStatus = 'Married' AND CityTier = 1
AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);

-- customer returns

CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount INT
);

INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) 
VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

desc customer_returns;
select*from customer_returns;
select*from customer_returns;
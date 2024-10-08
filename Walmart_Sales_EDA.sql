-- Inspect the data
SELECT *
FROM walmart_sales_raw
LIMIT 10;


-- Create new tables with a database structure
CREATE TABLE Stores (
    store_id INT PRIMARY KEY
);

CREATE TABLE Economic_Indicators (
    indicator_id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE,
    holiday_flag TINYINT,
    temperature DECIMAL(5,2),
    fuel_price DECIMAL(4,3),
    cpi DECIMAL(10,7),
    unemployment DECIMAL(5,3)
);

CREATE TABLE Sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    store_id INT,
    indicator_id INT,
    weekly_sales DECIMAL(12,2),
    FOREIGN KEY (store_id) REFERENCES Stores(store_id),
    FOREIGN KEY (indicator_id) REFERENCES Economic_Indicators(indicator_id)
);

-- Populate the tables
INSERT INTO Stores (store_id)
SELECT DISTINCT Store
FROM walmart_sales_raw;

-- Populate Economic_Indicators table
INSERT INTO Economic_Indicators (date, holiday_flag, temperature, fuel_price, cpi, unemployment)
SELECT DISTINCT 
    STR_TO_DATE(Date, '%d-%m-%Y'),
    Holiday_Flag,
    Temperature,
    Fuel_Price,
    CPI,
    Unemployment
FROM walmart_sales_raw;

-- Populate Sales table
INSERT INTO Sales (store_id, indicator_id, weekly_sales)
SELECT w.Store, e.indicator_id, w.Weekly_Sales
FROM walmart_sales_raw w
JOIN Economic_Indicators e ON STR_TO_DATE(w.Date, '%d-%m-%Y') = e.date
    AND w.Holiday_Flag = e.holiday_flag
    AND w.Temperature = e.temperature
    AND w.Fuel_Price = e.fuel_price
    AND w.CPI = e.cpi
    AND w.Unemployment = e.unemployment;
    

-- Check data quality
-- Check for null values
SELECT 
    'Sales' AS table_name,
    COUNT(*) - COUNT(store_id) AS null_store_id,
    COUNT(*) - COUNT(indicator_id) AS null_indicator_id,
    COUNT(*) - COUNT(weekly_sales) AS null_weekly_sales,
    NULL AS placeholder1,  -- Placeholder for Economic_Indicators column 1
    NULL AS placeholder2,  -- Placeholder for Economic_Indicators column 2
    NULL AS placeholder3,  -- Placeholder for Economic_Indicators column 3
    NULL AS placeholder4   -- Placeholder for Economic_Indicators column 4
FROM Sales

UNION ALL

SELECT 
    'Stores' AS table_name,
    COUNT(*) - COUNT(store_id) AS null_store_id,
    NULL AS placeholder1,  -- Placeholder for Economic_Indicators column 1
    NULL AS placeholder2,  -- Placeholder for Economic_Indicators column 2
    NULL AS placeholder3,  -- Placeholder for Economic_Indicators column 3
    NULL AS placeholder4,  -- Placeholder for Economic_Indicators column 4
    NULL AS placeholder5,  -- Placeholder for Economic_Indicators column 5
    NULL AS placeholder6   -- Placeholder for Economic_Indicators column 6
FROM Stores

UNION ALL

SELECT 
    'Economic_Indicators' AS table_name,
    COUNT(*) - COUNT(indicator_id) AS null_indicator_id,
    COUNT(*) - COUNT(date) AS null_date,
    COUNT(*) - COUNT(holiday_flag) AS null_holiday_flag,
    COUNT(*) - COUNT(temperature) AS null_temperature,
    COUNT(*) - COUNT(fuel_price) AS null_fuel_price,
    COUNT(*) - COUNT(cpi) AS null_cpi,
    COUNT(*) - COUNT(unemployment) AS null_unemployment 
FROM Economic_Indicators;

-- Exploratory data analysis
-- 1. Basic data overview
-- Count of records in each table
SELECT COUNT(*) FROM Stores;
SELECT COUNT(*) FROM Economic_Indicators;
SELECT COUNT(*) FROM Sales;

-- Date range of the data
SELECT MIN(date), MAX(date) FROM Economic_Indicators;

-- Number of unique stores
SELECT COUNT(DISTINCT store_id) FROM Stores;

-- 2. Descriptive statistics
-- Summary statistics for Sales
SELECT 
    AVG(weekly_sales) AS avg_sales,
    MIN(weekly_sales) AS min_sales,
    MAX(weekly_sales) AS max_sales,
    STDDEV(weekly_sales) AS stddev_sales
FROM Sales;

-- Summary statistics for Economic Indicators
SELECT 
    AVG(temperature) AS avg_temp,
    AVG(fuel_price) AS avg_fuel_price,
    AVG(cpi) AS avg_cpi,
    AVG(unemployment) AS avg_unemployment
FROM Economic_Indicators;

-- 3. Trends over time
-- Monthly sales trend
SELECT 
    YEAR(e.date) AS year,
    MONTH(e.date) AS month,
    SUM(s.weekly_sales) AS total_sales
FROM Sales s
JOIN Economic_Indicators e ON s.indicator_id = e.indicator_id
GROUP BY YEAR(e.date), MONTH(e.date)
ORDER BY year, month;

-- 4. Top performing stores
SELECT 
    s.store_id,
    SUM(s.weekly_sales) AS total_sales
FROM Sales s
GROUP BY s.store_id
ORDER BY total_sales DESC;

-- 5. Holiday impact (avg sales on holiday vs non-holiday)
SELECT 
    e.holiday_flag,
    AVG(s.weekly_sales) AS avg_sales
FROM Sales s
JOIN Economic_Indicators e ON s.indicator_id = e.indicator_id
GROUP BY e.holiday_flag;

-- 6. Seasonal variations (Average sales by month)
SELECT 
    MONTH(e.date) AS month,
    AVG(s.weekly_sales) AS avg_sales
FROM Sales s
JOIN Economic_Indicators e ON s.indicator_id = e.indicator_id
GROUP BY MONTH(e.date)
ORDER BY month;

-- 7. Fuel price, temperature, CPI and Unemployment Rate effect on sales
-- a. Create a temporary table or CTE with the joined data
WITH sales_and_indicators AS (
    SELECT 
        s.weekly_sales,
        e.fuel_price,
        e.temperature,
        e.cpi,
        e.unemployment
    FROM Sales s
    JOIN Economic_Indicators e ON s.indicator_id = e.indicator_id
)

-- b. Create a function to calculate correlation
, correlation_calc AS (
    SELECT indicator, 
           (COUNT(*) * SUM(weekly_sales * indicator_value) - SUM(weekly_sales) * SUM(indicator_value)) /
           SQRT((COUNT(*) * SUM(weekly_sales * weekly_sales) - SUM(weekly_sales) * SUM(weekly_sales)) *
                (COUNT(*) * SUM(indicator_value * indicator_value) - SUM(indicator_value) * SUM(indicator_value))) AS correlation
    FROM (
        SELECT 'Fuel Price' AS indicator, weekly_sales, fuel_price AS indicator_value FROM sales_and_indicators
        UNION ALL
        SELECT 'Temperature', weekly_sales, temperature FROM sales_and_indicators
        UNION ALL
        SELECT 'CPI', weekly_sales, cpi FROM sales_and_indicators
        UNION ALL
        SELECT 'Unemployment', weekly_sales, unemployment FROM sales_and_indicators
    ) AS unpivoted_data
    GROUP BY indicator
)

-- c. Final select to display results
SELECT * FROM correlation_calc
ORDER BY ABS(correlation) DESC;
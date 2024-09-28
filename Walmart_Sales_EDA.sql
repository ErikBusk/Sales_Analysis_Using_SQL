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
    

SELECT *
FROM Sales
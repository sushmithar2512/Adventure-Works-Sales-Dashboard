USE adventure_Works;
    select * from dimdate;
    select * from dimcustomer;
    select count(*) as total_rows from dimcustomer;
    describe dimcustomer;
    select count(*) from dimcustomer;
    describe dimcustomer;
     select * from dimcustomer;
     select * from dimdate;
     
    Use adventure_works;
    show tables;
    Use adventure_works;
    
    /* I . Append/Union of Fact Internet sales and Fact internet sales new - SALES */

    Create table sales as 
    select * from factinternetsales
    union all
    select * from fact_internet_sales_new;
    select COUNT(*) from sales;
    
/*    II. Merge Products, ProductCategory and ProductSubCategory Tables */
create table product_details as
select 
p.ProductKey,
p.EnglishProductName as ProductName,
ps.EnglishProductSubcategoryName as subcategoryName,
pc.EnglishProductCategoryName as CategoryName
From dimproduct p
left join dimproductsubcategory ps
ON p.ProductSubcategoryKey = ps.ProductSubcategoryKey
left join dimproductcategory pc
ON ps.ProductCategoryKey = pc.ProductCategoryKey;
select COUNT(*) FROM product_details;

/* 1. Lookup the Productname from the Product sheet to Sales sheet */

SELECT 
    s.ProductKey,
    dp.EnglishProductName AS ProductName,
    s.OrderQuantity,
    s.UnitPrice
FROM sales s
LEFT JOIN dimproduct dp
    ON s.ProductKey = dp.ProductKey;


/*2. Lookup the Customerfullname from the Customer Table and Unit Price from Product Table to Sales sheet.*/
 
Use adventure_works;
SELECT 
    s.*,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    UnitPrice
FROM sales s
LEFT JOIN dimcustomer c 
    ON s.CustomerKey = c.CustomerKey
LEFT JOIN dimproduct dp 
    ON s.ProductKey = dp.ProductKey;

/*3.  Create a Date Field from Orderdatekey
Usually orderdatekey is like (YYYYMMDD format) */

SELECT 
    STR_TO_DATE(OrderDateKey, '%Y%m%d') AS OrderDate
FROM sales;

 /* 3. Calcuate the following fields from the Orderdatekey field
    A. Year, B. Monthno,  C. Monthfullname, D. Quarter(Q1,Q2,Q3,Q4),  E. YearMonth ( YYYY-MMM),  F. Weekday Number,
     G. Weekday Name
   H. Financial Month (** Financial Year starts from April and ends at March - April : 1, May : 2 ….. March : 12)
   I. Financial Quarter */
   
   use adventure_works;
   
   ALTER TABLE sales
ADD COLUMN Year INT;
UPDATE sales
SET Year = YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d'));
SELECT OrderDateKey, Year
FROM sales
LIMIT 100000;
   SELECT 

    STR_TO_DATE(OrderDateKey, '%Y%m%d') AS OrderDate,

    /* A. Year */
    YEAR(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Year,

    /* B. Month Number */
    MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthNo,

    /* C. Month Full Name */
    MONTHNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS MonthFullName,

    /* D. Quarter */
    QUARTER(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS Quarter,

    /* E. Year-Month (YYYY-MMM) */
    DATE_FORMAT(STR_TO_DATE(OrderDateKey, '%Y%m%d'), '%Y-%b') AS YearMonth,

    /* F. Weekday Number (1=Sunday, 7=Saturday) */
    DAYOFWEEK(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS WeekdayNumber,

    /* G. Weekday Name */
    DAYNAME(STR_TO_DATE(OrderDateKey, '%Y%m%d')) AS WeekdayName,

    /* H. Financial Month (April = 1, March = 12) */
    CASE 
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) >= 4 
        THEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) - 3
        ELSE MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) + 9
    END AS FinancialMonth,

    /* I. Financial Quarter */
    CASE 
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 4 AND 6 THEN 1
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 7 AND 9 THEN 2
        WHEN MONTH(STR_TO_DATE(OrderDateKey, '%Y%m%d')) BETWEEN 10 AND 12 THEN 3
        ELSE 4
    END AS FinancialQuarter

FROM sales;
   
/* 4. Calculate the Sales amount using the columns (Unit price, Order quantity, Unit discount) */

SELECT 
    UnitPrice,
    OrderQuantity,
    UnitPriceDiscountPct,

    (UnitPrice * OrderQuantity * 
    (1 - UnitPriceDiscountPct)) AS Calculated_SalesAmount

FROM sales;

/* 5. Calculate the Productioncost using the columns (Unit cost, Order quantity) */
/* If UnitCost is in dimproduct table */

SELECT 
    s.ProductKey,
    s.OrderQuantity,
    dp.StandardCost,

    (dp.StandardCost * s.OrderQuantity) AS ProductionCost

FROM sales s
LEFT JOIN dimproduct dp
    ON s.ProductKey = dp.ProductKey;
    
/* 6. Calculate the Profit. (Sales - ProductionCost) */

SELECT 
    s.ProductKey,
    s.OrderQuantity,
    s.ExtendedAmount AS SalesAmount,
    (dp.StandardCost * s.OrderQuantity) AS ProductionCost,
    (s.ExtendedAmount - 
     (dp.StandardCost * s.OrderQuantity)) AS Profit
FROM sales s
LEFT JOIN dimproduct dp
    ON s.ProductKey = dp.ProductKey;

/* 7. Create a Pivot table for month and sales (provide the Year as filter to select a particular Year) */

SELECT 
    MONTH(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS MonthName,
    SUM(ExtendedAmount) AS Total_Sales
FROM sales
WHERE YEAR(STR_TO_DATE(OrderDateKey,'%Y%m%d')) = 2013   -- Change year here
GROUP BY MonthNo, MonthName
ORDER BY MonthNo;

/* 8. Yearwise Sales */

SELECT 
    YEAR(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS Year,
    ROUND(SUM(ExtendedAmount),2) AS Total_Sales
FROM sales
GROUP BY Year
ORDER BY Year;

/* 9. Monthwise sales */

SELECT 
    MONTH(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS MonthName,
    ROUND(SUM(ExtendedAmount),2) AS Total_Sales
FROM sales
GROUP BY MonthNo, MonthName
ORDER BY MonthNo;

/* Monthwise Sales for Specific Year (Example - 2013) */

SELECT 
    MONTH(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS MonthNo,
    MONTHNAME(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS MonthName,
    ROUND(SUM(ExtendedAmount),2) AS Total_Sales
FROM sales
WHERE YEAR(STR_TO_DATE(OrderDateKey,'%Y%m%d')) = 2013
GROUP BY MonthNo, MonthName
ORDER BY MonthNo;

/* 10. Quarterwise sales */

SELECT 
    QUARTER(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS Quarter,
    ROUND(SUM(ExtendedAmount),2) AS Total_Sales
FROM sales
GROUP BY Quarter
ORDER BY Quarter;

/* Quarterwise Sales for Specific Year (Example - 2013) */ 

SELECT 
    QUARTER(STR_TO_DATE(OrderDateKey,'%Y%m%d')) AS Quarter,
    ROUND(SUM(ExtendedAmount),2) AS Total_Sales
FROM sales
WHERE YEAR(STR_TO_DATE(OrderDateKey,'%Y%m%d')) = 2013
GROUP BY Quarter
ORDER BY Quarter;

/* 11. Salesamount and Productioncost together */

SELECT 
    s.ProductKey,
    s.OrderQuantity,

    /* Sales Amount */
    ROUND(
        (s.UnitPrice * s.OrderQuantity * 
        (1 - s.UnitPriceDiscountPct)), 2
    ) AS ExtendedAmount,

    /* Production Cost */
    ROUND(
        (dp.StandardCost * s.OrderQuantity), 2
    ) AS ProductionCost

FROM sales s
LEFT JOIN dimproduct dp
    ON s.ProductKey = dp.ProductKey;


-- Total Revenue

SELECT CONCAT(ROUND(SUM(ExtendedAmount)/1000000,2),' M') AS Total_Revenue
FROM sales;

-- Total Profit
SELECT 
CONCAT(ROUND(SUM(s.ExtendedAmount - (dp.StandardCost * s.OrderQuantity))/1000000,2),' M') AS Total_Profit
FROM sales s
JOIN dimproduct dp
ON s.ProductKey = dp.ProductKey;

-- Region Wise Sales

SELECT 
    st.SalesTerritoryRegion AS Region,
    CONCAT(ROUND(SUM(s.ExtendedAmount)/1000000,2),' M') AS Sales
FROM sales s
JOIN dimsalesterritory st
ON s.SalesTerritoryKey = st.SalesTerritoryKey
GROUP BY st.SalesTerritoryRegion
ORDER BY Sales DESC;

-- Top Selling Products

SELECT 
    pd.ProductName,
    CONCAT(ROUND(SUM(s.ExtendedAmount)/1000000,2),' M') AS Total_Sales
FROM sales s
JOIN product_details pd
ON s.ProductKey = pd.ProductKey
GROUP BY pd.ProductName
ORDER BY Total_Sales DESC
LIMIT 10;


-- category wise sales
SELECT 
    pc.EnglishProductCategoryName AS Category,
    CONCAT(ROUND(COALESCE(SUM(s.ExtendedAmount),0) / 1000000,2),' M') AS Sales
FROM dimproductcategory pc
LEFT JOIN dimproductsubcategory ps
ON pc.ProductCategoryKey = ps.ProductCategoryKey
LEFT JOIN dimproduct dp
ON ps.ProductSubcategoryKey = dp.ProductSubcategoryKey
LEFT JOIN sales s
ON dp.ProductKey = s.ProductKey
GROUP BY pc.EnglishProductCategoryName
ORDER BY Sales DESC;  

-- Sub-category wise sales

SELECT 
    pc.EnglishProductCategoryName AS Category,
    ps.EnglishProductSubcategoryName AS Subcategory,
    ROUND(SUM(s.ExtendedAmount)/1000000,2) AS Sales_Million
FROM sales s
JOIN dimproduct dp
ON s.ProductKey = dp.ProductKey
JOIN dimproductsubcategory ps
ON dp.ProductSubcategoryKey = ps.ProductSubcategoryKey
JOIN dimproductcategory pc
ON ps.ProductCategoryKey = pc.ProductCategoryKey
GROUP BY 
    pc.EnglishProductCategoryName,
    ps.EnglishProductSubcategoryName
ORDER BY Sales_Million DESC;
  
  
-- SALES,PRODUCTION COST, PROFIT BY YEAR
SELECT  
    s.Year,

    CONCAT(ROUND(SUM(s.ExtendedAmount)/1000000,2),' M') AS Sales,

    CONCAT(ROUND(SUM(dp.StandardCost * s.OrderQuantity)/1000000,2),' M') AS Production_Cost,

    CONCAT(ROUND(SUM(s.ExtendedAmount - (dp.StandardCost * s.OrderQuantity))/1000000,2),' M') AS Profit

FROM sales s
JOIN dimproduct dp
ON s.ProductKey = dp.ProductKey

GROUP BY s.Year
ORDER BY s.Year;

    
    
 
    
    
    
     
     
    
    
    
    
    
     
    



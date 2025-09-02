-- Total Revenue
SELECT 
    SUM(UnitPrice * Quantity) AS TotalRevenue
FROM InvoiceLine;

-- Total Orders
SELECT 
    COUNT(DISTINCT InvoiceId) AS TotalOrders
FROM InvoiceLine;

-- Total Customers
SELECT 
    COUNT(DISTINCT CustomerId) AS TotalCustomers
FROM Customer;

-- Profit Percentage
SELECT 
    SUM(UnitPrice * Quantity) AS TotalRevenue,
    SUM(UnitPrice * Quantity) * 0.3 AS EstimatedProfit,
    (SUM(UnitPrice * Quantity) * 0.3) / SUM(UnitPrice * Quantity) * 100 AS ProfitPercent
FROM InvoiceLine;

-- Monthly Revenue Growth
SELECT 
    YEAR(i.InvoiceDate) AS Year,
    MONTH(i.InvoiceDate) AS Month,
    SUM(il.UnitPrice * il.Quantity) AS MonthlyRevenue,
    SUM(il.UnitPrice * il.Quantity) - 
      LAG(SUM(il.UnitPrice * il.Quantity)) OVER (ORDER BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)) 
      AS RevenueGrowth
FROM InvoiceLine il
JOIN Invoice i ON il.InvoiceId = i.InvoiceId
GROUP BY Year, Month
ORDER BY Year, Month;

-- Average Revenue per Customer
SELECT 
    AVG(customer_total) AS AvgRevenuePerCustomer
FROM (
    SELECT CustomerId, SUM(UnitPrice * Quantity) AS customer_total
    FROM InvoiceLine il
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
    GROUP BY CustomerId
) AS customer_revenue;

-- Total revenue per product
SELECT 
    p.Name AS ProductName,
    SUM(il.UnitPrice * il.Quantity) AS TotalRevenue,
    SUM(il.Quantity) AS TotalQuantitySold
FROM InvoiceLine il
JOIN Track p ON il.TrackId = p.TrackId
GROUP BY p.Name
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Total revenue per country
SELECT 
    c.Country,
    SUM(il.UnitPrice * il.Quantity) AS TotalRevenue
FROM InvoiceLine il
JOIN Invoice i ON il.InvoiceId = i.InvoiceId
JOIN Customer c ON i.CustomerId = c.CustomerId
GROUP BY c.Country
ORDER BY TotalRevenue DESC;

-- Top Product per Region
SELECT *
FROM (
    SELECT 
        c.Country,
        t.Name AS ProductName,
        SUM(il.UnitPrice * il.Quantity) AS Revenue,
        RANK() OVER (PARTITION BY c.Country ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS ProductRank
    FROM InvoiceLine il
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
    JOIN Customer c ON i.CustomerId = c.CustomerId
    JOIN Track t ON il.TrackId = t.TrackId
    GROUP BY c.Country, t.Name
) AS RankedProducts
WHERE ProductRank = 1;

-- Top Customers by Revenue
SELECT 
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    c.Country,
    SUM(il.UnitPrice * il.Quantity) AS TotalRevenue
FROM InvoiceLine il
JOIN Invoice i ON il.InvoiceId = i.InvoiceId
JOIN Customer c ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId, c.FirstName, c.LastName, c.Country
ORDER BY TotalRevenue DESC
LIMIT 10;

-- Revenue per Genre
SELECT 
    g.Name AS Genre,
    SUM(il.UnitPrice * il.Quantity) AS Revenue
FROM InvoiceLine il
JOIN Track t ON il.TrackId = t.TrackId
JOIN Genre g ON t.GenreId = g.GenreId
GROUP BY g.GenreId
ORDER BY Revenue DESC;

-- Sales Performance by Employee
SELECT
	CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
    SUM(il.UnitPrice * il.Quantity) AS Revenue
FROM InvoiceLine il
JOIN Invoice i ON il.InvoiceId = i.InvoiceId
JOIN Customer c ON i.CustomerId = c.CustomerId
JOIN Employee e ON c.SupportRepId = e.EmployeeId
GROUP BY e.EmployeeId
ORDER BY Revenue DESC;

-- Average Order Value (AOV) per Country
SELECT 
    orders.Country,
    AVG(orders.order_total) AS AvgOrderValue
FROM (
    SELECT 
        i.InvoiceId,
        c.Country,
        SUM(il.UnitPrice * il.Quantity) AS order_total
    FROM InvoiceLine il
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
    JOIN Customer c ON i.CustomerId = c.CustomerId
    GROUP BY i.InvoiceId, c.Country
) AS orders
GROUP BY orders.Country
ORDER BY AvgOrderValue DESC;

-- Top Product per Country
SELECT *
FROM (
    SELECT 
        c.Country,
        t.Name AS ProductName,
        SUM(il.UnitPrice * il.Quantity) AS Revenue,
        RANK() OVER (PARTITION BY c.Country ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS ProductRank
    FROM InvoiceLine il
    JOIN Invoice i ON il.InvoiceId = i.InvoiceId
    JOIN Customer c ON i.CustomerId = c.CustomerId
    JOIN Track t ON il.TrackId = t.TrackId
    GROUP BY c.Country, t.Name
) AS RankedProducts
WHERE ProductRank = 1;

-- Repeat vs. New Customers
SELECT 
    CASE 
        WHEN invoice_count = 1 THEN 'New Customer'
        ELSE 'Repeat Customer'
    END AS CustomerType,
    COUNT(*) AS CustomerCount
FROM (
    SELECT CustomerId, COUNT(InvoiceId) AS invoice_count
    FROM Invoice
    GROUP BY CustomerId
) AS customer_invoices
GROUP BY CustomerType;

-- Customer Lifetime Value
SELECT 
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
    SUM(il.UnitPrice * il.Quantity) AS LifetimeValue
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
JOIN InvoiceLine il ON i.InvoiceId = il.InvoiceId
GROUP BY c.CustomerId
ORDER BY LifetimeValue DESC
LIMIT 10;

-- Sales Conversion Rate
SELECT 
    COUNT(DISTINCT i.InvoiceId) / COUNT(DISTINCT c.CustomerId) AS ConversionRate
FROM Customer c
LEFT JOIN Invoice i ON c.CustomerId = i.CustomerId;

-- Revenue per Order
SELECT 
    SUM(il.UnitPrice * il.Quantity) / COUNT(DISTINCT i.InvoiceId) AS RevenuePerOrder
FROM InvoiceLine il
JOIN Invoice i ON il.InvoiceId = i.InvoiceId;

-- Churn Indicator (Customers inactive in last 12 months)
SELECT 
    COUNT(*) AS ChurnedCustomers
FROM Customer c
WHERE c.CustomerId NOT IN (
    SELECT DISTINCT i.CustomerId
    FROM Invoice i
    WHERE i.InvoiceDate >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
);
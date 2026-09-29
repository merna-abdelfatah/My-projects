-- Query 1: Total Sales Revenue per Product Category
SELECT 
    c.Name AS CategoryName,
    SUM(oi.Quantity * oi.UnitPrice) AS TotalRevenue
FROM Categories c
JOIN Products p 
    ON c.CategoryID = p.CategoryID
JOIN OrderItems oi 
    ON p.ProductID = oi.ProductID
JOIN Orders o 
    ON oi.OrderID = o.OrderID
WHERE o.Status <> 'Cancelled'
GROUP BY c.Name
ORDER BY TotalRevenue DESC;


-- Top Spending Customers
SELECT TOP 5
    cu.Name AS CustomerName,
    SUM(oi.Quantity * oi.UnitPrice) AS TotalSpent
FROM Customers cu
JOIN Orders o 
    ON cu.CustomerID = o.CustomerID
JOIN OrderItems oi 
    ON o.OrderID = oi.OrderID
WHERE o.Status <> 'Cancelled'
GROUP BY cu.CustomerID, cu.Name
ORDER BY TotalSpent DESC;



-- Query 2: Low-Stock Products with Supplier Contact Details
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.StockQuantity,
    s.Name AS SupplierName,
    s.ContactEmail
FROM Products p
JOIN Suppliers s
    ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity < 10
ORDER BY p.StockQuantity ASC;

-- Query 3: Month-over-Month Revenue Breakdown

WITH MonthlyRevenue AS
(
    SELECT
        YEAR(o.OrderDate) AS SalesYear,
        MONTH(o.OrderDate) AS SalesMonth,
        SUM(oi.Quantity * oi.UnitPrice) AS MonthlyRevenue
    FROM Orders o
    JOIN OrderItems oi
        ON o.OrderID = oi.OrderID
    WHERE o.Status <> 'Cancelled'
    GROUP BY
        YEAR(o.OrderDate),
        MONTH(o.OrderDate)
)
SELECT
    SalesYear,
    SalesMonth,
    MonthlyRevenue,
    LAG(MonthlyRevenue) OVER (
        ORDER BY SalesYear, SalesMonth
    ) AS PreviousMonthRevenue,
    MonthlyRevenue -
    LAG(MonthlyRevenue) OVER (
        ORDER BY SalesYear, SalesMonth
    ) AS RevenueDifference
FROM MonthlyRevenue
ORDER BY SalesYear, SalesMonth;

-- Query 4: Running Total Expenditure per Customer

SELECT
    cu.CustomerID,
    cu.Name AS CustomerName,
    o.OrderID,
    o.OrderDate,
    SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal,
    SUM(SUM(oi.Quantity * oi.UnitPrice)) OVER (
        PARTITION BY cu.CustomerID
        ORDER BY o.OrderDate, o.OrderID
    ) AS RunningTotalExpenditure
FROM Customers cu
JOIN Orders o
    ON cu.CustomerID = o.CustomerID
JOIN OrderItems oi
    ON o.OrderID = oi.OrderID
WHERE o.Status <> 'Cancelled'
GROUP BY
    cu.CustomerID,
    cu.Name,
    o.OrderID,
    o.OrderDate
ORDER BY
    cu.CustomerID,
    o.OrderDate,
    o.OrderID;


	-- Query 5: Multi-table JOIN

SELECT
    c.CustomerID,
    c.Name AS CustomerName,
    o.OrderID,
    o.OrderDate,
    o.Status,
    p.Name AS ProductName,
    oi.Quantity,
    oi.UnitPrice,
    pay.Amount AS PaymentAmount,
    pay.PaymentMethod,
    s.ShippedDate,
    s.Carrier
FROM Customers c
JOIN Orders o
    ON c.CustomerID = o.CustomerID
JOIN OrderItems oi
    ON o.OrderID = oi.OrderID
JOIN Products p
    ON oi.ProductID = p.ProductID
LEFT JOIN Payments pay
    ON o.OrderID = pay.OrderID
LEFT JOIN Shipments s
    ON o.OrderID = s.OrderID
ORDER BY o.OrderID;
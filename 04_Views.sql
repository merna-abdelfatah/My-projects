-- =============================================
-- VIEWS - E-Commerce Order Management System
-- =============================================

-- VIEW 1: Order Summary
CREATE VIEW vw_OrderSummary
AS
SELECT
    o.OrderID,
    o.OrderDate,
    o.Status,
    c.CustomerID,
    c.Name AS CustomerName,
    c.Email,
    c.Phone,
    COUNT(oi.ProductID) AS ItemCount,
    SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
FROM Orders o
JOIN Customers c
    ON o.CustomerID = c.CustomerID
JOIN OrderItems oi
    ON o.OrderID = oi.OrderID
GROUP BY
    o.OrderID,
    o.OrderDate,
    o.Status,
    c.CustomerID,
    c.Name,
    c.Email,
    c.Phone;
GO


-- VIEW 2: Low Stock Products
CREATE VIEW vw_LowStockProducts
AS
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.StockQuantity,
    s.SupplierID,
    s.Name AS SupplierName,
    s.ContactEmail
FROM Products p
JOIN Suppliers s
    ON p.SupplierID = s.SupplierID
WHERE p.StockQuantity < 10;
GO


-- VIEW 3: Sales By Category
CREATE VIEW vw_SalesByCategory
AS
SELECT
    c.CategoryID,
    c.Name AS CategoryName,
    SUM(oi.Quantity * oi.UnitPrice) AS TotalSalesRevenue,
    SUM(oi.Quantity) AS UnitsSold,
    AVG(oi.UnitPrice) AS AveragePrice
FROM Categories c
JOIN Products p
    ON c.CategoryID = p.CategoryID
JOIN OrderItems oi
    ON p.ProductID = oi.ProductID
JOIN Orders o
    ON oi.OrderID = o.OrderID
WHERE o.Status <> 'Cancelled'
GROUP BY
    c.CategoryID,
    c.Name;
GO


-- VIEW 4: Customer Lifetime Value
CREATE VIEW vw_CustomerLifetimeValue
AS
SELECT
    c.CustomerID,
    c.Name AS CustomerName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders,
    ISNULL(SUM(oi.Quantity * oi.UnitPrice), 0) AS LifetimeRevenue
FROM Customers c
LEFT JOIN Orders o
    ON c.CustomerID = o.CustomerID
    AND o.Status <> 'Cancelled'
LEFT JOIN OrderItems oi
    ON o.OrderID = oi.OrderID
GROUP BY
    c.CustomerID,
    c.Name;
GO


-- VIEW 5: Pending Shipments
CREATE VIEW vw_PendingShipments
AS
SELECT
    o.OrderID,
    o.OrderDate,
    o.Status,
    c.CustomerID,
    c.Name AS CustomerName,
    s.ShipmentID,
    s.ShippedDate,
    s.Carrier
FROM Orders o
JOIN Customers c
    ON o.CustomerID = c.CustomerID
LEFT JOIN Shipments s
    ON o.OrderID = s.OrderID
WHERE o.Status IN ('Processing', 'Shipped')
  AND s.ShipmentID IS NULL;
GO
-- FUNCTION 1: fn_GetOrderTotal

CREATE FUNCTION fn_GetOrderTotal
(
    @OrderID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2);

    SELECT @Total =
        ISNULL(SUM(Quantity * UnitPrice), 0)
    FROM OrderItems
    WHERE OrderID = @OrderID;

    RETURN @Total;
END;
GO


-- FUNCTION 2: fn_GetCustomerTotalSpent

CREATE FUNCTION fn_GetCustomerTotalSpent
(
    @CustomerID INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalSpent DECIMAL(18,2);

    SELECT @TotalSpent =
        ISNULL(SUM(oi.Quantity * oi.UnitPrice), 0)
    FROM Orders o
    JOIN OrderItems oi
        ON o.OrderID = oi.OrderID
    WHERE o.CustomerID = @CustomerID
      AND o.Status <> 'Cancelled';

    RETURN @TotalSpent;
END;
GO



-- FUNCTION 3: fn_CheckStockAvailability

CREATE FUNCTION fn_CheckStockAvailability
(
    @ProductID INT,
    @Qty INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Available BIT;

    IF EXISTS
    (
        SELECT 1
        FROM Products
        WHERE ProductID = @ProductID
          AND StockQuantity >= @Qty
    )
        SET @Available = 1;
    ELSE
        SET @Available = 0;

    RETURN @Available;
END;
GO


-- FUNCTION 4: fn_GetCustomerOrders

CREATE FUNCTION fn_GetCustomerOrders
(
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        o.OrderID,
        o.OrderDate,
        o.Status,
        p.ProductID,
        p.Name AS ProductName,
        oi.Quantity,
        oi.UnitPrice,
        (oi.Quantity * oi.UnitPrice) AS ItemTotal
    FROM Orders o
    JOIN OrderItems oi
        ON o.OrderID = oi.OrderID
    JOIN Products p
        ON oi.ProductID = p.ProductID
    WHERE o.CustomerID = @CustomerID
);
GO


-- FUNCTION 5: fn_GetTopSellingProducts

CREATE FUNCTION fn_GetTopSellingProducts
(
    @TopN INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP (@TopN)
        p.ProductID,
        p.Name AS ProductName,
        SUM(oi.Quantity) AS TotalQuantitySold
    FROM Products p
    JOIN OrderItems oi
        ON p.ProductID = oi.ProductID
    JOIN Orders o
        ON oi.OrderID = o.OrderID
    WHERE o.Status <> 'Cancelled'
    GROUP BY
        p.ProductID,
        p.Name
    ORDER BY
        SUM(oi.Quantity) DESC
);
GO






-- INDEX 1: Orders(CustomerID)

CREATE NONCLUSTERED INDEX IX_Orders_CustomerID
ON Orders(CustomerID);
GO

-- INDEX 2: OrderItems(ProductID)

CREATE NONCLUSTERED INDEX IX_OrderItems_ProductID
ON OrderItems(ProductID);
GO


-- INDEX 3: Products(CategoryID)

CREATE NONCLUSTERED INDEX IX_Products_CategoryID
ON Products(CategoryID);
GO


-- INDEX 4: Orders(OrderDate, Status)

CREATE NONCLUSTERED INDEX IX_Orders_OrderDate_Status
ON Orders(OrderDate, Status);
GO



-- INDEX 5: Filtered Index on Products(StockQuantity)

CREATE NONCLUSTERED INDEX IX_Products_LowStock
ON Products(StockQuantity)
WHERE StockQuantity < 10;
GO
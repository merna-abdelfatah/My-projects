-- TRIGGER 1: trg_UpdateStockOnOrder

CREATE TRIGGER trg_UpdateStockOnOrder
ON OrderItems
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET p.StockQuantity = p.StockQuantity - i.Quantity
    FROM Products p
    INNER JOIN inserted i
        ON p.ProductID = i.ProductID;
END;
GO


-- TRIGGER 2: trg_PreventProductDelete

CREATE TRIGGER trg_PreventProductDelete
ON Products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM deleted d
        JOIN OrderItems oi
            ON d.ProductID = oi.ProductID
    )
    BEGIN
        THROW 50018, 'Cannot delete a product referenced in historical orders.', 1;
    END;

    DELETE FROM Products
    WHERE ProductID IN
    (
        SELECT ProductID
        FROM deleted
    );
END;
GO



-- TRIGGER 3: trg_AuditOrderStatus

CREATE TRIGGER trg_AuditOrderStatus
ON Orders
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO OrderStatusAudit
        (OrderID, OldStatus, NewStatus)
    SELECT
        d.OrderID,
        d.Status,
        i.Status
    FROM deleted d
    INNER JOIN inserted i
        ON d.OrderID = i.OrderID
    WHERE ISNULL(d.Status, '') <> ISNULL(i.Status, '');
END;
GO



-- TRIGGER 4: trg_CheckPaymentAmount

CREATE TRIGGER trg_CheckPaymentAmount
ON Payments
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM
        (
            SELECT
                i.OrderID,
                SUM(i.Amount) AS NewPaymentAmount
            FROM inserted i
            GROUP BY i.OrderID
        ) x
        JOIN
        (
            SELECT
                p.OrderID,
                SUM(p.Amount) AS ExistingPaymentAmount
            FROM Payments p
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM inserted i
                WHERE i.PaymentID = p.PaymentID
            )
            GROUP BY p.OrderID
        ) y
            ON x.OrderID = y.OrderID
        JOIN
        (
            SELECT
                oi.OrderID,
                SUM(oi.Quantity * oi.UnitPrice) AS OrderTotal
            FROM OrderItems oi
            GROUP BY oi.OrderID
        ) o
            ON x.OrderID = o.OrderID
        WHERE y.ExistingPaymentAmount + x.NewPaymentAmount > o.OrderTotal
    )
    BEGIN
        THROW 50017, 'Payment exceeds the remaining order balance.', 1;
    END;
END;
GO



-- TRIGGER 5: trg_AutoUpdateShipmentStatus

CREATE TRIGGER trg_AutoUpdateShipmentStatus
ON Shipments
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE o
    SET o.Status = 'Shipped'
    FROM Orders o
    INNER JOIN inserted i
        ON o.OrderID = i.OrderID;
END;
GO
-- TYPE: OrderItemType

CREATE TYPE OrderItemType AS TABLE
(
    ProductID INT,
    Quantity INT,
    UnitPrice DECIMAL(18,2)
);
GO

-- STORED PROCEDURE 1: sp_CreateOrder

CREATE PROCEDURE sp_CreateOrder
    @CustomerID INT,
    @OrderDate DATE,
    @Items OrderItemType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate Customer
        IF NOT EXISTS (
            SELECT 1
            FROM Customers
            WHERE CustomerID = @CustomerID
        )
        BEGIN
            THROW 50001, 'Customer does not exist.', 1;
        END;

        -- Validate Items
        IF NOT EXISTS (SELECT 1 FROM @Items)
        BEGIN
          THROW 50016, 'Order must contain at least one item.', 1;
        END; 
        
        -- Validate Products
        IF EXISTS (
            SELECT 1
            FROM @Items i
            WHERE NOT EXISTS (
                SELECT 1
                FROM Products p
                WHERE p.ProductID = i.ProductID
            )
        )
        BEGIN
            THROW 50003, 'Product does not exist.', 1;
        END;


		-- Validate Stock
        IF EXISTS (
               SELECT 1
               FROM @Items i
        JOIN Products p
               ON p.ProductID = i.ProductID
              WHERE p.StockQuantity < i.Quantity
          )
        BEGIN
           THROW 50002, 'Insufficient stock.', 1;
        END;
        -- Create Order
        DECLARE @OrderID INT;

        SELECT @OrderID = ISNULL(MAX(OrderID), 0) + 1
        FROM Orders;

        INSERT INTO Orders
            (OrderID, CustomerID, OrderDate, Status)
        VALUES
            (@OrderID, @CustomerID, @OrderDate, 'Pending');

        -- Create Order Items
        INSERT INTO OrderItems
            (OrderID, ProductID, Quantity, UnitPrice)
        SELECT
            @OrderID,
            i.ProductID,
            i.Quantity,
            p.Price
        FROM @Items i
        JOIN Products p
            ON p.ProductID = i.ProductID;

        COMMIT TRANSACTION;

        SELECT @OrderID AS NewOrderID;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


-- STORED PROCEDURE 2: sp_UpdateOrderStatus

CREATE PROCEDURE sp_UpdateOrderStatus
    @OrderID INT,
    @NewStatus VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentStatus VARCHAR(20);

        SELECT @CurrentStatus = Status
        FROM Orders
        WHERE OrderID = @OrderID;

        IF @CurrentStatus IS NULL
        BEGIN
            THROW 50004, 'Order does not exist.', 1;
        END;

        IF @NewStatus NOT IN
            ('Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled')
        BEGIN
            THROW 50005, 'Invalid order status.', 1;
        END;

        IF @CurrentStatus = 'Pending'
           AND @NewStatus NOT IN ('Processing', 'Cancelled')
        BEGIN
            THROW 50006, 'Invalid status transition.', 1;
        END;

        IF @CurrentStatus = 'Processing'
           AND @NewStatus NOT IN ('Shipped', 'Cancelled')
        BEGIN
            THROW 50007, 'Invalid status transition.', 1;
        END;

        IF @CurrentStatus = 'Shipped'
           AND @NewStatus <> 'Delivered'
        BEGIN
            THROW 50008, 'Invalid status transition.', 1;
        END;

        IF @CurrentStatus IN ('Delivered', 'Cancelled')
        BEGIN
            THROW 50009, 'Order status cannot be changed.', 1;
        END;

        UPDATE Orders
        SET Status = @NewStatus
        WHERE OrderID = @OrderID;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO


-- STORED PROCEDURE 3: sp_ProcessPayment

CREATE PROCEDURE sp_ProcessPayment
    @OrderID INT,
    @Amount DECIMAL(18,2),
    @PaymentMethod VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validate Order
        IF NOT EXISTS (
            SELECT 1
            FROM Orders
            WHERE OrderID = @OrderID
        )
        BEGIN
            THROW 50010, 'Order does not exist.', 1;
        END;

        -- Validate Payment Amount
        IF @Amount <= 0
        BEGIN
            THROW 50011, 'Payment amount must be greater than zero.', 1;
        END;

        DECLARE @OrderTotal DECIMAL(18,2);
        DECLARE @PaidAmount DECIMAL(18,2);
        DECLARE @PaymentID INT;

        -- Calculate Order Total
        SELECT @OrderTotal =
            ISNULL(SUM(Quantity * UnitPrice), 0)
        FROM OrderItems
        WHERE OrderID = @OrderID;

        -- Calculate Previous Payments
        SELECT @PaidAmount =
            ISNULL(SUM(Amount), 0)
        FROM Payments
        WHERE OrderID = @OrderID;

        -- Prevent Overpayment
        IF @PaidAmount + @Amount > @OrderTotal
        BEGIN
            THROW 50012, 'Payment exceeds the remaining order balance.', 1;
        END;

        -- Generate Payment ID
        SELECT @PaymentID = ISNULL(MAX(PaymentID), 0) + 1
        FROM Payments;

        -- Record Payment
        INSERT INTO Payments
            (PaymentID, OrderID, PaymentDate, Amount, PaymentMethod)
        VALUES
            (@PaymentID, @OrderID, GETDATE(), @Amount, @PaymentMethod);

        -- Check Full Settlement
        IF @PaidAmount + @Amount = @OrderTotal
        BEGIN
            PRINT 'Order balance is fully settled.';
        END
        ELSE
        BEGIN
            PRINT 'Order still has a remaining balance.';
        END;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO



-- STORED PROCEDURE 4: sp_CancelOrder

CREATE PROCEDURE sp_CancelOrder
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentStatus VARCHAR(20);

        SELECT @CurrentStatus = Status
        FROM Orders
        WHERE OrderID = @OrderID;

        IF @CurrentStatus IS NULL
        BEGIN
            THROW 50013, 'Order does not exist.', 1;
        END;

        IF @CurrentStatus IN ('Delivered', 'Cancelled')
        BEGIN
            THROW 50014, 'Order cannot be cancelled.', 1;
        END;

        -- Restore Stock
        UPDATE p
        SET p.StockQuantity = p.StockQuantity + oi.Quantity
        FROM Products p
        JOIN OrderItems oi
            ON p.ProductID = oi.ProductID
        WHERE oi.OrderID = @OrderID;

        -- Update Order Status
        UPDATE Orders
        SET Status = 'Cancelled'
        WHERE OrderID = @OrderID;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO



-- STORED PROCEDURE 5: sp_ApplyDiscountCoupon

CREATE PROCEDURE sp_ApplyDiscountCoupon
    @OrderID INT,
    @Code VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @DiscountPercentage DECIMAL(5,2);
        DECLARE @OrderTotal DECIMAL(18,2);
        DECLARE @DiscountAmount DECIMAL(18,2);
        DECLARE @FinalAmount DECIMAL(18,2);

        -- Validate Coupon
        SELECT @DiscountPercentage = DiscountPercentage
        FROM Coupons
        WHERE Code = @Code
          AND ExpiryDate >= CAST(GETDATE() AS DATE);

        IF @DiscountPercentage IS NULL
        BEGIN
            THROW 50015, 'Invalid or expired coupon.', 1;
        END;

        -- Calculate Order Total
        SELECT @OrderTotal =
            ISNULL(SUM(Quantity * UnitPrice), 0)
        FROM OrderItems
        WHERE OrderID = @OrderID;

        -- Calculate Discount
        SET @DiscountAmount =
            @OrderTotal * (@DiscountPercentage / 100);

        SET @FinalAmount =
            @OrderTotal - @DiscountAmount;

        SELECT
            @OrderID AS OrderID,
            @OrderTotal AS OrderTotal,
            @DiscountPercentage AS DiscountPercentage,
            @DiscountAmount AS DiscountAmount,
            @FinalAmount AS FinalAmount;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

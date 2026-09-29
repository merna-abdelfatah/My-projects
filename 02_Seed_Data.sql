INSERT INTO Categories (CategoryID, Name)
VALUES
(1, 'Electronics'),
(2, 'Home Appliances'),
(3, 'Accessories');



INSERT INTO Suppliers (SupplierID, Name, ContactEmail)
VALUES
(1, 'Tech Supplier', 'tech@supplier.com'),
(2, 'Home Supplier', 'home@supplier.com'),
(3, 'Accessories Supplier', 'accessories@supplier.com');



INSERT INTO Customers (CustomerID, Name, Email, Phone, Adderes)
VALUES
(1, 'Ahmed Ali', 'ahmed.ali@gmail.com', '01011111111', 'Cairo'),
(2, 'Sara Mohamed', 'sara.mohamed@gmail.com', '01022222222', 'Giza'),
(3, 'Omar Hassan', 'omar.hassan@gmail.com', '01033333333', 'Alexandria'),
(4, 'Mariam Adel', 'mariam.adel@gmail.com', '01044444444', 'Cairo'),
(5, 'Youssef Mahmoud', 'youssef.mahmoud@gmail.com', '01055555555', 'Giza');


INSERT INTO Products
    (ProductID, Name, Price, StockQuantity, CategoryID, SupplierID)
VALUES
    (1, 'Laptop', 25000.00, 10, 1, 1),
    (2, 'Smartphone', 15000.00, 15, 1, 1),
    (3, 'Air Fryer', 4500.00, 8, 2, 2),
    (4, 'Microwave', 7000.00, 6, 2, 2),
    (5, 'Wireless Mouse', 500.00, 25, 3, 3),
    (6, 'Keyboard', 800.00, 20, 3, 3);



	INSERT INTO Orders (OrderID, CustomerID, OrderDate, Status)
VALUES
(1, 1, '2026-08-01', 'Pending'),
(2, 2, '2026-08-02', 'Processing'),
(3, 3, '2026-08-03', 'Shipped'),
(4, 4, '2026-08-04', 'Delivered'),
(5, 5, '2026-08-05', 'Cancelled');


INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES
(1, 1, 1, 25000.00),
(2, 2, 2, 15000.00),
(3, 3, 1, 4500.00),
(4, 4, 1, 7000.00),
(5, 5, 3, 500.00);


INSERT INTO Payments
    (PaymentID, OrderID, PaymentDate, Amount, PaymentMethod)
VALUES
    (1, 1, '2026-08-01', 25000.00, 'Credit Card'),
    (2, 2, '2026-08-02', 30000.00, 'Cash'),
    (3, 3, '2026-08-03', 4500.00, 'Credit Card'),
    (4, 4, '2026-08-04', 7000.00, 'Bank Transfer'),
    (5, 5, '2026-08-05', 1500.00, 'Cash');
	INSERT INTO Shipments
    (ShipmentID, OrderID, ShippedDate, Carrier)
VALUES
(1, 3, '2026-08-04', 'Aramex'),
(2, 4, '2026-08-05', 'DHL');

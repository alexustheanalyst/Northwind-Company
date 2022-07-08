-- Step 1: create dimensional tables and fact tables

-- step 1.1: create dimProducts:
CREATE TABLE [dbo].[dimProducts]
(
    [ProductKey] [int] IDENTITY(1, 1) PRIMARY KEY,
	[ProductID] [int] NOT NULL,
	[ProductName] [nvarchar](40) NOT NULL,
	[QuantityPerUnit] [nvarchar](20) NULL,
	[UnitPrice] [money] NULL,
	[UnitsInStock] [smallint] NULL,
	[UnitsOnOrder] [smallint] NULL,
	[ReorderLevel] [smallint] NULL,
	[Discontinued] [bit] NOT NULL,
	[SupplierID] [int] NULL,
	[CompanyName] [nvarchar](40) NOT NULL,
	[ContactName] [nvarchar](30) NULL,
	[ContactTitle] [nvarchar](30) NULL,
	[Address] [nvarchar](60) NULL,
	[City] [nvarchar](15) NULL,
	[Region] [nvarchar](15) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[Country] [nvarchar](15) NULL,
	[Phone] [nvarchar](24) NULL,
	[Fax] [nvarchar](24) NULL,
	[Homepage] [ntext] NULL,
) 
GO

--step 1.2: create dimCustomers

CREATE TABLE [dbo].[dimCustomers]
(
    [CustomerKey] INT IDENTITY(1,1) primary key,
	[CustomerID] [nchar](5) NOT NULL,
	[CompanyName] [nvarchar](40) NOT NULL,
	[ContactName] [nvarchar](30) NULL,
	[ContactTitle] [nvarchar](30) NULL,
	[Address] [nvarchar](60) NULL,
	[City] [nvarchar](15) NULL,
	[Region] [nvarchar](15) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[Country] [nvarchar](15) NULL,
	[Phone] [nvarchar](24) NULL,
	[Fax] [nvarchar](24) NULL,	
) 
GO

--step 1.3: create dimCategories

CREATE TABLE [dbo].[dimCategories]
(
	[CategoryKey] INT IDENTITY(1,1) primary key,
	[CategoryID] [int] NOT NULL,
	[CategoryName] [nvarchar](15) NOT NULL,
	[Description] [ntext] NULL,
	[Picture] [image] NULL,

) 
GO

--step 1.4: create factOrders
CREATE TABLE [factOrders]
(
    [ProductKey] INT FOREIGN KEY REFERENCES dimProducts(ProductKey),
    [CustomerKey] INT FOREIGN KEY REFERENCES dimCustomers(CustomerKey),
	[CategoryKey] INT FOREIGN KEY REFERENCES dimCategories(CategoryKey),
    [OrderDateKey] INT FOREIGN KEY REFERENCES dimTime(TimeKey), 
	[RequiredDateKey] INT FOREIGN KEY REFERENCES dimTime(TimeKey),
	[ShippedDateKey] INT FOREIGN KEY REFERENCES dimTime(TimeKey),
	[ShipperID] [int] NULL,
	[OrderID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[Quantity] [smallint] NOT NULL,
	[Discount] [real] NOT NULL,
	[TotalPrice] [money] NOT NULL, -- this is a derived (calculated) field from [UnitPrice] * [Qty] * (1 - [Discount]),
	[ShipperCompany] [nvarchar] (40) NOT NULL ,
    [ShipperPhone] [nvarchar] (24) NULL ,
	CONSTRAINT [pk_factOrders] PRIMARY KEY ([ProductKey], [CustomerKey],[CategoryKey], [OrderDateKey])
)
GO

-- Step 2: Populating the dimensions and facts:
-- Step 2.1: populating dimProducts:

-- Populating dimProducts

MERGE INTO dimProducts dp USING
(
	SELECT 
		ProductID, 
		ProductName,
		QuantityPerUnit,
		UnitPrice, 
		UnitsInStock,
		UnitsOnOrder,
		ReorderLevel,
		Discontinued,
		CompanyName,
		ContactName,
		ContactTitle,
		Address,
		City,
		Region,
		PostalCode,
		Country,
		Phone,
		Fax,
		Homepage
 FROM 
		northwind5.dbo.Products p1, northwind5.dbo.Suppliers s1 
	WHERE p1.SupplierID=s1.SupplierID
) ps ON (dp.ProductID = ps.ProductID)-- Assume ProductID is unique
WHEN MATCHED THEN -- if ProductID matched, do nothing 
	UPDATE SET dp.ProductName = ps.ProductName -- Dummy update
WHEN NOT MATCHED THEN -- Otherwise, insert a new product 
	INSERT(ProductID, ProductName, QuantityPerUnit, UnitPrice, UnitsInStock, UnitsOnOrder, 
	ReorderLevel, Discontinued, CompanyName, ContactName, ContactTitle, Address, 
	City, Region, PostalCode, Country, Phone, Fax,Homepage)
	VALUES(ps.ProductID, ps.ProductName, ps.QuantityPerUnit, ps.UnitPrice, ps.UnitsInStock, 
	ps.UnitsOnOrder, ps.ReorderLevel, ps.Discontinued, ps.CompanyName, ps.ContactName, 
	ps.ContactTitle, ps.Address, ps.City, ps.Region, ps.PostalCode, ps.Country, ps.Phone, ps.Fax, ps.Homepage);

MERGE INTO dimProducts dp USING
(
	SELECT 
		ProductID, 
		ProductName,
		QuantityPerUnit,
		UnitPrice, 
		UnitsInStock,
		UnitsOnOrder,
		ReorderLevel,
		Discontinued,
		CompanyName,
		ContactName,
		ContactTitle,
		Address,
		City,
		Region,
		PostalCode,
		Country,
		Phone,
		Fax,
		Homepage
 FROM 
		northwind6.dbo.Products p2, northwind6.dbo.Suppliers s2
	WHERE p2.SupplierID=s2.SupplierID
) ps ON (dp.ProductID = ps.ProductID)-- Assume ProductID is unique
WHEN MATCHED THEN -- if ProductID matched, do nothing 
	UPDATE SET dp.ProductName = ps.ProductName -- Dummy update
WHEN NOT MATCHED THEN -- Otherwise, insert a new product 
	INSERT(ProductID, ProductName, QuantityPerUnit, UnitPrice, UnitsInStock, UnitsOnOrder, 
	ReorderLevel, Discontinued, CompanyName, ContactName, ContactTitle, Address, 
	City, Region, PostalCode, Country, Phone, Fax,Homepage)
	VALUES(ps.ProductID, ps.ProductName, ps.QuantityPerUnit, ps.UnitPrice, ps.UnitsInStock, 
	ps.UnitsOnOrder, ps.ReorderLevel, ps.Discontinued, ps.CompanyName, ps.ContactName, 
	ps.ContactTitle, ps.Address, ps.City, ps.Region, ps.PostalCode, ps.Country, ps.Phone, ps.Fax, ps.Homepage);

-- dimProducts Validation
select 'OLTP' as [SourceType], 'northwind5.Products' as [TableName], count(*) as [RowCounts] from northwind5.dbo.Products
Union
select 'OLTP' as [SourceType], 'northwind6.Products' as [TableName], count(*) as [RowCounts] from northwind6.dbo.Products
Union
select 'OLAP' as [SourceType], 'northwind_dw_assign3.dimProducts' as [TableName], count(*) as [RowCounts] from northwind_dw_assign3.dbo.dimProducts;

-- Step 2.2 populating dimCustomers
MERGE INTO dimCustomers dc
USING
(
	SELECT 
		CustomerID, 
		CompanyName, 
		ContactName, 
		ContactTitle, 
		Address,
		City, 
		Region, 
		PostalCode, 
		Country, 
		Phone, 
		Fax
	FROM northwind5.dbo.Customers
) c ON (dc.CustomerID = c.CustomerID) -- Assume CustomerID is unique
	WHEN MATCHED THEN -- if CustomerID matched, do nothing
	UPDATE SET dc.CompanyName = c.CompanyName -- Dummy update
	WHEN NOT MATCHED THEN -- Otherwise, insert a new customer
	INSERT(CustomerID, CompanyName, ContactName, ContactTitle, Address,
	City, Region, PostalCode, Country, Phone, Fax)
	VALUES(c.CustomerID, c.CompanyName, c.ContactName, c.ContactTitle,
	c.Address, c.City, C.Region, c.PostalCode, c.Country, c.Phone,
	c.Fax);

MERGE INTO dimCustomers dc
USING
(
	SELECT 
		CustomerID, 
		CompanyName, 
		ContactName, 
		ContactTitle, 
		Address,
		City, 
		Region, 
		PostalCode, 
		Country, 
		Phone, 
		Fax
	FROM northwind6.dbo.Customers
) c ON (dc.CustomerID = c.CustomerID) -- Assume CustomerID is unique
	WHEN MATCHED THEN -- if CustomerID matched, do nothing
	UPDATE SET dc.CompanyName = c.CompanyName -- Dummy update
	WHEN NOT MATCHED THEN -- Otherwise, insert a new customer
	INSERT(CustomerID, CompanyName, ContactName, ContactTitle, Address,
	City, Region, PostalCode, Country, Phone, Fax)
	VALUES(c.CustomerID, c.CompanyName, c.ContactName, c.ContactTitle,
	c.Address, c.City, C.Region, c.PostalCode, c.Country, c.Phone,
	c.Fax);

--dimCustomers Validation
select 'OLTP' as [SourceType], 'northwind5.Customers' as [TableName], count(*) as [RowCounts] from northwind5.dbo.Customers
Union
select 'OLTP' as [SourceType], 'northwind6.Customers' as [TableName], count(*) as [RowCounts] from northwind6.dbo.Customers
Union
select 'OLAP' as [SourceType], 'northwind_dw_assign3.dimCustomers' as [TableName], count(*) as [RowCounts] from northwind_dw_assign3.dbo.dimCustomers;

-- Step 2.3 populating dimCategories
MERGE INTO dimCategories dca
USING
(
	SELECT 
		CategoryID, 
		CategoryName, 
		Description, 
		Picture 
	FROM northwind5.dbo.Categories
) ca ON (dca.CategoryID = ca.CategoryID) -- Assume CategoryID is unique
	WHEN MATCHED THEN -- if CategoryID matched, do nothing
	UPDATE SET dca.CategoryName = ca.CategoryName -- Dummy update
	WHEN NOT MATCHED THEN -- Otherwise, insert a new category
	INSERT(CategoryID,CategoryName,Description,Picture)
	VALUES(ca.CategoryID,ca.CategoryName,ca.Description,ca.Picture);

MERGE INTO dimCategories dca
USING
(
	SELECT 
		CategoryID, 
		CategoryName, 
		Description, 
		Picture 
	FROM northwind6.dbo.Categories
) ca ON (dca.CategoryID = ca.CategoryID) -- Assume CategoryID is unique
	WHEN MATCHED THEN -- if CategoryID matched, do nothing
	UPDATE SET dca.CategoryName = ca.CategoryName -- Dummy update
	WHEN NOT MATCHED THEN -- Otherwise, insert a new category
	INSERT(CategoryID,CategoryName,Description,Picture)
	VALUES(ca.CategoryID,ca.CategoryName,ca.Description,ca.Picture);

-- dimCategories Validation 
select 'OLTP' as [SourceType], 'northwind5.Categories' as [TableName], count(*) as [RowCounts] from northwind5.dbo.Categories
Union
select 'OLTP' as [SourceType], 'northwind6.Categories' as [TableName], count(*) as [RowCounts] from northwind6.dbo.Categories
Union
select 'OLAP' as [SourceType], 'northwind_dw_assign3.dimCategories' as [TableName], count(*) as [RowCounts] from northwind_dw_assign3.dbo.dimCategories;

-- step 2.4 Populating factOrders
MERGE INTO factOrders fo
USING
(
	SELECT ProductKey, 
		CustomerKey,
		CategoryKey,
		dt1.TimeKey as [OrderDatekey], -- from dimTime
		dt2.TimeKey as [RequiredDatekey], -- from dimTime
		dt3.TimeKey as [ShippedDateKey], --from dimTime
		o.OrderID as [OrderID],
		od.UnitPrice as [UnitPrice], 
		Quantity as [Qty],
		Discount,
		od.UnitPrice*od.Quantity as [TotalPrice], -- Calculation!
		sh.CompanyName as [ShipperCompany],
		sh.Phone as [ShipperPhone]
	FROM northwind5.dbo.Orders o,
	northwind5.dbo.[Order Details] od,
	northwind5.dbo.Products p,
	dimCustomers dc, dimProducts dp, dimCategories dca,
	dimTime dt1, dimTime dt2, dimTime dt3, northwind5.dbo.Shippers sh -- Three dimTime tables
	WHERE od.OrderID=o.OrderID
	AND dp.ProductID=od.ProductID
	AND dp.ProductID=p.ProductID
	AND o.CustomerID=dc.CustomerID
	AND p.CategoryID = dca.CategoryID
	AND dt1.Date=o.OrderDate  
	AND dt2.Date=o.RequiredDate
	AND dt3.Date=o.ShippedDate
	AND sh.ShipperID = o.ShipVia
) o 
	ON (o.ProductKey = fo.ProductKey -- Assume All Keys are unique
		AND o.CustomerKey=fo.CustomerKey
		AND o.OrderDateKey=fo.OrderDateKey
		AND o.CategoryKey=fo.CategoryKey)
	WHEN MATCHED THEN -- if they matched, do nothing
	UPDATE SET fo.OrderID = o.OrderID -- Dummy update
	WHEN NOT MATCHED THEN -- Otherwise, insert a new row
	INSERT(ProductKey, CustomerKey,CategoryKey, OrderDateKey, RequiredDateKey,
	ShippedDateKey, OrderID, UnitPrice, Quantity, Discount, TotalPrice, ShipperCompany, ShipperPhone)
	VALUES(o.ProductKey,o.CustomerKey,o.CategoryKey, o.OrderDateKey,o.RequiredDateKey,o.ShippedDateKey,o.
	OrderID,o.UnitPrice,o.Qty,o.Discount, o.TotalPrice, o.ShipperCompany, o.ShipperPhone);

MERGE INTO factOrders fo
USING
(
	SELECT ProductKey, 
		CustomerKey,
		CategoryKey,
		dt1.TimeKey as [OrderDatekey], -- from dimTime
		dt2.TimeKey as [RequiredDatekey], -- from dimTime
		dt3.TimeKey as [ShippedDateKey], --from dimTime
		o.OrderID as [OrderID],
		od.UnitPrice as [UnitPrice], 
		Quantity as [Qty],
		Discount,
		od.UnitPrice*od.Quantity as [TotalPrice], -- Calculation!
		sh.CompanyName as [ShipperCompany],
		sh.Phone as [ShipperPhone]
	FROM northwind6.dbo.Orders o,
	northwind6.dbo.[Order Details] od,
	northwind6.dbo.Products p,
	dimCustomers dc, dimProducts dp, dimCategories dca,
	dimTime dt1, dimTime dt2, dimTime dt3, northwind6.dbo.Shippers sh -- Three dimTime tables
	WHERE od.OrderID=o.OrderID
	AND dp.ProductID=od.ProductID
	AND dp.ProductID=p.ProductID
	AND o.CustomerID=dc.CustomerID
	AND p.CategoryID = dca.CategoryID
	AND dt1.Date=o.OrderDate  
	AND dt2.Date=o.RequiredDate
	AND dt3.Date=o.ShippedDate
	AND sh.ShipperID = o.ShipVia
) o 
	ON (o.ProductKey = fo.ProductKey -- Assume All Keys are unique
		AND o.CustomerKey=fo.CustomerKey
		AND o.OrderDateKey=fo.OrderDateKey
		AND o.CategoryKey=fo.CategoryKey)
	WHEN MATCHED THEN -- if they matched, do nothing
	UPDATE SET fo.OrderID = o.OrderID -- Dummy update
	WHEN NOT MATCHED THEN -- Otherwise, insert a new row
	INSERT(ProductKey, CustomerKey,CategoryKey, OrderDateKey, RequiredDateKey,
	ShippedDateKey, OrderID, UnitPrice, Quantity, Discount, TotalPrice, ShipperCompany, ShipperPhone)
	VALUES(o.ProductKey,o.CustomerKey,o.CategoryKey, o.OrderDateKey,o.RequiredDateKey,o.ShippedDateKey,o.
	OrderID,o.UnitPrice,o.Qty,o.Discount, o.TotalPrice, o.ShipperCompany, o.ShipperPhone);

-- factOrders Validation
select 'OLTP' as [SourceType], 'northwind5.dbo.Order Details' as [TableName], count(*) as [RowCounts] from northwind5.dbo.[Order Details]
Union
select 'OLTP' as [SourceType], 'northwind6.dbo.Order Details' as [TableName], count(*) as [RowCounts] from northwind6.dbo.[Order Details]
Union
select 'OLAP' as [SourceType], 'northwind_dw_assign3.factOrders' as [TableName], count(*) as [RowCounts] from northwind_dw_assign3.dbo.factOrders;

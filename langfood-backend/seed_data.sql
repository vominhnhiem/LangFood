-- ======================================================================================
-- LANGFOOD — SCRIPT KHỞI TẠO DỮ LIỆU THẬT KTX ĐHQG TP.HCM (KTX KHU B & KHU A)
-- Dự án: LangFood - Ứng dụng đặt món & giao đồ ăn KTX Làng Đại Học TP.HCM
-- Cơ sở dữ liệu: LangFoodBackendDB (SQL Server)
-- ======================================================================================

USE [LangFoodBackendDB];
GO

SET NOCOUNT ON;

PRINT N'>> [BƯỚC 1/7] Bổ sung cấu trúc cột mở rộng & các bảng hỗ trợ...';

-- 1. Bổ sung các cột chi tiết cho bảng Buildings (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Buildings]') AND name = 'BuildingCode')
    ALTER TABLE [Buildings] ADD [BuildingCode] NVARCHAR(20) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Buildings]') AND name = 'ClusterGroup')
    ALTER TABLE [Buildings] ADD [ClusterGroup] NVARCHAR(20) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Buildings]') AND name = 'TotalFloors')
    ALTER TABLE [Buildings] ADD [TotalFloors] INT DEFAULT 16 NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Buildings]') AND name = 'HasElevator')
    ALTER TABLE [Buildings] ADD [HasElevator] BIT DEFAULT 1 NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Buildings]') AND name = 'BuildingId')
    ALTER TABLE [Buildings] ADD [BuildingId] NVARCHAR(20) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Buildings]') AND name = 'BuildingName')
    ALTER TABLE [Buildings] ADD [BuildingName] NVARCHAR(100) NULL;
GO

-- Đảm bảo BuildingId có ràng buộc duy nhất để DropOffPoints có thể tham chiếu
IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = 'UQ_Buildings_BuildingId')
BEGIN
    UPDATE [Buildings] SET [BuildingId] = [BuildingCode] WHERE [BuildingId] IS NULL;
    ALTER TABLE [Buildings] ALTER COLUMN [BuildingId] NVARCHAR(20) NOT NULL;
    ALTER TABLE [Buildings] ADD CONSTRAINT UQ_Buildings_BuildingId UNIQUE ([BuildingId]);
END
GO

-- 2. Bổ sung các cột chi tiết cho bảng Shops (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Shops]') AND name = 'StoreCode')
    ALTER TABLE [Shops] ADD [StoreCode] NVARCHAR(20) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Shops]') AND name = 'OpenTime')
    ALTER TABLE [Shops] ADD [OpenTime] NVARCHAR(10) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Shops]') AND name = 'CloseTime')
    ALTER TABLE [Shops] ADD [CloseTime] NVARCHAR(10) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Shops]') AND name = 'Rating')
    ALTER TABLE [Shops] ADD [Rating] DECIMAL(2, 1) DEFAULT 5.0 NULL;

-- 3. Bổ sung các cột chi tiết cho Categories (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Categories]') AND name = 'CategoryCode')
    ALTER TABLE [Categories] ADD [CategoryCode] NVARCHAR(20) NULL;

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Categories]') AND name = 'DisplayOrder')
    ALTER TABLE [Categories] ADD [DisplayOrder] INT DEFAULT 0 NULL;

-- 4. Bổ sung cột DishCode cho Products (nếu chưa có)
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[Products]') AND name = 'DishCode')
    ALTER TABLE [Products] ADD [DishCode] NVARCHAR(20) NULL;

-- 4.1 Đảm bảo Orders có ràng buộc mặc định cho CommissionFee
IF NOT EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_Orders_CommissionFee')
BEGIN
    ALTER TABLE [Orders] ADD CONSTRAINT DF_Orders_CommissionFee DEFAULT (0) FOR [CommissionFee];
END
GO

-- 5. Tạo bảng DropOffPoints (Điểm giao nhận đồ ăn KTX)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DropOffPoints')
BEGIN
    CREATE TABLE [DropOffPoints] (
        [LocationId] NVARCHAR(50) PRIMARY KEY,
        [BuildingId] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Buildings]([BuildingId]),
        [LocationType] NVARCHAR(30) NOT NULL, -- LOBBY, SECURITY, DOOR_TO_DOOR, GATE
        [Title] NVARCHAR(150) NOT NULL,
        [Description] NVARCHAR(255) NOT NULL,
        [Surcharge] DECIMAL(18, 2) DEFAULT 0,
        [IsRecommended] BIT DEFAULT 0
    );
END

-- 6. Tạo bảng Toppings (Định nghĩa Topping chuẩn)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Toppings')
BEGIN
    CREATE TABLE [Toppings] (
        [ToppingId] NVARCHAR(20) PRIMARY KEY,
        [ToppingName] NVARCHAR(100) NOT NULL,
        [Price] DECIMAL(18, 2) NOT NULL,
        [GroupType] NVARCHAR(30) NOT NULL -- TOPPING_FOOD, TOPPING_DRINK, LEVEL_SUGAR, LEVEL_ICE
    );
END

-- 7. Tạo bảng DishToppings (Liên kết món ăn - Topping)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DishToppings')
BEGIN
    CREATE TABLE [DishToppings] (
        [DishCode] NVARCHAR(20) NOT NULL,
        [ToppingId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Toppings]([ToppingId]),
        PRIMARY KEY ([DishCode], [ToppingId])
    );
END
GO

PRINT N'>> [BƯỚC 2/7] Dọn dẹp dữ liệu cũ theo đúng ràng buộc khóa ngoại...';

DELETE FROM [OrderItems];
DELETE FROM [Orders];
DELETE FROM [CartItems];
DELETE FROM [DishToppings];
DELETE FROM [Toppings];
DELETE FROM [DropOffPoints];
DELETE FROM [ProductOptions];
DELETE FROM [ProductOptionGroups];
DELETE FROM [Products];
DELETE FROM [Categories];
DELETE FROM [Shops];
DELETE FROM [Shippers];
DELETE FROM [Wallets];
DELETE FROM [RoleRequests];
DELETE FROM [Notifications];
DELETE FROM [Complaints];
DELETE FROM [Users];
DELETE FROM [Buildings];
GO

PRINT N'>> [BƯỚC 3/7] Nạp danh sách Tòa Nhà KTX Khu A & Khu B...';

SET IDENTITY_INSERT [Buildings] ON;
INSERT INTO [Buildings] ([Id], [Name], [IsActive], [BuildingCode], [ClusterGroup], [TotalFloors], [HasElevator], [BuildingId], [BuildingName]) VALUES
-- KTX Khu A
(1, N'Tòa A1 - KTX Khu A ĐHQG', 1, N'A1', N'A', 5, 0, N'A1', N'Tòa A1 - KTX Khu A ĐHQG'),
(2, N'Tòa A2 - KTX Khu A ĐHQG', 1, N'A2', N'A', 5, 0, N'A2', N'Tòa A2 - KTX Khu A ĐHQG'),

-- Cụm Tòa C (16 tầng - có thang máy)
(3, N'Tòa C1 - KTX Khu B', 1, N'C1', N'C', 16, 1, N'C1', N'Tòa C1 - KTX Khu B'),
(4, N'Tòa C2 - KTX Khu B', 1, N'C2', N'C', 16, 1, N'C2', N'Tòa C2 - KTX Khu B'),
(5, N'Tòa C3 - KTX Khu B', 1, N'C3', N'C', 16, 1, N'C3', N'Tòa C3 - KTX Khu B'),
(6, N'Tòa C4 - KTX Khu B', 1, N'C4', N'C', 16, 1, N'C4', N'Tòa C4 - KTX Khu B'),
(7, N'Tòa C5 - KTX Khu B', 1, N'C5', N'C', 16, 1, N'C5', N'Tòa C5 - KTX Khu B'),
(8, N'Tòa C6 - KTX Khu B', 1, N'C6', N'C', 16, 1, N'C6', N'Tòa C6 - KTX Khu B'),

-- Cụm Tòa D (16 tầng - có thang máy)
(9, N'Tòa D1 - KTX Khu B', 1, N'D1', N'D', 16, 1, N'D1', N'Tòa D1 - KTX Khu B'),
(10, N'Tòa D2 - KTX Khu B', 1, N'D2', N'D', 16, 1, N'D2', N'Tòa D2 - KTX Khu B'),
(11, N'Tòa D3 - KTX Khu B', 1, N'D3', N'D', 16, 1, N'D3', N'Tòa D3 - KTX Khu B'),
(12, N'Tòa D4 - KTX Khu B', 1, N'D4', N'D', 16, 1, N'D4', N'Tòa D4 - KTX Khu B'),
(13, N'Tòa D5 - KTX Khu B', 1, N'D5', N'D', 16, 1, N'D5', N'Tòa D5 - KTX Khu B'),
(14, N'Tòa D6 - KTX Khu B', 1, N'D6', N'D', 16, 1, N'D6', N'Tòa D6 - KTX Khu B'),

-- Cụm Tòa B.B (5 tầng - thang bộ)
(15, N'Tòa B.B1 - KTX Khu B', 1, N'BB1', N'B.B', 5, 0, N'BB1', N'Tòa B.B1 - KTX Khu B'),
(16, N'Tòa B.B2 - KTX Khu B', 1, N'BB2', N'B.B', 5, 0, N'BB2', N'Tòa B.B2 - KTX Khu B'),

-- Cụm Tòa B.A (5 tầng - thang bộ)
(17, N'Tòa B.A1 - KTX Khu B', 1, N'BA1', N'B.A', 5, 0, N'BA1', N'Tòa B.A1 - KTX Khu B'),
(18, N'Tòa B.A2 - KTX Khu B', 1, N'BA2', N'B.A', 5, 0, N'BA2', N'Tòa B.A2 - KTX Khu B'),
(19, N'Tòa B.A3 - KTX Khu B', 1, N'BA3', N'B.A', 5, 0, N'BA3', N'Tòa B.A3 - KTX Khu B'),
(20, N'Tòa B.A4 - KTX Khu B', 1, N'BA4', N'B.A', 5, 0, N'BA4', N'Tòa B.A4 - KTX Khu B'),

-- Cụm Tòa B.C (5 tầng - thang bộ)
(21, N'Tòa B.C1 - KTX Khu B', 1, N'BC1', N'B.C', 5, 0, N'BC1', N'Tòa B.C1 - KTX Khu B'),
(22, N'Tòa B.C2 - KTX Khu B', 1, N'BC2', N'B.C', 5, 0, N'BC2', N'Tòa B.C2 - KTX Khu B'),

-- Cụm Tòa B.D (5 tầng - thang bộ)
(23, N'Tòa B.D1 - KTX Khu B', 1, N'BD1', N'B.D', 5, 0, N'BD1', N'Tòa B.D1 - KTX Khu B'),
(24, N'Tòa B.D2 - KTX Khu B', 1, N'BD2', N'B.D', 5, 0, N'BD2', N'Tòa B.D2 - KTX Khu B'),
(25, N'Tòa B.D3 - KTX Khu B', 1, N'BD3', N'B.D', 5, 0, N'BD3', N'Tòa B.D3 - KTX Khu B'),
(26, N'Tòa B.D4 - KTX Khu B', 1, N'BD4', N'B.D', 5, 0, N'BD4', N'Tòa B.D4 - KTX Khu B'),
(27, N'Tòa B.D5 - KTX Khu B', 1, N'BD5', N'B.D', 5, 0, N'BD5', N'Tòa B.D5 - KTX Khu B'),

-- Tòa dịch vụ trung tâm E1 (4 tầng - thang máy)
(28, N'Tòa E1 - Dịch Vụ Tổng Hợp', 1, N'E1', N'E', 4, 1, N'E1', N'Tòa E1 - Dịch Vụ Tổng Hợp');
SET IDENTITY_INSERT [Buildings] OFF;
GO

PRINT N'>> Nạp danh sách 87 Điểm giao nhận (DropOffPoints) KTX Khu B & Cổng...';

DECLARE @BuildingId NVARCHAR(20), @BuildingName NVARCHAR(100), @HasElevator BIT;

DECLARE building_cursor CURSOR FOR
SELECT BuildingId, BuildingName, HasElevator FROM Buildings;

OPEN building_cursor;
FETCH NEXT FROM building_cursor INTO @BuildingId, @BuildingName, @HasElevator;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- A. Sảnh tầng G (Khuyên dùng - Miễn phí)
    MERGE INTO DropOffPoints AS Target
    USING (VALUES (
        'LOC_' + @BuildingId + '_LOBBY',
        @BuildingId,
        'LOBBY',
        N'Sảnh tầng G (Chân tòa nhà)',
        N'Khu nhận đồ ăn tập trung của ' + @BuildingName,
        0,
        1
    )) AS Source (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
    ON Target.LocationId = Source.LocationId
    WHEN NOT MATCHED THEN
        INSERT (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
        VALUES (Source.LocationId, Source.BuildingId, Source.LocationType, Source.Title, Source.Description, Source.Surcharge, Source.IsRecommended);

    -- B. Cổng bảo vệ tòa nhà (Miễn phí)
    MERGE INTO DropOffPoints AS Target
    USING (VALUES (
        'LOC_' + @BuildingId + '_SECURITY',
        @BuildingId,
        'SECURITY',
        N'Cổng bảo vệ tòa nhà',
        N'Gửi tại bàn trực bảo vệ ' + @BuildingName + N' nếu bạn đang bận học/thi',
        0,
        0
    )) AS Source (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
    ON Target.LocationId = Source.LocationId
    WHEN NOT MATCHED THEN
        INSERT (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
        VALUES (Source.LocationId, Source.BuildingId, Source.LocationType, Source.Title, Source.Description, Source.Surcharge, Source.IsRecommended);

    -- C. Giao tận cửa phòng KTX (+5.000đ)
    MERGE INTO DropOffPoints AS Target
    USING (VALUES (
        'LOC_' + @BuildingId + '_DOOR',
        @BuildingId,
        'DOOR_TO_DOOR',
        N'Giao tận cửa phòng KTX',
        CASE WHEN @HasElevator = 1 
             THEN N'Hỗ trợ shipper nội trú gửi xe và đi thang máy lên tận phòng'
             ELSE N'Hỗ trợ shipper nội trú gửi xe và đi cầu thang bộ lên phòng' END,
        5000,
        0
    )) AS Source (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
    ON Target.LocationId = Source.LocationId
    WHEN NOT MATCHED THEN
        INSERT (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
        VALUES (Source.LocationId, Source.BuildingId, Source.LocationType, Source.Title, Source.Description, Source.Surcharge, Source.IsRecommended);

    FETCH NEXT FROM building_cursor INTO @BuildingId, @BuildingName, @HasElevator;
END;

CLOSE building_cursor;
DEALLOCATE building_cursor;

-- Nạp bổ sung các điểm nhận tại Cổng KTX
MERGE INTO DropOffPoints AS Target
USING (VALUES
    ('LOC_GATE_TO_VINH_DIEN', NULL, 'GATE', N'Cổng chính Tô Vĩnh Diện', N'Trước trạm xe buýt và bãi xe cổng chính KTX Khu B', 0, 0),
    ('LOC_GATE_TAN_LAP', NULL, 'GATE', N'Cổng phụ Tân Lập', N'Cuối hẻm Tân Lập sát chợ đêm sinh viên', 0, 0),
    ('LOC_GATE_VANH_DAI', NULL, 'GATE', N'Cổng Vành Đai ĐHQG', N'Lối ra đường Tạ Quang Bửu hướng ĐH Bách Khoa', 0, 0)
) AS Source (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
ON Target.LocationId = Source.LocationId
WHEN NOT MATCHED THEN
    INSERT (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
    VALUES (Source.LocationId, Source.BuildingId, Source.LocationType, Source.Title, Source.Description, Source.Surcharge, Source.IsRecommended);
GO

PRINT N'>> [BƯỚC 4/7] Nạp tài khoản Người dùng (Users), Ví (Wallets) & Shipper...';

INSERT INTO [Users] (
    [Id], [Username], [PasswordHash], [RoleId], [FullName], [Email], [PhoneNumber],
    [BuildingId], [KtxRoom], [IsVerifiedResident], [IsApproved], [CanManageOrders], [CanManageFinance], [CanManageShops]
) VALUES
-- Khách hàng: Võ Minh Nhiệm (Sinh viên Tòa C3)
('25285E00-5CE4-47B4-8E98-B62CE39FC82C', 'nhiem', 'nhiem2512005', 1, N'Võ Minh Nhiệm', 'nhiem@vnu.edu.vn', '0901234567', 5, N'P. 612', 1, 1, 0, 0, 0),

-- Khách hàng: Nguyễn Văn Sinh Viên (Sinh viên Tòa D5)
('A1000000-0000-0000-0000-000000000001', 'sinhvien', '123456', 1, N'Nguyễn Văn Sinh Viên', 'sinhvien@vnu.edu.vn', '0912345678', 13, N'P. 804', 1, 1, 0, 0, 0),

-- Chủ Quán ST01: Căn Tin Cụm C (Tài khoản chính 'seller')
('6FB513F5-0C65-49CA-A688-2EF27003FF25', 'seller', '123456', 2, N'Căn Tin Cụm C (C1 - C2)', 'cantin_c@langfood.vn', '0907654321', 3, N'Tầng trệt C1-C2', 1, 1, 0, 0, 0),

-- Chủ Quán ST02: Căn Tin Cụm D
('6FB513F5-0C65-49CA-A688-2EF270030002', 'seller_cantin_d', '123456', 2, N'Căn Tin Cụm D (D3 - D4)', 'cantin_d@langfood.vn', '0907111222', 11, N'Hành lang D3-D4', 1, 1, 0, 0, 0),

-- Chủ Quán ST03: Food Court Tòa E1
('6FB513F5-0C65-49CA-A688-2EF270030003', 'seller_foodcourt_e1', '123456', 2, N'Food Court Tòa E1', 'foodcourt_e1@langfood.vn', '0907333444', 28, N'Tầng 1 E1', 1, 1, 0, 0, 0),

-- Chủ Quán ST04: Cơm Tấm Đêm Tân Lập
('6FB513F5-0C65-49CA-A688-2EF270030004', 'seller_tanlap', '123456', 2, N'Cơm Tấm Đêm Tân Lập', 'comtam_tanlap@langfood.vn', '0907555666', NULL, N'Số 14 Tân Lập', 1, 1, 0, 0, 0),

-- Chủ Quán ST05: Trà Sữa & Ăn Vặt Làng KTX
('6FB513F5-0C65-49CA-A688-2EF270030005', 'seller_anvat', '123456', 2, N'Trà Sữa & Ăn Vặt Làng KTX', 'anvat_langktx@langfood.vn', '0907777888', NULL, N'Kiot Cổng chính', 1, 1, 0, 0, 0),

-- Chủ Quán ST06: Bánh Mì Chảo & Xôi Mặn B.A3
('6FB513F5-0C65-49CA-A688-2EF270030006', 'seller_ba3', '123456', 2, N'Bánh Mì Chảo B.A3', 'banhmi_ba3@langfood.vn', '0907888999', 19, N'Sảnh B.A3', 1, 1, 0, 0, 0),

-- Shipper KTX: Tài xế sinh viên
('919741A9-FABE-483D-950C-64E260AEE784', 'shipper', '123456', 3, N'Tài Xế Shipper KTX Khu B', 'shipper@langfood.vn', '0908889999', 15, N'P. 201', 1, 1, 0, 0, 0),

-- Admin Quản trị hệ thống
('c6eba905-994e-4a44-93f9-e37c143644fd', 'admin', 'Admin@123', 0, N'Làng Food Administrator', 'admin@langfood.vn', '0909999999', NULL, NULL, 1, 1, 1, 1, 1);
GO

SET IDENTITY_INSERT [Wallets] ON;
INSERT INTO [Wallets] ([Id], [UserId], [Balance], [UpdatedAt]) VALUES
(1, '25285E00-5CE4-47B4-8E98-B62CE39FC82C', 500000.00, GETDATE()),
(2, '6FB513F5-0C65-49CA-A688-2EF27003FF25', 1200000.00, GETDATE()),
(3, '919741A9-FABE-483D-950C-64E260AEE784', 350000.00, GETDATE()),
(4, 'c6eba905-994e-4a44-93f9-e37c143644fd', 8000000.00, GETDATE()),
(5, 'A1000000-0000-0000-0000-000000000001', 300000.00, GETDATE()),
(6, '6FB513F5-0C65-49CA-A688-2EF270030002', 950000.00, GETDATE()),
(7, '6FB513F5-0C65-49CA-A688-2EF270030003', 1100000.00, GETDATE()),
(8, '6FB513F5-0C65-49CA-A688-2EF270030004', 700000.00, GETDATE()),
(9, '6FB513F5-0C65-49CA-A688-2EF270030005', 850000.00, GETDATE()),
(10, '6FB513F5-0C65-49CA-A688-2EF270030006', 600000.00, GETDATE());
SET IDENTITY_INSERT [Wallets] OFF;
GO

SET IDENTITY_INSERT [Shippers] ON;
INSERT INTO [Shippers] ([Id], [UserId], [Mssv], [IsOnline], [IsApproved], [CreatedAt]) VALUES
(1, '919741A9-FABE-483D-950C-64E260AEE784', '202612345', 1, 1, GETDATE());
SET IDENTITY_INSERT [Shippers] OFF;
GO

PRINT N'>> [BƯỚC 5/7] Nạp Danh mục món ăn (Categories) & Gian hàng (Shops)...';

SET IDENTITY_INSERT [Categories] ON;
INSERT INTO [Categories] ([Id], [Name], [IsDeleted], [ImageUrl], [CategoryCode], [DisplayOrder]) VALUES
(1, N'Cơm & Món No', 0, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&auto=format&fit=crop&q=80', N'CAT_COM', 1),
(2, N'Bún, Phở & Mì', 0, 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=400&auto=format&fit=crop&q=80', N'CAT_BUN', 2),
(3, N'Trà Sữa & Đồ Uống', 0, 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=400&auto=format&fit=crop&q=80', N'CAT_DRINK', 3),
(4, N'Ăn Vặt Đêm', 0, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400&auto=format&fit=crop&q=80', N'CAT_SNACK', 4),
(5, N'Bánh Mì & Điểm Tâm', 0, 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=400&auto=format&fit=crop&q=80', N'CAT_FAST', 5),
(6, N'Cà Phê Sinh Viên', 0, 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&auto=format&fit=crop&q=80', N'CAT_COFFEE', 6);
SET IDENTITY_INSERT [Categories] OFF;
GO

SET IDENTITY_INSERT [Shops] ON;
INSERT INTO [Shops] (
    [Id], [UserId], [Name], [Address], [Description], [ImageUrl], [IsActive], [IsOpen],
    [StoreCode], [OpenTime], [CloseTime], [Rating]
) VALUES
(1, '6FB513F5-0C65-49CA-A688-2EF27003FF25', N'Căn Tin Cụm C (C1 - C2)', N'Tầng trệt cụm tòa C1 - C2 KTX Khu B', N'Cơm phần, cơm sườn nướng than hoa thơm nức mũi, mì trộn Indomie nóng sốt, phục vụ sinh viên từ sáng sớm.', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80', 1, 1, N'ST01', '06:30', '20:30', 4.5),
(2, '6FB513F5-0C65-49CA-A688-2EF270030002', N'Căn Tin Cụm D (D3 - D4)', N'Tầng trệt hành lang nối D3 - D4 KTX Khu B', N'Chuyên bò xào lúc lắc, bún bò Huế nước dùng ngọt tủy thanh cay chuẩn vị cố đô, rau tươi sạch miễn phí.', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&auto=format&fit=crop&q=80', 1, 1, N'ST02', '06:30', '21:00', 4.6),
(3, '6FB513F5-0C65-49CA-A688-2EF270030003', N'Food Court Tòa E1', N'Tầng 1 Nhà dịch vụ tổng hợp E1 KTX Khu B', N'Khu ẩm thực hiện đại với trà mãng cầu xiêm ngọt mát, trà đào cam sả trứ danh và các món nước giải nhiệt mùa thi.', 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=600&auto=format&fit=crop&q=80', 1, 1, N'ST03', '07:00', '22:00', 4.8),
(4, '6FB513F5-0C65-49CA-A688-2EF270030004', N'Cơm Tấm Đêm Tân Lập', N'Số 14 Đường Tân Lập (Sát cổng phụ KTX B)', N'Cơm tấm đêm phục vụ sinh viên thức khuya làm đồ án, sườn bì chả nướng than đẫm vị sốt gia truyền, canh nóng.', 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop&q=80', 1, 1, N'ST04', '16:00', '23:30', 4.7),
(5, '6FB513F5-0C65-49CA-A688-2EF270030005', N'Trà Sữa & Ăn Vặt Làng KTX', N'Kiot Cổng chính Tô Vĩnh Diện, KTX Khu B', N'Trà sữa Oolong nướng thơm béo, trân châu hoàng kim, bánh tráng trộn khô bò trứng cút, mẹt cá viên mắm tỏi.', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop&q=80', 1, 1, N'ST05', '09:00', '23:00', 4.4),
(6, '6FB513F5-0C65-49CA-A688-2EF270030006', N'Bánh Mì Chảo & Xôi Mặn B.A3', N'Khuôn viên nhà B.A3 KTX Khu B', N'Bánh mì chảo xíu mại nóng giòn, xôi mặn thập cẩm thơm dẻo cùng cà phê phin sữa đá đậm đà khởi đầu ngày mới.', 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600&auto=format&fit=crop&q=80', 1, 1, N'ST06', '06:00', '13:00', 4.5);
SET IDENTITY_INSERT [Shops] OFF;
GO

PRINT N'>> [BƯỚC 6/7] Nạp Món ăn (Products), Topping & Tùy chọn (ProductOptionGroups & ProductOptions)...';

SET IDENTITY_INSERT [Products] ON;
INSERT INTO [Products] (
    [Id], [ShopId], [CategoryId], [Name], [Description], [Price], [ImageUrl],
    [IsDeleted], [Status], [IsAvailable], [UserId], [DishCode]
) VALUES
-- Món Căn tin C (ST01)
(1, 1, 1, N'Cơm sườn nướng mật ong', N'Sườn nướng than hoa, kèm mỡ hành và canh rau', 30000.00, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF27003FF25', N'DISH_01'),
(2, 1, 1, N'Cơm gà xối mỡ (Đùi góc tư)', N'Cơm chiên hồng ngọc, đùi gà chiên giòn rụm', 35000.00, 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF27003FF25', N'DISH_02'),
(3, 1, 2, N'Mì trộn Indomie thập cẩm', N'Indomie trộn xúc xích, bò viên, trứng ốp la', 25000.00, 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF27003FF25', N'DISH_05'),

-- Món Căn tin D (ST02)
(4, 2, 1, N'Cơm bò xào lúc lắc', N'Bò xào ớt chuông, hành tây kèm xà lách giấm', 35000.00, 'https://images.unsplash.com/photo-1544025162-d76694265947?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030002', N'DISH_03'),
(5, 2, 2, N'Bún bò Huế đặc biệt', N'Nước dùng chuẩn vị Huế, kèm nạm bò, chả cua, tiết', 35000.00, 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030002', N'DISH_04'),

-- Món Food Court E1 (ST03)
(6, 3, 3, N'Trà mãng cầu xiêm', N'Trà lài đậm vị, thịt mãng cầu tươi dầm ngọt thanh', 22000.00, 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030003', N'DISH_06'),
(7, 3, 3, N'Trà đào cam sả (Size L)', N'Trà đen thơm sả, kèm 3 miếng đào giòn', 25000.00, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030003', N'DISH_07'),

-- Món Bánh Mì Chảo & Cà Phê B.A3 (ST06)
(8, 6, 6, N'Cà phê sữa đá pha phin', N'Đậm vị cà phê Tây Nguyên, sữa đặc truyền thống', 15000.00, 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030006', N'DISH_08'),
(9, 6, 5, N'Bánh mì chảo xíu mại trứng ốp la', N'Bánh mì nóng giòn, chảo xíu mại sốt cà chua, trứng ốp la lòng đào, pate béo', 28000.00, 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030006', N'DISH_12'),
(10, 6, 5, N'Xôi mặn thập cẩm chả lụa pate', N'Nếp dẻo thơm hạt sen, chả lụa, lạp xưởng nướng than, chà bông và mỡ hành', 20000.00, 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030006', N'DISH_13'),

-- Món Quán Trà Sữa & Ăn Vặt Làng KTX (ST05)
(11, 5, 3, N'Trà sữa Oolong nướng chân trâu', N'Vị trà đậm, trân châu hoàng kim dẻo dai', 28000.00, 'https://images.unsplash.com/photo-1558857563-b37cfb62a4d4?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030005', N'DISH_09'),
(12, 5, 4, N'Bánh tráng trộn khô bò trứng cút', N'Bánh tráng dẻo Tây Ninh, kèm ruốc, khô bò, trứng cút', 20000.00, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030005', N'DISH_10'),
(13, 5, 4, N'Mẹt cá viên chiên mắm tỏi', N'Xúc xích, bò viên, hồ lô xào sốt mắm tỏi kẹo cay ngọt', 35000.00, 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030005', N'DISH_11'),

-- Món Quán Cơm Tấm Đêm Tân Lập (ST04)
(14, 4, 1, N'Cơm tấm sườn bì chả đặc biệt Tân Lập', N'Cơm tấm đêm sinh viên hạt dẻo thơm, sườn ướp mật ong, bì thơm giòn, chả trứng béo', 35000.00, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80', 0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF270030004', N'DISH_14');
SET IDENTITY_INSERT [Products] OFF;
GO

PRINT N'>> Nạp Bảng Toppings & DishToppings trực tiếp...';
INSERT INTO [Toppings] ([ToppingId], [ToppingName], [Price], [GroupType]) VALUES
-- Topping thức ăn
(N'TOP_EGG', N'Thêm trứng ốp la', 5000, N'TOPPING_FOOD'),
(N'TOP_PORK', N'Thêm miếng sườn nướng', 15000, N'TOPPING_FOOD'),
(N'TOP_RICE', N'Thêm phần cơm thêm', 3000, N'TOPPING_FOOD'),
(N'TOP_SAUSAGE', N'Thêm xúc xích nướng', 5000, N'TOPPING_FOOD'),

-- Topping đồ uống
(N'TOP_PEARL', N'Trân châu đen dẻo', 5000, N'TOPPING_DRINK'),
(N'TOP_CHEESE', N'Kem cheese Macchiato', 7000, N'TOPPING_DRINK'),

-- Tùy chỉnh mức đường / đá (Miễn phí)
(N'OPT_SUGAR_0', N'Đường 0%', 0, N'LEVEL_SUGAR'),
(N'OPT_SUGAR_50', N'Đường 50% (Ít ngọt)', 0, N'LEVEL_SUGAR'),
(N'OPT_SUGAR_100', N'Đường 100% (Tiêu chuẩn)', 0, N'LEVEL_SUGAR'),
(N'OPT_ICE_NONE', N'Không lấy đá', 0, N'LEVEL_ICE'),
(N'OPT_ICE_50', N'50% đá', 0, N'LEVEL_ICE'),
(N'OPT_ICE_SEPARATE', N'Đá để riêng bọc ngoài', 0, N'LEVEL_ICE');

INSERT INTO [DishToppings] ([DishCode], [ToppingId]) VALUES
-- DISH_01: Cơm sườn nướng có thể thêm trứng, sườn, cơm
(N'DISH_01', N'TOP_EGG'),
(N'DISH_01', N'TOP_PORK'),
(N'DISH_01', N'TOP_RICE'),

-- DISH_02: Cơm gà xối mỡ có thể thêm trứng, cơm
(N'DISH_02', N'TOP_EGG'),
(N'DISH_02', N'TOP_RICE'),

-- DISH_05: Mì trộn Indomie thêm trứng, xúc xích
(N'DISH_05', N'TOP_EGG'),
(N'DISH_05', N'TOP_SAUSAGE'),

-- DISH_09: Trà sữa Oolong nướng chọn đường, đá, trân châu, cheese
(N'DISH_09', N'TOP_PEARL'),
(N'DISH_09', N'TOP_CHEESE'),
(N'DISH_09', N'OPT_SUGAR_50'),
(N'DISH_09', N'OPT_SUGAR_100'),
(N'DISH_09', N'OPT_ICE_50'),
(N'DISH_09', N'OPT_ICE_SEPARATE');
GO

PRINT N'>> Nạp ProductOptionGroups & ProductOptions cho Frontend & Backend API...';

SET IDENTITY_INSERT [ProductOptionGroups] ON;
INSERT INTO [ProductOptionGroups] ([Id], [ProductId], [Name], [IsRequired], [MinSelectable], [MaxSelectable]) VALUES
-- Cho Món 1 (DISH_01: Cơm sườn nướng mật ong)
(1, 1, N'Thêm Topping món ăn', 0, 0, 3),

-- Cho Món 2 (DISH_02: Cơm gà xối mỡ)
(2, 2, N'Thêm Topping món ăn', 0, 0, 2),

-- Cho Món 3 (DISH_05: Mì trộn Indomie thập cẩm)
(3, 3, N'Thêm Topping mì trộn', 0, 0, 2),

-- Cho Món 4 (DISH_03: Cơm bò xào lúc lắc)
(4, 4, N'Thêm Topping món ăn', 0, 0, 2),

-- Cho Món 5 (DISH_04: Bún bò Huế đặc biệt)
(5, 5, N'Thêm Topping bún bò', 0, 0, 3),

-- Cho Món 11 (DISH_09: Trà sữa Oolong nướng chân trâu)
(6, 11, N'Thêm Topping đồ uống', 0, 0, 2),
(7, 11, N'Chọn độ ngọt (Đường)', 1, 1, 1),
(8, 11, N'Chọn mức đá', 1, 1, 1),

-- Cho Món 6 (DISH_06: Trà mãng cầu xiêm)
(9, 6, N'Mức đá & Thêm Topping', 0, 0, 2),

-- Cho Món 7 (DISH_07: Trà đào cam sả)
(10, 7, N'Độ ngọt & Mức đá', 1, 1, 1),

-- Cho Món 8 (DISH_08: Cà phê sữa đá pha phin)
(11, 8, N'Tùy chọn cà phê', 1, 1, 1);
SET IDENTITY_INSERT [ProductOptionGroups] OFF;
GO

SET IDENTITY_INSERT [ProductOptions] ON;
INSERT INTO [ProductOptions] ([Id], [OptionGroupId], [Name], [AdditionalPrice], [IsAvailable]) VALUES
-- Nhóm 1: Topping Cơm sườn
(1, 1, N'Thêm trứng ốp la', 5000.00, 1),
(2, 1, N'Thêm miếng sườn nướng', 15000.00, 1),
(3, 1, N'Thêm phần cơm thêm', 3000.00, 1),

-- Nhóm 2: Topping Cơm gà
(4, 2, N'Thêm trứng ốp la', 5000.00, 1),
(5, 2, N'Thêm phần cơm thêm', 3000.00, 1),

-- Nhóm 3: Topping Mì trộn Indomie
(6, 3, N'Thêm trứng ốp la', 5000.00, 1),
(7, 3, N'Thêm xúc xích nướng', 5000.00, 1),

-- Nhóm 4: Topping Cơm bò
(8, 4, N'Thêm trứng ốp la', 5000.00, 1),
(9, 4, N'Thêm phần cơm thêm', 3000.00, 1),

-- Nhóm 5: Topping Bún bò Huế
(10, 5, N'Chả cua viên thêm', 8000.00, 1),
(11, 5, N'Nạm bò thái lát thêm', 12000.00, 1),
(12, 5, N'Huyết mềm thêm', 4000.00, 1),

-- Nhóm 6: Topping Trà sữa Oolong
(13, 6, N'Trân châu đen dẻo', 5000.00, 1),
(14, 6, N'Kem cheese Macchiato', 7000.00, 1),

-- Nhóm 7: Đường Trà sữa
(15, 7, N'Đường 0%', 0.00, 1),
(16, 7, N'Đường 50% (Ít ngọt)', 0.00, 1),
(17, 7, N'Đường 100% (Tiêu chuẩn)', 0.00, 1),

-- Nhóm 8: Đá Trà sữa
(18, 8, N'Không lấy đá', 0.00, 1),
(19, 8, N'50% đá', 0.00, 1),
(20, 8, N'Đá để riêng bọc ngoài', 0.00, 1),

-- Nhóm 9: Trà mãng cầu
(21, 9, N'Đá để riêng', 0.00, 1),
(22, 9, N'Kem cheese Macchiato', 7000.00, 1),

-- Nhóm 10: Trà đào cam sả
(23, 10, N'100% đường + 100% đá (Chuẩn)', 0.00, 1),
(24, 10, N'50% đường + 50% đá (Thanh mát)', 0.00, 1),
(25, 10, N'Đá để riêng', 0.00, 1),

-- Nhóm 11: Cà phê sữa
(26, 11, N'Ít ngọt, đậm đà cà phê', 0.00, 1),
(27, 11, N'Ngọt chuẩn pha phin Sài Gòn', 0.00, 1),
(28, 11, N'Đá riêng', 0.00, 1);
SET IDENTITY_INSERT [ProductOptions] OFF;
GO

PRINT N'>> [BƯỚC 7/7] Nạp Đơn hàng mẫu KTX Khu B cho Nhiệm và Shipper...';

SET IDENTITY_INSERT [Orders] ON;
INSERT INTO [Orders] (
    [Id], [BuyerId], [BuyerName], [ShopId], [BuildingId], [ShipperId], [Status],
    [TotalAmount], [ShippingFee], [CommissionFee], [CreatedAt], [DeliveredAt],
    [DeliveryBuilding], [DeliveryRoom], [DeliveryPhone], [PaymentMethod],
    [DeliveryLatitude], [DeliveryLongitude]
) VALUES
-- Đơn 1: Đã hoàn thành (Delivered)
(101, '25285E00-5CE4-47B4-8E98-B62CE39FC82C', N'Võ Minh Nhiệm', 1, 5, 1, 'Completed', 40000.00, 10000.00, 2000.00, DATEADD(minute, -45, GETDATE()), DATEADD(minute, -15, GETDATE()), N'Tòa C3 - KTX Khu B', N'P. 612 (Sảnh C3)', '0901234567', 1, 10.8805, 106.8048),

-- Đơn 2: Đang giao hàng thực tế (Delivering)
(102, '25285E00-5CE4-47B4-8E98-B62CE39FC82C', N'Võ Minh Nhiệm', 5, 5, 1, 'Delivering', 45000.00, 10000.00, 2000.00, DATEADD(minute, -10, GETDATE()), NULL, N'Tòa C3 - KTX Khu B', N'P. 612 (Sảnh C3)', '0901234567', 0, 10.8805, 106.8048);
SET IDENTITY_INSERT [Orders] OFF;
GO

SET IDENTITY_INSERT [OrderItems] ON;
INSERT INTO [OrderItems] ([Id], [OrderId], [ProductId], [Quantity], [UnitPrice], [Note], [OptionsSummary], [OptionsPrice]) VALUES
(1, 101, 1, 1, 30000.00, N'Giao trước bàn giao đồ ăn sảnh trệt C3 gọi em', N'Thêm trứng ốp la (+5.000₫)', 5000.00),
(2, 102, 11, 1, 28000.00, N'Đá để riêng bọc ngoài giúp em', N'Trân châu đen dẻo (+5.000₫), Đường 50%, Đá để riêng bọc ngoài', 5000.00);
SET IDENTITY_INSERT [OrderItems] OFF;
GO

PRINT N'>> [HOÀN TẤT] NẠP DỮ LIỆU KTX KHU B ĐHQG THÀNH CÔNG RỰC RỠ!';
GO

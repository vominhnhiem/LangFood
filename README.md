# Làng Food (LangFood)

Hệ sinh thái ứng dụng đặt món và giao đồ ăn chuyên biệt cho ký túc xá Làng Đại Học Quốc Gia TP.HCM (ĐHQG TP.HCM):
- **Frontend Mobile:** Flutter (Hỗ trợ Android, iOS, Web).
- **Backend API:** ASP.NET Core 8 Web API, Entity Framework Core, SignalR.
- **Quản trị:** ASP.NET Core MVC Web Admin.
- **Cơ sở dữ liệu:** Microsoft SQL Server (`LangFoodBackendDB`).

---

## 1. Dữ Liệu Thật KTX Khu B & Khởi Tạo Database (Seed Data)

Dự án cung cấp sẵn file script SQL nạp toàn bộ dữ liệu thật KTX ĐHQG TP.HCM tại:
👉 [`langfood-backend/seed_data.sql`](file:///d:/Đồ%20án/LangFood/langfood-backend/seed_data.sql)

### Dữ liệu nạp vào hệ thống bao gồm:
- **28 Tòa nhà KTX:**
  - **KTX Khu B (26 tòa):**
    - Cụm C (16 tầng, thang máy): Tòa C1, C2, C3, C4, C5, C6.
    - Cụm D (16 tầng, thang máy): Tòa D1, D2, D3, D4, D5, D6.
    - Cụm B.B (5 tầng, thang bộ): Tòa B.B1, B.B2.
    - Cụm B.A (5 tầng, thang bộ): Tòa B.A1, B.A2, B.A3, B.A4.
    - Cụm B.C (5 tầng, thang bộ): Tòa B.C1, B.C2.
    - Cụm B.D (5 tầng, thang bộ): Tòa B.D1, B.D2, B.D3, B.D4, B.D5.
    - Tòa dịch vụ trung tâm E1 (4 tầng, thang máy).
  - **KTX Khu A (2 tòa):** Tòa A1, Tòa A2.
- **87 Điểm giao nhận KTX (`DropOffPoints`):** Tự động sinh ra 3 hình thức nhận hàng chuẩn cho tất cả 28 tòa nhà KTX (28 × 3 = 84 điểm) cùng 3 cổng KTX Khu B:
  1. **Sảnh tầng G (Chân tòa nhà):** Điểm nhận tập trung tại sảnh, khuyên dùng (`Surcharge = 0`, `IsRecommended = 1`).
  2. **Cổng bảo vệ tòa nhà:** Bàn trực bảo vệ tòa nhà khi sinh viên bận học/thi (`Surcharge = 0`).
  3. **Giao tận cửa phòng KTX:** Shipper nội trú gửi xe đi thang máy/thang bộ mang lên tận phòng (`Surcharge = 5000`).
  4. **Điểm đón tại cổng KTX:** Cổng chính Tô Vĩnh Diện, Cổng phụ Tân Lập, Cổng Vành Đai ĐHQG.
- **6 Gian hàng / Quán ăn KTX Khu B (`Shops`):**
  1. `ST01`: Căn Tin Cụm C (C1 - C2) — Tầng trệt C1-C2 (06:30 - 20:30, 4.5⭐)
  2. `ST02`: Căn Tin Cụm D (D3 - D4) — Hành lang nối D3-D4 (06:30 - 21:00, 4.6⭐)
  3. `ST03`: Food Court Tòa E1 — Tầng 1 Tòa E1 (07:00 - 22:00, 4.8⭐)
  4. `ST04`: Cơm Tấm Đêm Tân Lập — Số 14 Tân Lập, sát cổng phụ KTX B (16:00 - 23:30, 4.7⭐)
  5. `ST05`: Trà Sữa & Ăn Vặt Làng KTX — Kiot Cổng chính Tô Vĩnh Diện (09:00 - 23:00, 4.4⭐)
  6. `ST06`: Bánh Mì Chảo & Xôi Mặn B.A3 — Sảnh B.A3 (06:00 - 13:00, 4.5⭐)
- **6 Danh mục món ăn (`Categories`):** Cơm & Món No, Bún Phở & Mì, Trà Sữa & Đồ Uống, Ăn Vặt Đêm, Bánh Mì & Điểm Tâm, Cà Phê Sinh Viên.
- **14 Món ăn thực tế (`Products`):** Cơm sườn nướng mật ong, Cơm gà xối mỡ, Mì trộn Indomie thập cẩm, Cơm bò xào lúc lắc, Bún bò Huế đặc biệt, Trà mãng cầu xiêm, Trà đào cam sả, Cà phê sữa đá pha phin, Bánh mì chảo xíu mại, Xôi mặn thập cẩm, Trà sữa Oolong nướng, Bánh tráng trộn khô bò, Mẹt cá viên chiên mắm tỏi, Cơm tấm đêm Tân Lập.
- **Topping & Tùy chọn (`ProductOptionGroups`, `ProductOptions`, `Toppings`, `DishToppings`):**
  - Topping thức ăn: Trứng ốp la (+5k), Sườn nướng (+15k), Cơm thêm (+3k), Xúc xích (+5k).
  - Topping đồ uống: Trân châu đen dẻo (+5k), Kem cheese Macchiato (+7k).
  - Chọn mức đường: 0%, 50%, 100%.
  - Chọn mức đá: Không đá, 50% đá, Đá để riêng bọc ngoài.
- **10 Tài khoản người dùng mẫu:** Phục vụ đầy đủ 3 vai trò (Sinh viên KTX, Chủ quán, Shipper KTX, Quản trị viên).

---

### Hướng Dẫn Nạp Dữ Liệu Vào SQL Server:

#### Cách 1: Dùng SQL Server Management Studio (SSMS) hoặc Azure Data Studio
1. Mở SSMS hoặc Azure Data Studio, kết nối đến SQL Server của bạn (ví dụ: `localhost`, `.\SQLEXPRESS` hoặc `TÊN_MÁY\SQLEXPRESS`).
2. Mở file `langfood-backend/seed_data.sql`.
3. Nhấn **Execute (F5)** để chạy. Script sẽ tự động dọn dẹp dữ liệu cũ theo đúng ràng buộc và nạp mới toàn bộ dữ liệu chuẩn.

#### Cách 2: Dùng dòng lệnh `sqlcmd` trong Terminal (Bắt buộc dùng tham số `-f 65001` để chuẩn tiếng Việt UTF-8):
```powershell
# Chạy trực tiếp từ thư mục gốc của dự án (tham số -f 65001 giúp đọc đúng phông chữ tiếng Việt UTF-8 không bị lỗi ký tự CÆ¡m...)
sqlcmd -S ".\SQLEXPRESS" -d LangFoodBackendDB -E -C -f 65001 -i "langfood-backend/seed_data.sql"
```

---

## 2. Danh Sách Tài Khoản Kiểm Thử Mẫu (Test Accounts)

Các thành viên có thể sử dụng các tài khoản sau để đăng nhập vào app và kiểm thử:

| Vai trò | Tên đăng nhập | Mật khẩu | Họ và tên | Số dư ví | Ghi chú vị trí |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Khách hàng 1** | `nhiem` | `nhiem2512005` | Võ Minh Nhiệm | 500.000₫ | Sinh viên KTX B, Tòa C3, P. 612 |
| **Khách hàng 2** | `sinhvien` | `123456` | Nguyễn Văn Sinh Viên | 300.000₫ | Sinh viên KTX B, Tòa D5, P. 804 |
| **Chủ quán 1** | `seller` | `123456` | Căn Tin Cụm C (C1 - C2) | 1.200.000₫ | Tầng trệt C1 - C2 KTX Khu B |
| **Chủ quán 2** | `seller_cantin_d` | `123456` | Căn Tin Cụm D (D3 - D4) | 950.000₫ | Hành lang D3 - D4 KTX Khu B |
| **Chủ quán 3** | `seller_foodcourt_e1` | `123456` | Food Court Tòa E1 | 1.100.000₫ | Tầng 1 Nhà dịch vụ E1 |
| **Chủ quán 4** | `seller_tanlap` | `123456` | Cơm Tấm Đêm Tân Lập | 700.000₫ | Số 14 Tân Lập (Cổng phụ KTX B) |
| **Chủ quán 5** | `seller_anvat` | `123456` | Trà Sữa & Ăn Vặt Làng KTX | 850.000₫ | Kiot Cổng chính Tô Vĩnh Diện |
| **Chủ quán 6** | `seller_ba3` | `123456` | Bánh Mì Chảo B.A3 | 600.000₫ | Sảnh trệt B.A3 KTX Khu B |
| **Shipper KTX** | `shipper` | `123456` | Tài Xế Shipper KTX Khu B | 350.000₫ | Sinh viên KTX B.B1, MSSV: 202612345 |
| **Admin** | `admin` | `Admin@123` | Làng Food Administrator | 8.000.000₫ | Toàn quyền quản trị hệ thống |

---

## 3. Hướng Dẫn Thêm & Chỉnh Sửa Thông Tin

### A. Thêm món ăn mới (`Products`):
Chèn một dòng mới vào bảng `Products` (chú ý `Status = 1`, `IsAvailable = 1`, `IsDeleted = 0`):
```sql
USE [LangFoodBackendDB];
GO

SET IDENTITY_INSERT [Products] ON;
INSERT INTO [Products] (
    [Id], [ShopId], [CategoryId], [Name], [Description], [Price], [ImageUrl],
    [IsDeleted], [Status], [IsAvailable], [UserId], [DishCode]
) VALUES (
    15, 1, 1, 
    N'Cơm sườn bì chả ốp la đặc biệt', 
    N'Cơm tấm nóng dẻo, sườn nướng than hoa vàng rộm, chả trứng béo ngậy kèm trứng ốp la lòng đào.', 
    40000.00, 
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80', 
    0, 1, 1, '6FB513F5-0C65-49CA-A688-2EF27003FF25', N'DISH_15'
);
SET IDENTITY_INSERT [Products] OFF;
GO
```

### B. Thêm nhóm tùy chọn & Topping cho món ăn:
```sql
USE [LangFoodBackendDB];
GO

-- 1. Tạo nhóm tùy chọn cho món ăn (ProductId = 15)
SET IDENTITY_INSERT [ProductOptionGroups] ON;
INSERT INTO [ProductOptionGroups] ([Id], [ProductId], [Name], [IsRequired], [MinSelectable], [MaxSelectable])
VALUES (12, 15, N'Thêm món ăn kèm', 0, 0, 3);
SET IDENTITY_INSERT [ProductOptionGroups] OFF;

-- 2. Thêm các mục Topping trong nhóm
SET IDENTITY_INSERT [ProductOptions] ON;
INSERT INTO [ProductOptions] ([Id], [OptionGroupId], [Name], [AdditionalPrice], [IsAvailable]) VALUES
(29, 12, N'Thêm chả trứng', 7000.00, 1),
(30, 12, N'Thêm canh rong biển', 8000.00, 1);
SET IDENTITY_INSERT [ProductOptions] OFF;
GO
```

### C. Thêm điểm giao nhận mới (`DropOffPoints`):
```sql
USE [LangFoodBackendDB];
GO

MERGE INTO [DropOffPoints] AS Target
USING (VALUES (
    'LOC_C2_LOBBY',
    N'C2',
    'LOBBY',
    N'Sảnh tầng G (Chân tòa nhà C2)',
    N'Bàn nhận thức ăn tập trung sảnh C2',
    0,
    1
)) AS Source (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
ON Target.LocationId = Source.LocationId
WHEN NOT MATCHED THEN
    INSERT (LocationId, BuildingId, LocationType, Title, Description, Surcharge, IsRecommended)
    VALUES (Source.LocationId, Source.BuildingId, Source.LocationType, Source.Title, Source.Description, Source.Surcharge, Source.IsRecommended);
GO
```

### D. Quy chuẩn hình ảnh món ăn:
Nên sử dụng link ảnh trực tiếp từ Unsplash với kích thước tối ưu hóa:
`https://images.unsplash.com/photo-...?...&w=600&auto=format&fit=crop&q=80`

---

## 4. Khởi Chạy Backend (ASP.NET Core)

1. Cấu hình chuỗi kết nối SQL Server trong `langfood-backend/LangFoodBackend/appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=.\\SQLEXPRESS;Database=LangFoodBackendDB;Trusted_Connection=True;TrustServerCertificate=True;"
   }
   ```
2. Chạy ứng dụng Backend:
   ```powershell
   cd langfood-backend
   dotnet run --project LangFoodBackend
   ```
3. Mở trình duyệt kiểm tra Web API & Swagger:
   * **URL máy tính:** [http://localhost:5289/swagger](http://localhost:5289/swagger) (hoặc [http://localhost:5289/](http://localhost:5289/))
   * **URL mạng LAN:** `http://<IP_MÁY_BẠN>:5289/swagger`

---

## 5. Khởi Chạy Ứng Dụng Flutter

1. Cài đặt các thư viện:
   ```powershell
   cd langfood-flutter
   flutter pub get
   ```
2. Cấu hình file `.env` (tạo từ `.env.example`):
   ```powershell
   Copy-Item .env.example .env
   ```
3. Mở file `langfood-flutter/.env` và cập nhật `BASE_URL`:
   * Chạy trên Chrome / Edge: `BASE_URL=http://localhost:5289/api/`
   * Chạy trên Android Emulator: `BASE_URL=http://10.0.2.2:5289/api/`
   * Chạy trên Điện thoại thật: `BASE_URL=http://<IP_MÁY_BẠN>:5289/api/` (Ví dụ: `http://192.168.2.24:5289/api/`)
4. Khởi chạy ứng dụng:
   ```powershell
   # Chạy trên Web Chrome
   flutter run -d chrome

   # Hoặc chạy trên thiết bị Android / iOS
   flutter run
   ```

---

## 6. Chạy Bộ Kiểm Thử (Automated Tests)

Đảm bảo toàn bộ hệ thống hoạt động chính xác trước khi commit:
```powershell
# Kiểm tra Backend
dotnet build langfood-backend/LangFoodBackend/LangFoodBackend.csproj

# Kiểm tra Flutter (94/94 unit, widget & contract tests)
cd langfood-flutter
flutter test --no-pub
```

Đây file README đã được căn chỉnh đẹp mắt theo chuẩn Markdown, mày copy nguyên khối bên dưới dán vào file README.md là xong:



Markdown
# 🚀 Hướng dẫn Cài đặt & Chạy Ứng dụng

## 📋 1. Yêu cầu Hệ thống (Prerequisites)

- **.NET 8 SDK** (hoặc mới hơn) — Chạy ứng dụng Backend.
- **Flutter SDK** (phiên bản mới nhất) & **Dart** — Chạy ứng dụng Mobile.
- **SQL Server** — LocalDB hoặc SQL Server Management Studio (SSMS).

---

## ⚙️ 2. Cài đặt và Chạy Backend (.NET C#)

1. **Mở thư mục Backend:**  
   Mở thư mục `langfood-backend` bằng Visual Studio hoặc Terminal.

2. **Cấu hình Cơ sở dữ liệu:**  
   Cấu hình chuỗi kết nối `ConnectionStrings:DefaultConnection` trong file `appsettings.json` trỏ tới SQL Server của bạn.

3. **Chạy Migration CSDL:**  
   Khởi tạo các bảng CSDL (bao gồm cả bảng `OrderTests` phục vụ demo Map & Shipper):
   ```bash
   dotnet ef database update --project LangFood.Shared --startup-project LangFoodBackend


Khởi động Backend:
Lắng nghe trên tất cả các mạng LAN để thiết bị thật kết nối:
Bash
cd LangFoodBackend
dotnet run --urls "[http://0.0.0.0:5289](http://0.0.0.0:5289)"
Mẹo: Hoặc bấm nút Start trong Visual Studio. Mặc định ứng dụng chạy ở cổng 5289.
📱 3. Cài đặt và Chạy Frontend (Flutter)
Mở thư mục Frontend:
Mở thư mục langfood-flutter bằng Android Studio hoặc VS Code.
Tải các thư viện phụ thuộc:
Bash
flutter pub get


Cấu hình địa chỉ IP Backend:
Mở file lib/core/constants/app_constants.dart.
Cập nhật biến baseUrl trỏ tới địa chỉ IPv4 của máy tính đang chạy Backend (Ví dụ: http://10.X.X.X:5289/).
⚠️ Lưu ý: Điện thoại thật và máy tính phải kết nối chung một mạng Wi-Fi hoặc sử dụng cáp USB Tethering.
Chạy ứng dụng:
Kết nối điện thoại thật (hoặc máy ảo) và chạy lệnh:
Bash
flutter run


🗺️ 4. Hướng dẫn Test Luồng Demo Map & Shipper Realtime
Khách hàng:
Đăng nhập tài khoản khách hàng.
Chọn món, chọn điểm giao hàng trên bản đồ (LocationPickerScreen) và chốt đơn.
(Dữ liệu được lưu qua API POST /api/OrderTests).
Shipper:
Đăng nhập tài khoản Shipper.
Mở màn hình danh sách đơn hàng (ShipperOrdersScreen), bấm Tải lại để nhận đơn mới.
Bấm Nhận đơn ngay (API PUT /api/OrderTests/accept/{id}).
Live Tracking (SignalR):
Màn hình dẫn đường tự động mở.
Vị trí của Shipper sẽ được cập nhật tự động định kỳ 5 giây/lần qua SignalR Hub (/locationHub) để Khách hàng theo dõi realtime trên bản đồ.

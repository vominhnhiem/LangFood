🚀 Hướng dẫn Cài đặt & Chạy Ứng dụng
1. Yêu cầu Hệ thống (Prerequisites)
•
.NET 8 SDK (hoặc mới hơn) để chạy Backend.
•
Flutter SDK (phiên bản mới nhất) & Dart để chạy ứng dụng Mobile.
•
SQL Server (LocalDB hoặc SQL Server Management Studio).
2. Cài đặt và Chạy Backend (.NET C#)
1.
Mở thư mục langfood-backend bằng Visual Studio hoặc Terminal.
2.
Cấu hình chuỗi kết nối cơ sở dữ liệu (ConnectionStrings:DefaultConnection) trong file appsettings.json trỏ tới SQL Server của bạn.
3.
Chạy lệnh Migration để khởi tạo các bảng CSDL (bao gồm cả bảng OrderTests phục vụ demo Map & Shipper):
Shell Script
dotnet ef database update --project LangFood.Shared --startup-project LangFoodBackend
4.
Khởi động Backend (cho phép lắng nghe trên tất cả các mạng LAN để thiết bị thật kết nối):
Shell Script
cd LangFoodBackend
dotnet run --urls "http://0.0.0.0:5289"
(Hoặc bấm nút Start trong Visual Studio. Mặc định ứng dụng chạy ở cổng 5289).
3. Cài đặt và Chạy Frontend (Flutter)
1.
Mở thư mục langfood-flutter trong Android Studio hoặc VS Code.
2.
Tải về các thư viện phụ thuộc của Flutter:
Shell Script
flutter pub get
3.
Cấu hình địa chỉ IP Backend:
◦
Mở file lib/core/constants/app_constants.dart.
◦
Cập nhật biến baseUrl trỏ tới địa chỉ IPv4 của máy tính đang chạy Backend (Ví dụ: http://10.X.X.X:5289/). (Lưu ý: Điện thoại thật và máy tính phải kết nối chung một mạng Wi-Fi hoặc dùng cáp USB Tethering).
4.
Kết nối điện thoại thật (hoặc máy ảo) và chạy ứng dụng:
Shell Script
flutter run
4. Hướng dẫn Test Luồng Demo Map & Shipper Realtime
1.
Khách hàng: Đăng nhập bằng tài khoản khách hàng, chọn món, chọn điểm giao hàng trên bản đồ (LocationPickerScreen) và chốt đơn (dữ liệu được lưu qua API POST /api/OrderTests).
2.
Shipper: Đăng nhập tài khoản Shipper, mở màn hình danh sách đơn hàng (ShipperOrdersScreen), bấm Tải lại để nhận đơn mới, sau đó bấm Nhận đơn ngay (PUT /api/OrderTests/accept/{id}).
3.
Live Tracking (SignalR): Màn hình dẫn đường tự động mở, vị trí của Shipper sẽ được cập nhật tự động định kỳ 5 giây/lần qua SignalR Hub (/locationHub) để Khách hàng theo dõi realtime trên bản đồ.

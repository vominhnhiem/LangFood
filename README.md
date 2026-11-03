# Làng Food

Ứng dụng đặt món cho khu ký túc xá: Flutter, ASP.NET Core Web API, Web Admin và SQL Server.

## Chức năng hiện có

- Đăng ký email qua OTP, đăng nhập và điều hướng theo vai trò.
- Danh sách món/danh mục/menu quán từ API, tìm kiếm bằng văn bản.
- Chi tiết món, tùy chọn món có trong dữ liệu API, giỏ hàng và tạo đơn.
- Quán xác nhận chế biến và báo món sẵn sàng.
- Shipper nhận đơn, chia sẻ GPS từ thiết bị và xác nhận đã giao.
- Khách xem trạng thái đơn, vị trí shipper và tuyến đường OSRM.
- Web Admin quản lý dữ liệu, duyệt giao dịch, đối tác và xem thống kê.

Không còn danh sách món/topping mẫu, di chuyển giả, tìm giọng nói, quét QR menu, chat, gọi điện hoặc nhận hộ.
Giao diện chọn phương thức thanh toán vẫn được giữ; chưa tích hợp cổng MoMo/ZaloPay thực tế.
Phần xử lý đơn nhiều quán được giữ theo hiện trạng, chưa tách đơn theo quán.

## Chạy backend

Cấu hình kết nối SQL Server trong appsettings của backend và admin, sau đó:

```powershell
cd langfood-backend
dotnet restore LangFoodBackend.slnx
dotnet ef database update --project LangFood.Shared --startup-project LangFoodBackend
dotnet run --project LangFoodBackend
```

API sử dụng cổng 5289. Có thể chạy Web Admin bằng:

```powershell
dotnet run --project LangFoodAdmin
```

## Chạy Flutter

```powershell
cd langfood-flutter
flutter pub get
flutter run
```

Tạo file cấu hình trước khi chạy (theo mẫu LTDD Tuần 7):

```powershell
Copy-Item .env.example .env
```

Sửa BASE_URL trong langfood-flutter/.env:
- Android Emulator: http://10.0.2.2:5289/api/
- Web: http://localhost:5289/api/
- Điện thoại: dùng IP LAN của máy chạy backend, giữ đuôi /api/.

Ứng dụng nạp .env trước runApp; lib/config/config_url.dart cung cấp URL cho ApiClient.
Đường dẫn ảnh được lấy từ gốc máy chủ, không ghép nhầm vào /api/.
Không commit .env; .env.example được giữ để các thành viên tự cấu hình.
Phí giao hàng nằm ở SHIPPING_FEE trong .env (VND), hiện giữ mức 10000. API Settings chưa có trường phí nên giao diện ghi rõ đây là phí theo cấu hình.
Sau khi đổi URL hoặc phí, dừng và chạy lại ứng dụng.

## Thử luồng GPS và chỉ đường

1. Khách thêm món thật từ API, chọn điểm trên bản đồ và nhập địa chỉ nhận.
2. Đặt đơn; quán xác nhận chế biến rồi báo món đã sẵn sàng.
3. Shipper nhận đơn và cấp quyền vị trí. Có thể bật/tắt công tắc chia sẻ GPS.
4. GPS được gửi cho các đơn đang giao khi thiết bị thay đổi vị trí ít nhất 10 mét.
5. Khách mở bản đồ của đúng đơn. Ứng dụng lấy vị trí từ API mỗi 3 giây và xin tuyến OSRM khi cần.
6. Khi giao xong hoặc tắt chia sẻ, ứng dụng dừng gửi GPS.

Chia sẻ GPS hoạt động khi ứng dụng shipper ở phía trước. Chưa triển khai dịch vụ theo dõi chạy nền.
Android Emulator lấy vị trí do hệ điều hành giả lập cung cấp; dùng Extended Controls > Location để kiểm thử.
Ứng dụng không tự tạo tọa độ hoặc tự di chuyển marker. Đơn cũ chưa lưu tọa độ sẽ báo thiếu điểm giao.
Bản đồ và chỉ đường cần Internet; khi lỗi chỉ đường, ứng dụng báo lỗi và không vẽ tuyến giả.
OSRM đang dùng cấu hình driving của máy chủ công cộng, chưa phải định tuyến riêng cho xe máy.

## Kiểm tra

```powershell
dotnet build langfood-backend/LangFoodBackend.slnx
cd langfood-flutter
flutter analyze
flutter test
```

Các migration và model OrderTest cũ được giữ để bảo toàn lịch sử schema; API và mã Flutter thử nghiệm tương ứng đã bỏ.

## Chức năng mới theo vai trò

- Khách: nút Đơn hàng của tôi trên trang chủ, lọc đơn đang xử lý/đã kết thúc, mở lại chi tiết và hủy đơn khi còn chờ.
- Giỏ hàng: tự khôi phục sau đăng nhập/mở app, lưu riêng theo tài khoản, gộp giỏ khách vào tài khoản khi đăng nhập. Lỗi đồng bộ được hiển thị cùng nút thử lại.
- Tài khoản: menu hình người ở góc trên, sửa họ tên/SĐT/tòa/phòng và tải ảnh đại diện từ thư viện.
- Chủ quán: nút menu trên màn hình đơn của quán để thêm/sửa/xóa món; khi thêm món có thể chọn ảnh tải lên hoặc URL. Món sửa sẽ chờ admin duyệt lại.
- Shipper: nút ví trên màn hình giao hàng, xem số dư/giao dịch, gửi yêu cầu nạp/rút và xem trạng thái, biên lai do admin cung cấp. Không tự duyệt hoặc tự tăng số dư.

Giới hạn của API hiện có: hủy đơn sẽ xóa khỏi lịch sử; ảnh món đang có được thay bằng URL; API sửa món chưa hỗ trợ bật/tắt bán. Các thao tác nạp/rút cần admin đối soát và xử lý thủ công. Mỗi giỏ đồng bộ bằng ảnh chụp dữ liệu vì API hiện chưa cập nhật được từng biến thể món. Backend và phần tách đơn nhiều quán được giữ nguyên trong đợt bổ sung này.

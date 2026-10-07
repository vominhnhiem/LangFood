# 🍔 Làng Food - Bản đồ & Định vị Thời gian thực (Real-time Map & Tracking)

> *Giải pháp không gian khép kín cho dự án Làng Food KTX Khu B.*  
> **Môn học**: Lập trình trên thiết bị di động  
> **Nhóm thực hiện**: Nhóm 13 | **GVHD**: Nguyễn Mạnh Hùng

---

## 🌟 Giới thiệu Dự án
**Làng Food** là ứng dụng đặt đồ ăn và giao nhận chuyên biệt dành cho khu vực có mật độ cao như KTX Khu B. Dự án tích hợp hệ thống **Bản đồ & Định vị Thời gian thực** giải quyết các bài toán thực chiến:
* **Lọc thô siêu tốc**: Sử dụng thuật toán toán học **Haversine** tính khoảng cách mặt cầu trên RAM/CPU nội bộ (~1ms, hoàn toàn miễn phí).
* **Định tuyến chuẩn xác**: Tích hợp **OSRM API** để vẽ đường đi (`Polyline`) bám sát đường xá thực tế và tính toán thời gian giao hàng dự kiến (ETA).
* **Đồng bộ Realtime**: Sử dụng **ASP.NET Core SignalR (WebSockets)** triệt tiêu cơ chế Polling cũ, giúp cập nhật vị trí Shipper liên tục mỗi 5 giây mà không gây nghẽn băng thông hay tốn pin.

---

## 🛠️ Công nghệ Sử dụng (Tech Stack)

### 📱 Frontend (Flutter)
* **`flutter_map`**: Render bản đồ mã nguồn mở (tối ưu hóa hiệu năng 60 FPS).
* **Esri ArcGIS Tile Layer**: Lớp nền bản đồ không bị chặn ở Việt Nam (`server.arcgisonline.com`).
* **`geolocator`**: Giao tiếp phần cứng GPS định vị thời gian thực (`High Accuracy`).
* **`signalr_netcore`**: Duy trì kết nối WebSocket hai chiều với server.
* **`latlong2` & `http`**: Quản lý tọa độ và kết nối RESTful APIs / OSRM routing.

### 🖥️ Backend (.NET C#)
* **ASP.NET Core Web API**: Xây dựng các RESTful APIs quản lý đơn hàng (`OrderTestsController`).
* **ASP.NET Core SignalR Hub**: Trung gian broadcast tọa độ real-time (`LocationHub`).
* **Entity Framework Core & SQL Server**: Quản lý cơ sở dữ liệu và ánh xạ dữ liệu (`OrderTest.cs`, `LangFoodDbContext.cs`).

---

## 🚀 Hướng dẫn Cài đặt & Chạy Ứng dụng

### 1. Cài đặt và Chạy Backend (.NET C#)
1. Mở thư mục backend (`langfood-backend`) bằng Visual Studio hoặc Terminal.
2. Cấu hình chuỗi kết nối cơ sở dữ liệu SQL Server trong `appsettings.json`.
3. Chạy lệnh Migration để khởi tạo bảng dữ liệu demo:
   ```bash
   dotnet ef database update --project LangFood.Shared --startup-project LangFoodBackend
   ```
4. Khởi động Backend (cho phép lắng nghe mọi IP trong mạng LAN):
   ```bash
   cd LangFoodBackend
   dotnet run --urls "http://0.0.0.0:5289"
   ```

### 2. Cài đặt và Chạy Frontend (Flutter)
1. Mở thư mục `langfood-flutter` trong Android Studio hoặc VS Code.
2. Tải các thư viện phụ thuộc:
   ```bash
   flutter pub get
   ```
3. **Cấu hình IP Backend**:
   * Mở file `lib/core/constants/app_constants.dart`.
   * Cập nhật biến `baseUrl` trỏ tới địa chỉ IPv4 của máy tính (Ví dụ: `http://10.X.X.X:5289/`). *(Đảm bảo điện thoại và máy tính kết nối chung 1 mạng Wi-Fi hoặc dùng cáp USB Tethering).*
4. Chạy ứng dụng trên thiết bị thật:
   ```bash
   flutter run
   ```

---

## 👥 Hướng dẫn Luồng Demo (User Flow)
1. **Khách hàng**: Đăng nhập, chọn món ăn, chọn điểm nhận hàng trên bản đồ (`LocationPickerScreen`) và chốt đơn (`POST /api/OrderTests`).
2. **Shipper**: Đăng nhập tài khoản Shipper, mở danh sách đơn hàng (`ShipperOrdersScreen`), bấm **Tải lại** và chọn **Nhận đơn ngay** (`PUT /api/OrderTests/accept/{id}`).
3. **Live Tracking (Realtime)**: Màn hình dẫn đường mở ra, vị trí của Shipper sẽ tự động truyền tải lên Server qua SignalR mỗi 5 giây và hiển thị trực quan chuyển động trên bản đồ của Khách hàng!

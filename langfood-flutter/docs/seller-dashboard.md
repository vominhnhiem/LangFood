# Bảng điều hành chủ quán Làng Food

Màn hình mẫu dành cho Căn tin C1–C2 ở KTX Khu B. Chủ quán có thể xem đơn sắp hết giờ, nhận đơn và đánh dấu món đã xong ngay từ danh sách. Các mã đơn, tên, số điện thoại và doanh thu đều là dữ liệu mô phỏng.

## Bố cục trên điện thoại

```text
┌────────────────────────────────────────┐
│ LÀNG FOOD · BẢN DEMO             🔔    │
│ Bảng điều hành                         │
├────────────────────────────────────────┤
│ Căn tin C1–C2                   [ ● ]  │
│ ● Đang mở cửa                          │
│ Tạm ngưng 15 phút       + Tạo đơn thử  │
│                                        │
│ KẾT QUẢ HÔM NAY                        │
│ Thực nhận    Thành công      Tỷ lệ hủy │
│ 474.000 đ    3               25%       │
│                                        │
│ 🔔 2 đơn mới cần xác nhận           →  │
├────────────────────────────────────────┤
│ Đơn mới 2  Đang nấu 2  Chờ shipper 2  →│
├────────────────────────────────────────┤
│ #LF-108                          01:45 │
│ 11:29 · 3 phần                         │
│ Nguyễn Minh An                         │
│ Tòa BA2 · Sảnh tầng G                  │
│ ────────────────────────────────────── │
│ 2× Cơm sườn                            │
│    Kèm theo · 2 × Trứng ốp la           │
│    Lưu ý · Một phần không hành…        │
│ 1× Trà tắc                             │
│ [ Từ chối ]       [     Nhận đơn     ] │
│                                        │
│ ↓ Cuộn tới các đơn tiếp theo           │
├────────────────────────────────────────┤
│       [ Hết món nhanh · 1 đã tắt ]     │
└────────────────────────────────────────┘
```

Thanh nhận diện và nút chuông ở trên cùng. Cụm điều khiển quán, KPI và banner có thể cuộn khỏi màn hình để nhường chỗ cho đơn. Bốn tab nằm trên một hàng ngang và ghim lại khi cuộn. **Lịch sử** ở cuối hàng tab. Thanh hết món nằm cố định phía dưới, trong vùng an toàn của thiết bị.

## Luồng thao tác

1. **Nhận đơn.** Banner dẫn tới tab **Đơn mới**. Hàng đợi ưu tiên đơn gần hết hạn nhất. Chủ quán chạm **Nhận đơn**, thẻ chuyển sang **Đang nấu** và badge ở cả hai tab cập nhật. Thông báo ngắn có nút mở danh sách đích để chủ quán tiếp tục xử lý các đơn mới nếu cần.
2. **Từ chối hoặc hết giờ.** **Từ chối** mở hộp thoại với các lựa chọn xác nhận theo lý do. Đơn hết giờ hoặc bị từ chối chuyển vào **Lịch sử** kèm lý do riêng. Nếu đơn hết giờ trong lúc hộp thoại mở, lý do hết giờ được giữ nguyên.
3. **Chuẩn bị và bàn giao.** **Đang nấu** sắp đơn cũ trước. Chạm **Báo xong món** chuyển đơn sang **Chờ shipper**. Thẻ cho biết đang tìm shipper hay shipper đã nhận chuyến, kèm tên, số điện thoại, biển số và điểm giao KTX. **Lịch sử** hỗ trợ tìm theo mã, tên, tòa và trạng thái.
4. **Quá tải hoặc hết món.** Công tắc quán đổi giữa mở và đóng. **Tạm ngưng 15 phút** chặn đơn thử mới, giữ các đơn đang xử lý trong hàng đợi và hiện thời gian còn lại. Quán tự mở lại khi hết hạn hoặc khi bấm **Nhận lại**. Trong **Hết món nhanh**, thay đổi mỗi công tắc áp dụng ngay cho đơn thử tạo sau đó, kể cả topping.

## Đặc tả component

| Thành phần | Hiển thị và tương tác |
| --- | --- |
| Điều khiển quán | Công tắc kèm nhãn trạng thái, xanh lá cho đang mở, cam cho tạm ngưng, xám cho đóng. Khi tạm ngưng, công tắc vẫn bật vì quán chỉ dừng nhận đơn trong thời gian giới hạn. |
| `LiveStatsHeader` | Ba ô đọc nhanh với chữ số có bề rộng cố định. Thực nhận là tổng doanh thu mẫu của đơn đã giao. Tỷ lệ hủy là số đơn hủy chia cho số đơn đã giao hoặc đã hủy trong ngày theo giờ KTX (UTC+7). Khi chưa có đơn kết thúc, tỷ lệ hiện dấu gạch ngang. |
| Tab và badge | Chạm tab hoặc vuốt ngang để đổi danh sách. Badge đổi số với chuyển cảnh ngắn. Chế độ giảm chuyển động tắt hiệu ứng badge. Khi chữ lớn, thanh tab cuộn ngang để đọc đủ nhãn. |
| Cảnh báo | **Tạo đơn thử** thêm đơn vào hàng đợi và hiện banner xanh cùng thông báo ngắn. Trên Android/iOS, ứng dụng phát ba tiếng chuông và ba nhịp rung khi màn hình đang mở. Công tắc chuông tắt cả hai tín hiệu. Android dùng âm lượng thông báo, iOS dùng âm thanh có tôn trọng công tắc im lặng. Trình duyệt hiển thị cảnh báo trực quan. |
| `OrderCardItem` | Mã đơn 22sp ở góc trái, đồng hồ 19sp ở góc phải. Dưới mã là thời gian và số phần, tiếp theo là khách và điểm giao. Mỗi món có số lượng riêng, tùy chọn/topping ở dòng phụ và ghi chú in đậm trên nền vàng nhạt. Đồng hồ chuyển đỏ từ 30 giây cuối và đếm theo hạn tuyệt đối. |
| Nút xử lý đơn | **Nhận đơn** màu xanh đậm, chiếm hai phần ba chiều rộng khả dụng. **Từ chối** có viền và chữ đỏ. **Báo xong món** chạy hết chiều rộng thẻ. Các nút chính cao tối thiểu 56dp. Vuốt ngang dành cho điều hướng giữa tab. |
| `QuickStockSheet` | Mở một chạm từ thanh đáy. Từng dòng có tên, phân loại món/topping và nhãn đang bán/đã hết. Chạm cả dòng hoặc gạt công tắc đều cập nhật ngay. Sheet cuộn độc lập và hỗ trợ kéo xuống hoặc bấm nút đóng 48dp. |

Nền dùng `#F8F9FA`, thẻ trắng với góc squircle 16dp và bóng nhẹ. Cam `#FF5722` đánh dấu thương hiệu và tab được chọn. Các màu `#2ECC71`, `#FF9800`, `#4298E8` và `#E74C3C` làm điểm nhấn trạng thái, đi cùng màu chữ đậm hơn để dễ đọc dưới ánh sáng quầy. Nhãn và biểu tượng giữ nghĩa của trạng thái khi người dùng khó phân biệt màu.

## Chạy và phạm vi dữ liệu

Chạy `flutter run` và đăng nhập tài khoản Chủ quán đã được duyệt để mở dashboard với dữ liệu thật. Màn hình đọc đơn theo quán, làm mới mỗi 5 giây khi app đang mở và dùng API hiện hành cho **Nhận đơn** và **Báo xong món**. Mục **Tiền món** cộng tiền món của các đơn đã giao trong nhóm đơn tạo hôm nay. Nút **Quản lý menu** mở màn hình quản lý món của quán.

Từ thư mục `langfood-flutter`:

```powershell
flutter run --dart-define=SELLER_DASHBOARD_PREVIEW=true
```

Thêm `-d edge` để xem trên trình duyệt Windows. Để thử cả chuông và rung, chạy trên điện thoại Android hoặc iOS và bấm **Tạo đơn thử** khi quán đang mở.

Chế độ demo dùng bộ nhớ của màn hình. Mỗi lần khởi động lại sẽ nạp bộ mẫu mới.

Khi triển khai vận hành, thời hạn xác nhận và thời điểm mở lại quán cần lấy từ máy chủ. API hiện có cho phép nhận đơn và báo món sẵn sàng. Các luồng từ chối, tạm ngưng và tồn món cần API được phân quyền theo quán. Để chặn đặt món hết hàng cả khi giỏ sinh viên đã mở, API tạo đơn cần kiểm tra lại tồn món/topping tại thời điểm chốt đơn. Thông báo khi ứng dụng ở nền cần tích hợp push riêng. KPI thực nhận cần lấy từ dữ liệu đối soát.

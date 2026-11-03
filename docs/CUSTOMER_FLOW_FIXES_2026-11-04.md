# LangFood — sửa và kiểm thử lại luồng khách hàng (04/11/2026)

## Kết quả

Đã sửa Flutter và chạy lại chọn món → giỏ → địa điểm → checkout → theo dõi → lịch sử.
Không sửa backend, không chạy migration/seed, không commit/push. Giữ các thay đổi có sẵn trong workspace.

## Các sửa đổi

- Giá hiển thị, giỏ và đơn hàng dùng giá sản phẩm thật; bỏ phần trăm giảm tự sinh.
- Home tải thực đơn từ API, báo lỗi/rỗng thay vì âm thầm thay bằng sản phẩm mẫu.
- Bỏ countdown khuyến mãi, lượt bán, điểm đánh giá và ưu đãi viết cố định ở các thẻ Home. Giữ cấu trúc thẻ và banner theo LF-01, thay nội dung bằng hướng dẫn chọn món.
- Checkbox giỏ và nút đặt riêng một quán truyền đúng snapshot lựa chọn tới checkout. Ghi chú quán được giữ theo shopId.
- Giỏ và checkout cùng tính phí từ `SHIPPING_FEE`; phụ phí giao tận phòng được hiển thị riêng. Không tự áp voucher.
- Giỏ rỗng/không hợp lệ không có nút đặt; không dựng người mua, món, mã đơn hoặc số tiền dự phòng.
- Chỉ tạo `Orders`, không tạo thêm `OrderTests`. Không fallback Orders sang OrderTests khi xem chi tiết.
- Chống chạm liên tiếp; chỉ xóa số lượng món đã tạo đơn thành công. Món bỏ chọn vẫn còn trong giỏ.
- Nhiều quán tạo các đơn riêng, tách đúng shopId và orderItems. Nếu một quán bị từ chối, lần thử lại trong checkout chỉ gửi các quán chưa có đơn.
- Timeout/lỗi máy chủ/thiếu mã xác nhận được coi là kết quả chưa xác định: giữ giỏ, chặn gửi lại ngay và hướng dẫn kiểm tra lịch sử.
- Thay đổi điểm giao trả kết quả về checkout hiện tại. Sau đặt thành công, không để lại route location/checkout cũ trong luồng Back.
- Giao tận phòng yêu cầu số phòng và giữ số phòng khi sửa địa điểm.
- Tracking dùng trạng thái Orders thật; không dựng tài xế, tọa độ, đơn dự phòng hay đẩy vị trí mô phỏng. Khi chưa có GPS thì hiển thị chờ vị trí.
- Shipper lấy/nhận đơn từ Orders thật. Chia sẻ GPS chỉ bắt đầu qua nút rõ ràng, yêu cầu quyền hệ điều hành và đúng shipper được gán. Không tự bật GPS.
- Tab Đơn hàng mở lịch sử; từ lịch sử đi thẳng tới màn hình tracking chung. Menu tài khoản có hồ sơ, lịch sử, ví và đăng xuất.
- Nút Thông báo có phản hồi và lối vào lịch sử; Đặt chung không còn báo tạo một phòng giả.
- Khôi phục giỏ bổ sung tên quán từ API Shops khi Cart API chỉ trả Product không kèm Shop; giữ giá tùy chọn và ghi chú.

## Đối chiếu Stitch và bố cục

Đã mở được dự án tham chiếu:
https://stitch.withgoogle.com/projects/8904364497132995449

Đã đọc cấu trúc và thông tin của các khung LF-05/06/07/08/09. Giữ nền nhóm sáng/tối, màu cam #FF5722, thẻ bo góc, khoảng cách 16px, payment sheet, CTA cố định trong SafeArea và map sheet kéo được.

Các chi tiết được điều chỉnh theo API thật, thay vì sao chép dữ liệu minh họa trong Stitch:

- Checkout hiện hỗ trợ COD. Ví/MoMo/VietQR/ZaloPay hiển thị chưa hỗ trợ và không chọn được, vì chưa có luồng thanh toán đơn hàng được xác minh.
- API Orders nhận một quán cho mỗi đơn. UI nói rõ nhiều quán sẽ tạo nhiều đơn và tính phí riêng; không hứa một shipper giao gộp hay chia phí miễn phí.
- Không hiển thị điểm đánh giá, lượt bán, số dư, voucher, ETA hoặc kết nối SignalR giả trong các phần đã sửa.

Đã kiểm tra responsive qua widget tests tại 320×640, 360×800, 393×852, 430×932, cỡ chữ 1.0 và 1.3. Bộ test cuối không ghi nhận RenderFlex overflow. Đã kiểm tra trực quan bản web tại 393×852 và lịch sử tại 320×640.

## Bằng chứng API thật

### Đơn #108 — kiểm tra bỏ chọn và ghi chú

- Thêm món ở hai quán, bỏ chọn món quán đầu.
- Chỉ tạo ProductId 13, quantity 1, ShopId 5.
- Tiền món 35.000đ + phí giao 10.000đ = 45.000đ.
- Trạng thái API `Pending`; tracking hiển thị “Chờ quán xác nhận”, không có marker shipper giả.
- Ghi chú quán “QA LangFood: để riêng nước sốt” được lưu trong OrderItem.Note.
- Ghi chú “Gọi trước 2p” được lưu cùng điểm nhận trong DeliveryRoom, dùng trường backend hiện có.
- Món ProductId 14 bỏ chọn vẫn còn trong giỏ, được xác nhận trên UI và API giỏ.

### Đơn #109 và #110 — kiểm tra nhiều quán và số phòng

| Mã | ShopId | ProductId | Tiền món | Phí giao gồm tận phòng | Trạng thái |
|---|---:|---:|---:|---:|---|
| 109 | 4 | 14 | 35.000đ | 15.000đ | Pending |
| 110 | 5 | 13 | 35.000đ | 15.000đ | Pending |

Tổng 100.000đ khớp checkout. Cả hai lưu “Giao tận cửa phòng 512 (+5k)”. Sau thành công điều hướng tới lịch sử và thấy cả hai mã. Không thực hiện chuyển tiền, xác nhận quán, nhận đơn, hoàn tất giao hoặc hủy/xóa các đơn này.

Các đơn #108, #109, #110 là dữ liệu kiểm thử đã tạo và còn lưu trên backend cục bộ. Đơn #107 từ lần audit trước cũng không bị thay đổi.

## Kiểm thử tự động và phân tích tĩnh

- `flutter test --no-pub --reporter expanded`: **105/105 PASS**, exit code 0.
- Bổ sung 11 test hồi quy: giỏ rỗng, chọn đúng món, giữ món không mua, giữ snapshot, hai quán lỗi một phần, chống double tap, timeout không gửi lại ngay, tracking Pending không dựng GPS, không fallback OrderTests, lỗi tạo đơn chỉ có một API write, phục hồi tên quán/giá/ghi chú, và số phòng/đổi địa điểm không sinh checkout lồng nhau (một số tình huống cùng nằm trong một test).
- `dart analyze --format machine lib test`: **0 lỗi**, còn 7 warning unused import đã có ở `test/ui_01_tokens_test.dart` và các style/deprecation info. Không coi toàn bộ analyze là sạch warning.
- `flutter analyze --no-pub` gặp lỗi giao thức của analysis server khi truyền đường dẫn Unicode; dùng Dart analyzer trực tiếp để kiểm tra.
- Diff check phần Flutter đã sửa không có lỗi whitespace. README có trailing whitespace tồn tại từ trước, không sửa trong task này.

Log cuối: [tests-after-fixes.txt](qa-2026-11-04/tests-after-fixes.txt), [analysis.txt](qa-2026-11-04/analysis.txt).

## Giới hạn còn lại

- Chưa kiểm thử Android thật, quyền GPS, hành trình GPS thật và hoàn tất giao hàng.
- Cập nhật tracking dùng polling 5 giây, chưa tích hợp SignalR client; không gọi đây là kết nối SignalR đã xác minh.
- Backend chưa có idempotency key cho tạo đơn. Frontend ngăn gửi trùng trong phiên và hướng dẫn kiểm tra lịch sử khi kết quả mạng chưa rõ; không bảo đảm chống trùng giữa nhiều thiết bị/phiên.
- Giỏ chung nhiều tài khoản và thanh toán online chưa được triển khai qua API thật; UI không báo thành công giả.
- Không khẳng định toàn bộ 12 màn hình Stitch đã khớp pixel; phạm vi là luồng khách hàng và các phần giao diện liên quan đã nêu.

## Ảnh

- [Checkout chỉ chứa món đã chọn](qa-2026-11-04/fixed/checkout-selected-item.png)
- [Tracking trạng thái Pending](qa-2026-11-04/fixed/tracking-pending.png)
- [Lịch sử đơn #108](qa-2026-11-04/fixed/orders-history.png)
- [Tạo hai đơn thành công](qa-2026-11-04/fixed/multi-shop-success.png)
- [Lịch sử hai đơn riêng](qa-2026-11-04/fixed/multi-shop-history.png)

Bản web kiểm tra: http://127.0.0.1:18358/ (cần giữ Flutter web server đang chạy).

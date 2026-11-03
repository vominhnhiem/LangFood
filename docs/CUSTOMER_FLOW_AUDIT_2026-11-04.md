# Rà luồng khách hàng LangFood — 04/11/2026

## Phạm vi và môi trường

- Nhánh `nguyen-flutter-ui`, HEAD `7efaf28`; workspace có sẵn nhiều thay đổi chưa commit.
- Chạy source Flutter hiện tại bằng `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 18357 --no-pub`.
- Trình duyệt trong Codex, backend cục bộ đã chạy sẵn; Flutter dùng BASE_URL cấu hình trong `.env`. Không rebuild backend.
- Dùng nút tài khoản sinh viên demo có sẵn. Chọn COD, không thực hiện giao dịch thanh toán trực tuyến.
- Đã tạo một đơn thật qua API: `Orders/107`, ShopId 4, ProductId 14, quantity 1, unitPrice 35000, totalAmount 35000, shippingFee 0, paymentMethod 0, status Pending. GET API đọc lại thành công.
- GET `OrderTests/107` trả 404: hai luồng không có cùng mã đơn trên backend đang chạy. Không xóa/hủy đơn thử nghiệm hoặc thay đổi trạng thái giao hàng.
- Chỉ thêm báo cáo và ảnh; không chỉnh source nghiệp vụ, không commit/push.

## Kết quả chạy trực tiếp

| Bước | Kết quả |
|---|---|
| Đăng nhập sinh viên | Thành công bằng tài khoản demo trên UI |
| Chọn món | Nút cộng thêm được một món vào giỏ |
| Giỏ hàng | Có món và đúng số lượng; giá không khớp thẻ deal |
| Chọn địa điểm | Mở bản đồ, chọn sảnh, chuyển được sang checkout |
| Phương thức | Mở được danh sách và chọn COD |
| Tạo đơn | Hiện thành công LF-107; GET Orders/107 xác nhận lưu qua API thật |
| Theo dõi | Mở đúng màn hình #107 nhưng trạng thái và vị trí không phản ánh đơn Pending |
| Quay lại | Quay về location picker; vào lại checkout được dù giỏ đã rỗng |
| Mở lại đơn | Tab Đơn hàng dẫn tới giỏ hàng, không phải lịch sử |

## Lỗi tái hiện trên UI

### P1 — Giá deal khác giá thực trả

Trang chủ hiển thị Cơm tấm sườn bì chả đặc biệt Tân Lập **22.750đ**, giá gạch **35.000đ**, giảm 35%. Bấm cộng: giỏ và checkout tính **35.000đ**; API đơn 107 cũng lưu 35.000đ.

Nguồn: `lib/core/widgets/langfood_deal_card.dart:44` tự tính giá giảm để hiển thị; `home_screen.dart` truyền sản phẩm gốc vào thao tác thêm giỏ. Không có giá khuyến mãi thống nhất giữa UI và đơn hàng.

### P1 — Tracking báo đang giao dù API còn Pending

Ngay sau tạo đơn, dialog nói tài xế đang nhận/giao món. Tracking #107 hiển thị “Tài xế đang giao”, marker shipper, tuyến đường và khoảng cách dù GET Orders/107 là Pending. Nhãn trạng thái trong `live_tracking_screen.dart:643` là chuỗi cố định; vị trí khởi tạo tại `_defaultShopOrigin` (dòng 170, 186). Tuyến đường vẽ được không chứng minh shipper đã nhận đơn hay GPS thật.

### P1 — Giỏ rỗng vẫn vào checkout và còn nút đặt

Sau đặt đơn: Back từ tracking → location picker → Xác nhận điểm giao này. Checkout không có món nhưng hiện **48.000đ** và nút Đặt đơn ngay vẫn bật. Không bấm đặt lần hai.

`checkout_screen.dart:719` dùng subtotal dự phòng 48000 khi giỏ rỗng; `_submitOrder` thiếu chặn giỏ rỗng và còn tự thêm món dự phòng ProductId 1. Cần bỏ dự phòng và chặn trước khi gửi API.

Ảnh: [empty-cart-checkout.png](qa-2026-11-04/empty-cart-checkout.png).

### P2 — Tổng tiền đổi sau khi đặt thành công

Ngay khi clearCart, checkout phía sau hộp thoại thành công chuyển từ **35.000đ** sang **48.000đ**. Đơn API vẫn 35.000đ. Cùng nguyên nhân subtotal dự phòng, cộng với màn hình tính lại từ giỏ đang thay đổi thay vì snapshot đơn đã đặt.

### P1 — Tab Đơn hàng không mở lịch sử

Từ trang chủ, bấm Đơn hàng mở CartScreen. Menu Tài khoản đang dùng trên Home chỉ có giỏ hàng, showcase, bản đồ, chuyển vai demo, đăng xuất; không có lịch sử. Dù đã có `MyOrdersScreen` và một `account_menu.dart` riêng, luồng Home hiện tại chưa nối tới chúng.

Nguồn: `home_screen.dart:1779` gọi `_openCart()` cho index 1. Người dùng không có lối rõ ràng để tìm lại đơn vừa đặt sau khi thoát tracking.

### P2 — Thông tin ưu đãi và ví không đáng tin cậy

Checkout hiện sẵn LANGFOODPAIR -20.000đ trên đơn 35.000đ, dù tổng không được giảm 20.000đ. Đồng thời ghi tiết kiệm 15.000đ và số dư ví 150.000đ. Mã nguồn dùng số dư chuỗi cố định ở dòng 177/1271 và quy tắc voucher phía client. Không thử giao dịch ví/MoMo/VietQR/ZaloPay.

## Vấn đề xác nhận qua source, chưa tái hiện bằng đơn thứ hai

1. **P1: Mất phạm vi món đã chọn.** Cart có checkbox và Đặt đơn quán này, nhưng `_startCheckoutFlow` chỉ truyền label/amount/count vào dialog rồi mở LocationPicker không mang danh sách lựa chọn. Checkout đọc toàn bộ `cartProvider.items`, nên món bỏ chọn hoặc quán khác vẫn có thể được tính/gửi; thành công còn clear toàn bộ giỏ.
2. **P1: Đơn nhiều quán bị gộp vào ShopId đầu.** Checkout lấy shopId từ món đầu rồi gắn toàn bộ orderItems vào một OrderModel. Không thấy tách đơn theo quán trong luồng này.
3. **P1: Hai lần tạo đơn không nguyên tử.** Tạo Orders lỗi bị catch rồi vẫn tiếp tục tạo OrderTests. Ngược lại Orders thành công nhưng OrderTests lỗi sẽ báo thất bại và giữ giỏ; thử lại có nguy cơ tạo Orders trùng. OrderTestService thêm bản ghi vào bộ nhớ trước API và giữ lại khi lỗi. OrderTests phía backend cũng không giữ mã 107 trùng Orders trong lần chạy này.
4. **P2: Sửa điểm nhận tạo thêm checkout.** Checkout chờ Navigator.push trả CampusDeliveryLocation, trong khi LocationPicker luôn push một CheckoutScreen mới thay vì pop kết quả. Có thể sinh màn hình thanh toán lồng nhau và nút Back khó đoán.
5. **P2: Ghi chú có thể mất.** Ghi chú shipper được giữ trong CampusDeliveryLocation và hiển thị, nhưng không được đưa vào realOrder payload; ghi chú theo quán trong Cart dùng controller riêng, không có đường nối tới orderItems. Ghi chú riêng từng món là trường khác, có được serialize.
6. **P2: Công thức tiền chưa thống nhất.** Cart dùng phụ phí 2 quán 5000 và ngưỡng voucher 80000; checkout dùng phí 15000, giảm ghép 10000 và ngưỡng voucher 50000. Những giỏ nhất định có thể đổi tổng ở bước tiếp theo.

## Kiểm thử tự động

`flutter test --no-pub --reporter expanded`: **94/94 PASS**, exit code 0.

Các test bao phủ model, contract với HTTP mock, khôi phục giỏ và widget UI-01…UI-06. Log test vẫn có lỗi tạo Orders/OrderTests giả lập; toàn bộ suite PASS không chứng minh luồng API thật hoạt động đúng. Lần rà này đã phát hiện lỗi runtime mà suite chưa chặn.

Chưa kiểm chứng: Android thật, quyền GPS, hành trình shipper thật, quán xác nhận/chế biến, hoàn tất giao hàng, thanh toán online, lỗi mạng end-to-end, đặt đa quán thực tế. Không tuyên bố các phần đó PASS.

## Thứ tự xử lý đề xuất

1. Chốt một luồng Orders thật; bỏ phụ thuộc tạo OrderTests khỏi checkout khách hàng.
2. Mang snapshot món đã chọn qua location/checkout; chặn giỏ rỗng, thiếu tài khoản, thiếu món/quán hợp lệ.
3. Thống nhất giá/khuyến mãi/phí, không hiển thị số dư hoặc ưu đãi tự đặt.
4. Tracking theo trạng thái và dữ liệu vị trí server; chờ shipper khi chưa có vị trí thật.
5. Nối tab Đơn hàng vào lịch sử, sửa Back và trả kết quả thay đổi địa điểm.
6. Bổ sung test hành vi cho các lỗi trên rồi chạy lại cùng đơn thử nghiệm mới được nhận diện rõ.

## Bằng chứng

- [Trang chủ và giá deal](qa-2026-11-04/home-deal-price.png)
- [Checkout giỏ rỗng vẫn hiển thị tiền và nút đặt](qa-2026-11-04/empty-cart-checkout.png)
- [Menu tài khoản hiện tại](qa-2026-11-04/account-menu.png)

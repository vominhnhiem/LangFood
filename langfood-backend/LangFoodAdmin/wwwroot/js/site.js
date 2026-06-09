// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

/**
 * MÃ MẪU: Hướng dẫn thực hiện xóa AJAX kết hợp SweetAlert2
 * Ví dụ áp dụng cho việc xóa cửa hàng (Shops) hoặc các thực thể khác mà không cần load lại trang.
 * 
 * Cách sử dụng trên HTML:
 * <button class="btn btn-danger btn-delete-ajax" data-id="123" data-url="/Shops/Delete/123" data-name="Quán Cơm Trưa Sinh Viên">Xóa</button>
 */
function initializeAjaxDeleteHandlers() {
    $(document).on('click', '.btn-delete-ajax', function (e) {
        e.preventDefault();
        var button = $(this);
        var id = button.data('id');
        var url = button.data('url');
        var name = button.data('name') || 'mục này';

        Swal.fire({
            title: 'Bạn có chắc chắn?',
            text: 'Bạn sắp xóa "' + name + '". Hành động này không thể hoàn tác!',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#fd7e14', // Màu cam thương hiệu Làng Food
            cancelButtonColor: '#6c757d',  // Màu xám
            confirmButtonText: 'Đồng ý xóa',
            cancelButtonText: 'Hủy bỏ',
            customClass: {
                popup: 'rounded-4'
            }
        }).then((result) => {
            if (result.isConfirmed) {
                // Hiển thị loading trong lúc chờ phản hồi từ Server
                Swal.showLoading();

                $.ajax({
                    url: url,
                    type: 'POST',
                    data: { id: id },
                    success: function (res) {
                        if (res.success) {
                            // Cảnh báo thành công
                            Swal.fire({
                                icon: 'success',
                                title: 'Thành công',
                                text: res.message || 'Đã xóa thành công!',
                                confirmButtonColor: '#fd7e14',
                                customClass: {
                                    popup: 'rounded-4'
                                }
                            }).then(() => {
                                // Xóa dòng/phần tử trên giao diện DOM (giả sử nút xóa nằm trong tr hoặc thẻ cha)
                                button.closest('tr').fadeOut(400, function() {
                                    $(this).remove();
                                });
                            });
                        } else {
                            // Cảnh báo thất bại từ server
                            Swal.fire({
                                icon: 'error',
                                title: 'Thất bại',
                                text: res.message || 'Có lỗi xảy ra khi xóa!',
                                confirmButtonColor: '#fd7e14',
                                customClass: {
                                    popup: 'rounded-4'
                                }
                            });
                        }
                    },
                    error: function (xhr, status, error) {
                        // Cảnh báo lỗi kết nối/hệ thống
                        Swal.fire({
                            icon: 'error',
                            title: 'Lỗi hệ thống',
                            text: 'Không thể kết nối đến máy chủ. Vui lòng thử lại sau!',
                            confirmButtonColor: '#fd7e14',
                            customClass: {
                                popup: 'rounded-4'
                            }
                        });
                    }
                });
            }
        });
    });
}

// Khởi chạy trình lắng nghe sự kiện xóa AJAX
$(document).ready(function() {
    initializeAjaxDeleteHandlers();
});

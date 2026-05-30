package com.example.langfood;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.Order;
import java.util.Locale;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.OrderStatusResponse;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class OrderDetailsActivity extends AppCompatActivity {

    private TextView tvShopName, tvOrderId, tvOrderDate, tvOrderStatus;
    private TextView tvDeliveryAddress, tvDeliveryPhone;
    private TextView tvSubtotal, tvServiceFee, tvTotal;
    private RecyclerView rvOrderItems;
    private Button btnComplaint;
    private Order order;

    // Step ProgressBar Views
    private TextView tvStep1Circle, tvStep2Circle, tvStep3Circle, tvStep4Circle;
    private TextView tvStep1Label, tvStep2Label, tvStep3Label, tvStep4Label;
    private View viewLine1To2, viewLine2To3, viewLine3To4;

    // Polling Mechanism
    private ApiService apiService;
    private android.os.Handler pollingHandler;
    private Runnable pollingRunnable;
    private static final int POLLING_INTERVAL = 10000; // 10 seconds

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_order_details);

        order = (Order) getIntent().getSerializableExtra("ORDER");
        if (order == null) {
            finish();
            return;
        }

        initViews();
        displayOrderDetails();

        findViewById(R.id.btnBack).setOnClickListener(v -> finish());
        btnComplaint.setOnClickListener(v -> {
            Intent intent = new Intent(OrderDetailsActivity.this, ComplaintActivity.class);
            intent.putExtra("ORDER_ID", order.getId());
            startActivity(intent);
        });

        // Start polling real-time status update
        startPolling();
    }

    private void initViews() {
        tvShopName = findViewById(R.id.tvShopName);
        tvOrderId = findViewById(R.id.tvOrderId);
        tvOrderDate = findViewById(R.id.tvOrderDate);
        tvOrderStatus = findViewById(R.id.tvOrderStatus);
        tvDeliveryAddress = findViewById(R.id.tvDeliveryAddress);
        tvDeliveryPhone = findViewById(R.id.tvDeliveryPhone);
        tvSubtotal = findViewById(R.id.tvSubtotal);
        tvServiceFee = findViewById(R.id.tvServiceFee);
        tvTotal = findViewById(R.id.tvTotal);
        rvOrderItems = findViewById(R.id.rvOrderItems);
        btnComplaint = findViewById(R.id.btnComplaint);

        // Step ProgressBar
        tvStep1Circle = findViewById(R.id.tvStep1Circle);
        tvStep2Circle = findViewById(R.id.tvStep2Circle);
        tvStep3Circle = findViewById(R.id.tvStep3Circle);
        tvStep4Circle = findViewById(R.id.tvStep4Circle);

        tvStep1Label = findViewById(R.id.tvStep1Label);
        tvStep2Label = findViewById(R.id.tvStep2Label);
        tvStep3Label = findViewById(R.id.tvStep3Label);
        tvStep4Label = findViewById(R.id.tvStep4Label);

        viewLine1To2 = findViewById(R.id.viewLine1To2);
        viewLine2To3 = findViewById(R.id.viewLine2To3);
        viewLine3To4 = findViewById(R.id.viewLine3To4);

        apiService = ApiClient.getClient().create(ApiService.class);
    }

    private void displayOrderDetails() {
        tvShopName.setText(order.getShopName() != null ? order.getShopName() : "Cửa hàng #" + order.getShopId());
        tvOrderId.setText("Mã đơn hàng: #" + order.getId());
        tvOrderDate.setText("Ngày đặt: " + order.getCreatedAt());

        // Cập nhật trạng thái
        String status = order.getStatus();
        setStatusUI(tvOrderStatus, status);
        updateStepProgressBar(status);

        // Hiển thị nút khiếu nại nếu đơn hàng đã Completed (hoàn thành)
        if (status != null && (status.equalsIgnoreCase("completed") || status.equalsIgnoreCase("delivered"))) {
            btnComplaint.setVisibility(View.VISIBLE);
        } else {
            btnComplaint.setVisibility(View.GONE);
        }

        // Địa chỉ giao
        String address = "Tòa " + order.getDeliveryBuilding() + " - Phòng " + order.getDeliveryRoom();
        tvDeliveryAddress.setText(address);
        tvDeliveryPhone.setText("SĐT: " + order.getDeliveryPhone());

        // Phân tích giá tiền
        double subtotal = order.getTotalAmount();
        double serviceFee = order.getShippingFee();
        double total = subtotal + serviceFee;

        tvSubtotal.setText(String.format(Locale.getDefault(), "%,.0fđ", subtotal));
        tvServiceFee.setText(String.format(Locale.getDefault(), "%,.0fđ", serviceFee));
        tvTotal.setText(String.format(Locale.getDefault(), "%,.0fđ", total));

        // Setup items list
        if (order.getOrderItems() != null) {
            OrderItemDetailAdapter itemsAdapter = new OrderItemDetailAdapter(order.getOrderItems());
            rvOrderItems.setLayoutManager(new LinearLayoutManager(this));
            rvOrderItems.setAdapter(itemsAdapter);
        }
    }

    private void setStatusUI(TextView tvStatus, String status) {
        if (status == null) return;
        String s = status.toLowerCase().trim();
        switch (s) {
            case "pending":
                tvStatus.setText("Chờ xác nhận");
                tvStatus.setBackgroundColor(Color.parseColor("#FF9800"));
                break;
            case "pendingpayment":
                tvStatus.setText("Chờ thanh toán");
                tvStatus.setBackgroundColor(Color.parseColor("#E91E63"));
                break;
            case "confirmed":
            case "approved":
                tvStatus.setText("Đã xác nhận");
                tvStatus.setBackgroundColor(Color.parseColor("#4CAF50"));
                break;
            case "preparing":
                tvStatus.setText("Đang chế biến");
                tvStatus.setBackgroundColor(Color.parseColor("#FBC02D"));
                break;
            case "ready":
                tvStatus.setText("Chờ shipper");
                tvStatus.setBackgroundColor(Color.parseColor("#008000"));
                break;
            case "shipping":
            case "delivering":
                tvStatus.setText("Đang giao");
                tvStatus.setBackgroundColor(Color.parseColor("#2196F3"));
                break;
            case "completed":
            case "delivered":
                tvStatus.setText("Đã hoàn thành");
                tvStatus.setBackgroundColor(Color.parseColor("#808080"));
                break;
            case "cancelled":
                tvStatus.setText("Đã hủy");
                tvStatus.setBackgroundColor(Color.parseColor("#F44336"));
                break;
            default:
                tvStatus.setText(status);
                tvStatus.setBackgroundColor(Color.GRAY);
                break;
        }
    }

    private void updateStepProgressBar(String status) {
        if (status == null) return;
        String s = status.toLowerCase().trim();

        // Mặc định: tất cả xám
        tvStep1Circle.setBackgroundResource(R.drawable.bg_circle_inactive);
        tvStep2Circle.setBackgroundResource(R.drawable.bg_circle_inactive);
        tvStep3Circle.setBackgroundResource(R.drawable.bg_circle_inactive);
        tvStep4Circle.setBackgroundResource(R.drawable.bg_circle_inactive);

        viewLine1To2.setBackgroundColor(Color.parseColor("#BDBDBD"));
        viewLine2To3.setBackgroundColor(Color.parseColor("#BDBDBD"));
        viewLine3To4.setBackgroundColor(Color.parseColor("#BDBDBD"));

        tvStep1Label.setTextColor(Color.parseColor("#757575"));
        tvStep2Label.setTextColor(Color.parseColor("#757575"));
        tvStep3Label.setTextColor(Color.parseColor("#757575"));
        tvStep4Label.setTextColor(Color.parseColor("#757575"));

        // Định mức tiến trình từ 1 đến 4
        int progress = 0;
        if (s.equals("pending") || s.equals("pendingpayment")) {
            progress = 1;
        } else if (s.equals("confirmed") || s.equals("approved") || s.equals("preparing") || s.equals("ready")) {
            progress = 2;
        } else if (s.equals("shipping") || s.equals("delivering")) {
            progress = 3;
        } else if (s.equals("completed") || s.equals("delivered")) {
            progress = 4;
        }

        // Tô màu cam cho các bước và đường nối đã đi qua
        int activeColor = Color.parseColor("#EE4D2D");

        if (progress >= 1) {
            tvStep1Circle.setBackgroundResource(R.drawable.bg_circle_active);
            tvStep1Label.setTextColor(activeColor);
        }
        if (progress >= 2) {
            tvStep2Circle.setBackgroundResource(R.drawable.bg_circle_active);
            tvStep2Label.setTextColor(activeColor);
            viewLine1To2.setBackgroundColor(activeColor);
        }
        if (progress >= 3) {
            tvStep3Circle.setBackgroundResource(R.drawable.bg_circle_active);
            tvStep3Label.setTextColor(activeColor);
            viewLine2To3.setBackgroundColor(activeColor);
        }
        if (progress >= 4) {
            tvStep4Circle.setBackgroundResource(R.drawable.bg_circle_active);
            tvStep4Label.setTextColor(activeColor);
            viewLine3To4.setBackgroundColor(activeColor);
        }
    }

    private void startPolling() {
        if (pollingHandler == null) {
            pollingHandler = new android.os.Handler();
        }
        if (pollingRunnable == null) {
            pollingRunnable = new Runnable() {
                @Override
                public void run() {
                    fetchOrderStatus();
                    pollingHandler.postDelayed(this, POLLING_INTERVAL);
                }
            };
        }
        pollingHandler.post(pollingRunnable);
    }

    private void stopPolling() {
        if (pollingHandler != null && pollingRunnable != null) {
            pollingHandler.removeCallbacks(pollingRunnable);
        }
    }

    private void fetchOrderStatus() {
        if (order == null || apiService == null) return;
        apiService.getOrderStatus(order.getId()).enqueue(new Callback<OrderStatusResponse>() {
            @Override
            public void onResponse(Call<OrderStatusResponse> call, Response<OrderStatusResponse> response) {
                if (response.isSuccessful() && response.body() != null) {
                    String newStatus = response.body().getStatus();
                    if (newStatus != null) {
                        order.setStatus(newStatus);
                        setStatusUI(tvOrderStatus, newStatus);
                        updateStepProgressBar(newStatus);

                        if (newStatus.equalsIgnoreCase("completed") || newStatus.equalsIgnoreCase("delivered")) {
                            btnComplaint.setVisibility(View.VISIBLE);
                        } else {
                            btnComplaint.setVisibility(View.GONE);
                        }
                    }
                }
            }

            @Override
            public void onFailure(Call<OrderStatusResponse> call, Throwable t) {
                // Thất bại tạm thời do kết nối mạng không gián đoạn app
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        stopPolling();
    }
}

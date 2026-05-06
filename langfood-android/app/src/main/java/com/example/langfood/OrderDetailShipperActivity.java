package com.example.langfood;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.google.gson.Gson;
import com.example.langfood.models.Order;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class OrderDetailShipperActivity extends AppCompatActivity {

    private TextView tvOrderId, tvBuyerName, tvDeliveryAddress, tvTotalAmount;
    private RecyclerView rvOrderItems;
    private Button btnCompleteOrder, btnBack;
    private Order order;
    private ApiService apiService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_order_detail_shipper);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);

        // Nhận dữ liệu Order từ Intent
        String orderJson = getIntent().getStringExtra("ORDER_DATA");
        boolean isPreview = getIntent().getBooleanExtra("IS_PREVIEW", false);

        if (orderJson != null) {
            order = new Gson().fromJson(orderJson, Order.class);
            displayOrderInfo();
        }

        if (isPreview) {
            btnCompleteOrder.setVisibility(View.GONE);
        }

        btnCompleteOrder.setOnClickListener(v -> completeOrder());
        btnBack.setOnClickListener(v -> finish());
    }

    private void initViews() {
        tvOrderId = findViewById(R.id.tvOrderId);
        tvBuyerName = findViewById(R.id.tvBuyerName);
        tvDeliveryAddress = findViewById(R.id.tvDeliveryAddress);
        tvTotalAmount = findViewById(R.id.tvTotalAmount);
        rvOrderItems = findViewById(R.id.rvOrderItems); // Ánh xạ RecyclerView
        btnCompleteOrder = findViewById(R.id.btnCompleteOrder);
        btnBack = findViewById(R.id.btnBack);
    }

    private void displayOrderInfo() {
        if (order != null) {
            tvOrderId.setText("Mã đơn: #" + order.getId());

            // Hiển thị tên khách hàng (nếu có) hoặc ID
            String customerName = (order.getBuyerName() != null && !order.getBuyerName().isEmpty())
                    ? order.getBuyerName() : order.getBuyerId();
            tvBuyerName.setText("👤 Khách hàng: " + customerName);

            tvDeliveryAddress.setText("📍 Địa chỉ: " + (order.getDeliveryBuilding() != null ? order.getDeliveryBuilding() : "Chưa cập nhật"));
            tvTotalAmount.setText("💰 Tổng tiền: " + String.format("%,.0fđ", order.getTotalAmount()));

            // THIẾT LẬP DANH SÁCH MÓN ĂN
            if (order.getOrderItems() != null && !order.getOrderItems().isEmpty()) {
                OrderItemDetailAdapter adapter = new OrderItemDetailAdapter(order.getOrderItems());
                rvOrderItems.setLayoutManager(new LinearLayoutManager(this));
                rvOrderItems.setAdapter(adapter);
            }
        }
    }

    private void completeOrder() {
        if (order == null) return;

        btnCompleteOrder.setEnabled(false);
        apiService.completeOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(OrderDetailShipperActivity.this, "Giao hàng thành công!", Toast.LENGTH_LONG).show();
                    setResult(RESULT_OK);
                    finish();
                } else {
                    btnCompleteOrder.setEnabled(true);
                    Toast.makeText(OrderDetailShipperActivity.this, "Lỗi khi cập nhật trạng thái", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                btnCompleteOrder.setEnabled(true);
                Toast.makeText(OrderDetailShipperActivity.this, "Lỗi kết nối", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

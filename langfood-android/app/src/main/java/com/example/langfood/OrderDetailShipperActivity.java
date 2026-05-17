package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Wallet;
import com.google.gson.Gson;
import com.example.langfood.models.Order;
import java.util.Locale;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class OrderDetailShipperActivity extends AppCompatActivity {

    private TextView tvOrderId, tvBuyerName, tvDeliveryAddress, tvTotalAmount;
    private RecyclerView rvOrderItems;
    private Button btnCompleteOrder, btnAcceptOrder, btnBack;
    private Order order;
    private ApiService apiService;
    private String currentUserId;
    private int currentShipperId;
    private boolean isSellerView = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_order_detail_shipper);

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        currentUserId = prefs.getString("USER_ID", "");
        currentShipperId = prefs.getInt("SHIPPER_ID", -1);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);

        String orderJson = getIntent().getStringExtra("ORDER_DATA");
        boolean isPreview = getIntent().getBooleanExtra("IS_PREVIEW", false);
        isSellerView = getIntent().getBooleanExtra("IS_SELLER_VIEW", false);

        if (orderJson != null) {
            order = new Gson().fromJson(orderJson, Order.class);
            displayOrderInfo();
        }

        if (isSellerView) {
            btnAcceptOrder.setVisibility(View.GONE);
            btnCompleteOrder.setVisibility(View.GONE);
        } else {
            if (isPreview) {
                btnAcceptOrder.setVisibility(View.VISIBLE);
                btnCompleteOrder.setVisibility(View.GONE);
            } else {
                btnAcceptOrder.setVisibility(View.GONE);
                if (order != null && "Delivering".equals(order.getStatus()) && order.getShipperId() != null && order.getShipperId() == currentShipperId) {
                    btnCompleteOrder.setVisibility(View.VISIBLE);
                } else {
                    btnCompleteOrder.setVisibility(View.GONE);
                }
            }
        }

        btnAcceptOrder.setOnClickListener(v -> handleAcceptOrder());
        btnCompleteOrder.setOnClickListener(v -> completeOrder());
        btnBack.setOnClickListener(v -> finish());
    }

    private void initViews() {
        tvOrderId = findViewById(R.id.tvOrderId);
        tvBuyerName = findViewById(R.id.tvBuyerName);
        tvDeliveryAddress = findViewById(R.id.tvDeliveryAddress);
        tvTotalAmount = findViewById(R.id.tvTotalAmount);
        rvOrderItems = findViewById(R.id.rvOrderItems);
        btnCompleteOrder = findViewById(R.id.btnCompleteOrder);
        btnAcceptOrder = findViewById(R.id.btnAcceptOrder);
        btnBack = findViewById(R.id.btnBack);
    }

    private void displayOrderInfo() {
        if (order != null) {
            tvOrderId.setText("Mã đơn: #" + order.getId());
            String customerName = (order.getBuyerName() != null && !order.getBuyerName().isEmpty())
                    ? order.getBuyerName() : order.getBuyerId();
            tvBuyerName.setText("👤 Khách hàng: " + customerName);

            // HIỂN THỊ ĐỊA CHỈ VÀ SỐ ĐIỆN THOẠI
            StringBuilder addressInfo = new StringBuilder();
            addressInfo.append("📍 Địa chỉ: ").append(order.getDeliveryBuilding() != null ? order.getDeliveryBuilding() : "Chưa cập nhật");
            if (order.getDeliveryRoom() != null && !order.getDeliveryRoom().isEmpty()) {
                addressInfo.append(" - Phòng ").append(order.getDeliveryRoom());
            }
            if (order.getDeliveryPhone() != null && !order.getDeliveryPhone().isEmpty()) {
                addressInfo.append("\n📞 SĐT: ").append(order.getDeliveryPhone());
            }
            tvDeliveryAddress.setText(addressInfo.toString());

            // Nhấn vào địa chỉ (SĐT) để gọi điện nhanh cho khách (Dành cho Shipper)
            if (order.getDeliveryPhone() != null && !order.getDeliveryPhone().isEmpty() && !isSellerView) {
                tvDeliveryAddress.setOnClickListener(v -> {
                    Intent intent = new Intent(Intent.ACTION_DIAL);
                    intent.setData(Uri.parse("tel:" + order.getDeliveryPhone()));
                    startActivity(intent);
                });
            }
            
            if (isSellerView) {
                tvTotalAmount.setText("💰 Giá trị đơn: " + String.format(Locale.getDefault(), "%,.0fđ", order.getTotalAmount()));
            } else {
                double totalToCollect = order.getTotalAmount() + order.getShippingFee();
                tvTotalAmount.setText("💰 Tổng thu khách: " + String.format(Locale.getDefault(), "%,.0fđ", totalToCollect));
            }

            if (order.getOrderItems() != null && !order.getOrderItems().isEmpty()) {
                OrderItemDetailAdapter adapter = new OrderItemDetailAdapter(order.getOrderItems());
                rvOrderItems.setLayoutManager(new LinearLayoutManager(this));
                rvOrderItems.setAdapter(adapter);
            }
        }
    }

    private void handleAcceptOrder() {
        if (currentShipperId == -1 || currentUserId.isEmpty()) {
            Toast.makeText(this, "Lỗi: Bạn không có quyền Shipper!", Toast.LENGTH_SHORT).show();
            return;
        }

        double requiredAmount = order.getTotalAmount() + order.getShippingFee();
        apiService.getWallet(currentUserId).enqueue(new Callback<Wallet>() {
            @Override
            public void onResponse(Call<Wallet> call, Response<Wallet> response) {
                if (response.isSuccessful() && response.body() != null) {
                    double balance = response.body().getBalance();
                    if (balance < requiredAmount) {
                        showInsufficientBalanceDialog(requiredAmount, balance);
                    } else {
                        showAcceptConfirmation(requiredAmount);
                    }
                }
            }
            @Override public void onFailure(Call<Wallet> call, Throwable t) { Toast.makeText(OrderDetailShipperActivity.this, "Lỗi ví!", Toast.LENGTH_SHORT).show(); }
        });
    }

    private void showInsufficientBalanceDialog(double required, double current) {
        new AlertDialog.Builder(this)
                .setTitle("Số dư không đủ")
                .setMessage(String.format(Locale.getDefault(), "Bạn cần %,.0fđ để nhận đơn.\nSố dư hiện tại: %,.0fđ.", required, current))
                .setPositiveButton("Nạp tiền", (d, w) -> startActivity(new Intent(this, WalletActivity.class)))
                .setNegativeButton("Đóng", null).show();
    }

    private void showAcceptConfirmation(double amount) {
        new AlertDialog.Builder(this)
                .setTitle("Xác nhận nhận đơn")
                .setMessage(String.format(Locale.getDefault(), "Hệ thống giam %,.0fđ.\nGiao xong: Hoàn %,.0fđ + Tặng 20k công.\nBạn đồng ý chứ?", amount, order.getTotalAmount()))
                .setPositiveButton("Đồng ý", (d, w) -> executeAccept()).setNegativeButton("Hủy", null).show();
    }

    private void executeAccept() {
        btnAcceptOrder.setEnabled(false);
        apiService.acceptOrder(order.getId(), currentShipperId).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(OrderDetailShipperActivity.this, "Nhận đơn thành công!", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    btnAcceptOrder.setEnabled(true);
                    Toast.makeText(OrderDetailShipperActivity.this, "Đơn đã có chủ!", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<Void> call, Throwable t) { btnAcceptOrder.setEnabled(true); }
        });
    }

    private void completeOrder() {
        if (order == null) return;
        btnCompleteOrder.setEnabled(false);
        apiService.completeOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(OrderDetailShipperActivity.this, "Giao hàng thành công!", Toast.LENGTH_LONG).show();
                    finish();
                } else {
                    btnCompleteOrder.setEnabled(true);
                }
            }
            @Override public void onFailure(Call<Void> call, Throwable t) { btnCompleteOrder.setEnabled(true); }
        });
    }
}

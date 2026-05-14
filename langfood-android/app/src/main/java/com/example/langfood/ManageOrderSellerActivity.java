package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Order;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ManageOrderSellerActivity extends AppCompatActivity {

    private RecyclerView rvOrders;
    private SellerOrderAdapter adapter;
    private List<Order> sellerOrders = new ArrayList<>();
    private ApiService apiService;
    private int shopId;
    private ImageView btnBack, btnLogout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_order_seller);

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        shopId = prefs.getInt("SHOP_ID", -1);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);
        
        btnBack.setOnClickListener(v -> finish());
        btnLogout.setOnClickListener(v -> showLogoutDialog());

        loadOrders();
    }

    private void showLogoutDialog() {
        new AlertDialog.Builder(this)
                .setTitle("Đăng xuất")
                .setMessage("Bạn có muốn đăng xuất khỏi tài khoản Shop không?")
                .setPositiveButton("Đăng xuất", (dialog, which) -> {
                    SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
                    prefs.edit().clear().commit();
                    
                    Intent intent = new Intent(ManageOrderSellerActivity.this, LoginActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                })
                .setNegativeButton("Hủy", null)
                .show();
    }

    private void initViews() {
        rvOrders = findViewById(R.id.rvOrders);
        btnBack = findViewById(R.id.btnBack);
        btnLogout = findViewById(R.id.btnLogout);
        
        adapter = new SellerOrderAdapter(this, sellerOrders, new SellerOrderAdapter.OnOrderActionListener() {
            @Override
            public void onConfirm(Order order) {
                confirmOrder(order);
            }

            @Override
            public void onItemClick(Order order) {
                // Mở chi tiết đơn hàng (Dùng chung layout với Shipper nhưng ở chế độ xem)
                Intent intent = new Intent(ManageOrderSellerActivity.this, OrderDetailShipperActivity.class);
                intent.putExtra("ORDER_DATA", new Gson().toJson(order));
                intent.putExtra("IS_PREVIEW", true); // Ẩn nút "Hoàn thành" của shipper
                startActivity(intent);
            }
        });
        rvOrders.setLayoutManager(new LinearLayoutManager(this));
        rvOrders.setAdapter(adapter);
    }

    private void loadOrders() {
        if (shopId == -1) {
            Toast.makeText(this, "Không tìm thấy thông tin cửa hàng", Toast.LENGTH_SHORT).show();
            return;
        }

        apiService.getOrdersByShop(shopId).enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(Call<List<Order>> call, Response<List<Order>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    sellerOrders.clear();
                    sellerOrders.addAll(response.body());
                    adapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<List<Order>> call, Throwable t) {
                Toast.makeText(ManageOrderSellerActivity.this, "Lỗi tải đơn hàng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void confirmOrder(Order order) {
        apiService.shopAcceptOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ManageOrderSellerActivity.this, "Đã xác nhận đơn #" + order.getId() + ". Đơn đã sẵn sàng cho Shipper!", Toast.LENGTH_SHORT).show();
                    loadOrders();
                } else {
                    Toast.makeText(ManageOrderSellerActivity.this, "Lỗi xác nhận đơn", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(ManageOrderSellerActivity.this, "Lỗi kết nối", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadOrders();
    }
}

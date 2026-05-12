package com.example.langfood;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Order;
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
    private ImageView btnBack;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_order_seller);

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        shopId = prefs.getInt("SHOP_ID", -1);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);
        
        btnBack.setOnClickListener(v -> finish());

        loadOrders();
    }

    private void initViews() {
        rvOrders = findViewById(R.id.rvOrders);
        btnBack = findViewById(R.id.btnBack);
        
        adapter = new SellerOrderAdapter(this, sellerOrders, order -> {
            // Chức năng xác nhận đơn hàng (Dành cho Seller)
            confirmOrder(order);
        });
        rvOrders.setLayoutManager(new LinearLayoutManager(this));
        rvOrders.setAdapter(adapter);
    }

    private void loadOrders() {
        if (shopId == -1) {
            Toast.makeText(this, "Không tìm thấy thông tin cửa hàng", Toast.LENGTH_SHORT).show();
            return;
        }

        // Lấy danh sách đơn hàng dành riêng cho Shop này
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
        // Gọi API xác nhận đơn hàng, chuyển trạng thái từ Pending -> Confirmed
        apiService.confirmOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ManageOrderSellerActivity.this, "Đã xác nhận đơn hàng #" + order.getId() + ". Đang chờ shipper nhận đơn.", Toast.LENGTH_LONG).show();
                    loadOrders(); // Tải lại danh sách để cập nhật trạng thái UI
                } else {
                    Toast.makeText(ManageOrderSellerActivity.this, "Xác nhận đơn thất bại", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(ManageOrderSellerActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

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
import com.example.langfood.models.OrderItem;
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
    private String sellerId;
    private ImageView btnBack;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_order_seller);

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        sellerId = prefs.getString("USER_ID", "");

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
            // Vì backend hiện tại tập trung vào Shipper Accept, 
            // Ở đây ta có thể giả lập hoặc cập nhật trạng thái nếu cần.
            confirmOrder(order);
        });
        rvOrders.setLayoutManager(new LinearLayoutManager(this));
        rvOrders.setAdapter(adapter);
    }

    private void loadOrders() {
        apiService.getAllOrders().enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(Call<List<Order>> call, Response<List<Order>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    filterOrdersForSeller(response.body());
                }
            }

            @Override
            public void onFailure(Call<List<Order>> call, Throwable t) {
                Toast.makeText(ManageOrderSellerActivity.this, "Lỗi tải đơn hàng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void filterOrdersForSeller(List<Order> allOrders) {
        sellerOrders.clear();
        for (Order order : allOrders) {
            boolean hasSellerProduct = false;
            if (order.getOrderItems() != null) {
                for (OrderItem item : order.getOrderItems()) {
                    // Kiểm tra xem món ăn này có phải của Seller này không
                    // Cần đảm bảo model OrderItem/Product có chứa SellerId
                    if (item.getProduct() != null && sellerId.equals(item.getProduct().getSellerId())) {
                        hasSellerProduct = true;
                        break;
                    }
                }
            }
            if (hasSellerProduct) {
                sellerOrders.add(order);
            }
        }
        adapter.notifyDataSetChanged();
    }

    private void confirmOrder(Order order) {
        // Backend hiện chưa có endpoint xác nhận đơn riêng cho Seller
        // Ta có thể tạm thời thông báo hoặc thêm logic cập nhật status sang "Confirmed" nếu Backend hỗ trợ
        Toast.makeText(this, "Đã xác nhận đơn hàng #" + order.getId() + ". Đang chờ shipper nhận đơn.", Toast.LENGTH_LONG).show();
        
        // Giả lập: Cập nhật UI ngay lập tức
        order.setStatus("Confirmed");
        adapter.notifyDataSetChanged();
    }
}

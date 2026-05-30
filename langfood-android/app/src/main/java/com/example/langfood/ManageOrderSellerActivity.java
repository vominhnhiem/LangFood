package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

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
    private ImageView btnBack, btnLogout, btnNotification;
    private SwipeRefreshLayout swipeRefresh;

    private androidx.appcompat.widget.SwitchCompat switchShopStatus;
    private TextView tvShopStatusText;

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
        btnNotification.setOnClickListener(v -> {
            markNotificationsAsRead();
            startActivity(new Intent(ManageOrderSellerActivity.this, NotificationActivity.class));
        });

        setupSwipeRefresh();
        loadOrders();
    }

    private void setupSwipeRefresh() {
        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::loadOrders);
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
        btnNotification = findViewById(R.id.btnNotification);
        swipeRefresh = findViewById(R.id.swipeRefresh);
        
        switchShopStatus = findViewById(R.id.switchShopStatus);
        tvShopStatusText = findViewById(R.id.tvShopStatusText);
        
        adapter = new SellerOrderAdapter(this, sellerOrders, new SellerOrderAdapter.OnOrderActionListener() {
            @Override
            public void onConfirm(Order order) {
                confirmOrder(order);
            }

            @Override
            public void onReady(Order order) {
                markOrderReady(order);
            }

            @Override
            public void onItemClick(Order order) {
                // Mở chi tiết đơn hàng
                Intent intent = new Intent(ManageOrderSellerActivity.this, OrderDetailShipperActivity.class);
                intent.putExtra("ORDER_DATA", new Gson().toJson(order));
                intent.putExtra("IS_PREVIEW", true);
                intent.putExtra("IS_SELLER_VIEW", true); // BÁO CHO ACTIVITY BIẾT ĐÂY LÀ SHOP XEM
                startActivity(intent);
            }
        });
        rvOrders.setLayoutManager(new LinearLayoutManager(this));
        rvOrders.setAdapter(adapter);
    }

    private void loadOrders() {
        if (shopId == -1) {
            if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
            Toast.makeText(this, "Không tìm thấy thông tin cửa hàng", Toast.LENGTH_SHORT).show();
            return;
        }

        apiService.getOrdersByShop(shopId).enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(Call<List<Order>> call, Response<List<Order>> response) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    sellerOrders.clear();
                    sellerOrders.addAll(response.body());
                    adapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<List<Order>> call, Throwable t) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                Toast.makeText(ManageOrderSellerActivity.this, "Lỗi tải đơn hàng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void confirmOrder(Order order) {
        apiService.shopAcceptOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ManageOrderSellerActivity.this, "Đã xác nhận đơn #" + order.getId() + ". Hãy bắt đầu chế biến!", Toast.LENGTH_SHORT).show();
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

    private void markOrderReady(Order order) {
        apiService.shopReadyOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ManageOrderSellerActivity.this, "Đơn #" + order.getId() + " đã sẵn sàng cho Shipper!", Toast.LENGTH_SHORT).show();
                    loadOrders();
                } else {
                    Toast.makeText(ManageOrderSellerActivity.this, "Lỗi cập nhật trạng thái", Toast.LENGTH_SHORT).show();
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
        fetchUnreadNotificationCount();
        fetchShopStatus();
    }

    private void updateNotificationBadge(int count) {
        TextView tvBadge = findViewById(R.id.tvNotificationBadge);
        if (tvBadge != null) {
            if (count > 0) {
                tvBadge.setText(String.valueOf(count));
                tvBadge.setVisibility(android.view.View.VISIBLE);
            } else {
                tvBadge.setVisibility(android.view.View.GONE);
            }
        }
    }

    private void fetchUnreadNotificationCount() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", "");
        if (userId.isEmpty() || apiService == null) return;

        apiService.getUnreadNotificationCount(userId).enqueue(new Callback<Integer>() {
            @Override
            public void onResponse(Call<Integer> call, Response<Integer> response) {
                if (response.isSuccessful() && response.body() != null) {
                    updateNotificationBadge(response.body());
                }
            }

            @Override
            public void onFailure(Call<Integer> call, Throwable t) {}
        });
    }

    private void markNotificationsAsRead() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", "");
        if (userId.isEmpty() || apiService == null) return;

        updateNotificationBadge(0);

        apiService.markAllNotificationsAsRead(userId).enqueue(new Callback<okhttp3.ResponseBody>() {
            @Override
            public void onResponse(Call<okhttp3.ResponseBody> call, Response<okhttp3.ResponseBody> response) {}

            @Override
            public void onFailure(Call<okhttp3.ResponseBody> call, Throwable t) {}
        });
    }

    private void fetchShopStatus() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", "");
        if (userId.isEmpty() || apiService == null) return;

        apiService.getShopByUserId(userId).enqueue(new Callback<com.example.langfood.models.Shop>() {
            @Override
            public void onResponse(Call<com.example.langfood.models.Shop> call, Response<com.example.langfood.models.Shop> response) {
                if (response.isSuccessful() && response.body() != null) {
                    com.example.langfood.models.Shop shop = response.body();
                    setShopStatusUI(shop.isOpen());
                }
            }

            @Override
            public void onFailure(Call<com.example.langfood.models.Shop> call, Throwable t) {}
        });
    }

    private void setShopStatusUI(boolean isOpen) {
        switchShopStatus.setOnCheckedChangeListener(null);
        switchShopStatus.setChecked(isOpen);
        if (isOpen) {
            tvShopStatusText.setText("Mở cửa");
            tvShopStatusText.setTextColor(android.graphics.Color.parseColor("#4CAF50"));
        } else {
            tvShopStatusText.setText("Đóng cửa");
            tvShopStatusText.setTextColor(android.graphics.Color.parseColor("#F44336"));
        }
        setupSwitchListener();
    }

    private void setupSwitchListener() {
        switchShopStatus.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (shopId == -1) {
                Toast.makeText(ManageOrderSellerActivity.this, "Không tìm thấy thông tin cửa hàng", Toast.LENGTH_SHORT).show();
                setShopStatusUI(!isChecked);
                return;
            }
            apiService.toggleShopStatus(shopId).enqueue(new Callback<com.example.langfood.models.Shop>() {
                @Override
                public void onResponse(Call<com.example.langfood.models.Shop> call, Response<com.example.langfood.models.Shop> response) {
                    if (response.isSuccessful() && response.body() != null) {
                        com.example.langfood.models.Shop updatedShop = response.body();
                        Toast.makeText(ManageOrderSellerActivity.this, "Đã cập nhật trạng thái cửa hàng", Toast.LENGTH_SHORT).show();
                        setShopStatusUI(updatedShop.isOpen());
                    } else {
                        Toast.makeText(ManageOrderSellerActivity.this, "Lỗi cập nhật trạng thái", Toast.LENGTH_SHORT).show();
                        setShopStatusUI(!isChecked);
                    }
                }

                @Override
                public void onFailure(Call<com.example.langfood.models.Shop> call, Throwable t) {
                    Toast.makeText(ManageOrderSellerActivity.this, "Lỗi kết nối mạng", Toast.LENGTH_SHORT).show();
                    setShopStatusUI(!isChecked);
                }
            });
        });
    }
}

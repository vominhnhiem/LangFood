package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentTransaction;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class MainActivity extends AppCompatActivity {

    private int shopId;
    private ApiService apiService;

    // Views
    private androidx.appcompat.widget.SwitchCompat switchShopStatus;
    private TextView tvShopStatusText;
    private TextView tvMainTitle;
    private ImageView btnNotification;
    private TextView tvNotificationBadge;
    private BottomNavigationView bottomNavigation;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        shopId = prefs.getInt("SHOP_ID", -1);
        apiService = ApiClient.getClient().create(ApiService.class);

        initViews();
        setupNavigation();
        setupListeners();

        // Load default fragment (Orders tab)
        if (savedInstanceState == null) {
            loadFragment(new SellerOrdersFragment(), "Đơn hàng");
        }
    }

    private void initViews() {
        switchShopStatus = findViewById(R.id.switchShopStatus);
        tvShopStatusText = findViewById(R.id.tvShopStatusText);
        tvMainTitle = findViewById(R.id.tvMainTitle);
        btnNotification = findViewById(R.id.btnNotification);
        tvNotificationBadge = findViewById(R.id.tvNotificationBadge);
        bottomNavigation = findViewById(R.id.bottom_navigation);
    }

    private void setupNavigation() {
        bottomNavigation.setOnItemSelectedListener(item -> {
            int itemId = item.getItemId();
            if (itemId == R.id.menu_orders) {
                loadFragment(new SellerOrdersFragment(), "Đơn hàng");
                return true;
            } else if (itemId == R.id.menu_menu) {
                loadFragment(new SellerMenuFragment(), "Thực đơn");
                return true;
            } else if (itemId == R.id.menu_finance) {
                loadFragment(new SellerFinanceFragment(), "Tài chính");
                return true;
            } else if (itemId == R.id.menu_account) {
                loadFragment(new SellerAccountFragment(), "Tài khoản");
                return true;
            }
            return false;
        });
    }

    private void setupListeners() {
        btnNotification.setOnClickListener(v -> {
            markNotificationsAsRead();
            startActivity(new Intent(MainActivity.this, NotificationActivity.class));
        });
    }

    private void loadFragment(Fragment fragment, String title) {
        tvMainTitle.setText(title);
        FragmentTransaction transaction = getSupportFragmentManager().beginTransaction();
        transaction.replace(R.id.fragment_container, fragment);
        transaction.commit();
    }

    @Override
    protected void onResume() {
        super.onResume();
        fetchUnreadNotificationCount();
        fetchShopStatus();
    }

    private void fetchUnreadNotificationCount() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", "");
        if (userId.isEmpty()) return;

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

    private void updateNotificationBadge(int count) {
        if (count > 0) {
            tvNotificationBadge.setText(String.valueOf(count));
            tvNotificationBadge.setVisibility(android.view.View.VISIBLE);
        } else {
            tvNotificationBadge.setVisibility(android.view.View.GONE);
        }
    }

    private void markNotificationsAsRead() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", "");
        if (userId.isEmpty()) return;

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
        if (userId.isEmpty()) return;

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
                Toast.makeText(MainActivity.this, "Không tìm thấy thông tin cửa hàng", Toast.LENGTH_SHORT).show();
                setShopStatusUI(!isChecked);
                return;
            }
            apiService.toggleShopStatus(shopId).enqueue(new Callback<com.example.langfood.models.Shop>() {
                @Override
                public void onResponse(Call<com.example.langfood.models.Shop> call, Response<com.example.langfood.models.Shop> response) {
                    if (response.isSuccessful() && response.body() != null) {
                        com.example.langfood.models.Shop updatedShop = response.body();
                        Toast.makeText(MainActivity.this, "Đã cập nhật trạng thái cửa hàng", Toast.LENGTH_SHORT).show();
                        setShopStatusUI(updatedShop.isOpen());
                    } else {
                        Toast.makeText(MainActivity.this, "Lỗi cập nhật trạng thái", Toast.LENGTH_SHORT).show();
                        setShopStatusUI(!isChecked);
                    }
                }

                @Override
                public void onFailure(Call<com.example.langfood.models.Shop> call, Throwable t) {
                    Toast.makeText(MainActivity.this, "Lỗi kết nối mạng", Toast.LENGTH_SHORT).show();
                    setShopStatusUI(!isChecked);
                }
            });
        });
    }
}

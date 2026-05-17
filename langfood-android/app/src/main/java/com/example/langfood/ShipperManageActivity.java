package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Order;
import com.example.langfood.models.Wallet;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ShipperManageActivity extends AppCompatActivity implements ShipperOrderAdapter.OnOrderClickListener {

    private RecyclerView rvShipperOrders;
    private ShipperOrderAdapter adapter;
    private List<Order> orderList = new ArrayList<>();
    private ImageView btnBack;
    private ApiService apiService;
    private int shipperId;
    private String userId;
    private SwipeRefreshLayout swipeRefresh;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shipper_manage);

        initViews();
        setupRecyclerView();
        setupSwipeRefresh();

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        shipperId = prefs.getInt("SHIPPER_ID", -1);
        userId = prefs.getString("USER_ID", "");

        apiService = ApiClient.getClient().create(ApiService.class);

        btnBack.setOnClickListener(v -> finish());
        btnBack.setOnLongClickListener(v -> {
            showLogoutDialog();
            return true;
        });

        loadAvailableOrders();
    }

    private void setupSwipeRefresh() {
        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::loadAvailableOrders);
    }

    private void showLogoutDialog() {
        new AlertDialog.Builder(this)
                .setTitle("Đăng xuất")
                .setMessage("Bạn có muốn đăng xuất khỏi tài khoản Shipper không?")
                .setPositiveButton("Đăng xuất", (dialog, which) -> {
                    SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
                    prefs.edit().clear().commit(); 
                    startActivity(new Intent(ShipperManageActivity.this, LoginActivity.class));
                    finish();
                })
                .setNegativeButton("Hủy", null)
                .show();
    }

    private void initViews() {
        rvShipperOrders = findViewById(R.id.rvShipperOrders);
        btnBack = findViewById(R.id.btnBack);
        swipeRefresh = findViewById(R.id.swipeRefresh);
    }

    private void setupRecyclerView() {
        adapter = new ShipperOrderAdapter(this, orderList, this);
        rvShipperOrders.setLayoutManager(new LinearLayoutManager(this));
        rvShipperOrders.setAdapter(adapter);
    }

    private void loadAvailableOrders() {
        if (apiService == null || shipperId == -1) return;
        
        swipeRefresh.setRefreshing(true);
        apiService.getOrdersForShipper(shipperId).enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(Call<List<Order>> call, Response<List<Order>> response) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    orderList.clear();
                    orderList.addAll(response.body());
                    adapter.updateList(orderList);
                } else {
                    orderList.clear();
                    adapter.updateList(orderList);
                }
            }

            @Override
            public void onFailure(Call<List<Order>> call, Throwable t) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                Toast.makeText(ShipperManageActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onAcceptClick(Order order) {
        if ("Delivering".equals(order.getStatus())) {
            goToDetail(order, false);
            return;
        }

        if (shipperId == -1 || userId.isEmpty()) {
            Toast.makeText(this, "Lỗi thông tin tài khoản!", Toast.LENGTH_SHORT).show();
            return;
        }

        double requiredAmount = order.getTotalAmount() + order.getShippingFee();

        apiService.getWallet(userId).enqueue(new Callback<Wallet>() {
            @Override
            public void onResponse(Call<Wallet> call, Response<Wallet> response) {
                if (response.isSuccessful() && response.body() != null) {
                    double balance = response.body().getBalance();
                    if (balance < requiredAmount) {
                        showInsufficientBalanceDialog(requiredAmount, balance);
                    } else {
                        showAcceptConfirmation(order, requiredAmount);
                    }
                } else {
                    Toast.makeText(ShipperManageActivity.this, "Không thể kiểm tra số dư ví!", Toast.LENGTH_SHORT).show();
                }
            }
            @Override
            public void onFailure(Call<Wallet> call, Throwable t) {
                Toast.makeText(ShipperManageActivity.this, "Lỗi kết nối ví!", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showInsufficientBalanceDialog(double required, double current) {
        new AlertDialog.Builder(this)
                .setTitle("Số dư không đủ")
                .setMessage(String.format(Locale.getDefault(), 
                    "Bạn cần ít nhất %,.0fđ trong ví để nhận đơn này.\nSố dư hiện tại: %,.0fđ.\nVui lòng nạp thêm tiền!", required, current))
                .setPositiveButton("Nạp tiền", (d, w) -> startActivity(new Intent(this, WalletActivity.class)))
                .setNegativeButton("Đóng", null)
                .show();
    }

    private void showAcceptConfirmation(Order order, double holdAmount) {
        double foodPrice = order.getTotalAmount();
        new AlertDialog.Builder(this)
                .setTitle("Xác nhận nhận đơn")
                .setMessage(String.format(Locale.getDefault(), 
                    "Hệ thống sẽ tạm giam %,.0fđ từ ví (Món + phí 3k).\n\n" +
                    "Quyền lợi khi giao thành công:\n" +
                    "✅ Nhận %,.0fđ tiền mặt từ khách.\n" +
                    "✅ Hoàn %,.0fđ vào ví (Tiền món).\n" +
                    "✅ Cộng thêm 20,000đ tiền công vào ví.\n\n" +
                    "Bạn đồng ý chứ?", holdAmount, holdAmount, foodPrice))
                .setPositiveButton("Đồng ý nhận", (d, w) -> executeAcceptOrder(order))
                .setNegativeButton("Hủy", null)
                .show();
    }

    private void executeAcceptOrder(Order order) {
        apiService.acceptOrder(order.getId(), shipperId).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ShipperManageActivity.this, "Nhận đơn thành công!", Toast.LENGTH_SHORT).show();
                    goToDetail(order, false);
                    loadAvailableOrders();
                } else {
                    Toast.makeText(ShipperManageActivity.this, "Đơn đã có người nhận!", Toast.LENGTH_SHORT).show();
                }
            }
            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(ShipperManageActivity.this, "Lỗi kết nối", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onItemClick(Order order) {
        boolean isPreview = !"Delivering".equals(order.getStatus());
        goToDetail(order, isPreview);
    }

    private void goToDetail(Order order, boolean isPreview) {
        Intent intent = new Intent(this, OrderDetailShipperActivity.class);
        intent.putExtra("ORDER_DATA", new Gson().toJson(order));
        intent.putExtra("IS_PREVIEW", isPreview);
        startActivity(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadAvailableOrders();
    }
}

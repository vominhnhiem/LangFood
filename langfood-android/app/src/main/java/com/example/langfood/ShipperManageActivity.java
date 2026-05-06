package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;
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

public class ShipperManageActivity extends AppCompatActivity implements ShipperOrderAdapter.OnOrderClickListener {

    private RecyclerView rvShipperOrders;
    private ShipperOrderAdapter adapter;
    private List<Order> orderList = new ArrayList<>();
    private ImageView btnBack;
    private ApiService apiService;
    private String shipperId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shipper_manage);

        initViews();
        setupRecyclerView();

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        shipperId = prefs.getString("USER_ID", "");

        apiService = ApiClient.getClient().create(ApiService.class);

        btnBack.setOnClickListener(v -> finish());

        loadAvailableOrders();
    }

    private void initViews() {
        rvShipperOrders = findViewById(R.id.rvShipperOrders);
        btnBack = findViewById(R.id.btnBack);
    }

    private void setupRecyclerView() {
        adapter = new ShipperOrderAdapter(this, orderList, this);
        rvShipperOrders.setLayoutManager(new LinearLayoutManager(this));
        rvShipperOrders.setAdapter(adapter);
    }

    private void loadAvailableOrders() {
        apiService.getAvailableOrders().enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(Call<List<Order>> call, Response<List<Order>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    orderList = response.body();
                    adapter.updateList(orderList);
                } else {
                    orderList.clear();
                    adapter.updateList(orderList);
                    Toast.makeText(ShipperManageActivity.this, "Không có đơn hàng nào khả dụng", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<List<Order>> call, Throwable t) {
                Toast.makeText(ShipperManageActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onAcceptClick(Order order) {
        apiService.acceptOrder(order.getId(), shipperId).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ShipperManageActivity.this, "Nhận đơn thành công!", Toast.LENGTH_SHORT).show();
                    
                    // Chuyển sang màn hình chi tiết để đi giao
                    Intent intent = new Intent(ShipperManageActivity.this, OrderDetailShipperActivity.class);
                    intent.putExtra("ORDER_DATA", new Gson().toJson(order));
                    startActivity(intent);
                    
                    loadAvailableOrders(); // Tải lại danh sách sau khi nhận đơn
                } else {
                    Toast.makeText(ShipperManageActivity.this, "Lỗi khi nhận đơn hoặc đơn đã có người nhận", Toast.LENGTH_SHORT).show();
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
        // Xem chi tiết đơn hàng trước khi nhận
        Intent intent = new Intent(ShipperManageActivity.this, OrderDetailShipperActivity.class);
        intent.putExtra("ORDER_DATA", new Gson().toJson(order));
        intent.putExtra("IS_PREVIEW", true); // Flag để ẩn nút hoàn thành
        startActivity(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadAvailableOrders();
    }
}

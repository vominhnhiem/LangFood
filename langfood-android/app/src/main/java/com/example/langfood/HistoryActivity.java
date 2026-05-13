package com.example.langfood;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Order;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class HistoryActivity extends AppCompatActivity {

    private RecyclerView rvHistory;
    private OrderHistoryAdapter adapter;
    private final List<Order> orderList = new ArrayList<>();
    private SwipeRefreshLayout swipeRefresh;
    private ProgressBar progressBar;
    private TextView tvEmpty;
    private ApiService apiService;
    private String userId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_history);

        initViews();
        setupRecyclerView();
        setupSwipeRefresh();
        
        apiService = ApiClient.getClient().create(ApiService.class);
        
        // Lấy userId từ SharedPreferences
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");

        if (userId.isEmpty()) {
            Toast.makeText(this, "Vui lòng đăng nhập để xem lịch sử", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        loadOrderHistory();
    }

    private void setupSwipeRefresh() {
        if (swipeRefresh != null) {
            swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
            swipeRefresh.setOnRefreshListener(this::loadOrderHistory);
        }
    }

    private void initViews() {
        rvHistory = findViewById(R.id.rvHistory);
        swipeRefresh = findViewById(R.id.swipeRefresh);
        progressBar = findViewById(R.id.progressBar);
        tvEmpty = findViewById(R.id.tvEmpty);
        
        View btnBack = findViewById(R.id.btnBack);
        if (btnBack != null) {
            btnBack.setOnClickListener(v -> finish());
        }
    }

    private void setupRecyclerView() {
        if (rvHistory == null) return;
        adapter = new OrderHistoryAdapter(orderList);
        rvHistory.setLayoutManager(new LinearLayoutManager(this));
        rvHistory.setAdapter(adapter);
    }

    private void loadOrderHistory() {
        if (userId == null || userId.isEmpty() || swipeRefresh == null || apiService == null) return;

        swipeRefresh.setRefreshing(true);
        if (tvEmpty != null) tvEmpty.setVisibility(View.GONE);

        apiService.getOrdersByBuyer(userId).enqueue(new Callback<>() {
            @Override
            public void onResponse(@NonNull Call<List<Order>> call, @NonNull Response<List<Order>> response) {
                swipeRefresh.setRefreshing(false);
                if (progressBar != null) progressBar.setVisibility(View.GONE);

                if (response.isSuccessful() && response.body() != null) {
                    orderList.clear();
                    orderList.addAll(response.body());
                    
                    // Sắp xếp đơn hàng mới nhất lên đầu
                    Collections.reverse(orderList);
                    
                    if (adapter != null) adapter.notifyDataSetChanged();

                    if (orderList.isEmpty() && tvEmpty != null) {
                        tvEmpty.setVisibility(View.VISIBLE);
                    }
                } else {
                    Toast.makeText(HistoryActivity.this, "Không thể tải lịch sử đơn hàng", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(@NonNull Call<List<Order>> call, @NonNull Throwable t) {
                swipeRefresh.setRefreshing(false);
                if (progressBar != null) progressBar.setVisibility(View.GONE);
                Toast.makeText(HistoryActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }
}

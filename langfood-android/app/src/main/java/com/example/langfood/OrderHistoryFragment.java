package com.example.langfood;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Order;
import com.example.langfood.models.Product;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class OrderHistoryFragment extends Fragment {

    private SwipeRefreshLayout swipeRefresh;
    private ProgressBar progressBar;
    private View scrollViewEmpty;
    private RecyclerView rvRecommendations;
    private RecyclerView rvHistoryOrders;

    private OrderHistoryAdapter ordersAdapter;
    private RecommendProductAdapter recommendAdapter;
    private final List<Order> historyOrdersList = new ArrayList<>();

    private ApiService apiService;
    private String userId;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_order_history, container, false);

        initViews(view);
        setupRecyclerViews();
        
        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");

        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::fetchHistoryOrders);

        if (userId.isEmpty()) {
            progressBar.setVisibility(View.GONE);
            showEmptyState();
        } else {
            fetchHistoryOrders();
        }

        return view;
    }

    private void initViews(View view) {
        swipeRefresh = view.findViewById(R.id.swipeRefresh);
        progressBar = view.findViewById(R.id.progressBar);
        scrollViewEmpty = view.findViewById(R.id.scrollViewEmpty);
        rvRecommendations = view.findViewById(R.id.rvRecommendations);
        rvHistoryOrders = view.findViewById(R.id.rvHistoryOrders);
    }

    private void setupRecyclerViews() {
        // Recommendations
        rvRecommendations.setLayoutManager(new LinearLayoutManager(getContext()));
        
        // History Orders
        ordersAdapter = new OrderHistoryAdapter(historyOrdersList);
        rvHistoryOrders.setLayoutManager(new LinearLayoutManager(getContext()));
        rvHistoryOrders.setAdapter(ordersAdapter);
    }

    private void fetchHistoryOrders() {
        if (userId.isEmpty() || apiService == null) {
            swipeRefresh.setRefreshing(false);
            progressBar.setVisibility(View.GONE);
            return;
        }

        swipeRefresh.setRefreshing(true);
        apiService.getOrdersByBuyer(userId).enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(@NonNull Call<List<Order>> call, @NonNull Response<List<Order>> response) {
                swipeRefresh.setRefreshing(false);
                progressBar.setVisibility(View.GONE);

                if (response.isSuccessful() && response.body() != null) {
                    historyOrdersList.clear();
                    for (Order order : response.body()) {
                        if (isHistory(order.getStatus())) {
                            historyOrdersList.add(order);
                        }
                    }

                    // Sắp xếp ID giảm dần (mới nhất lên đầu)
                    Collections.sort(historyOrdersList, (o1, o2) -> Integer.compare(o2.getId(), o1.getId()));

                    ordersAdapter.notifyDataSetChanged();

                    if (historyOrdersList.isEmpty()) {
                        showEmptyState();
                    } else {
                        showHistoryList();
                    }
                } else {
                    Toast.makeText(getContext(), "Không thể tải lịch sử đơn hàng", Toast.LENGTH_SHORT).show();
                    showEmptyState();
                }
            }

            @Override
            public void onFailure(@NonNull Call<List<Order>> call, @NonNull Throwable t) {
                swipeRefresh.setRefreshing(false);
                progressBar.setVisibility(View.GONE);
                Toast.makeText(getContext(), "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_SHORT).show();
                showEmptyState();
            }
        });
    }

    private boolean isHistory(String status) {
        if (status == null) return false;
        String s = status.toLowerCase().trim();
        return s.equals("completed") || s.equals("delivered") || s.equals("cancelled") || s.equals("rejected");
    }

    private void showEmptyState() {
        rvHistoryOrders.setVisibility(View.GONE);
        scrollViewEmpty.setVisibility(View.VISIBLE);
        loadRecommendations();
    }

    private void showHistoryList() {
        scrollViewEmpty.setVisibility(View.GONE);
        rvHistoryOrders.setVisibility(View.VISIBLE);
    }

    private void loadRecommendations() {
        apiService.getProducts(null, null).enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(@NonNull Call<List<Product>> call, @NonNull Response<List<Product>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    List<Product> products = response.body();
                    List<Product> suggestions = new ArrayList<>();
                    // Lấy tối đa 10 sản phẩm đầu tiên để gợi ý
                    for (int i = 0; i < Math.min(10, products.size()); i++) {
                        suggestions.add(products.get(i));
                    }
                    recommendAdapter = new RecommendProductAdapter(suggestions);
                    rvRecommendations.setAdapter(recommendAdapter);
                }
            }

            @Override
            public void onFailure(@NonNull Call<List<Product>> call, @NonNull Throwable t) {
                // Không hiển thị lỗi cho người dùng ở phần gợi ý
            }
        });
    }
}

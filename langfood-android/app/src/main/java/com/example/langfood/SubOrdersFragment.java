package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
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
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SubOrdersFragment extends Fragment implements SellerOrderAdapter.OnOrderActionListener {

    private static final String ARG_ORDER_TYPE = "order_type";
    
    public static final String TYPE_PENDING = "Pending";
    public static final String TYPE_PREPARING = "Preparing";
    public static final String TYPE_HISTORY = "History";

    private String orderType;
    private int shopId;
    private ApiService apiService;

    // Views
    private SwipeRefreshLayout swipeRefresh;
    private RecyclerView rvOrders;
    private View layoutEmpty;
    private TextView tvEmptyText;

    private List<Order> allOrders = new ArrayList<>();
    private List<Order> filteredOrders = new ArrayList<>();
    private SellerOrderAdapter adapter;

    public static SubOrdersFragment newInstance(String orderType) {
        SubOrdersFragment fragment = new SubOrdersFragment();
        Bundle args = new Bundle();
        args.putString(ARG_ORDER_TYPE, orderType);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            orderType = getArguments().getString(ARG_ORDER_TYPE);
        }
        SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        shopId = prefs.getInt("SHOP_ID", -1);
        apiService = ApiClient.getClient().create(ApiService.class);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_sub_orders, container, false);
        
        swipeRefresh = view.findViewById(R.id.swipeRefresh);
        rvOrders = view.findViewById(R.id.rvSubOrders);
        layoutEmpty = view.findViewById(R.id.layoutEmpty);
        tvEmptyText = view.findViewById(R.id.tvEmptyText);

        adapter = new SellerOrderAdapter(requireContext(), filteredOrders, this);
        rvOrders.setLayoutManager(new LinearLayoutManager(requireContext()));
        rvOrders.setAdapter(adapter);

        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::loadOrders);

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        loadOrders();
    }

    public void loadOrders() {
        if (shopId == -1) {
            if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
            return;
        }

        apiService.getOrdersByShop(shopId).enqueue(new Callback<List<Order>>() {
            @Override
            public void onResponse(Call<List<Order>> call, Response<List<Order>> response) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    allOrders.clear();
                    allOrders.addAll(response.body());
                    applyFilter();
                }
            }

            @Override
            public void onFailure(Call<List<Order>> call, Throwable t) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                Toast.makeText(getContext(), "Lỗi kết nối khi tải đơn hàng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void applyFilter() {
        filteredOrders.clear();
        for (Order order : allOrders) {
            String status = order.getStatus();
            if (TYPE_PENDING.equals(orderType)) {
                if ("Pending".equalsIgnoreCase(status)) {
                    filteredOrders.add(order);
                }
            } else if (TYPE_PREPARING.equals(orderType)) {
                if ("Preparing".equalsIgnoreCase(status)) {
                    filteredOrders.add(order);
                }
            } else { // History
                if (!"Pending".equalsIgnoreCase(status) && !"Preparing".equalsIgnoreCase(status)) {
                    filteredOrders.add(order);
                }
            }
        }

        adapter.notifyDataSetChanged();

        if (filteredOrders.isEmpty()) {
            rvOrders.setVisibility(View.GONE);
            layoutEmpty.setVisibility(View.VISIBLE);
            if (TYPE_PENDING.equals(orderType)) {
                tvEmptyText.setText("Không có đơn hàng mới nào!");
            } else if (TYPE_PREPARING.equals(orderType)) {
                tvEmptyText.setText("Hiện tại không có đơn đang chế biến!");
            } else {
                tvEmptyText.setText("Lịch sử đơn hàng trống!");
            }
        } else {
            rvOrders.setVisibility(View.VISIBLE);
            layoutEmpty.setVisibility(View.GONE);
        }
    }

    @Override
    public void onConfirm(Order order) {
        apiService.shopAcceptOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(getContext(), "Đã chấp nhận đơn #" + order.getId() + ". Bắt đầu chuẩn bị!", Toast.LENGTH_SHORT).show();
                    loadOrders();
                    
                    // Phát thông báo cập nhật sang fragment khác nếu cần
                    if (getParentFragment() instanceof SellerOrdersFragment) {
                        ((SellerOrdersFragment) getParentFragment()).refreshAllTabs();
                    }
                } else {
                    Toast.makeText(getContext(), "Lỗi chấp nhận đơn", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(getContext(), "Lỗi mạng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onReady(Order order) {
        apiService.shopReadyOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(getContext(), "Đơn hàng #" + order.getId() + " đã chuẩn bị xong!", Toast.LENGTH_SHORT).show();
                    loadOrders();
                    
                    if (getParentFragment() instanceof SellerOrdersFragment) {
                        ((SellerOrdersFragment) getParentFragment()).refreshAllTabs();
                    }
                } else {
                    Toast.makeText(getContext(), "Lỗi cập nhật đơn hàng", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(getContext(), "Lỗi mạng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onCancel(Order order) {
        apiService.shopCancelOrder(order.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(getContext(), "Đã hủy đơn #" + order.getId(), Toast.LENGTH_SHORT).show();
                    loadOrders();
                    
                    if (getParentFragment() instanceof SellerOrdersFragment) {
                        ((SellerOrdersFragment) getParentFragment()).refreshAllTabs();
                    }
                } else {
                    Toast.makeText(getContext(), "Lỗi hủy đơn hàng", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(getContext(), "Lỗi kết nối mạng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onItemClick(Order order) {
        Intent intent = new Intent(requireActivity(), OrderDetailShipperActivity.class);
        intent.putExtra("ORDER_DATA", new Gson().toJson(order));
        intent.putExtra("IS_PREVIEW", true);
        intent.putExtra("IS_SELLER_VIEW", true);
        startActivity(intent);
    }
}

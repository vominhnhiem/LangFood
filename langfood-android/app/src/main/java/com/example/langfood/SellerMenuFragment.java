package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Product;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SellerMenuFragment extends Fragment implements SellerMenuAdapter.OnProductActionListener {

    private int shopId;
    private ApiService apiService;

    // Views
    private SwipeRefreshLayout swipeRefresh;
    private RecyclerView rvMenu;
    private EditText etSearch;
    private View layoutEmpty;
    private FloatingActionButton fabAddFood;

    // Data
    private List<Product> allProducts = new ArrayList<>();
    private List<Product> filteredProducts = new ArrayList<>();
    private SellerMenuAdapter adapter;
    private String currentQuery = "";

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        shopId = prefs.getInt("SHOP_ID", -1);
        apiService = ApiClient.getClient().create(ApiService.class);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_seller_menu, container, false);

        swipeRefresh = view.findViewById(R.id.swipeRefreshMenu);
        rvMenu = view.findViewById(R.id.rvSellerMenu);
        etSearch = view.findViewById(R.id.etSearchMenu);
        layoutEmpty = view.findViewById(R.id.layoutEmptyMenu);
        fabAddFood = view.findViewById(R.id.fabAddFood);

        adapter = new SellerMenuAdapter(requireContext(), filteredProducts, this);
        rvMenu.setLayoutManager(new LinearLayoutManager(requireContext()));
        rvMenu.setAdapter(adapter);

        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::loadMenu);

        setupListeners();

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        loadMenu();
    }

    private void setupListeners() {
        etSearch.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentQuery = s.toString().trim().toLowerCase();
                applyFilter();
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        fabAddFood.setOnClickListener(v -> {
            Intent intent = new Intent(requireActivity(), AddFoodActivity.class);
            startActivity(intent);
        });
    }

    private void loadMenu() {
        if (shopId == -1) {
            if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
            return;
        }

        apiService.getProductsByShop(shopId).enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    allProducts.clear();
                    allProducts.addAll(response.body());
                    applyFilter();
                }
            }

            @Override
            public void onFailure(Call<List<Product>> call, Throwable t) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                Toast.makeText(getContext(), "Lỗi tải thực đơn", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void applyFilter() {
        filteredProducts.clear();
        for (Product p : allProducts) {
            boolean matchesSearch = currentQuery.isEmpty() || 
                    p.getName().toLowerCase().contains(currentQuery) || 
                    (p.getDescription() != null && p.getDescription().toLowerCase().contains(currentQuery));
            if (matchesSearch) {
                filteredProducts.add(p);
            }
        }

        adapter.notifyDataSetChanged();

        if (filteredProducts.isEmpty()) {
            rvMenu.setVisibility(View.GONE);
            layoutEmpty.setVisibility(View.VISIBLE);
        } else {
            rvMenu.setVisibility(View.VISIBLE);
            layoutEmpty.setVisibility(View.GONE);
        }
    }

    @Override
    public void onToggleAvailability(Product product, boolean isAvailable) {
        apiService.toggleProductAvailability(product.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    product.setAvailable(isAvailable);
                    String statusText = isAvailable ? "Còn hàng" : "Hết hàng";
                    Toast.makeText(getContext(), "Đã chuyển '" + product.getName() + "' sang: " + statusText, Toast.LENGTH_SHORT).show();
                } else {
                    Toast.makeText(getContext(), "Lỗi cập nhật trạng thái món ăn", Toast.LENGTH_SHORT).show();
                    loadMenu(); // Reload to sync UI state
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(getContext(), "Lỗi kết nối", Toast.LENGTH_SHORT).show();
                loadMenu(); // Reload to sync UI state
            }
        });
    }
}

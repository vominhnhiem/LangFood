package com.example.langfood;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.widget.EditText;
import android.widget.Toast;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Category;
import com.example.langfood.models.Product;
import java.util.ArrayList;
import java.util.List;
import androidx.viewpager2.widget.ViewPager2;
import android.os.Handler;
import android.os.Looper;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class HomeActivity extends AppCompatActivity {

    private RecyclerView rcvProducts, rcvCategories;
    private ProductAdapter productAdapter;
    private CategoryHomeAdapter categoryAdapter;
    private List<Product> allProducts = new ArrayList<>(); 
    private List<Product> filteredList = new ArrayList<>(); 
    private List<Category> categoryList = new ArrayList<>();
    private EditText editSearch;
    private ApiService apiService;
    private int selectedCategoryId = -1; 
    private SwipeRefreshLayout swipeRefreshLayout;

    private ViewPager2 vpBanners;
    private Handler bannerHandler = new Handler(Looper.getMainLooper());
    private Runnable bannerRunnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_home);

        apiService = ApiClient.getClient().create(ApiService.class);
        CartManager.getInstance().init(this);

        // Xử lý Insets để tránh bị Status Bar (icon pin, sóng) đè lên Header
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            
            // Chỉ Padding Bottom cho thanh điều hướng dưới cùng
            v.setPadding(systemBars.left, 0, systemBars.right, systemBars.bottom);
            
            // Đẩy riêng phần NỘI DUNG của Header xuống dưới Status Bar
            android.view.View header = findViewById(R.id.headerContent);
            if (header != null) {
                header.setPadding(header.getPaddingLeft(), systemBars.top, header.getPaddingRight(), header.getPaddingBottom());
            }
            
            return WindowInsetsCompat.CONSUMED;
        });

        initViews();
        setupRecyclerViews();
        setupSwipeRefresh();
        loadCategories();
        fetchAllProducts(); 
        setupNavigation();
        setupSearch();
        setupBanners();
    }

    private void initViews() {
        rcvProducts = findViewById(R.id.rv_recommend);
        rcvCategories = findViewById(R.id.rv_categories);
        editSearch = findViewById(R.id.et_search);
        swipeRefreshLayout = findViewById(R.id.swipeRefreshLayout);
    }

    private void setupSwipeRefresh() {
        swipeRefreshLayout.setColorSchemeResources(R.color.shopee_orange);
        swipeRefreshLayout.setOnRefreshListener(() -> {
            loadCategories();
            fetchAllProducts();
        });
    }

    private void setupRecyclerViews() {
        // 1. Categories
        categoryAdapter = new CategoryHomeAdapter(categoryList, category -> {
            selectedCategoryId = category.getId();
            applyFilters();
        });
        rcvCategories.setLayoutManager(new androidx.recyclerview.widget.GridLayoutManager(this, 2, androidx.recyclerview.widget.GridLayoutManager.HORIZONTAL, false));
        rcvCategories.setAdapter(categoryAdapter);

        // 2. Recommendations (Grid)
        productAdapter = new ProductAdapter(filteredList);
        rcvProducts.setLayoutManager(new androidx.recyclerview.widget.GridLayoutManager(this, 2));
        rcvProducts.setAdapter(productAdapter);
    }

    private void loadCategories() {
        apiService.getCategories().enqueue(new Callback<List<Category>>() {
            @Override
            public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    categoryList.clear();
                    categoryList.add(new Category(-1, "Tất cả"));
                    categoryList.addAll(response.body());
                    categoryAdapter.updateData(categoryList);
                    
                    if (productAdapter != null) productAdapter.setCategories(categoryList);
                }
            }
            @Override
            public void onFailure(Call<List<Category>> call, Throwable t) {}
        });
    }

    private void fetchAllProducts() {
        apiService.getProducts(null).enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                if (swipeRefreshLayout.isRefreshing()) {
                    swipeRefreshLayout.setRefreshing(false);
                }
                if (response.isSuccessful() && response.body() != null) {
                    allProducts.clear();
                    allProducts.addAll(response.body());
                    applyFilters(); 
                }
            }
            @Override
            public void onFailure(Call<List<Product>> call, Throwable t) {
                if (swipeRefreshLayout.isRefreshing()) {
                    swipeRefreshLayout.setRefreshing(false);
                }
                Toast.makeText(HomeActivity.this, "Lỗi tải dữ liệu", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupSearch() {
        editSearch.addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override public void onTextChanged(CharSequence s, int start, int before, int count) { applyFilters(); }
            @Override public void afterTextChanged(Editable s) {}
        });
    }

    private void applyFilters() {
        filteredList.clear();
        String searchQuery = editSearch.getText().toString().toLowerCase().trim();
        for (Product p : allProducts) {
            boolean matchesCategory = (selectedCategoryId == -1) || (p.getCategoryId() == selectedCategoryId);
            boolean matchesSearch = searchQuery.isEmpty() || p.getName().toLowerCase().contains(searchQuery);
            if (matchesCategory && matchesSearch) filteredList.add(p);
        }
        productAdapter.notifyDataSetChanged();
    }

    private void setupNavigation() {
        findViewById(R.id.iv_profile).setOnClickListener(v -> startActivity(new Intent(this, ProfileActivity.class)));
        findViewById(R.id.iv_cart).setOnClickListener(v -> startActivity(new Intent(this, CartActivity.class)));
        findViewById(R.id.btnNavOrder).setOnClickListener(v -> startActivity(new Intent(this, HistoryActivity.class)));
        findViewById(R.id.btnNavSupport).setOnClickListener(v -> startActivity(new Intent(this, ProfileActivity.class)));
    }

    private void setupBanners() {
        vpBanners = findViewById(R.id.vp_banners);
        List<Integer> banners = new ArrayList<>();
        banners.add(R.drawable.banner_khu_b);
        banners.add(R.drawable.banner_khu_b_2);
        BannerAdapter adapter = new BannerAdapter(banners);
        vpBanners.setAdapter(adapter);

        bannerRunnable = new Runnable() {
            @Override public void run() {
                if (vpBanners != null && banners.size() > 0) {
                    int nextItem = (vpBanners.getCurrentItem() + 1) % banners.size();
                    vpBanners.setCurrentItem(nextItem, true);
                    bannerHandler.postDelayed(this, 3000);
                }
            }
        };
    }

    @Override protected void onResume() { 
        super.onResume(); 
        fetchAllProducts(); 
        bannerHandler.postDelayed(bannerRunnable, 3000); 
    }
    
    @Override protected void onPause() { 
        super.onPause(); 
        bannerHandler.removeCallbacks(bannerRunnable); 
    }
}

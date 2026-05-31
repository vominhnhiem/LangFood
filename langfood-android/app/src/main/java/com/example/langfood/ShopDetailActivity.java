package com.example.langfood;

import android.graphics.Color;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Product;
import com.example.langfood.models.Shop;
import com.google.android.material.appbar.CollapsingToolbarLayout;
import com.google.android.material.tabs.TabLayout;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ShopDetailActivity extends AppCompatActivity {

    private int shopId;
    private ApiService apiService;

    // Views
    private ImageView ivShopCover;
    private de.hdodenhof.circleimageview.CircleImageView ivShopAvatar;
    private TextView tvShopName, tvShopStatus, tvShopRating, tvShopDelivery;
    private CollapsingToolbarLayout collapsingToolbar;
    private Toolbar toolbar;
    private EditText etSearchFood;
    private ImageView btnClearSearch;
    private TabLayout tabCategories;
    private RecyclerView rvFoods;
    private View layoutEmpty;

    // Data lists
    private List<Product> allProducts = new ArrayList<>();
    private List<Product> filteredProducts = new ArrayList<>();
    private ShopProductAdapter adapter;

    // Filter state
    private int currentCategoryId = -1; // -1 means "Tất cả" (All)
    private String currentSearchQuery = "";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shop_detail);

        shopId = getIntent().getIntExtra("SHOP_ID", -1);
        if (shopId == -1) {
            Toast.makeText(this, "Không tìm thấy quán ăn này!", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        apiService = ApiClient.getClient().create(ApiService.class);
        initViews();
        setupListeners();
        
        loadShopInfo();
        loadShopProducts();
    }

    private void initViews() {
        ivShopCover = findViewById(R.id.ivShopCover);
        ivShopAvatar = findViewById(R.id.ivShopAvatar);
        tvShopName = findViewById(R.id.tvShopName);
        tvShopStatus = findViewById(R.id.tvShopStatus);
        tvShopRating = findViewById(R.id.tvShopRating);
        tvShopDelivery = findViewById(R.id.tvShopDelivery);
        collapsingToolbar = findViewById(R.id.collapsingToolbar);
        toolbar = findViewById(R.id.toolbar);
        etSearchFood = findViewById(R.id.etSearchFood);
        btnClearSearch = findViewById(R.id.btnClearSearch);
        tabCategories = findViewById(R.id.tabCategories);
        rvFoods = findViewById(R.id.rvFoods);
        layoutEmpty = findViewById(R.id.layoutEmpty);

        // Setup Toolbar
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle("");
        }
        toolbar.setNavigationOnClickListener(v -> finish());

        // Setup collapsing toolbar title styling
        collapsingToolbar.setExpandedTitleColor(Color.TRANSPARENT); // Hide title when expanded
        collapsingToolbar.setCollapsedTitleTextColor(Color.WHITE);

        // Setup RecyclerView
        adapter = new ShopProductAdapter(filteredProducts);
        rvFoods.setLayoutManager(new LinearLayoutManager(this));
        rvFoods.setAdapter(adapter);
    }

    private void setupListeners() {
        // Search clear button
        btnClearSearch.setOnClickListener(v -> {
            etSearchFood.setText("");
            currentSearchQuery = "";
            applyFilters();
        });

        // Search text watcher
        etSearchFood.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                currentSearchQuery = s.toString().trim().toLowerCase();
                btnClearSearch.setVisibility(currentSearchQuery.isEmpty() ? View.GONE : View.VISIBLE);
                applyFilters();
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        // TabLayout Selection
        tabCategories.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                if (tab.getTag() != null) {
                    currentCategoryId = (int) tab.getTag();
                    applyFilters();
                }
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {}

            @Override
            public void onTabReselected(TabLayout.Tab tab) {}
        });
    }

    private void loadShopInfo() {
        apiService.getShopById(shopId).enqueue(new Callback<Shop>() {
            @Override
            public void onResponse(Call<Shop> call, Response<Shop> response) {
                if (response.isSuccessful() && response.body() != null) {
                    Shop shop = response.body();
                    displayShopHeader(shop);
                } else {
                    Toast.makeText(ShopDetailActivity.this, "Không thể tải thông tin quán ăn", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Shop> call, Throwable t) {
                Toast.makeText(ShopDetailActivity.this, "Lỗi kết nối máy chủ", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void displayShopHeader(Shop shop) {
        tvShopName.setText(shop.getName());
        collapsingToolbar.setTitle(shop.getName());

        if (shop.isOpen()) {
            tvShopStatus.setText("ĐANG MỞ CỬA");
            tvShopStatus.setBackgroundResource(R.drawable.bg_circle_active);
            tvShopStatus.setBackgroundColor(Color.parseColor("#4CAF50"));
        } else {
            tvShopStatus.setText("QUÁN TẠM NGHỈ");
            tvShopStatus.setBackgroundResource(R.drawable.bg_circle_active);
            tvShopStatus.setBackgroundColor(Color.parseColor("#E53935"));
        }

        // Ratings (Mock values standard for visual details)
        tvShopRating.setText("4.8 (100+ đánh giá)");
        tvShopDelivery.setText("Giao tới sảnh KTX");

        String imageUrl = shop.getImageUrl();
        if (imageUrl != null && !imageUrl.isEmpty()) {
            String fullImageUrl = imageUrl.startsWith("http") ? imageUrl : ApiClient.BASE_URL + (imageUrl.startsWith("/") ? imageUrl.substring(1) : imageUrl);
            
            Glide.with(this)
                    .load(fullImageUrl)
                    .placeholder(R.drawable.ga)
                    .error(R.drawable.ga)
                    .into(ivShopCover);

            Glide.with(this)
                    .load(fullImageUrl)
                    .placeholder(R.drawable.anhavt)
                    .error(R.drawable.anhavt)
                    .into(ivShopAvatar);
        }
    }

    private void loadShopProducts() {
        apiService.getProductsByShop(shopId).enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    allProducts.clear();
                    
                    // Lọc chỉ lấy các món đã được approved (Status == 1) và còn kinh doanh (IsAvailable)
                    for (Product p : response.body()) {
                        if (p.getStatus() == 1 && p.isAvailable()) {
                            allProducts.add(p);
                        }
                    }

                    setupCategoryTabs();
                    applyFilters();
                }
            }

            @Override
            public void onFailure(Call<List<Product>> call, Throwable t) {
                Toast.makeText(ShopDetailActivity.this, "Lỗi tải thực đơn", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupCategoryTabs() {
        tabCategories.removeAllTabs();

        // 1. Thêm tab "Tất cả"
        TabLayout.Tab allTab = tabCategories.newTab().setText("Tất cả").setTag(-1);
        tabCategories.addTab(allTab);

        // 2. Gom nhóm các Category duy nhất từ danh sách món ăn
        Map<Integer, String> uniqueCategories = new HashMap<>();
        for (Product product : allProducts) {
            int catId = product.getCategoryId();
            String catName = product.getCategoryName();
            if (catName == null || catName.isEmpty()) {
                catName = "Danh mục khác";
            }
            uniqueCategories.put(catId, catName);
        }

        // 3. Đưa danh sách category thu được lên TabLayout
        for (Map.Entry<Integer, String> entry : uniqueCategories.entrySet()) {
            TabLayout.Tab tab = tabCategories.newTab()
                    .setText(entry.getValue())
                    .setTag(entry.getKey());
            tabCategories.addTab(tab);
        }
    }

    private void applyFilters() {
        filteredProducts.clear();

        for (Product product : allProducts) {
            // Lọc theo Category
            boolean matchesCategory = (currentCategoryId == -1 || product.getCategoryId() == currentCategoryId);

            // Lọc theo Search Query
            boolean matchesSearch = (currentSearchQuery.isEmpty() ||
                    product.getName().toLowerCase().contains(currentSearchQuery) ||
                    (product.getDescription() != null && product.getDescription().toLowerCase().contains(currentSearchQuery)));

            if (matchesCategory && matchesSearch) {
                filteredProducts.add(product);
            }
        }

        adapter.notifyDataSetChanged();

        if (filteredProducts.isEmpty()) {
            rvFoods.setVisibility(View.GONE);
            layoutEmpty.setVisibility(View.VISIBLE);
        } else {
            rvFoods.setVisibility(View.VISIBLE);
            layoutEmpty.setVisibility(View.GONE);
        }
    }
}

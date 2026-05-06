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
    private List<Product> allProducts = new ArrayList<>(); // Giữ toàn bộ data gốc
    private List<Product> filteredList = new ArrayList<>(); // Data đang hiển thị
    private List<Category> categoryList = new ArrayList<>();
    private EditText editSearch;
    private ApiService apiService;
    private int selectedCategoryId = -1; // -1 nghĩa là xem tất cả

    // Auto-sliding Banner
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

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        initViews();
        setupRecyclerViews();
        loadCategories();
        fetchAllProducts(); // Luôn tải tất cả về để tự lọc
        setupNavigation();
        setupSearch();
        setupBanners();
    }

    private void initViews() {
        rcvProducts = findViewById(R.id.rv_recommend);
        rcvCategories = findViewById(R.id.rv_categories);
        editSearch = findViewById(R.id.et_search);
    }

    private void setupRecyclerViews() {
        // 1. Danh mục dạng lưới 2 hàng (5 cột mỗi hàng)
        categoryAdapter = new CategoryHomeAdapter(categoryList, category -> {
            selectedCategoryId = category.getId();
            applyFilters();
            Toast.makeText(this, "Đang xem: " + category.getName(), Toast.LENGTH_SHORT).show();
        });
        rcvCategories.setLayoutManager(new androidx.recyclerview.widget.GridLayoutManager(this, 2, androidx.recyclerview.widget.GridLayoutManager.HORIZONTAL, false));
        rcvCategories.setAdapter(categoryAdapter);

        // 2. Danh sách món ăn gợi ý (Gợi ý hôm nay) - Dạng lưới 2 cột dọc
        productAdapter = new ProductAdapter(filteredList);
        rcvProducts.setLayoutManager(new androidx.recyclerview.widget.GridLayoutManager(this, 2));
        rcvProducts.setAdapter(productAdapter);
        
        // 3. Flash Sale (Best Seller cũ) - Dạng ngang
        RecyclerView rvFlashSale = findViewById(R.id.rv_best_seller);
        ProductAdapter flashSaleAdapter = new ProductAdapter(allProducts); // Dùng tạm data allProducts
        rvFlashSale.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        rvFlashSale.setAdapter(flashSaleAdapter);
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
                if (response.isSuccessful() && response.body() != null) {
                    allProducts.clear();
                    allProducts.addAll(response.body());
                    applyFilters(); // Hiển thị dữ liệu lần đầu
                }
            }
            @Override
            public void onFailure(Call<List<Product>> call, Throwable t) {
                Toast.makeText(HomeActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupSearch() {
        editSearch.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                applyFilters();
            }
            @Override
            public void afterTextChanged(Editable s) {}
        });
    }

    // HÀM LỌC CHÍNH (Kết hợp cả Category và Search)
    private void applyFilters() {
        filteredList.clear();
        String searchQuery = editSearch.getText().toString().toLowerCase().trim();

        for (Product p : allProducts) {
            // 1. Kiểm tra Category
            boolean matchesCategory = (selectedCategoryId == -1) || (p.getCategoryId() == selectedCategoryId);
            
            // 2. Kiểm tra Search
            boolean matchesSearch = searchQuery.isEmpty() || 
                                   p.getName().toLowerCase().contains(searchQuery) ||
                                   (p.getDescription() != null && p.getDescription().toLowerCase().contains(searchQuery));

            if (matchesCategory && matchesSearch) {
                filteredList.add(p);
            }
        }
        productAdapter.notifyDataSetChanged();
    }

    private void setupNavigation() {
        findViewById(R.id.iv_profile).setOnClickListener(v -> startActivity(new Intent(this, ProfileActivity.class)));
        findViewById(R.id.iv_cart).setOnClickListener(v -> startActivity(new Intent(this, CartActivity.class)));
        findViewById(R.id.btnNavOrder).setOnClickListener(v -> startActivity(new Intent(this, HistoryActivity.class)));
        findViewById(R.id.btnNavSupport).setOnClickListener(v -> startActivity(new Intent(this, ProfileActivity.class))); // "Tôi" -> Profile
    }

    private void setupBanners() {
        vpBanners = findViewById(R.id.vp_banners);
        List<Integer> banners = new ArrayList<>();
        banners.add(R.drawable.banner_khu_b);
        banners.add(R.drawable.banner_khu_b_2);

        BannerAdapter adapter = new BannerAdapter(banners);
        vpBanners.setAdapter(adapter);

        bannerRunnable = new Runnable() {
            @Override
            public void run() {
                int currentItem = vpBanners.getCurrentItem();
                int nextItem = (currentItem + 1) % banners.size();
                vpBanners.setCurrentItem(nextItem, true);
                bannerHandler.postDelayed(this, 3000); // 3 giây chuyển 1 lần
            }
        };
    }

    @Override
    protected void onResume() {
        super.onResume();
        fetchAllProducts(); // Cập nhật lại khi quay lại từ màn hình khác
        bannerHandler.postDelayed(bannerRunnable, 3000);
    }

    @Override
    protected void onPause() {
        super.onPause();
        bannerHandler.removeCallbacks(bannerRunnable);
    }
}

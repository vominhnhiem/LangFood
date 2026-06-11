package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Product;
import com.example.langfood.models.ProductOption;
import com.example.langfood.models.ProductOptionGroup;
import com.example.langfood.models.Shop;
import com.example.langfood.models.User;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class FoodDetailActivity extends AppCompatActivity implements OptionAdapter.OnOptionSelectedListener {

    private ImageView imgFood, btnBack, ivSellerAvatar, btnMinus, btnPlus;
    private TextView txtFoodName, txtFoodPrice, txtFoodDescription, tvSellerName, tvQuantity;
    private Button btnAddToCart;
    private EditText etNote;
    private RecyclerView rvOptionGroups;
    private OptionGroupAdapter groupAdapter;
    
    private Product currentProduct;
    private Shop currentShop;
    private int quantity = 1;
    private ApiService apiService;
    private int userRoleId; 
    private String mSellerId; // Lưu sellerId để dùng cho intent

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_food_detail);

        apiService = ApiClient.getClient().create(ApiService.class);
        
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        userRoleId = prefs.getInt("ROLE_ID", 1); 

        initViews();
        
        int productId = getIntent().getIntExtra("PRODUCT_ID", -1);
        if (productId != -1) {
            loadProductDetail(productId);
        } else {
            finish();
        }
        
        btnBack.setOnClickListener(v -> finish());
        
        btnPlus.setOnClickListener(v -> {
            quantity++;
            updateQuantityUI();
        });

        btnMinus.setOnClickListener(v -> {
            if (quantity > 1) {
                quantity--;
                updateQuantityUI();
            }
        });

        btnAddToCart.setOnClickListener(v -> {
            if (userRoleId == 2 || userRoleId == 3) {
                String roleName = (userRoleId == 2) ? "Người bán" : "Người giao hàng";
                Toast.makeText(this, "Tài khoản " + roleName + " không thể đặt đơn hàng!", Toast.LENGTH_SHORT).show();
                return;
            }

            if (currentProduct != null) {
                String note = etNote.getText().toString().trim();
                List<Integer> selectedOptionIds = new ArrayList<>();
                if (currentProduct.getOptionGroups() != null) {
                    for (ProductOptionGroup group : currentProduct.getOptionGroups()) {
                        for (ProductOption option : group.getOptions()) {
                            if (option.isSelected()) {
                                selectedOptionIds.add(option.getId());
                            }
                        }
                    }
                }
                String optionsJson = new Gson().toJson(selectedOptionIds);
                
                CartManager.getInstance().addToCart(currentProduct, quantity, note, optionsJson);
                Toast.makeText(this, "Đã thêm vào giỏ hàng!", Toast.LENGTH_SHORT).show();
                finish();
            }
        });

        findViewById(R.id.cardSeller).setOnClickListener(v -> {
            if (mSellerId != null && !mSellerId.isEmpty()) {
                Intent intent = new Intent(this, SellerStoreActivity.class);
                intent.putExtra("SELLER_ID", mSellerId);
                startActivity(intent);
            } else {
                Toast.makeText(this, "Không tìm thấy thông tin người bán", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void initViews() {
        imgFood = findViewById(R.id.imgFood);
        txtFoodName = findViewById(R.id.txtFoodName);
        txtFoodPrice = findViewById(R.id.txtFoodPrice);
        txtFoodDescription = findViewById(R.id.txtFoodDescription);
        btnAddToCart = findViewById(R.id.btnAddToCart);
        btnBack = findViewById(R.id.btnBack);
        tvSellerName = findViewById(R.id.tvSellerName);
        ivSellerAvatar = findViewById(R.id.ivSellerAvatar);
        
        btnMinus = findViewById(R.id.btnMinus);
        btnPlus = findViewById(R.id.btnPlus);
        tvQuantity = findViewById(R.id.tvQuantity);
        etNote = findViewById(R.id.etNote);
        rvOptionGroups = findViewById(R.id.rvOptionGroups);
        
        rvOptionGroups.setLayoutManager(new LinearLayoutManager(this));
    }

    private void loadProductDetail(int productId) {
        apiService.getProductById(productId).enqueue(new Callback<Product>() {
            @Override
            public void onResponse(Call<Product> call, Response<Product> response) {
                if (response.isSuccessful() && response.body() != null) {
                    currentProduct = response.body();
                    displayData();
                }
            }
            @Override
            public void onFailure(Call<Product> call, Throwable t) {
                Toast.makeText(FoodDetailActivity.this, "Không thể tải chi tiết món ăn", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void displayData() {
        txtFoodName.setText(currentProduct.getName());
        txtFoodDescription.setText(currentProduct.getDescription());
        txtFoodPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", currentProduct.getPrice()));
        
        // Hiển thị tên tạm thời từ Product
        tvSellerName.setText(stripOwnerName(currentProduct.getShopName()));
        
        Glide.with(this)
                .load(ApiClient.BASE_URL + currentProduct.getImageUrl())
                .placeholder(R.drawable.lang_food_avt)
                .into(imgFood);

        if (currentProduct.getOptionGroups() != null) {
            groupAdapter = new OptionGroupAdapter(currentProduct.getOptionGroups(), this);
            rvOptionGroups.setAdapter(groupAdapter);
        }

        // Lấy sellerId: Ưu tiên từ Product trả về, fallback là Intent
        mSellerId = currentProduct.getSellerId();
        if (mSellerId == null || mSellerId.isEmpty()) {
            mSellerId = getIntent().getStringExtra("SELLER_ID");
        }

        if (mSellerId != null && !mSellerId.isEmpty()) {
            loadShopInfo(mSellerId);
        } else {
            Log.e("FoodDetail", "SellerId is null, check Product model alternates or Backend response");
        }
        updateQuantityUI();
    }

    private void loadShopInfo(String sellerId) {
        apiService.getShopByUserId(sellerId).enqueue(new Callback<Shop>() {
            @Override
            public void onResponse(Call<Shop> call, Response<Shop> response) {
                if (response.isSuccessful() && response.body() != null) {
                    currentShop = response.body();
                    
                    // Ghi đè tên shop thật từ database
                    if (currentShop.getName() != null && !currentShop.getName().isEmpty()) {
                        tvSellerName.setText(stripOwnerName(currentShop.getName()));
                    }
                    
                    // Cập nhật ảnh đại diện shop
                    if (currentShop.getImageUrl() != null && !currentShop.getImageUrl().isEmpty()) {
                        String imageUrl = currentShop.getImageUrl();
                        String fullUrl = imageUrl.startsWith("http") ? imageUrl : ApiClient.BASE_URL + (imageUrl.startsWith("/") ? imageUrl.substring(1) : imageUrl);
                        
                        Glide.with(FoodDetailActivity.this)
                                .load(fullUrl)
                                .placeholder(R.drawable.anhavt)
                                .error(R.drawable.anhavt)
                                .into(ivSellerAvatar);
                    }
                    calculateTotalPrice();
                } else {
                    Log.e("FoodDetail", "Load shop info failed code: " + response.code());
                }
            }
            @Override 
            public void onFailure(Call<Shop> call, Throwable t) {
                Log.e("FoodDetail", "Load shop info error: " + t.getMessage());
            }
        });
    }

    private String stripOwnerName(String name) {
        if (name == null) return "";
        return name.replaceAll("\\s*\\(Chủ:.*\\)", "").trim();
    }

    private void updateQuantityUI() {
        tvQuantity.setText(String.valueOf(quantity));
        calculateTotalPrice();
    }

    @Override
    public void onOptionChanged() {
        calculateTotalPrice();
    }

    private void calculateTotalPrice() {
        if (currentProduct == null) return;

        double totalPerItem = currentProduct.getPrice();
        if (currentProduct.getOptionGroups() != null) {
            for (ProductOptionGroup group : currentProduct.getOptionGroups()) {
                for (ProductOption option : group.getOptions()) {
                    if (option.isSelected()) {
                        totalPerItem += option.getAdditionalPrice();
                    }
                }
            }
        }

        double finalTotal = totalPerItem * quantity;

        if (userRoleId == 2 || userRoleId == 3) {
            btnAddToCart.setEnabled(false);
            btnAddToCart.setBackgroundTintList(android.content.res.ColorStateList.valueOf(android.graphics.Color.GRAY));
            btnAddToCart.setText("Chỉ dành cho Khách hàng");
        } else if (currentShop != null && !currentShop.isOpen()) {
            btnAddToCart.setEnabled(false);
            btnAddToCart.setBackgroundTintList(android.content.res.ColorStateList.valueOf(android.graphics.Color.GRAY));
            btnAddToCart.setText("Quán đang tạm nghỉ");
        } else {
            btnAddToCart.setEnabled(true);
            btnAddToCart.setBackgroundTintList(android.content.res.ColorStateList.valueOf(android.graphics.Color.parseColor("#FF5722")));
            btnAddToCart.setText(String.format(Locale.getDefault(), "THÊM VÀO GIỎ - %,.0fđ", finalTotal));
        }
    }
}

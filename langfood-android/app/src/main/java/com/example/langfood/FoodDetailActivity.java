package com.example.langfood;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Product;
import com.example.langfood.models.User;
import java.util.Locale;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class FoodDetailActivity extends AppCompatActivity {

    private ImageView imgFood, btnBack, ivSellerAvatar;
    private TextView txtFoodName, txtFoodPrice, txtFoodDescription, tvSellerName;
    private Button btnAddToCart;
    private Product currentProduct;
    private static final String BASE_URL = "http://192.168.100.192:5289/";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_food_detail);

        initViews();
        displayProductDetails();
        
        btnBack.setOnClickListener(v -> finish());
        
        btnAddToCart.setOnClickListener(v -> {
            if (currentProduct != null) {
                CartManager.getInstance().addToCart(currentProduct, 1);
                Toast.makeText(this, "Đã thêm " + currentProduct.getName() + " vào giỏ hàng!", Toast.LENGTH_SHORT).show();
            }
        });

        findViewById(R.id.cardSeller).setOnClickListener(v -> {
            if (currentProduct != null && currentProduct.getSellerId() != null) {
                Intent intent = new Intent(this, SellerStoreActivity.class);
                intent.putExtra("SELLER_ID", currentProduct.getSellerId());
                startActivity(intent);
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
    }

    private void displayProductDetails() {
        int id = getIntent().getIntExtra("PRODUCT_ID", -1);
        String name = getIntent().getStringExtra("PRODUCT_NAME");
        double price = getIntent().getDoubleExtra("PRODUCT_PRICE", 0);
        String desc = getIntent().getStringExtra("PRODUCT_DESC");
        String imagePath = getIntent().getStringExtra("PRODUCT_IMAGE");
        String sellerId = getIntent().getStringExtra("SELLER_ID");
        String sellerName = getIntent().getStringExtra("SELLER_NAME");

        currentProduct = new Product();
        currentProduct.setId(id);
        currentProduct.setName(name);
        currentProduct.setPrice(price);
        currentProduct.setDescription(desc);
        currentProduct.setImageUrl(imagePath);
        currentProduct.setSellerId(sellerId);
        currentProduct.setSellerName(sellerName);

        txtFoodName.setText(name);
        txtFoodPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", price));
        txtFoodDescription.setText(desc);
        btnAddToCart.setText("THÊM VÀO GIỎ HÀNG - " + String.format(Locale.getDefault(), "%,.0fđ", price));

        // Hiển thị tên người bán nhận từ Intent
        if (sellerName != null && !sellerName.isEmpty()) {
            tvSellerName.setText("Người bán: " + sellerName);
        } else {
            tvSellerName.setText("Người bán: Đang tải...");
        }

        // Gọi API lấy thêm thông tin chi tiết của người bán (như Avatar)
        if (sellerId != null) {
            loadSellerInfo(sellerId);
        }

        String imageUrl = BASE_URL + imagePath;
        Glide.with(this)
                .load(imageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(imgFood);
    }

    private void loadSellerInfo(String sellerId) {
        ApiService apiService = ApiClient.getClient().create(ApiService.class);
        apiService.getUserById(sellerId).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    User user = response.body();
                    tvSellerName.setText(user.getFullName());
                    
                    String avatarUrl = user.getAvatarUrl();
                    if (avatarUrl != null && !avatarUrl.isEmpty()) {
                        String fullAvatarUrl = avatarUrl.startsWith("http") ? avatarUrl : BASE_URL + avatarUrl;
                        Glide.with(FoodDetailActivity.this)
                                .load(fullAvatarUrl)
                                .placeholder(R.drawable.anhavt)
                                .error(R.drawable.anhavt)
                                .into(ivSellerAvatar);
                    }
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Log.e("API_ERROR", "Load seller info failed: " + t.getMessage());
            }
        });
    }
}

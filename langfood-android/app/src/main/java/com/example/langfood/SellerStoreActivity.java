package com.example.langfood;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Product;
import com.example.langfood.models.User;
import de.hdodenhof.circleimageview.CircleImageView;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SellerStoreActivity extends AppCompatActivity {

    private String sellerId;
    private CircleImageView ivSellerAvatar;
    private TextView tvSellerName;
    private RecyclerView rvSellerProducts;
    private View layoutEmpty;
    private SellerProductAdapter adapter; // Dùng adapter mới
    private List<Product> productList = new ArrayList<>();
    private ApiService apiService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_seller_store);

        sellerId = getIntent().getStringExtra("SELLER_ID");
        if (sellerId == null || sellerId.isEmpty()) {
            Toast.makeText(this, "Không tìm thấy thông tin người bán", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        apiService = ApiClient.getClient().create(ApiService.class);
        initViews();
        loadSellerInfo();
        loadSellerProducts();

        findViewById(R.id.btnBack).setOnClickListener(v -> finish());
    }

    private void initViews() {
        ivSellerAvatar = findViewById(R.id.ivSellerAvatar);
        tvSellerName = findViewById(R.id.tvSellerName);
        rvSellerProducts = findViewById(R.id.rvSellerProducts);
        layoutEmpty = findViewById(R.id.layoutEmpty);

        adapter = new SellerProductAdapter(productList);
        rvSellerProducts.setLayoutManager(new GridLayoutManager(this, 2));
        rvSellerProducts.setAdapter(adapter);
    }

    private void loadSellerInfo() {
        apiService.getUserById(sellerId).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    User user = response.body();
                    tvSellerName.setText(user.getFullName());
                    
                    String avatarUrl = user.getAvatarUrl();
                    if (avatarUrl != null && !avatarUrl.isEmpty()) {
                        String fullAvatarUrl = avatarUrl.startsWith("http") ? avatarUrl : ApiClient.BASE_URL + (avatarUrl.startsWith("/") ? avatarUrl.substring(1) : avatarUrl);
                        Glide.with(SellerStoreActivity.this)
                                .load(fullAvatarUrl)
                                .placeholder(R.drawable.anhavt)
                                .into(ivSellerAvatar);
                    }
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Log.e("API_ERROR", "Seller info fail: " + t.getMessage());
            }
        });
    }

    private void loadSellerProducts() {
        apiService.getProducts(null).enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    productList.clear();
                    for (Product p : response.body()) {
                        if (p.getSellerId() != null && p.getSellerId().equals(sellerId)) {
                            productList.add(p);
                        }
                    }
                    adapter.notifyDataSetChanged();
                    layoutEmpty.setVisibility(productList.isEmpty() ? View.VISIBLE : View.GONE);
                }
            }

            @Override
            public void onFailure(Call<List<Product>> call, Throwable t) {
                Toast.makeText(SellerStoreActivity.this, "Lỗi tải sản phẩm", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

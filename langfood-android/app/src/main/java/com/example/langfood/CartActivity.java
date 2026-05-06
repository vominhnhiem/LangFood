package com.example.langfood;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.CartItem;
import java.util.List;

public class CartActivity extends AppCompatActivity implements CartAdapter.OnCartChangeListener {

    private RecyclerView rvCart;
    private CartAdapter adapter;
    private ImageView btnBack;
    private ApiService apiService;
    private String currentUserId;
    private String currentFullName;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_cart);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);
        
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        currentUserId = prefs.getString("USER_ID", "");
        currentFullName = prefs.getString("FULL_NAME", "");

        setupRecyclerView();

        btnBack.setOnClickListener(v -> finish());
    }

    private void initViews() {
        rvCart = findViewById(R.id.rvCart);
        btnBack = findViewById(R.id.btnBack);
    }

    private void setupRecyclerView() {
        List<CartItem> cartItems = CartManager.getInstance().getCartItems();
        adapter = new CartAdapter(this, cartItems, this);
        rvCart.setLayoutManager(new LinearLayoutManager(this));
        rvCart.setAdapter(adapter);
    }

    @Override
    public void onQuantityChanged() {
        // Có thể thêm logic cập nhật khác nếu cần
    }
}

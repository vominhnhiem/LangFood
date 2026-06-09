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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_cart);

        initViews();
        
        // Khởi tạo adapter với dữ liệu hiện tại từ CartManager
        adapter = new CartAdapter(this, CartManager.getInstance().getCartItems(), this);
        rvCart.setLayoutManager(new LinearLayoutManager(this));
        rvCart.setAdapter(adapter);

        btnBack.setOnClickListener(v -> finish());
    }

    @Override
    protected void onResume() {
        super.onResume();
        // Cập nhật lại UI từ dữ liệu local (đã được CheckoutActivity xóa khi đặt đơn thành công)
        // Tuyệt đối không gọi loadCartFromServer() ở đây để tránh bị server ghi đè dữ liệu cũ
        refreshCartUI();
    }

    private void refreshCartUI() {
        if (adapter != null) {
            adapter.setCartItems(CartManager.getInstance().getCartItems());
        }
    }

    private void initViews() {
        rvCart = findViewById(R.id.rvCart);
        btnBack = findViewById(R.id.btnBack);
    }

    @Override
    public void onQuantityChanged() {
        refreshCartUI();
    }
}

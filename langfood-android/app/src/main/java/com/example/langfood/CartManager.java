package com.example.langfood;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.CartItem;
import com.example.langfood.models.Product;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class CartManager {
    private static CartManager instance;
    private List<CartItem> cartItems;
    private ApiService apiService;
    private String userId;

    private CartManager() {
        cartItems = new ArrayList<>();
        apiService = ApiClient.getClient().create(ApiService.class);
    }

    public static synchronized CartManager getInstance() {
        if (instance == null) {
            instance = new CartManager();
        }
        return instance;
    }

    public void init(Context context) {
        SharedPreferences prefs = context.getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");
        if (!userId.isEmpty()) {
            loadCartFromServer();
        }
    }

    public void loadCartFromServer() {
        if (userId == null || userId.isEmpty()) return;
        
        apiService.getCart(userId).enqueue(new Callback<List<CartItem>>() {
            @Override
            public void onResponse(Call<List<CartItem>> call, Response<List<CartItem>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    cartItems = response.body();
                    Log.d("CartManager", "Cart loaded from server: " + cartItems.size() + " items");
                }
            }

            @Override
            public void onFailure(Call<List<CartItem>> call, Throwable t) {
                Log.e("CartManager", "Failed to load cart", t);
            }
        });
    }

    public void addToCart(Product product, int quantity) {
        // Cập nhật local trước để UI mượt
        boolean exists = false;
        for (CartItem item : cartItems) {
            if (item.getProduct().getId() == product.getId()) {
                item.setQuantity(item.getQuantity() + quantity);
                exists = true;
                break;
            }
        }
        if (!exists) {
            cartItems.add(new CartItem(product, quantity));
        }

        // Đồng bộ lên Server
        if (userId != null && !userId.isEmpty()) {
            apiService.addToCart(userId, product.getId(), quantity).enqueue(new Callback<Void>() {
                @Override
                public void onResponse(Call<Void> call, Response<Void> response) {
                    Log.d("CartManager", "Added to server cart");
                }

                @Override
                public void onFailure(Call<Void> call, Throwable t) {
                    Log.e("CartManager", "Failed to add to server cart");
                }
            });
        }
    }

    public List<CartItem> getCartItems() {
        return cartItems;
    }

    public void clearCart() {
        cartItems.clear();
        if (userId != null && !userId.isEmpty()) {
            apiService.clearCart(userId).enqueue(new Callback<Void>() {
                @Override
                public void onResponse(Call<Void> call, Response<Void> response) {}
                @Override
                public void onFailure(Call<Void> call, Throwable t) {}
            });
        }
    }

    public double getTotalPrice() {
        double total = 0;
        for (CartItem item : cartItems) {
            total += item.getProduct().getPrice() * item.getQuantity();
        }
        return total;
    }

    public void removeItem(int productId) {
        cartItems.removeIf(item -> item.getProduct().getId() == productId);
        if (userId != null && !userId.isEmpty()) {
            apiService.removeFromCart(userId, productId).enqueue(new Callback<Void>() {
                @Override
                public void onResponse(Call<Void> call, Response<Void> response) {}
                @Override
                public void onFailure(Call<Void> call, Throwable t) {}
            });
        }
    }
}

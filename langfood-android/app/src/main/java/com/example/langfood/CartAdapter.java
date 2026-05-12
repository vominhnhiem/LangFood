package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.models.CartItem;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class CartAdapter extends RecyclerView.Adapter<CartAdapter.CartViewHolder> {

    private Context context;
    private List<CartGroup> cartGroups;
    private OnCartChangeListener listener;

    public interface OnCartChangeListener {
        void onQuantityChanged();
    }

    public CartAdapter(Context context, List<CartItem> cartItems, OnCartChangeListener listener) {
        this.context = context;
        this.listener = listener;
        setCartItems(cartItems);
    }

    public void setCartItems(List<CartItem> cartItems) {
        Map<Integer, CartGroup> groupMap = new HashMap<>();
        for (CartItem item : cartItems) {
            int shopId = item.getProduct().getShopId();
            
            if (!groupMap.containsKey(shopId)) {
                CartGroup group = new CartGroup();
                group.shopId = shopId;
                group.shopName = item.getProduct().getShopName();
                group.shopAvatar = item.getProduct().getImageUrl(); 
                group.items = new ArrayList<>();
                groupMap.put(shopId, group);
            }
            groupMap.get(shopId).items.add(item);
        }
        this.cartGroups = new ArrayList<>(groupMap.values());
        notifyDataSetChanged();
    }

    @NonNull
    @Override
    public CartViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_cart_group, parent, false);
        return new CartViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull CartViewHolder holder, int position) {
        CartGroup group = cartGroups.get(position);
        
        String shopName = group.shopName != null ? group.shopName : "Quán ăn Lang Food";
        holder.tvStoreName.setText(shopName);
        
        int totalItems = 0;
        for (CartItem item : group.items) {
            totalItems += item.getQuantity();
        }
        holder.tvStoreSummary.setText(totalItems + " món • Đang hoạt động");

        String imageUrl = group.shopAvatar;
        if (imageUrl != null && !imageUrl.startsWith("http")) {
            imageUrl = ApiClient.BASE_URL + (imageUrl.startsWith("/") ? imageUrl.substring(1) : imageUrl);
        }

        Glide.with(context)
                .load(imageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .into(holder.imgStore);

        holder.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(context, CheckoutActivity.class);
            intent.putExtra("CART_GROUP", group);
            context.startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return cartGroups.size();
    }

    public static class CartViewHolder extends RecyclerView.ViewHolder {
        ImageView imgStore;
        TextView tvStoreName, tvStoreSummary;

        public CartViewHolder(@NonNull View itemView) {
            super(itemView);
            imgStore = itemView.findViewById(R.id.imgStore);
            tvStoreName = itemView.findViewById(R.id.tvStoreName);
            tvStoreSummary = itemView.findViewById(R.id.tvStoreSummary);
        }
    }

    public static class CartGroup implements Serializable {
        int shopId;
        String shopName;
        String shopAvatar;
        List<CartItem> items;
    }
}

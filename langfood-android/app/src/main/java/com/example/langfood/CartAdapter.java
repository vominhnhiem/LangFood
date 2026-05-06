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
    private static final String BASE_URL = "http://192.168.100.192:5289/";

    public interface OnCartChangeListener {
        void onQuantityChanged();
    }

    public CartAdapter(Context context, List<CartItem> cartItems, OnCartChangeListener listener) {
        this.context = context;
        this.listener = listener;
        setCartItems(cartItems);
    }

    public void setCartItems(List<CartItem> cartItems) {
        Map<String, CartGroup> groupMap = new HashMap<>();
        for (CartItem item : cartItems) {
            String sellerId = item.getProduct().getSellerId();
            if (sellerId == null) sellerId = "unknown";
            
            if (!groupMap.containsKey(sellerId)) {
                CartGroup group = new CartGroup();
                group.sellerId = sellerId;
                group.sellerName = item.getProduct().getSellerName();
                group.sellerAvatar = item.getProduct().getImageUrl(); 
                group.items = new ArrayList<>();
                groupMap.put(sellerId, group);
            }
            groupMap.get(sellerId).items.add(item);
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
        
        String sellerName = group.sellerName != null ? group.sellerName : "Quán ăn Lang Food";
        holder.tvStoreName.setText(sellerName);
        
        int totalItems = 0;
        for (CartItem item : group.items) {
            totalItems += item.getQuantity();
        }
        holder.tvStoreSummary.setText(totalItems + " món • Đang hoạt động");

        String imageUrl = group.sellerAvatar;
        if (imageUrl != null && !imageUrl.startsWith("http")) {
            imageUrl = BASE_URL + imageUrl;
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
        String sellerId;
        String sellerName;
        String sellerAvatar;
        List<CartItem> items;
    }
}

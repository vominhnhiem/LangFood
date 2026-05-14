package com.example.langfood;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.models.OrderItem;
import com.example.langfood.models.Product;
import java.util.List;
import java.util.Locale;

public class OrderItemDetailAdapter extends RecyclerView.Adapter<OrderItemDetailAdapter.ViewHolder> {

    private List<OrderItem> orderItems;
    // Cập nhật IP đồng bộ với ApiClient
    private static final String BASE_URL = "http://192.168.61.39:5289/";

    public OrderItemDetailAdapter(List<OrderItem> orderItems) {
        this.orderItems = orderItems;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_order_detail, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        OrderItem item = orderItems.get(position);
        
        // Backend đã trả về full Product, lấy Name và ImageUrl từ đó
        String name = "Món ăn";
        String imageUrl = null;
        
        Product product = item.getProduct();
        if (product != null) {
            name = product.getName();
            imageUrl = product.getImageUrl();
        } else if (item.getProductName() != null) {
            name = item.getProductName();
        }

        holder.tvProductName.setText(name);
        holder.tvProductPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", item.getUnitPrice()));
        holder.tvProductQuantity.setText("x" + item.getQuantity());

        Glide.with(holder.itemView.getContext())
                .load(BASE_URL + imageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivProductImage);
    }

    @Override
    public int getItemCount() {
        return orderItems != null ? orderItems.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvProductName, tvProductPrice, tvProductQuantity;
        ImageView ivProductImage;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvProductName = itemView.findViewById(R.id.tvProductName);
            tvProductPrice = itemView.findViewById(R.id.tvProductPrice);
            tvProductQuantity = itemView.findViewById(R.id.tvProductQuantity);
            ivProductImage = itemView.findViewById(R.id.ivProductImage);
        }
    }
}

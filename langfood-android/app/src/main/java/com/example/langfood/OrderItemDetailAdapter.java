package com.example.langfood;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.models.OrderItem;
import com.example.langfood.models.Product;
import java.util.List;
import java.util.Locale;

public class OrderItemDetailAdapter extends RecyclerView.Adapter<OrderItemDetailAdapter.ViewHolder> {

    private List<OrderItem> orderItems;

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
        
        // Hiển thị số lượng tĩnh (x1, x2...)
        holder.tvProductQuantity.setText("x" + item.getQuantity());
        holder.tvProductQuantity.setVisibility(View.VISIBLE);

        // HIỂN THỊ TOPPING
        if (item.getOptionsSummary() != null && !item.getOptionsSummary().isEmpty()) {
            holder.tvProductOptions.setText("Lựa chọn: " + item.getOptionsSummary());
            holder.tvProductOptions.setVisibility(View.VISIBLE);
        } else {
            holder.tvProductOptions.setVisibility(View.GONE);
        }

        // HIỂN THỊ GHI CHÚ
        if (item.getNote() != null && !item.getNote().isEmpty()) {
            holder.tvProductNote.setText("Ghi chú: " + item.getNote());
            holder.tvProductNote.setVisibility(View.VISIBLE);
        } else {
            holder.tvProductNote.setVisibility(View.GONE);
        }

        // ẨN CÁC NÚT ĐIỀU CHỈNH (Chỉ dùng cho Checkout)
        if (holder.layoutQuantityControls != null) {
            holder.layoutQuantityControls.setVisibility(View.GONE);
        }
        if (holder.btnRemove != null) {
            holder.btnRemove.setVisibility(View.GONE);
        }

        // Sử dụng ApiClient.BASE_URL để đảm bộ đồng bộ địa chỉ IP server
        String fullImageUrl = (imageUrl != null && imageUrl.startsWith("http")) ? imageUrl : ApiClient.BASE_URL + (imageUrl != null && imageUrl.startsWith("/") ? imageUrl.substring(1) : (imageUrl != null ? imageUrl : ""));

        Glide.with(holder.itemView.getContext())
                .load(fullImageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivProductImage);
    }

    @Override
    public int getItemCount() {
        return orderItems != null ? orderItems.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvProductName, tvProductPrice, tvProductQuantity, tvProductOptions, tvProductNote;
        ImageView ivProductImage;
        View layoutQuantityControls, btnRemove;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvProductName = itemView.findViewById(R.id.tvProductName);
            tvProductPrice = itemView.findViewById(R.id.tvProductPrice);
            tvProductQuantity = itemView.findViewById(R.id.tvProductQuantity);
            tvProductOptions = itemView.findViewById(R.id.tvProductOptions);
            tvProductNote = itemView.findViewById(R.id.tvProductNote);
            ivProductImage = itemView.findViewById(R.id.ivProductImage);
            layoutQuantityControls = itemView.findViewById(R.id.layoutQuantityControls);
            btnRemove = itemView.findViewById(R.id.btnRemove);
        }
    }
}

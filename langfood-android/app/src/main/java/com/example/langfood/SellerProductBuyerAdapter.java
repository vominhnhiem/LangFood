package com.example.langfood;

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
import com.example.langfood.models.Product;
import java.util.List;
import java.util.Locale;

public class SellerProductBuyerAdapter extends RecyclerView.Adapter<SellerProductBuyerAdapter.ViewHolder> {
    private List<Product> products;

    public SellerProductBuyerAdapter(List<Product> products) {
        this.products = products;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_product_buyer, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Product product = products.get(position);
        holder.tvName.setText(product.getName());
        holder.tvPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", product.getPrice()));

        String imageUrl = product.getImageUrl();
        String fullUrl = imageUrl != null ? (imageUrl.startsWith("http") ? imageUrl : ApiClient.BASE_URL + (imageUrl.startsWith("/") ? imageUrl.substring(1) : imageUrl)) : "";

        Glide.with(holder.itemView.getContext())
                .load(fullUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivImage);

        // Click vào cả item -> Mở màn hình chi tiết món
        holder.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(v.getContext(), FoodDetailActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            intent.putExtra("SELLER_ID", product.getSellerId());
            v.getContext().startActivity(intent);
        });

        // Click vào nút "+" -> Cũng mở chi tiết để khách chọn topping và thêm
        holder.btnQuickAdd.setOnClickListener(v -> {
            Intent intent = new Intent(v.getContext(), FoodDetailActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            intent.putExtra("SELLER_ID", product.getSellerId());
            v.getContext().startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return products.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivImage, btnQuickAdd;
        TextView tvName, tvPrice;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivImage = itemView.findViewById(R.id.ivProductImage);
            btnQuickAdd = itemView.findViewById(R.id.btnQuickAdd);
            tvName = itemView.findViewById(R.id.tvProductName);
            tvPrice = itemView.findViewById(R.id.tvProductPrice);
        }
    }
}

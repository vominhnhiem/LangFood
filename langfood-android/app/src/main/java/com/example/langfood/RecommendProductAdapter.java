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

public class RecommendProductAdapter extends RecyclerView.Adapter<RecommendProductAdapter.ViewHolder> {

    private final List<Product> productList;

    public RecommendProductAdapter(List<Product> productList) {
        this.productList = productList;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_recommend_product, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Product product = productList.get(position);

        holder.tvProductName.setText(product.getName());
        holder.tvShopName.setText(product.getShopName());

        String formattedPrice = String.format(Locale.getDefault(), "%,.0fđ", product.getPrice());
        holder.tvProductPrice.setText(formattedPrice);

        Glide.with(holder.itemView.getContext())
                .load(ApiClient.BASE_URL + product.getImageUrl())
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivProductImage);

        // Click on item or the order button launches detail
        View.OnClickListener clickListener = v -> {
            Intent intent = new Intent(v.getContext(), FoodDetailActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            intent.putExtra("PRODUCT_NAME", product.getName());
            intent.putExtra("PRODUCT_PRICE", product.getPrice());
            intent.putExtra("PRODUCT_DESC", product.getDescription());
            intent.putExtra("PRODUCT_IMAGE", product.getImageUrl());
            intent.putExtra("SHOP_ID", product.getShopId());
            intent.putExtra("SELLER_ID", product.getSellerId());
            intent.putExtra("SELLER_NAME", product.getSellerName());
            v.getContext().startActivity(intent);
        };

        holder.itemView.setOnClickListener(clickListener);
        holder.btnRecommendOrder.setOnClickListener(clickListener);
    }

    @Override
    public int getItemCount() {
        return productList == null ? 0 : productList.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProductImage;
        TextView tvProductName, tvProductPrice, tvShopName;
        TextView btnRecommendOrder;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProductImage = itemView.findViewById(R.id.ivRecommendProductImage);
            tvProductName = itemView.findViewById(R.id.tvRecommendProductName);
            tvShopName = itemView.findViewById(R.id.tvRecommendShopName);
            tvProductPrice = itemView.findViewById(R.id.tvRecommendProductPrice);
            btnRecommendOrder = itemView.findViewById(R.id.btnRecommendOrder);
        }
    }
}

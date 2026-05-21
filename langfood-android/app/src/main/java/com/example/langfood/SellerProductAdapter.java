package com.example.langfood;

import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.models.Product;
import java.util.List;
import java.util.Locale;

public class SellerProductAdapter extends RecyclerView.Adapter<SellerProductAdapter.ViewHolder> {

    private List<Product> productList;

    public SellerProductAdapter(List<Product> productList) {
        this.productList = productList;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        // Sử dụng một layout mới có nút Quản lý Topping
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_seller_product, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Product product = productList.get(position);
        
        holder.tvName.setText(product.getName());
        holder.tvPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", product.getPrice()));
        
        Glide.with(holder.itemView.getContext())
                .load(ApiClient.BASE_URL + product.getImageUrl())
                .placeholder(R.drawable.lang_food_avt)
                .into(holder.ivProduct);

        // Nút Quản lý Topping
        holder.btnManageOptions.setOnClickListener(v -> {
            Intent intent = new Intent(v.getContext(), ManageOptionsActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            intent.putExtra("PRODUCT_NAME", product.getName());
            v.getContext().startActivity(intent);
        });

        // Nút Chỉnh sửa món
        holder.btnEditProduct.setOnClickListener(v -> {
            Intent intent = new Intent(v.getContext(), EditFoodActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            v.getContext().startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return productList != null ? productList.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProduct;
        TextView tvName, tvPrice;
        Button btnManageOptions, btnEditProduct;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProduct = itemView.findViewById(R.id.ivProductImage);
            tvName = itemView.findViewById(R.id.tvProductName);
            tvPrice = itemView.findViewById(R.id.tvProductPrice);
            btnManageOptions = itemView.findViewById(R.id.btnManageOptions);
            btnEditProduct = itemView.findViewById(R.id.btnEditProduct);
        }
    }
}

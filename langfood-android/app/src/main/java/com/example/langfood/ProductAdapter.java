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
import com.example.langfood.models.Category;
import com.example.langfood.models.Product;
import com.example.langfood.api.ApiClient;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class ProductAdapter extends RecyclerView.Adapter<ProductAdapter.ProductViewHolder> {

    private List<Product> productList;
    private List<Category> categories = new ArrayList<>();

    public ProductAdapter(List<Product> productList) {
        this.productList = productList;
    }

    public void setCategories(List<Category> categories) {
        this.categories = categories;
        notifyDataSetChanged();
    }

    private String getCategoryName(Product product) {
        // 1. Ưu tiên dùng tên thể loại nếu Server đã trả về sẵn
        if (product.getCategoryName() != null && !product.getCategoryName().isEmpty()) {
            return product.getCategoryName();
        }
        
        // 2. Tra cứu trong danh sách categoryList theo ID
        if (categories != null && !categories.isEmpty()) {
            for (Category cat : categories) {
                if (cat.getId() == product.getCategoryId()) {
                    return cat.getName();
                }
            }
        }
        
        // 3. Nếu không tìm thấy, hiển thị ID để dễ debug
        return "Khác (ID: " + product.getCategoryId() + ")";
    }

    @NonNull
    @Override
    public ProductViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_product_grid, parent, false);
        return new ProductViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ProductViewHolder holder, int position) {
        Product product = productList.get(position);
        
        holder.tvProductName.setText(product.getName());
        holder.tvCategoryName.setText(getCategoryName(product));
        
        String formattedPrice = String.format(Locale.getDefault(), "%,.0fđ", product.getPrice());
        holder.tvProductPrice.setText(formattedPrice);
        
        Glide.with(holder.itemView.getContext())
                .load(ApiClient.BASE_URL + product.getImageUrl())
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivProductImage);

        holder.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(v.getContext(), FoodDetailActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            intent.putExtra("PRODUCT_NAME", product.getName());
            intent.putExtra("PRODUCT_PRICE", product.getPrice());
            intent.putExtra("PRODUCT_DESC", product.getDescription());
            intent.putExtra("PRODUCT_IMAGE", product.getImageUrl());
            intent.putExtra("SHOP_ID", product.getShopId()); // Thêm dòng này để truyền ShopId
            intent.putExtra("SELLER_ID", product.getSellerId());
            intent.putExtra("SELLER_NAME", product.getSellerName());
            v.getContext().startActivity(intent);
        });
    }

    @Override
    public int getItemCount() {
        return productList == null ? 0 : productList.size();
    }

    public static class ProductViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProductImage;
        TextView tvProductName, tvProductPrice, tvCategoryName;

        public ProductViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProductImage = itemView.findViewById(R.id.ivProductImage);
            tvProductName = itemView.findViewById(R.id.tvProductName);
            tvCategoryName = itemView.findViewById(R.id.tvCategoryName);
            tvProductPrice = itemView.findViewById(R.id.tvProductPrice);
        }
    }
}

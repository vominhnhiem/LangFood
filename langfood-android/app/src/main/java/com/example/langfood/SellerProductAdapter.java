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
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_product_grid, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Product product = productList.get(position);
        
        holder.tvName.setText(product.getName());

        // Hiển thị tên thể loại
        if (holder.tvCategoryName != null) {
            holder.tvCategoryName.setText(product.getCategoryName() != null ? product.getCategoryName() : "Khác");
        }
        
        // Fix lỗi hiển thị giá tiền: Thêm đ và format dấu chấm
        String formattedPrice = String.format(Locale.getDefault(), "%,.0fđ", product.getPrice());
        holder.tvPrice.setText(formattedPrice);

        // Hiển thị mô tả nếu có
        if (holder.tvDescription != null) {
            holder.tvDescription.setText(product.getDescription() != null ? product.getDescription() : "Món ngon mỗi ngày");
        }

        // Dùng BASE_URL tập trung từ ApiClient để tránh lỗi load ảnh
        Glide.with(holder.itemView.getContext())
                .load(ApiClient.BASE_URL + product.getImageUrl())
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivProduct);

        // Xử lý click vào cả item để xem chi tiết hoặc thêm vào giỏ
        holder.itemView.setOnClickListener(v -> {
            // Logic xử lý khi click vào món ăn
        });
    }

    @Override
    public int getItemCount() {
        return productList != null ? productList.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProduct;
        TextView tvName, tvPrice, tvDescription, tvCategoryName;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProduct = itemView.findViewById(R.id.ivProductImage);
            tvName = itemView.findViewById(R.id.tvProductName);
            tvCategoryName = itemView.findViewById(R.id.tvCategoryName);
            tvPrice = itemView.findViewById(R.id.tvProductPrice);
            tvDescription = itemView.findViewById(R.id.tvProductDescription);
        }
    }
}

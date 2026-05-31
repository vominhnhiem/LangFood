package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.appcompat.widget.SwitchCompat;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.models.Product;
import java.util.List;
import java.util.Locale;

public class SellerMenuAdapter extends RecyclerView.Adapter<SellerMenuAdapter.ProductViewHolder> {

    public interface OnProductActionListener {
        void onToggleAvailability(Product product, boolean isAvailable);
    }

    private Context context;
    private List<Product> productList;
    private OnProductActionListener listener;

    public SellerMenuAdapter(Context context, List<Product> productList, OnProductActionListener listener) {
        this.context = context;
        this.productList = productList;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ProductViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_seller_product, parent, false);
        return new ProductViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ProductViewHolder holder, int position) {
        Product product = productList.get(position);

        holder.tvName.setText(product.getName());
        holder.tvCategory.setText(product.getCategoryName() != null ? product.getCategoryName() : "Danh mục khác");
        holder.tvPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", product.getPrice()));

        Glide.with(holder.itemView.getContext())
                .load(ApiClient.BASE_URL + product.getImageUrl())
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivProduct);

        // Handle Switch status & listener
        holder.switchAvailable.setOnCheckedChangeListener(null); // Temporarily remove listener to avoid triggers during binding
        holder.switchAvailable.setChecked(product.isAvailable());
        updateSwitchUI(holder.switchAvailable, product.isAvailable());

        holder.switchAvailable.setOnCheckedChangeListener((buttonView, isChecked) -> {
            updateSwitchUI(holder.switchAvailable, isChecked);
            if (listener != null) {
                listener.onToggleAvailability(product, isChecked);
            }
        });

        // Manage Options/Toppings click
        holder.btnOptions.setOnClickListener(v -> {
            Intent intent = new Intent(context, ManageOptionsActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            intent.putExtra("PRODUCT_NAME", product.getName());
            context.startActivity(intent);
        });

        // Edit Product click
        holder.btnEdit.setOnClickListener(v -> {
            Intent intent = new Intent(context, EditFoodActivity.class);
            intent.putExtra("PRODUCT_ID", product.getId());
            context.startActivity(intent);
        });
    }

    private void updateSwitchUI(SwitchCompat switchCompat, boolean isChecked) {
        if (isChecked) {
            switchCompat.setText("Còn hàng");
            switchCompat.setTextColor(Color.parseColor("#4CAF50"));
        } else {
            switchCompat.setText("Hết hàng");
            switchCompat.setTextColor(Color.parseColor("#F44336"));
        }
    }

    @Override
    public int getItemCount() {
        return productList == null ? 0 : productList.size();
    }

    public static class ProductViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProduct, btnOptions, btnEdit;
        TextView tvName, tvCategory, tvPrice;
        SwitchCompat switchAvailable;

        public ProductViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProduct = itemView.findViewById(R.id.ivSellerProductImg);
            tvName = itemView.findViewById(R.id.tvSellerProductName);
            tvCategory = itemView.findViewById(R.id.tvSellerProductCategory);
            tvPrice = itemView.findViewById(R.id.tvSellerProductPrice);
            switchAvailable = itemView.findViewById(R.id.switchProductAvailable);
            btnOptions = itemView.findViewById(R.id.btnSellerProductOptions);
            btnEdit = itemView.findViewById(R.id.btnSellerProductEdit);
        }
    }
}

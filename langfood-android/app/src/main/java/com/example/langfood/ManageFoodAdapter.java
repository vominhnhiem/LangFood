package com.example.langfood;

import android.content.Context;
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

public class ManageFoodAdapter extends RecyclerView.Adapter<ManageFoodAdapter.ViewHolder> {

    private Context context;
    private List<Product> productList;
    private OnFoodItemClickListener listener;

    public interface OnFoodItemClickListener {
        void onEditClick(Product product);
        void onDeleteClick(Product product);
    }

    public ManageFoodAdapter(Context context, List<Product> productList, OnFoodItemClickListener listener) {
        this.context = context;
        this.productList = productList;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_manage_food, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Product product = productList.get(position);
        holder.tvFoodName.setText(product.getName());
        holder.tvFoodPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", product.getPrice()));
        
        // Cập nhật trạng thái
        if (product.isAvailable()) {
            holder.tvFoodStatus.setText("Đang bán");
            holder.tvFoodStatus.setTextColor(context.getResources().getColor(android.R.color.holo_green_dark));
        } else {
            holder.tvFoodStatus.setText("Tạm hết");
            holder.tvFoodStatus.setTextColor(context.getResources().getColor(android.R.color.holo_red_dark));
        }

        // Load ảnh bằng Glide với BASE_URL
        String imageUrl = product.getImageUrl();
        String fullImageUrl = (imageUrl != null && imageUrl.startsWith("http")) ? imageUrl : ApiClient.BASE_URL + (imageUrl != null && imageUrl.startsWith("/") ? imageUrl.substring(1) : (imageUrl != null ? imageUrl : ""));

        Glide.with(context)
                .load(fullImageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivFoodImage);

        holder.btnEdit.setOnClickListener(v -> listener.onEditClick(product));
        holder.btnDelete.setOnClickListener(v -> listener.onDeleteClick(product));
    }

    @Override
    public int getItemCount() {
        return productList.size();
    }

    public void updateList(List<Product> newList) {
        this.productList = newList;
        notifyDataSetChanged();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        ImageView ivFoodImage, btnEdit, btnDelete;
        TextView tvFoodName, tvFoodPrice, tvFoodStatus;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            ivFoodImage = itemView.findViewById(R.id.ivFoodImage);
            tvFoodName = itemView.findViewById(R.id.tvFoodName);
            tvFoodPrice = itemView.findViewById(R.id.tvFoodPrice);
            tvFoodStatus = itemView.findViewById(R.id.tvFoodStatus);
            btnEdit = itemView.findViewById(R.id.btnEdit);
            btnDelete = itemView.findViewById(R.id.btnDelete);
        }
    }
}
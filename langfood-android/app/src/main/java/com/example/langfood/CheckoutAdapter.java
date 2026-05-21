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
import com.example.langfood.models.CartItem;
import com.example.langfood.models.ProductOption;
import com.example.langfood.models.ProductOptionGroup;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class CheckoutAdapter extends RecyclerView.Adapter<CheckoutAdapter.CheckoutViewHolder> {

    private List<CartItem> items;
    private Gson gson = new Gson();
    private OnItemUpdateListener listener;

    public interface OnItemUpdateListener {
        void onItemDeleted(CartItem item);
        void onQuantityChanged();
    }

    public CheckoutAdapter(List<CartItem> items, OnItemUpdateListener listener) {
        this.items = items;
        this.listener = listener;
    }

    @NonNull
    @Override
    public CheckoutViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_order_detail, parent, false);
        return new CheckoutViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull CheckoutViewHolder holder, int position) {
        CartItem item = items.get(holder.getAdapterPosition());
        holder.tvProductName.setText(item.getProduct().getName());
        
        // Cập nhật số lượng
        holder.tvQuantityValue.setText(String.valueOf(item.getQuantity()));
        
        double basePrice = item.getProduct().getPrice();
        double toppingTotal = 0;
        StringBuilder optionsBuilder = new StringBuilder();

        if (item.getSelectedOptionsJson() != null && !item.getSelectedOptionsJson().isEmpty()) {
            try {
                Type listType = new TypeToken<ArrayList<Integer>>() {}.getType();
                List<Integer> selectedIds = gson.fromJson(item.getSelectedOptionsJson(), listType);
                
                if (selectedIds != null && !selectedIds.isEmpty() && item.getProduct().getOptionGroups() != null) {
                    for (ProductOptionGroup group : item.getProduct().getOptionGroups()) {
                        for (ProductOption option : group.getOptions()) {
                            if (selectedIds.contains(option.getId())) {
                                if (optionsBuilder.length() > 0) optionsBuilder.append(", ");
                                optionsBuilder.append(option.getName());
                                toppingTotal += option.getAdditionalPrice();
                            }
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (optionsBuilder.length() > 0) {
            holder.tvProductOptions.setText(optionsBuilder.toString());
            holder.tvProductOptions.setVisibility(View.VISIBLE);
        } else {
            holder.tvProductOptions.setVisibility(View.GONE);
        }

        double totalPricePerItem = basePrice + toppingTotal;
        holder.tvProductPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", totalPricePerItem));

        String imageUrl = item.getProduct().getImageUrl();
        String fullImageUrl = (imageUrl != null && imageUrl.startsWith("http")) ? imageUrl : ApiClient.BASE_URL + (imageUrl != null && imageUrl.startsWith("/") ? imageUrl.substring(1) : (imageUrl != null ? imageUrl : ""));

        Glide.with(holder.itemView.getContext())
                .load(fullImageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .into(holder.ivProductImage);

        // Xử lý nút tăng giảm số lượng
        holder.btnPlus.setOnClickListener(v -> {
            int currentPos = holder.getAdapterPosition();
            if (currentPos != RecyclerView.NO_POSITION) {
                CartItem currentItem = items.get(currentPos);
                currentItem.setQuantity(currentItem.getQuantity() + 1);
                notifyItemChanged(currentPos);
                if (listener != null) listener.onQuantityChanged();
            }
        });

        holder.btnMinus.setOnClickListener(v -> {
            int currentPos = holder.getAdapterPosition();
            if (currentPos != RecyclerView.NO_POSITION) {
                CartItem currentItem = items.get(currentPos);
                if (currentItem.getQuantity() > 1) {
                    currentItem.setQuantity(currentItem.getQuantity() - 1);
                    notifyItemChanged(currentPos);
                    if (listener != null) listener.onQuantityChanged();
                }
            }
        });

        // Xử lý nút xóa
        holder.btnRemove.setOnClickListener(v -> {
            int currentPos = holder.getAdapterPosition();
            if (currentPos != RecyclerView.NO_POSITION && listener != null) {
                listener.onItemDeleted(items.get(currentPos));
            }
        });
    }

    @Override
    public int getItemCount() {
        return items.size();
    }

    static class CheckoutViewHolder extends RecyclerView.ViewHolder {
        ImageView ivProductImage, btnMinus, btnPlus, btnRemove;
        TextView tvProductName, tvProductPrice, tvQuantityValue, tvProductOptions;

        public CheckoutViewHolder(@NonNull View itemView) {
            super(itemView);
            ivProductImage = itemView.findViewById(R.id.ivProductImage);
            tvProductName = itemView.findViewById(R.id.tvProductName);
            tvProductPrice = itemView.findViewById(R.id.tvProductPrice);
            tvQuantityValue = itemView.findViewById(R.id.tvQuantityValue);
            tvProductOptions = itemView.findViewById(R.id.tvProductOptions);
            btnMinus = itemView.findViewById(R.id.btnMinus);
            btnPlus = itemView.findViewById(R.id.btnPlus);
            btnRemove = itemView.findViewById(R.id.btnRemove);
        }
    }
}

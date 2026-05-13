package com.example.langfood;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.models.Order;
import com.example.langfood.models.OrderItem;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;

public class OrderHistoryAdapter extends RecyclerView.Adapter<OrderHistoryAdapter.OrderViewHolder> {

    private List<Order> orderList;

    public OrderHistoryAdapter(List<Order> orderList) {
        this.orderList = orderList;
    }

    @NonNull
    @Override
    public OrderViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_history_order, parent, false);
        return new OrderViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull OrderViewHolder holder, int position) {
        Order order = orderList.get(position);

        // 1. Set Shop Name
        holder.tvShopName.setText(order.getShopName() != null ? order.getShopName() : "Cửa hàng #" + order.getShopId());

        // 2. Set Status and Color
        String status = order.getStatus() != null ? order.getStatus() : "Pending";
        setStatusUI(holder.tvStatus, status);

        // 3. Set Date
        holder.tvOrderDate.setText(formatDate(order.getCreatedAt()));

        // 4. Set Item Count
        int count = 0;
        if (order.getOrderItems() != null) {
            for (OrderItem item : order.getOrderItems()) {
                count += item.getQuantity();
            }
        }
        holder.tvItemCount.setText(count + " món");

        // 5. Set Total Amount
        holder.tvTotalAmount.setText(String.format(Locale.getDefault(), "%,.0fđ", order.getTotalAmount()));

        // 6. Set Image (using first item's product image or placeholder)
        String imageUrl = "";
        if (order.getOrderItems() != null && !order.getOrderItems().isEmpty() && order.getOrderItems().get(0).getProduct() != null) {
            imageUrl = order.getOrderItems().get(0).getProduct().getImageUrl();
        }
        
        Glide.with(holder.itemView.getContext())
                .load(ApiClient.BASE_URL + imageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(holder.ivOrderThumb);
    }

    private void setStatusUI(TextView tvStatus, String status) {
        switch (status) {
            case "Pending":
                tvStatus.setText("Chờ xác nhận");
                tvStatus.setTextColor(Color.parseColor("#FF9800"));
                break;
            case "Processing":
            case "Shipping":
                tvStatus.setText(status.equals("Shipping") ? "Đang giao" : "Đang xử lý");
                tvStatus.setTextColor(Color.parseColor("#2196F3"));
                break;
            case "Completed":
                tvStatus.setText("Đã hoàn thành");
                tvStatus.setTextColor(Color.parseColor("#4CAF50"));
                break;
            case "Cancelled":
                tvStatus.setText("Đã hủy");
                tvStatus.setTextColor(Color.parseColor("#F44336"));
                break;
            default:
                tvStatus.setText(status);
                tvStatus.setTextColor(Color.GRAY);
                break;
        }
    }

    private String formatDate(String isoDate) {
        if (isoDate == null) return "--/--/----";
        try {
            // ISO 8601 format usually is yyyy-MM-dd'T'HH:mm:ss
            SimpleDateFormat parser = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            parser.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = parser.parse(isoDate);
            
            SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault());
            return formatter.format(date);
        } catch (ParseException e) {
            return isoDate; // Fallback to original string
        }
    }

    @Override
    public int getItemCount() {
        return orderList != null ? orderList.size() : 0;
    }

    public static class OrderViewHolder extends RecyclerView.ViewHolder {
        TextView tvStatus, tvOrderDate, tvShopName, tvItemCount, tvTotalAmount;
        ImageView ivOrderThumb;

        public OrderViewHolder(@NonNull View itemView) {
            super(itemView);
            tvStatus = itemView.findViewById(R.id.tvStatus);
            tvOrderDate = itemView.findViewById(R.id.tvOrderDate);
            tvShopName = itemView.findViewById(R.id.tvShopName);
            tvItemCount = itemView.findViewById(R.id.tvItemCount);
            tvTotalAmount = itemView.findViewById(R.id.tvTotalAmount);
            ivOrderThumb = itemView.findViewById(R.id.ivOrderThumb);
        }
    }
}

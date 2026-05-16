package com.example.langfood;

import android.graphics.Color;
import android.graphics.Typeface;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
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

        holder.tvShopName.setText(order.getShopName() != null ? order.getShopName() : "Cửa hàng #" + order.getShopId());

        String status = order.getStatus() != null ? order.getStatus() : "Pending";
        setStatusUI(holder.tvStatus, status);

        // LÀM NỔI BẬT ĐƠN CHƯA HOÀN THÀNH
        if (isUnfinished(status)) {
            holder.cardRoot.setCardBackgroundColor(Color.parseColor("#FFF8E1")); // Vàng nhạt nổi bật
            holder.tvStatus.setTextSize(14f);
            holder.tvStatus.setTypeface(null, Typeface.BOLD_ITALIC);
        } else {
            holder.cardRoot.setCardBackgroundColor(Color.WHITE);
            holder.tvStatus.setTextSize(12f);
            holder.tvStatus.setTypeface(null, Typeface.BOLD);
        }

        holder.tvOrderDate.setText(formatDate(order.getCreatedAt()));

        int count = 0;
        if (order.getOrderItems() != null) {
            for (OrderItem item : order.getOrderItems()) {
                count += item.getQuantity();
            }
        }
        holder.tvItemCount.setText(count + " món");
        holder.tvTotalAmount.setText(String.format(Locale.getDefault(), "%,.0fđ", order.getTotalAmount()));

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

    private boolean isUnfinished(String status) {
        if (status == null) return true;
        String s = status.toLowerCase().trim();
        return !s.equals("completed") && !s.equals("delivered") && !s.equals("cancelled");
    }

    private void setStatusUI(TextView tvStatus, String status) {
        if (status == null) return;
        String s = status.toLowerCase().trim();
        switch (s) {
            case "pending":
                tvStatus.setText("● Chờ xác nhận");
                tvStatus.setTextColor(Color.parseColor("#FF9800"));
                break;
            case "pendingpayment":
                tvStatus.setText("● Chờ thanh toán");
                tvStatus.setTextColor(Color.parseColor("#E91E63"));
                break;
            case "confirmed":
            case "approved":
                tvStatus.setText("● Đã xác nhận");
                tvStatus.setTextColor(Color.parseColor("#4CAF50"));
                break;
            case "preparing":
                tvStatus.setText("● Đang chế biến");
                tvStatus.setTextColor(Color.parseColor("#FBC02D"));
                break;
            case "ready":
                tvStatus.setText("● Chờ shipper lấy");
                tvStatus.setTextColor(Color.parseColor("#008000"));
                break;
            case "shipping":
            case "delivering":
                tvStatus.setText("● Đang giao hàng");
                tvStatus.setTextColor(Color.parseColor("#2196F3"));
                break;
            case "completed":
            case "delivered":
                tvStatus.setText("Đã hoàn thành");
                tvStatus.setTextColor(Color.parseColor("#808080"));
                break;
            case "cancelled":
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
            SimpleDateFormat parser = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            parser.setTimeZone(TimeZone.getTimeZone("UTC"));
            Date date = parser.parse(isoDate);
            SimpleDateFormat formatter = new SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.getDefault());
            return formatter.format(date);
        } catch (ParseException e) {
            return isoDate;
        }
    }

    @Override
    public int getItemCount() {
        return orderList != null ? orderList.size() : 0;
    }

    public static class OrderViewHolder extends RecyclerView.ViewHolder {
        TextView tvStatus, tvOrderDate, tvShopName, tvItemCount, tvTotalAmount;
        ImageView ivOrderThumb;
        CardView cardRoot;

        public OrderViewHolder(@NonNull View itemView) {
            super(itemView);
            cardRoot = (CardView) itemView; // Gốc là CardView
            tvStatus = itemView.findViewById(R.id.tvStatus);
            tvOrderDate = itemView.findViewById(R.id.tvOrderDate);
            tvShopName = itemView.findViewById(R.id.tvShopName);
            tvItemCount = itemView.findViewById(R.id.tvItemCount);
            tvTotalAmount = itemView.findViewById(R.id.tvTotalAmount);
            ivOrderThumb = itemView.findViewById(R.id.ivOrderThumb);
        }
    }
}

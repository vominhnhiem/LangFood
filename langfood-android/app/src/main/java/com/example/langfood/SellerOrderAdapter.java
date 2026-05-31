package com.example.langfood;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.Order;
import com.example.langfood.models.OrderItem;
import java.util.List;
import java.util.Locale;

public class SellerOrderAdapter extends RecyclerView.Adapter<SellerOrderAdapter.OrderViewHolder> {

    public interface OnOrderActionListener {
        void onConfirm(Order order);
        void onReady(Order order);
        void onCancel(Order order);
        void onItemClick(Order order);
    }

    private Context context;
    private List<Order> orderList;
    private OnOrderActionListener listener;

    public SellerOrderAdapter(Context context, List<Order> orderList, OnOrderActionListener listener) {
        this.context = context;
        this.orderList = orderList;
        this.listener = listener;
    }

    @NonNull
    @Override
    public OrderViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_order_seller, parent, false);
        return new OrderViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull OrderViewHolder holder, int position) {
        Order order = orderList.get(position);

        holder.tvOrderId.setText("Đơn hàng #" + order.getId());
        
        // Time formatting
        String timeStr = order.getCreatedAt();
        if (timeStr != null && timeStr.contains("T")) {
            try {
                // simple split for ISO dates like 2026-05-30T10:30:00
                String[] parts = timeStr.split("T");
                String date = parts[0];
                String time = parts[1].substring(0, 5);
                holder.tvOrderTime.setText(time + " - " + date);
            } catch (Exception e) {
                holder.tvOrderTime.setText(timeStr);
            }
        } else {
            holder.tvOrderTime.setText(timeStr);
        }

        holder.tvBuyerName.setText("Khách hàng: " + (order.getBuyerName() != null ? order.getBuyerName() : "Không tên"));
        holder.tvAddress.setText("Giao tới Sảnh: " + order.getDeliveryBuilding() + " - Phòng " + order.getDeliveryRoom());

        // Summarize items
        StringBuilder sb = new StringBuilder();
        if (order.getOrderItems() != null) {
            for (OrderItem item : order.getOrderItems()) {
                sb.append("- ").append(item.getQuantity()).append("x ").append(item.getProductName());
                if (item.getOptionsSummary() != null && !item.getOptionsSummary().isEmpty()) {
                    sb.append(" (").append(item.getOptionsSummary()).append(")");
                }
                if (item.getNote() != null && !item.getNote().isEmpty()) {
                    sb.append(" [Lưu ý: ").append(item.getNote()).append("]");
                }
                sb.append("\n");
            }
        }
        holder.tvItems.setText(sb.toString().trim());

        // Format Total Price
        holder.tvTotalPrice.setText(String.format(Locale.getDefault(), "%,.0fđ", order.getTotalAmount()));

        // Set action buttons visibility and tint depending on status
        String status = order.getStatus();
        if ("Pending".equalsIgnoreCase(status)) {
            holder.btnCancel.setVisibility(View.VISIBLE);
            holder.btnAction.setVisibility(View.VISIBLE);
            holder.btnAction.setText("NHẬN ĐƠN & NẤU");
            holder.btnAction.setBackgroundTintList(ColorStateList.valueOf(Color.parseColor("#FF5722")));
            holder.btnAction.setOnClickListener(v -> {
                if (listener != null) listener.onConfirm(order);
            });
            holder.btnCancel.setOnClickListener(v -> {
                if (listener != null) listener.onCancel(order);
            });
        } else if ("Preparing".equalsIgnoreCase(status)) {
            holder.btnCancel.setVisibility(View.GONE);
            holder.btnAction.setVisibility(View.VISIBLE);
            holder.btnAction.setText("ĐÃ NẤU XONG");
            holder.btnAction.setBackgroundTintList(ColorStateList.valueOf(Color.parseColor("#4CAF50")));
            holder.btnAction.setOnClickListener(v -> {
                if (listener != null) listener.onReady(order);
            });
        } else {
            // Completed, Delivered, Cancelled or Ready
            holder.btnCancel.setVisibility(View.GONE);
            holder.btnAction.setVisibility(View.GONE);
        }

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onItemClick(order);
        });
    }

    @Override
    public int getItemCount() {
        return orderList == null ? 0 : orderList.size();
    }

    public static class OrderViewHolder extends RecyclerView.ViewHolder {
        TextView tvOrderId, tvOrderTime, tvBuyerName, tvAddress, tvItems, tvTotalPrice;
        Button btnAction, btnCancel;

        public OrderViewHolder(@NonNull View itemView) {
            super(itemView);
            tvOrderId = itemView.findViewById(R.id.tvOrderIdSeller);
            tvOrderTime = itemView.findViewById(R.id.tvOrderTimeSeller);
            tvBuyerName = itemView.findViewById(R.id.tvBuyerNameSeller);
            tvAddress = itemView.findViewById(R.id.tvAddressSeller);
            tvItems = itemView.findViewById(R.id.tvItemsSeller);
            tvTotalPrice = itemView.findViewById(R.id.tvTotalPriceSeller);
            btnAction = itemView.findViewById(R.id.btnActionSeller);
            btnCancel = itemView.findViewById(R.id.btnCancelSeller);
        }
    }
}

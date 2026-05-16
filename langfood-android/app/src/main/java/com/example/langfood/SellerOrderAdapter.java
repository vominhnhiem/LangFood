package com.example.langfood;

import android.content.Context;
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

public class SellerOrderAdapter extends RecyclerView.Adapter<SellerOrderAdapter.ViewHolder> {

    private Context context;
    private List<Order> orderList;
    private OnOrderActionListener listener;

    public interface OnOrderActionListener {
        void onConfirm(Order order);
        void onReady(Order order);
        void onItemClick(Order order);
    }

    public SellerOrderAdapter(Context context, List<Order> orderList, OnOrderActionListener listener) {
        this.context = context;
        this.orderList = orderList;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_seller_order, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Order order = orderList.get(position);

        holder.tvOrderId.setText("Đơn hàng #" + order.getId());
        
        // Làm sạch chuỗi status để so khớp chính xác
        String rawStatus = (order.getStatus() != null) ? order.getStatus().trim() : "";
        
        holder.tvOrderStatus.setText(translateStatus(rawStatus));
        setStatusColor(holder.tvOrderStatus, rawStatus);

        holder.tvBuyerName.setText("Khách hàng: " + (order.getBuyerName() != null ? order.getBuyerName() : "N/A"));
        holder.tvDeliveryAddress.setText("Địa chỉ: " + (order.getDeliveryBuilding() != null ? order.getDeliveryBuilding() : "N/A"));
        
        double total = order.getTotalAmount();
        holder.tvTotalAmount.setText(String.format(Locale.getDefault(), "Tổng: %,.0fđ", total));

        // Hiển thị tóm tắt món ăn
        StringBuilder itemsSummary = new StringBuilder("Món ăn: ");
        if (order.getOrderItems() != null) {
            for (OrderItem item : order.getOrderItems()) {
                itemsSummary.append(item.getProductName() != null ? item.getProductName() : "Món ẩn").append(" (x").append(item.getQuantity()).append("), ");
            }
        }
        String summary = itemsSummary.toString();
        if (summary.endsWith(", ")) summary = summary.substring(0, summary.length() - 2);
        holder.tvOrderItems.setText(summary);

        // Logic hiển thị nút bấm linh hoạt
        if ("Pending".equalsIgnoreCase(rawStatus)) {
            holder.btnConfirmOrder.setVisibility(View.VISIBLE);
            holder.btnConfirmOrder.setText("Xác nhận");
            holder.btnConfirmOrder.setOnClickListener(v -> listener.onConfirm(order));
        } else if ("Preparing".equalsIgnoreCase(rawStatus)) {
            holder.btnConfirmOrder.setVisibility(View.VISIBLE);
            holder.btnConfirmOrder.setText("Đã nấu xong");
            holder.btnConfirmOrder.setOnClickListener(v -> listener.onReady(order));
        } else {
            // Các trạng thái khác (Ready, Delivering, Completed) không hiện nút thao tác
            holder.btnConfirmOrder.setVisibility(View.GONE);
        }

        holder.itemView.setOnClickListener(v -> listener.onItemClick(order));
    }

    private void setStatusColor(TextView tv, String status) {
        if (status == null) return;
        String s = status.toLowerCase().trim();
        switch (s) {
            case "pending": tv.setTextColor(Color.parseColor("#FFA500")); break; // Orange
            case "preparing": tv.setTextColor(Color.parseColor("#FFD700")); break; // Gold
            case "ready": tv.setTextColor(Color.parseColor("#008000")); break; // Green
            case "delivering": tv.setTextColor(Color.parseColor("#1E90FF")); break; // Blue
            case "completed": tv.setTextColor(Color.parseColor("#808080")); break; // Gray
            default: tv.setTextColor(Color.BLACK); break;
        }
    }

    private String translateStatus(String status) {
        if (status == null) return "N/A";
        String s = status.toLowerCase().trim();
        switch (s) {
            case "pending": return "Chờ xác nhận";
            case "preparing": return "Đang chế biến";
            case "ready": return "Chờ Shipper lấy";
            case "delivering": return "Đang giao hàng";
            case "completed": return "Đã hoàn thành";
            case "cancelled": return "Đã hủy";
            default: return status;
        }
    }

    @Override
    public int getItemCount() {
        return orderList.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvOrderId, tvOrderStatus, tvBuyerName, tvDeliveryAddress, tvOrderItems, tvTotalAmount;
        Button btnConfirmOrder;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvOrderId = itemView.findViewById(R.id.tvOrderId);
            tvOrderStatus = itemView.findViewById(R.id.tvOrderStatus);
            tvBuyerName = itemView.findViewById(R.id.tvBuyerName);
            tvDeliveryAddress = itemView.findViewById(R.id.tvDeliveryAddress);
            tvOrderItems = itemView.findViewById(R.id.tvOrderItems);
            tvTotalAmount = itemView.findViewById(R.id.tvTotalAmount);
            btnConfirmOrder = itemView.findViewById(R.id.btnConfirmOrder);
        }
    }
}

package com.example.langfood;

import android.content.Context;
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
        holder.tvOrderStatus.setText(translateStatus(order.getStatus()));
        holder.tvBuyerName.setText("Khách hàng: " + (order.getBuyerName() != null ? order.getBuyerName() : "N/A"));
        holder.tvDeliveryAddress.setText("Địa chỉ: " + (order.getDeliveryBuilding() != null ? order.getDeliveryBuilding() : "N/A"));
        holder.tvTotalAmount.setText(String.format(Locale.getDefault(), "Tổng: %,.0fđ", order.getTotalAmount()));

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

        // Nút xác nhận chỉ hiện khi đơn đang ở trạng thái Pending
        if ("Pending".equalsIgnoreCase(order.getStatus())) {
            holder.btnConfirmOrder.setVisibility(View.VISIBLE);
            holder.btnConfirmOrder.setOnClickListener(v -> listener.onConfirm(order));
        } else {
            holder.btnConfirmOrder.setVisibility(View.GONE);
        }
    }

    private String translateStatus(String status) {
        if (status == null) return "N/A";
        switch (status) {
            case "Pending": return "Chờ xác nhận";
            case "Shipping": return "Đang giao";
            case "Delivered": return "Đã giao";
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
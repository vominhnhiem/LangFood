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
import java.util.List;
import java.util.Locale;

public class ShipperOrderAdapter extends RecyclerView.Adapter<ShipperOrderAdapter.ViewHolder> {

    private Context context;
    private List<Order> orderList;
    private OnOrderClickListener listener;

    public interface OnOrderClickListener {
        void onAcceptClick(Order order);
        void onItemClick(Order order);
    }

    public ShipperOrderAdapter(Context context, List<Order> orderList, OnOrderClickListener listener) {
        this.context = context;
        this.orderList = orderList;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(R.layout.item_shipper_order, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Order order = orderList.get(position);
        
        holder.tvShopName.setText("Từ: " + (order.getShopName() != null ? order.getShopName() : "Cửa hàng"));
        holder.tvOrderTime.setText(order.getCreatedAt());
        
        String address = "📍 Tới: " + order.getDeliveryBuilding();
        if (order.getDeliveryRoom() != null && !order.getDeliveryRoom().isEmpty()) {
            address += " - Phòng " + order.getDeliveryRoom();
        }
        holder.tvOrderAddress.setText(address);

        double totalToCollect = order.getTotalAmount() + order.getShippingFee();
        holder.tvTotalAmount.setText(String.format(Locale.getDefault(), "Thu khách: %,.0fđ", totalToCollect));
        holder.tvShippingFee.setText("Công ship: 20,000đ");

        // KIỂM TRA TRẠNG THÁI ĐỂ ĐỔI NÚT
        if ("Delivering".equals(order.getStatus())) {
            holder.btnAcceptOrder.setText("Tiếp tục giao");
            holder.btnAcceptOrder.setBackgroundColor(Color.parseColor("#4CAF50")); // Màu xanh lá
        } else {
            holder.btnAcceptOrder.setText("Nhận đơn");
            holder.btnAcceptOrder.setBackgroundColor(Color.parseColor("#FF5722")); // Màu cam mặc định
        }

        holder.btnAcceptOrder.setOnClickListener(v -> listener.onAcceptClick(order));
        holder.itemView.setOnClickListener(v -> listener.onItemClick(order));
    }

    @Override
    public int getItemCount() {
        return orderList != null ? orderList.size() : 0;
    }

    public void updateList(List<Order> newList) {
        this.orderList = newList;
        notifyDataSetChanged();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvOrderTime, tvOrderAddress, tvTotalAmount, tvShopName, tvShippingFee;
        Button btnAcceptOrder;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvShopName = itemView.findViewById(R.id.tvShopName);
            tvOrderTime = itemView.findViewById(R.id.tvOrderTime);
            tvOrderAddress = itemView.findViewById(R.id.tvOrderAddress);
            tvTotalAmount = itemView.findViewById(R.id.tvTotalAmount);
            tvShippingFee = itemView.findViewById(R.id.tvShippingFee);
            btnAcceptOrder = itemView.findViewById(R.id.btnAcceptOrder);
        }
    }
}

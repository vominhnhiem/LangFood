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
        
        // Hiển thị tên Shop để shipper biết chỗ lấy hàng
        holder.tvShopName.setText("Từ: " + (order.getShopName() != null ? order.getShopName() : "Cửa hàng"));
        
        // Hiển thị thời gian đặt
        holder.tvOrderTime.setText(order.getCreatedAt());
        
        // Hiển thị địa chỉ giao hàng đầy đủ
        String address = "📍 Tới: " + order.getDeliveryBuilding();
        if (order.getDeliveryRoom() != null && !order.getDeliveryRoom().isEmpty()) {
            address += " - Phòng " + order.getDeliveryRoom();
        }
        holder.tvOrderAddress.setText(address);

        // Hiển thị tiền phí ship (Shipper nhận) và tổng tiền (nếu thu hộ)
        holder.tvShippingFee.setText(String.format(Locale.getDefault(), "Phí ship: %,.0fđ", order.getShippingFee()));
        holder.tvTotalAmount.setText(String.format(Locale.getDefault(), "Tổng thu: %,.0fđ", order.getTotalAmount()));

        holder.btnAcceptOrder.setOnClickListener(v -> listener.onAcceptClick(order));
        holder.itemView.setOnClickListener(v -> listener.onItemClick(order));
    }

    @Override
    public int getItemCount() {
        return orderList.size();
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
            tvShopName = itemView.findViewById(R.id.tvShopName); // Cần đảm bảo layout có ID này
            tvOrderTime = itemView.findViewById(R.id.tvOrderTime);
            tvOrderAddress = itemView.findViewById(R.id.tvOrderAddress);
            tvTotalAmount = itemView.findViewById(R.id.tvTotalAmount);
            tvShippingFee = itemView.findViewById(R.id.tvShippingFee); // Cần đảm bảo layout có ID này
            btnAcceptOrder = itemView.findViewById(R.id.btnAcceptOrder);
        }
    }
}

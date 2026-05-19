package com.example.langfood;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.Transaction;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class TransactionAdapter extends RecyclerView.Adapter<TransactionAdapter.ViewHolder> {

    private List<Transaction> transactions;

    public TransactionAdapter(List<Transaction> transactions) {
        this.transactions = transactions;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_transaction, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Transaction transaction = transactions.get(position);
        
        String description = transaction.getDescription();
        holder.tvDate.setText(formatDate(transaction.getCreatedAt()));
        
        double amount = transaction.getAmount();
        if (amount > 0) {
            holder.tvAmount.setText(String.format(Locale.getDefault(), "+%,.0fđ", amount));
            holder.tvAmount.setTextColor(Color.parseColor("#4CAF50")); // Xanh lá
        } else {
            holder.tvAmount.setText(String.format(Locale.getDefault(), "%,.0fđ", amount));
            holder.tvAmount.setTextColor(Color.parseColor("#D32F2F")); // Đỏ
        }

        String typeText = "";
        holder.tvDescription.setTextColor(Color.parseColor("#333333")); // Mặc định

        // CẬP NHẬT CÁC LOẠI GIAO DỊCH MỚI ĐỂ ĐỒNG BỘ VỚI BACKEND
        switch (transaction.getType()) {
            case "ORDER_REVENUE":
                typeText = "Doanh thu món ăn";
                holder.tvAmount.setTextColor(Color.parseColor("#4CAF50"));
                break;
            case "COD_COLLECTED":
                typeText = "Đối soát thu hộ (COD)";
                holder.tvDescription.setTextColor(Color.parseColor("#D32F2F"));
                break;
            case "SHIPPER_EARNING":
                typeText = "Tiền công giao hàng";
                holder.tvAmount.setTextColor(Color.parseColor("#4CAF50"));
                break;
            case "PAYMENT": 
                typeText = "Thanh toán đơn hàng"; 
                break;
            case "DEPOSIT": 
                typeText = "Nạp tiền ví"; 
                break;
            case "WITHDRAW": 
                typeText = "Rút tiền"; 
                break;
            case "ORDER_DEPOSIT": 
                typeText = "Ký quỹ đơn hàng"; 
                break;
            case "ORDER_REWARD": 
                typeText = "Hoàn vốn & Thưởng";
                break;
            default: 
                typeText = transaction.getType();
        }
        
        holder.tvDescription.setText(description);
        holder.tvType.setText(typeText);
    }

    private String formatDate(String dateStr) {
        if (dateStr == null || dateStr.isEmpty()) return "";
        try {
            String cleanDate = dateStr.contains(".") ? dateStr.substring(0, dateStr.indexOf(".")) : dateStr;
            SimpleDateFormat inputFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
            SimpleDateFormat outputFormat = new SimpleDateFormat("HH:mm dd/MM/yyyy", Locale.getDefault());
            Date date = inputFormat.parse(cleanDate);
            return outputFormat.format(date);
        } catch (Exception e) {
            return dateStr;
        }
    }

    @Override
    public int getItemCount() {
        return transactions != null ? transactions.size() : 0;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvDescription, tvDate, tvAmount, tvType;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvDescription = itemView.findViewById(R.id.tvDescription);
            tvDate = itemView.findViewById(R.id.tvDate);
            tvAmount = itemView.findViewById(R.id.tvAmount);
            tvType = itemView.findViewById(R.id.tvType);
        }
    }
}

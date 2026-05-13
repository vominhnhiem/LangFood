package com.example.langfood;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.Transaction;
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
        holder.tvDate.setText(transaction.getCreatedAt());
        
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

        switch (transaction.getType()) {
            case "PAYMENT": 
                typeText = "Thanh toán đơn hàng"; 
                break;
            case "ORDER_DEPOSIT": 
                typeText = "Ký quỹ (Shipper trừ vốn)"; 
                break;
            case "ORDER_REWARD": 
                typeText = "Hoàn vốn & Thưởng Shipper";
                description += " (Thưởng giữ chân Shipper)";
                holder.tvDescription.setTextColor(Color.parseColor("#E64A19")); // Cam đậm nổi bật
                break;
            case "DEPOSIT": 
                typeText = "Nạp tiền ví"; 
                break;
            case "WITHDRAW": 
                typeText = "Rút tiền"; 
                break;
            case "RECEIVE": 
                typeText = "Nhận tiền"; 
                break;
            default: 
                typeText = transaction.getType();
        }
        
        holder.tvDescription.setText(description);
        holder.tvType.setText(typeText);
    }

    @Override
    public int getItemCount() {
        return transactions.size();
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

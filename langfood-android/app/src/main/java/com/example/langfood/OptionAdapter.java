package com.example.langfood;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.ProductOption;
import java.util.List;
import java.util.Locale;

public class OptionAdapter extends RecyclerView.Adapter<OptionAdapter.OptionViewHolder> {

    private List<ProductOption> options;
    private int maxSelectable;
    private OnOptionSelectedListener listener;

    public interface OnOptionSelectedListener {
        void onOptionChanged();
    }

    public OptionAdapter(List<ProductOption> options, int maxSelectable, OnOptionSelectedListener listener) {
        this.options = options;
        this.maxSelectable = maxSelectable;
        this.listener = listener;
    }

    @NonNull
    @Override
    public OptionViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_product_option, parent, false);
        return new OptionViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull OptionViewHolder holder, int position) {
        ProductOption option = options.get(position);
        holder.cbOption.setText(option.getName());
        holder.tvOptionPrice.setText(String.format(Locale.getDefault(), "+%,.0fđ", option.getAdditionalPrice()));
        
        holder.cbOption.setOnCheckedChangeListener(null);
        holder.cbOption.setChecked(option.isSelected());
        holder.cbOption.setEnabled(option.isAvailable());
        
        if (!option.isAvailable()) {
            holder.cbOption.setText(option.getName() + " (Hết hàng)");
        }

        holder.cbOption.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (isChecked && maxSelectable == 1) {
                // Logic for RadioButton behavior (Single choice)
                for (ProductOption op : options) {
                    op.setSelected(false);
                }
                option.setSelected(true);
                notifyDataSetChanged();
            } else if (isChecked) {
                // Logic for CheckBox behavior (Multiple choice)
                int selectedCount = 0;
                for (ProductOption op : options) {
                    if (op.isSelected()) selectedCount++;
                }
                
                if (selectedCount < maxSelectable || maxSelectable <= 0) {
                    option.setSelected(true);
                } else {
                    holder.cbOption.setChecked(false);
                    option.setSelected(false);
                }
            } else {
                option.setSelected(false);
            }
            
            if (listener != null) listener.onOptionChanged();
        });
    }

    @Override
    public int getItemCount() {
        return options != null ? options.size() : 0;
    }

    static class OptionViewHolder extends RecyclerView.ViewHolder {
        CheckBox cbOption;
        TextView tvOptionPrice;

        public OptionViewHolder(@NonNull View itemView) {
            super(itemView);
            cbOption = itemView.findViewById(R.id.cbOption);
            tvOptionPrice = itemView.findViewById(R.id.tvOptionPrice);
        }
    }
}

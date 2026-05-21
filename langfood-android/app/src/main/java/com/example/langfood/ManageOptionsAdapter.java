package com.example.langfood;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.ProductOption;
import com.example.langfood.models.ProductOptionGroup;
import java.util.List;
import java.util.Locale;

public class ManageOptionsAdapter extends RecyclerView.Adapter<ManageOptionsAdapter.GroupViewHolder> {

    private List<ProductOptionGroup> groups;
    private OnOptionActionListener listener;

    public interface OnOptionActionListener {
        void onDeleteGroup(int groupId);
        void onAddOption(int groupId);
        void onDeleteOption(int optionId);
    }

    public ManageOptionsAdapter(List<ProductOptionGroup> groups, OnOptionActionListener listener) {
        this.groups = groups;
        this.listener = listener;
    }

    @NonNull
    @Override
    public GroupViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_manage_option_group, parent, false);
        return new GroupViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull GroupViewHolder holder, int position) {
        ProductOptionGroup group = groups.get(position);
        holder.tvGroupName.setText(group.getName());
        
        holder.btnDeleteGroup.setOnClickListener(v -> listener.onDeleteGroup(group.getId()));
        holder.btnAddOption.setOnClickListener(v -> listener.onAddOption(group.getId()));

        holder.layoutOptionsContainer.removeAllViews();
        if (group.getOptions() != null) {
            for (ProductOption option : group.getOptions()) {
                View optionView = LayoutInflater.from(holder.itemView.getContext())
                        .inflate(R.layout.item_manage_option_item, holder.layoutOptionsContainer, false);
                
                TextView tvName = optionView.findViewById(R.id.tvOptionName);
                TextView tvPrice = optionView.findViewById(R.id.tvOptionPrice);
                ImageButton btnDelete = optionView.findViewById(R.id.btnDeleteOption);

                tvName.setText(option.getName());
                tvPrice.setText(String.format(Locale.getDefault(), "+%,.0fđ", option.getAdditionalPrice()));
                
                btnDelete.setOnClickListener(v -> listener.onDeleteOption(option.getId()));
                
                holder.layoutOptionsContainer.addView(optionView);
            }
        }
    }

    @Override
    public int getItemCount() {
        return groups != null ? groups.size() : 0;
    }

    static class GroupViewHolder extends RecyclerView.ViewHolder {
        TextView tvGroupName;
        ImageButton btnDeleteGroup;
        Button btnAddOption;
        LinearLayout layoutOptionsContainer;

        public GroupViewHolder(@NonNull View itemView) {
            super(itemView);
            tvGroupName = itemView.findViewById(R.id.tvGroupName);
            btnDeleteGroup = itemView.findViewById(R.id.btnDeleteGroup);
            btnAddOption = itemView.findViewById(R.id.btnAddOption);
            layoutOptionsContainer = itemView.findViewById(R.id.layoutOptionsContainer);
        }
    }
}

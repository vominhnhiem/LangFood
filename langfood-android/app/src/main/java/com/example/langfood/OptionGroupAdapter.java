package com.example.langfood;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.models.ProductOptionGroup;
import java.util.List;

public class OptionGroupAdapter extends RecyclerView.Adapter<OptionGroupAdapter.GroupViewHolder> {

    private List<ProductOptionGroup> groups;
    private OptionAdapter.OnOptionSelectedListener listener;

    public OptionGroupAdapter(List<ProductOptionGroup> groups, OptionAdapter.OnOptionSelectedListener listener) {
        this.groups = groups;
        this.listener = listener;
    }

    @NonNull
    @Override
    public GroupViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_option_group, parent, false);
        return new GroupViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull GroupViewHolder holder, int position) {
        ProductOptionGroup group = groups.get(position);
        holder.tvGroupName.setText(group.getName());
        
        String hint = group.isRequired() ? "Bắt buộc" : "Không bắt buộc";
        if (group.getMaxSelectable() > 1) {
            hint += " • Tối đa " + group.getMaxSelectable();
        }
        holder.tvGroupHint.setText(hint);

        OptionAdapter optionAdapter = new OptionAdapter(group.getOptions(), group.getMaxSelectable(), listener);
        holder.rvOptions.setLayoutManager(new LinearLayoutManager(holder.itemView.getContext()));
        holder.rvOptions.setAdapter(optionAdapter);
    }

    @Override
    public int getItemCount() {
        return groups != null ? groups.size() : 0;
    }

    static class GroupViewHolder extends RecyclerView.ViewHolder {
        TextView tvGroupName, tvGroupHint;
        RecyclerView rvOptions;

        public GroupViewHolder(@NonNull View itemView) {
            super(itemView);
            tvGroupName = itemView.findViewById(R.id.tvGroupName);
            tvGroupHint = itemView.findViewById(R.id.tvGroupHint);
            rvOptions = itemView.findViewById(R.id.rvOptions);
        }
    }
}

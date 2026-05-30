package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.NotificationModel;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class NotificationAdapter extends RecyclerView.Adapter<NotificationAdapter.ViewHolder> {

    private final List<NotificationModel> notifications;
    private final ApiService apiService;

    public NotificationAdapter(List<NotificationModel> notifications) {
        this.notifications = notifications;
        this.apiService = ApiClient.getClient().create(ApiService.class);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_notification, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        NotificationModel model = notifications.get(position);

        holder.tvTitle.setText(model.getTitle());
        holder.tvContent.setText(model.getContent());
        holder.tvDate.setText(model.getCreatedAt());

        // Unread styling
        if (!model.isRead()) {
            holder.viewUnreadDot.setVisibility(View.VISIBLE);
            holder.layoutNotifRoot.setBackgroundColor(Color.parseColor("#FFF3E0")); // Cam nhạt chưa đọc
        } else {
            holder.viewUnreadDot.setVisibility(View.GONE);
            holder.layoutNotifRoot.setBackgroundColor(Color.WHITE);
        }

        // Customise icon based on type
        if (model.getType() == 1) { // Penalty (Sad/Red)
            holder.layoutIconBg.setBackgroundColor(Color.parseColor("#FFEBEE")); // Đỏ nhạt
            holder.ivIcon.setImageResource(android.R.drawable.ic_dialog_alert);
            holder.ivIcon.setColorFilter(Color.parseColor("#F44336"));
        } else if (model.getType() == 2) { // Refund/Joy (Green)
            holder.layoutIconBg.setBackgroundColor(Color.parseColor("#E8F5E9")); // Xanh lá nhạt
            holder.ivIcon.setImageResource(android.R.drawable.ic_dialog_info);
            holder.ivIcon.setColorFilter(Color.parseColor("#4CAF50"));
        } else { // General
            holder.layoutIconBg.setBackgroundColor(Color.parseColor("#FFF0ED"));
            holder.ivIcon.setImageResource(android.R.drawable.ic_popup_reminder);
            holder.ivIcon.setColorFilter(Color.parseColor("#EE4D2D"));
        }

        holder.itemView.setOnClickListener(v -> {
            // 1. Đánh dấu đã đọc
            if (!model.isRead()) {
                model.setRead(true);
                notifyItemChanged(position);
                apiService.markNotificationAsRead(model.getId()).enqueue(new Callback<Void>() {
                    @Override public void onResponse(Call<Void> call, Response<Void> response) {}
                    @Override public void onFailure(Call<Void> call, Throwable t) {}
                });
            }

            // 2. Mở màn hình tương ứng
            SharedPreferences prefs = v.getContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
            int roleId = prefs.getInt("ROLE_ID", 1);

            if (model.getType() == 1 && roleId == 2) { // Phạt của Quán ăn
                Intent intent = new Intent(v.getContext(), PenaltyDetailActivity.class);
                intent.putExtra("NOTIFICATION", model);
                v.getContext().startActivity(intent);
            } else {
                // Các thông báo thông thường hiển thị Dialog
                new androidx.appcompat.app.AlertDialog.Builder(v.getContext())
                        .setTitle(model.getTitle())
                        .setMessage(model.getContent())
                        .setPositiveButton("Đóng", null)
                        .show();
            }
        });
    }

    @Override
    public int getItemCount() {
        return notifications == null ? 0 : notifications.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder {
        TextView tvTitle, tvContent, tvDate;
        ImageView ivIcon;
        View layoutIconBg, layoutNotifRoot, viewUnreadDot;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            tvTitle = itemView.findViewById(R.id.tvNotifTitle);
            tvContent = itemView.findViewById(R.id.tvNotifContent);
            tvDate = itemView.findViewById(R.id.tvNotifDate);
            ivIcon = itemView.findViewById(R.id.ivNotifIcon);
            layoutIconBg = itemView.findViewById(R.id.layoutIconBg);
            layoutNotifRoot = itemView.findViewById(R.id.layoutNotifRoot);
            viewUnreadDot = itemView.findViewById(R.id.viewUnreadDot);
        }
    }
}

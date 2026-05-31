package com.example.langfood;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ProgressBar;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.NotificationModel;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class NotificationFragment extends Fragment {

    private SwipeRefreshLayout swipeRefresh;
    private RecyclerView rvNotifications;
    private ProgressBar progressBar;
    private View layoutEmpty;

    private NotificationAdapter adapter;
    private final List<NotificationModel> notificationList = new ArrayList<>();
    private ApiService apiService;
    private String userId;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_notification, container, false);

        initViews(view);
        setupRecyclerView();

        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");

        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::loadNotifications);

        if (userId.isEmpty()) {
            layoutEmpty.setVisibility(View.VISIBLE);
        } else {
            loadNotifications();
        }

        return view;
    }

    private void initViews(View view) {
        swipeRefresh = view.findViewById(R.id.swipeRefresh);
        rvNotifications = view.findViewById(R.id.rvNotifications);
        progressBar = view.findViewById(R.id.progressBar);
        layoutEmpty = view.findViewById(R.id.layoutEmpty);
    }

    private void setupRecyclerView() {
        adapter = new NotificationAdapter(notificationList);
        rvNotifications.setLayoutManager(new LinearLayoutManager(getContext()));
        rvNotifications.setAdapter(adapter);
    }

    private void loadNotifications() {
        if (userId.isEmpty() || apiService == null) {
            swipeRefresh.setRefreshing(false);
            return;
        }

        swipeRefresh.setRefreshing(true);
        progressBar.setVisibility(notificationList.isEmpty() ? View.VISIBLE : View.GONE);
        layoutEmpty.setVisibility(View.GONE);

        // Tự động đánh dấu đã đọc toàn bộ thông báo khi mở
        apiService.markAllNotificationsAsRead(userId).enqueue(new Callback<okhttp3.ResponseBody>() {
            @Override
            public void onResponse(@NonNull Call<okhttp3.ResponseBody> call, @NonNull Response<okhttp3.ResponseBody> response) {}

            @Override
            public void onFailure(@NonNull Call<okhttp3.ResponseBody> call, @NonNull Throwable t) {}
        });

        apiService.getNotifications(userId).enqueue(new Callback<List<NotificationModel>>() {
            @Override
            public void onResponse(@NonNull Call<List<NotificationModel>> call, @NonNull Response<List<NotificationModel>> response) {
                swipeRefresh.setRefreshing(false);
                progressBar.setVisibility(View.GONE);

                if (response.isSuccessful() && response.body() != null) {
                    notificationList.clear();
                    notificationList.addAll(response.body());
                    adapter.notifyDataSetChanged();

                    layoutEmpty.setVisibility(notificationList.isEmpty() ? View.VISIBLE : View.GONE);
                } else {
                    Toast.makeText(getContext(), "Lỗi tải thông báo: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(@NonNull Call<List<NotificationModel>> call, @NonNull Throwable t) {
                swipeRefresh.setRefreshing(false);
                progressBar.setVisibility(View.GONE);
                Toast.makeText(getContext(), "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onResume() {
        super.onResume();
        loadNotifications();
    }
}

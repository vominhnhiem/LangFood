package com.example.langfood;

import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.ComplaintModel;
import com.example.langfood.models.NotificationModel;
import com.google.android.material.card.MaterialCardView;

import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class PenaltyDetailActivity extends AppCompatActivity {

    private ImageView btnBack;
    private TextView tvPenaltyAmount;
    private TextView tvPenaltyOrderId;
    private TextView tvAdminExplanation;
    private MaterialCardView cardProof;
    private ImageView ivPenaltyProofImage;
    private ProgressBar progressBar;

    private ApiService apiService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_penalty_detail);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);

        btnBack.setOnClickListener(v -> finish());

        NotificationModel notification = (NotificationModel) getIntent().getSerializableExtra("NOTIFICATION");
        if (notification == null) {
            Toast.makeText(this, "Không có dữ liệu thông báo", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        int orderId = extractOrderId(notification);
        if (orderId == -1) {
            Toast.makeText(this, "Không xác định được mã đơn hàng", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        fetchComplaintDetail(orderId);
    }

    private void initViews() {
        btnBack = findViewById(R.id.btnBack);
        tvPenaltyAmount = findViewById(R.id.tvPenaltyAmount);
        tvPenaltyOrderId = findViewById(R.id.tvPenaltyOrderId);
        tvAdminExplanation = findViewById(R.id.tvAdminExplanation);
        cardProof = findViewById(R.id.cardProof);
        ivPenaltyProofImage = findViewById(R.id.ivPenaltyProofImage);
        progressBar = findViewById(R.id.progressBar);
    }

    private int extractOrderId(NotificationModel notification) {
        // Match orderId using regex matching: #(\d+)
        Pattern pattern = Pattern.compile("#(\\d+)");
        
        Matcher matcher = pattern.matcher(notification.getTitle() != null ? notification.getTitle() : "");
        if (matcher.find()) {
            try {
                return Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException e) {
                // ignore
            }
        }

        matcher = pattern.matcher(notification.getContent() != null ? notification.getContent() : "");
        if (matcher.find()) {
            try {
                return Integer.parseInt(matcher.group(1));
            } catch (NumberFormatException e) {
                // ignore
            }
        }

        return -1;
    }

    private void fetchComplaintDetail(int orderId) {
        progressBar.setVisibility(View.VISIBLE);
        apiService.getComplaintByOrderId(orderId).enqueue(new Callback<ComplaintModel>() {
            @Override
            public void onResponse(@NonNull Call<ComplaintModel> call, @NonNull Response<ComplaintModel> response) {
                progressBar.setVisibility(View.GONE);
                if (response.isSuccessful() && response.body() != null) {
                    bindComplaintData(response.body());
                } else {
                    Toast.makeText(PenaltyDetailActivity.this, "Không tìm thấy chi tiết khiếu nại cho đơn hàng này", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(@NonNull Call<ComplaintModel> call, @NonNull Throwable t) {
                progressBar.setVisibility(View.GONE);
                Toast.makeText(PenaltyDetailActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void bindComplaintData(ComplaintModel complaint) {
        tvPenaltyOrderId.setText(String.format(Locale.getDefault(), "Đơn hàng: #%d", complaint.getOrderId()));
        tvPenaltyAmount.setText(String.format(Locale.getDefault(), "-%,.0fđ", complaint.getPenaltyAmount()));
        tvPenaltyAmount.setTextColor(Color.parseColor("#F44336"));

        String explanation = complaint.getAdminReply();
        if (explanation == null || explanation.trim().isEmpty()) {
            explanation = "Không có lời giải thích nào từ Admin.";
        }
        tvAdminExplanation.setText(explanation);

        String imageProofUrl = complaint.getImageProof();
        if (imageProofUrl != null && !imageProofUrl.isEmpty()) {
            cardProof.setVisibility(View.VISIBLE);
            
            String fullImageUrl = imageProofUrl;
            if (!fullImageUrl.startsWith("http://") && !fullImageUrl.startsWith("https://")) {
                if (fullImageUrl.startsWith("/")) {
                    fullImageUrl = fullImageUrl.substring(1);
                }
                fullImageUrl = ApiClient.BASE_URL + fullImageUrl;
            }

            Glide.with(this)
                    .load(fullImageUrl)
                    .placeholder(android.R.drawable.ic_menu_gallery)
                    .error(android.R.drawable.ic_menu_report_image)
                    .into(ivPenaltyProofImage);
        } else {
            cardProof.setVisibility(View.GONE);
        }
    }
}

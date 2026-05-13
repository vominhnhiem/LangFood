package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.card.MaterialCardView;
import de.hdodenhof.circleimageview.CircleImageView;
import java.util.Locale;

public class ProfileActivity extends AppCompatActivity {

    private TextView tvUserName, tvUserRole, tvPhone, tvEmail, tvWalletBalance;
    private TextView btnEditProfile, btnChangePassword, btnAddFood, btnManageFood, btnRegisterPartner, btnLogout, btnShipperManage, btnManageOrder;
    private MaterialButton btnWalletDetail;
    private MaterialCardView cardWallet;
    private View dividerAddFood, dividerManageFood, dividerShipperManage, dividerManageOrder;
    private CircleImageView ivAvatar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile);

        // 1. Ánh xạ
        initViews();

        // 2. Load thông tin và kiểm tra quyền Seller
        loadUserInfo();

        // 3. Xử lý click
        setupClickListeners();
    }

    private void initViews() {
        tvUserName = findViewById(R.id.tvUserName);
        tvUserRole = findViewById(R.id.tvUserRole);
        tvPhone = findViewById(R.id.tvPhone);
        tvEmail = findViewById(R.id.tvEmail);
        ivAvatar = findViewById(R.id.ivAvatar);
        
        cardWallet = findViewById(R.id.cardWallet);
        tvWalletBalance = findViewById(R.id.tvWalletBalance);
        btnWalletDetail = findViewById(R.id.btnWalletDetail);

        btnEditProfile = findViewById(R.id.btnEditProfile);
        btnChangePassword = findViewById(R.id.btnChangePassword);
        btnAddFood = findViewById(R.id.btnAddFood);
        dividerAddFood = findViewById(R.id.dividerAddFood);
        btnManageFood = findViewById(R.id.btnManageFood);
        dividerManageFood = findViewById(R.id.dividerManageFood);
        btnManageOrder = findViewById(R.id.btnManageOrder);
        dividerManageOrder = findViewById(R.id.dividerManageOrder);
        btnShipperManage = findViewById(R.id.btnShipperManage);
        dividerShipperManage = findViewById(R.id.dividerShipperManage);
        btnRegisterPartner = findViewById(R.id.btnRegisterPartner);
        btnLogout = findViewById(R.id.btnLogout);
    }

    private void loadUserInfo() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        
        String fullName = prefs.getString("FULL_NAME", "Chưa cập nhật");
        String username = prefs.getString("USERNAME", "");
        String phone = prefs.getString("PHONE", "Chưa có SĐT");
        String avatarUrl = prefs.getString("AVATAR_URL", "");
        int roleId = prefs.getInt("ROLE_ID", 1); // 1: Buyer, 2: Seller, 3: Shipper

        tvUserName.setText(fullName);
        tvPhone.setText("SĐT: " + phone);
        tvEmail.setText("Username: " + username);

        // Load Avatar
        if (avatarUrl != null && !avatarUrl.isEmpty()) {
            String fullAvatarUrl = avatarUrl.startsWith("http") ? avatarUrl : ApiClient.BASE_URL + (avatarUrl.startsWith("/") ? avatarUrl.substring(1) : avatarUrl);
            Glide.with(this)
                    .load(fullAvatarUrl)
                    .placeholder(R.drawable.anhavt)
                    .error(R.drawable.anhavt)
                    .into(ivAvatar);
        }

        // Hiển thị Wallet Card cho Shop và Shipper
        if (roleId == 2 || roleId == 3) {
            cardWallet.setVisibility(View.VISIBLE);
            float balance = prefs.getFloat("WALLET_BALANCE", 0.0f);
            tvWalletBalance.setText(String.format(Locale.getDefault(), "%,.0fđ", (double) balance));
        } else {
            cardWallet.setVisibility(View.GONE);
        }

        // Kiểm tra quyền hiển thị các nút chức năng
        if (roleId == 2) { // Seller
            tvUserRole.setText("Sinh viên - Seller");
            btnManageFood.setVisibility(View.VISIBLE);
            if (dividerManageFood != null) dividerManageFood.setVisibility(View.VISIBLE);
            
            btnManageOrder.setVisibility(View.VISIBLE);
            if (dividerManageOrder != null) dividerManageOrder.setVisibility(View.VISIBLE);

            btnAddFood.setVisibility(View.GONE);
            btnRegisterPartner.setVisibility(View.GONE);
        } else if (roleId == 3) { // Shipper
            tvUserRole.setText("Shipper");
            btnShipperManage.setVisibility(View.VISIBLE);
            if (dividerShipperManage != null) dividerShipperManage.setVisibility(View.VISIBLE);
            btnRegisterPartner.setVisibility(View.GONE);
            btnManageOrder.setVisibility(View.GONE);
        } else {
            tvUserRole.setText("Sinh viên - Buyer");
            btnAddFood.setVisibility(View.GONE);
            btnManageFood.setVisibility(View.GONE);
            btnShipperManage.setVisibility(View.GONE);
            btnManageOrder.setVisibility(View.GONE);
            
            boolean isPending = prefs.getBoolean("IS_PENDING", false);
            if (isPending && btnRegisterPartner != null) {
                btnRegisterPartner.setText("⏳  Hồ sơ đang được xem xét");
                btnRegisterPartner.setTextColor(0xFF888888);
            } else if (btnRegisterPartner != null) {
                btnRegisterPartner.setText("🤝  Hợp tác với Làng Food");
                btnRegisterPartner.setTextColor(0xFF333333);
            }
        }
    }

    private void setupClickListeners() {
        btnWalletDetail.setOnClickListener(v -> {
            // Chuyển sang màn hình quản lý ví
            startActivity(new Intent(ProfileActivity.this, WalletActivity.class));
        });

        btnManageFood.setOnClickListener(v -> {
            startActivity(new Intent(ProfileActivity.this, ManageFoodActivity.class));
        });

        btnManageOrder.setOnClickListener(v -> {
            startActivity(new Intent(ProfileActivity.this, ManageOrderSellerActivity.class));
        });

        btnAddFood.setOnClickListener(v -> {
            startActivity(new Intent(ProfileActivity.this, AddFoodActivity.class));
        });

        btnEditProfile.setOnClickListener(v -> {
            startActivity(new Intent(ProfileActivity.this, EditProfileActivity.class));
        });

        btnChangePassword.setOnClickListener(v -> {
            startActivity(new Intent(ProfileActivity.this, ChangePasswordActivity.class));
        });

        if (btnRegisterPartner != null) {
            btnRegisterPartner.setOnClickListener(v -> {
                SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
                boolean isPending = prefs.getBoolean("IS_PENDING", false);
                if (isPending) {
                    Toast.makeText(this, "Hồ sơ của bạn đang được xem xét, vui lòng chờ!", Toast.LENGTH_LONG).show();
                } else {
                    startActivity(new Intent(ProfileActivity.this, OnboardingActivity.class));
                }
            });
        }

        if (btnShipperManage != null) {
            btnShipperManage.setOnClickListener(v -> {
                startActivity(new Intent(ProfileActivity.this, ShipperManageActivity.class));
            });
        }

        btnLogout.setOnClickListener(v -> {
            SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
            prefs.edit().clear().apply();
            Toast.makeText(this, "Đã đăng xuất", Toast.LENGTH_SHORT).show();
            startActivity(new Intent(ProfileActivity.this, LoginActivity.class));
            finishAffinity();
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadUserInfo();
    }
}

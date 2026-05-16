package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
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

        initViews();
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
        int roleId = prefs.getInt("ROLE_ID", 1);
        int shopId = prefs.getInt("SHOP_ID", -1);
        int shipperId = prefs.getInt("SHIPPER_ID", -1);
        boolean isPending = prefs.getBoolean("IS_PENDING", false);

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

        // 1. Hiển thị Wallet Card nếu là Shop hoặc Shipper
        if (shopId != -1 || shipperId != -1) {
            cardWallet.setVisibility(View.VISIBLE);
            float balance = prefs.getFloat("WALLET_BALANCE", 0.0f);
            tvWalletBalance.setText(String.format(Locale.getDefault(), "%,.0fđ", (double) balance));
        } else {
            cardWallet.setVisibility(View.GONE);
        }

        // 2. Thiết lập hiển thị Menu dựa trên ShopId và ShipperId
        // Hiển thị menu Seller nếu có Shop
        if (shopId != -1) {
            btnManageFood.setVisibility(View.VISIBLE);
            if (dividerManageFood != null) dividerManageFood.setVisibility(View.VISIBLE);
            btnManageOrder.setVisibility(View.VISIBLE);
            if (dividerManageOrder != null) dividerManageOrder.setVisibility(View.VISIBLE);
        } else {
            btnManageFood.setVisibility(View.GONE);
            if (dividerManageFood != null) dividerManageFood.setVisibility(View.GONE);
            btnManageOrder.setVisibility(View.GONE);
            if (dividerManageOrder != null) dividerManageOrder.setVisibility(View.GONE);
        }

        // Hiển thị menu Shipper nếu có ShipperId
        if (shipperId != -1) {
            btnShipperManage.setVisibility(View.VISIBLE);
            if (dividerShipperManage != null) dividerShipperManage.setVisibility(View.VISIBLE);
            tvUserRole.setText(shopId != -1 ? "Seller & Shipper" : "Shipper");
        } else {
            btnShipperManage.setVisibility(View.GONE);
            if (dividerShipperManage != null) dividerShipperManage.setVisibility(View.GONE);
            tvUserRole.setText(shopId != -1 ? "Sinh viên - Seller" : "Sinh viên - Buyer");
        }

        // 3. Xử lý nút Đăng ký (Register Partner)
        // Nếu đã là Seller HOẶC Shipper thì ẩn nút đăng ký
        if (shopId != -1 || shipperId != -1) {
            btnRegisterPartner.setVisibility(View.GONE);
        } else {
            btnRegisterPartner.setVisibility(View.VISIBLE);
            if (isPending) {
                btnRegisterPartner.setText("⏳  Hồ sơ Shipper đang chờ duyệt");
                btnRegisterPartner.setEnabled(false);
                btnRegisterPartner.setAlpha(0.6f);
            } else {
                btnRegisterPartner.setText("🤝  Đăng ký làm Shipper");
                btnRegisterPartner.setEnabled(true);
                btnRegisterPartner.setAlpha(1.0f);
            }
        }
        
        // Luôn ẩn nút thêm món ăn (đã gộp vào Manage Food)
        if (btnAddFood != null) btnAddFood.setVisibility(View.GONE);
        if (dividerAddFood != null) dividerAddFood.setVisibility(View.GONE);
    }

    private void setupClickListeners() {
        btnWalletDetail.setOnClickListener(v -> startActivity(new Intent(ProfileActivity.this, WalletActivity.class)));
        btnManageFood.setOnClickListener(v -> startActivity(new Intent(ProfileActivity.this, ManageFoodActivity.class)));
        btnManageOrder.setOnClickListener(v -> startActivity(new Intent(ProfileActivity.this, ManageOrderSellerActivity.class)));
        btnEditProfile.setOnClickListener(v -> startActivity(new Intent(ProfileActivity.this, EditProfileActivity.class)));
        btnChangePassword.setOnClickListener(v -> startActivity(new Intent(ProfileActivity.this, ChangePasswordActivity.class)));

        btnRegisterPartner.setOnClickListener(v -> {
            startActivity(new Intent(ProfileActivity.this, OnboardingActivity.class));
        });

        btnShipperManage.setOnClickListener(v -> startActivity(new Intent(ProfileActivity.this, ShipperManageActivity.class)));

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

package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.fragment.app.Fragment;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Shop;
import com.example.langfood.models.User;
import de.hdodenhof.circleimageview.CircleImageView;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SellerAccountFragment extends Fragment {

    private String userId;
    private ApiService apiService;

    // Views
    private CircleImageView ivAvatar;
    private TextView tvName, tvStatus;
    private View layoutEditProfile, layoutBankAccount, layoutChangePassword, layoutLogout;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");
        apiService = ApiClient.getClient().create(ApiService.class);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_seller_account, container, false);

        ivAvatar = view.findViewById(R.id.ivSellerProfileAvatar);
        tvName = view.findViewById(R.id.tvSellerProfileName);
        tvStatus = view.findViewById(R.id.tvSellerProfileStatus);
        layoutEditProfile = view.findViewById(R.id.layoutEditProfile);
        layoutBankAccount = view.findViewById(R.id.layoutBankAccount);
        layoutChangePassword = view.findViewById(R.id.layoutChangePassword);
        layoutLogout = view.findViewById(R.id.layoutLogout);

        setupListeners();

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        loadShopProfile();
    }

    private void setupListeners() {
        layoutEditProfile.setOnClickListener(v -> {
            Intent intent = new Intent(requireActivity(), ShopProfileEditActivity.class);
            startActivity(intent);
        });

        layoutBankAccount.setOnClickListener(v -> {
            Toast.makeText(getContext(), "Tính năng đang được phát triển", Toast.LENGTH_SHORT).show();
        });

        layoutChangePassword.setOnClickListener(v -> {
            Intent intent = new Intent(requireActivity(), ChangePasswordActivity.class);
            startActivity(intent);
        });

        layoutLogout.setOnClickListener(v -> showLogoutDialog());
    }

    private void loadShopProfile() {
        if (userId.isEmpty()) return;

        apiService.getUserById(userId).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    User user = response.body();
                    Shop shop = user.getShop();
                    if (shop != null) {
                        tvName.setText(shop.getName());
                        if (shop.isActive()) {
                            tvStatus.setText("Trạng thái: Đã duyệt");
                            tvStatus.setTextColor(android.graphics.Color.parseColor("#4CAF50"));
                            tvStatus.setBackgroundTintList(android.content.res.ColorStateList.valueOf(android.graphics.Color.parseColor("#E8F5E9")));
                        } else {
                            tvStatus.setText("Trạng thái: Tạm khóa");
                            tvStatus.setTextColor(android.graphics.Color.parseColor("#F44336"));
                            tvStatus.setBackgroundTintList(android.content.res.ColorStateList.valueOf(android.graphics.Color.parseColor("#FFEBEE")));
                        }

                        // Lưu SHOP_ID vào preferences phòng trường hợp bị mất
                        SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
                        prefs.edit().putInt("SHOP_ID", shop.getId()).apply();

                        String imageUrl = shop.getImageUrl();
                        if (imageUrl != null && !imageUrl.isEmpty()) {
                            String fullAvatarUrl = imageUrl.startsWith("http") ? imageUrl : ApiClient.BASE_URL + (imageUrl.startsWith("/") ? imageUrl.substring(1) : imageUrl);
                            Glide.with(SellerAccountFragment.this)
                                    .load(fullAvatarUrl)
                                    .placeholder(R.drawable.anhavt)
                                    .error(R.drawable.anhavt)
                                    .into(ivAvatar);
                        }
                    } else {
                        tvName.setText(user.getFullName());
                        tvStatus.setText("Chưa có thông tin Cửa hàng");
                    }
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Toast.makeText(getContext(), "Lỗi tải thông tin Cửa hàng", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showLogoutDialog() {
        new AlertDialog.Builder(requireContext())
                .setTitle("Đăng xuất")
                .setMessage("Bạn có muốn đăng xuất khỏi tài khoản Cửa hàng không?")
                .setPositiveButton("Đăng xuất", (dialog, which) -> {
                    SharedPreferences prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
                    prefs.edit().clear().apply();

                    Intent intent = new Intent(requireActivity(), LoginActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    requireActivity().finish();
                })
                .setNegativeButton("Hủy", null)
                .show();
    }
}

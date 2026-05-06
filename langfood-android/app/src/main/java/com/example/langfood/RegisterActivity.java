package com.example.langfood;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.view.View;

import com.google.android.material.button.MaterialButtonToggleGroup;

import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.User;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class RegisterActivity extends AppCompatActivity {

    private EditText etFullName, etUsername, etEmail, etPhone, etKtxBuilding, etKtxRoom, etPassword, etConfirmPassword;
    private EditText etShopName, etShopAddress, etCccd;
    private Button btnRegister;
    private TextView tvLoginLink;
    private LinearLayout llKtxInfo, llMerchantInfo;
    private MaterialButtonToggleGroup toggleRole;
    private int selectedAccountType = 0; // 0: SinhVien KTX, 1: External Merchant

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_register);

        // 1. Ánh xạ View
        initViews();

        // 2. Nút Đăng ký
        btnRegister.setOnClickListener(v -> handleRegister());

        // 3. Xử lý logic chọn Role
        toggleRole.addOnButtonCheckedListener((group, checkedId, isChecked) -> {
            if (isChecked) {
                if (checkedId == R.id.btnRoleStudent) {
                    selectedAccountType = 0;
                    llKtxInfo.setVisibility(View.VISIBLE);
                    llMerchantInfo.setVisibility(View.GONE);
                    etEmail.setHint("Email (vnu.edu.vn)");
                } else if (checkedId == R.id.btnRoleMerchant) {
                    selectedAccountType = 1;
                    llKtxInfo.setVisibility(View.GONE);
                    llMerchantInfo.setVisibility(View.VISIBLE);
                    etEmail.setHint("Email cá nhân");
                    // Xóa data KTX nếu đổi sang ngoại khu
                    etKtxBuilding.setText("");
                    etKtxRoom.setText("");
                }
            }
        });

        // 4. Link về Đăng nhập
        tvLoginLink.setOnClickListener(v -> {
            finish(); // Quay lại màn hình Login
        });
    }

    private void initViews() {
        etFullName = findViewById(R.id.etFullName);
        etUsername = findViewById(R.id.etUsername);
        etEmail = findViewById(R.id.etEmail);
        etPhone = findViewById(R.id.etPhone);
        etKtxBuilding = findViewById(R.id.etKtxBuilding);
        etKtxRoom = findViewById(R.id.etKtxRoom);
        etShopName = findViewById(R.id.etShopName);
        etShopAddress = findViewById(R.id.etShopAddress);
        etCccd = findViewById(R.id.etCccd);
        etPassword = findViewById(R.id.etPassword);
        etConfirmPassword = findViewById(R.id.etConfirmPassword);
        btnRegister = findViewById(R.id.btnRegister);
        tvLoginLink = findViewById(R.id.tvLoginLink);
        llKtxInfo = findViewById(R.id.llKtxInfo);
        llMerchantInfo = findViewById(R.id.llMerchantInfo);
        toggleRole = findViewById(R.id.toggleRole);
    }

    private void handleRegister() {
        String fullName = etFullName.getText().toString().trim();
        String username = etUsername.getText().toString().trim();
        String email = etEmail.getText().toString().trim();
        String phone = etPhone.getText().toString().trim();
        String ktxBuilding = etKtxBuilding.getText().toString().trim();
        String ktxRoom = etKtxRoom.getText().toString().trim();
        String pass = etPassword.getText().toString().trim();
        String confirmPass = etConfirmPassword.getText().toString().trim();
        String shopName = etShopName.getText().toString().trim();
        String shopAddress = etShopAddress.getText().toString().trim();
        String cccd = etCccd.getText().toString().trim();

        // Validation - Bỏ ktxBuilding và ktxRoom khỏi điều kiện bắt buộc
        if (fullName.isEmpty() || username.isEmpty() || email.isEmpty() || phone.isEmpty() || pass.isEmpty()) {
            Toast.makeText(this, "Vui lòng nhập đầy đủ thông tin cơ bản!", Toast.LENGTH_SHORT).show();
            return;
        }

        if (selectedAccountType == 1 && (shopName.isEmpty() || shopAddress.isEmpty() || cccd.isEmpty())) {
            Toast.makeText(this, "Vui lòng nhập đầy đủ thông tin quán ăn và CCCD!", Toast.LENGTH_SHORT).show();
            return;
        }

        if (!pass.equals(confirmPass)) {
            Toast.makeText(this, "Mật khẩu xác nhận không khớp!", Toast.LENGTH_SHORT).show();
            return;
        }

        // Tạo object User
        User newUser = new User();
        newUser.setFullName(fullName);
        newUser.setUsername(username);
        newUser.setEmail(email);
        newUser.setPhoneNumber(phone);
        // Có thể để trống nếu không ở KTX
        newUser.setKtxBuilding(ktxBuilding.isEmpty() ? "" : ktxBuilding);
        newUser.setKtxRoom(ktxRoom.isEmpty() ? "" : ktxRoom);
        
        // Thêm fields phụ
        newUser.setShopName(shopName.isEmpty() ? "" : shopName);
        newUser.setShopAddress(shopAddress.isEmpty() ? "" : shopAddress);
        newUser.setCccdNumber(cccd.isEmpty() ? "" : cccd);

        newUser.setPasswordHash(pass); 
        newUser.setRoleId(1); // 1: Buyer (Tất cả đăng ký mới đều là Buyer)
        newUser.setAccountType(selectedAccountType); // 0: SinhVien, 1: Merchant Ngoại Khu

        // Gọi API
        ApiService apiService = ApiClient.getClient().create(ApiService.class);
        apiService.register(newUser).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful()) {
                    if (selectedAccountType == 1) {
                        Toast.makeText(RegisterActivity.this, "Đăng ký thành công! Hồ sơ quán đang chờ duyệt.", Toast.LENGTH_LONG).show();
                    } else {
                        Toast.makeText(RegisterActivity.this, "Đăng ký thành công!", Toast.LENGTH_LONG).show();
                    }
                    finish();
                } else {
                    Toast.makeText(RegisterActivity.this, "Đăng ký thất bại! Kiểm tra lại thông tin.", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Log.e("REGISTER_ERROR", t.getMessage());
                Toast.makeText(RegisterActivity.this, "Lỗi kết nối Server!", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

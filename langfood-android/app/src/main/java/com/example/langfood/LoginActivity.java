package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.style.ForegroundColorSpan;
import android.text.style.UnderlineSpan;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.User;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends AppCompatActivity {

    private EditText etUsername, etPassword;
    private Button btnLogin;
    private TextView tvRegisterLink, tvAppTitle, tvForgotPassword, tvSlogan;
    private ImageView ivLogo;
    private ApiService apiService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Kiểm tra đăng nhập cũ để chuyển hướng ngay
        checkLoggedUser();

        setContentView(R.layout.activity_login);

        apiService = ApiClient.getClient().create(ApiService.class);

        etUsername = findViewById(R.id.etUsername);
        etPassword = findViewById(R.id.etPassword);
        btnLogin = findViewById(R.id.btnLogin);
        tvRegisterLink = findViewById(R.id.tvRegisterLink);
        tvAppTitle = findViewById(R.id.tvAppTitle);
        tvForgotPassword = findViewById(R.id.tvForgotPassword);
        ivLogo = findViewById(R.id.ivLogo);
        tvSlogan = findViewById(R.id.tvSlogan);

        // Thiết lập link đăng ký
        String content = "Chưa có tài khoản? Đăng ký ngay";
        SpannableString ss = new SpannableString(content);
        int start = content.indexOf("Đăng ký ngay");
        if (start != -1) {
            ss.setSpan(new UnderlineSpan(), start, content.length(), 0);
            ss.setSpan(new ForegroundColorSpan(Color.parseColor("#FF5722")), start, content.length(), 0);
        }
        tvRegisterLink.setText(ss);

        btnLogin.setOnClickListener(v -> {
            String username = etUsername.getText().toString().trim();
            String password = etPassword.getText().toString().trim();

            if (username.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Vui lòng nhập đầy đủ thông tin!", Toast.LENGTH_SHORT).show();
            } else {
                handleLogin(username, password);
            }
        });

        tvRegisterLink.setOnClickListener(v -> {
            startActivity(new Intent(LoginActivity.this, RegisterActivity.class));
        });

        if (tvForgotPassword != null) {
            tvForgotPassword.setOnClickListener(v -> startActivity(new Intent(LoginActivity.this, ForgotPasswordActivity.class)));
        }

        // --- ĐÃ GỠ BỎ TOÀN BỘ LOGIC CLICK LOGO/SLOGAN ĐỂ ĐIỀN NHANH TÀI KHOẢN ---
    }

    private void checkLoggedUser() {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", null);
        if (userId != null) {
            // Tất cả người dùng đã đăng nhập đều vào HomeActivity
            Intent intent = new Intent(this, HomeActivity.class);
            startActivity(intent);
            finish();
        }
    }

    private void handleLogin(String user, String pass) {
        User loginData = new User();
        loginData.setUsername(user);
        loginData.setPasswordHash(pass);

        apiService.login(loginData).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    User userResponse = response.body();
                    
                    // Lưu vào Local trước
                    saveUserToLocal(userResponse);
                    
                    Toast.makeText(LoginActivity.this, "Đăng nhập thành công!", Toast.LENGTH_SHORT).show();
                    
                    // Sau khi đăng nhập thành công, tất cả đều vào HomeActivity
                    Intent intent = new Intent(LoginActivity.this, HomeActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                    finish();
                } else {
                    Toast.makeText(LoginActivity.this, "Sai tài khoản hoặc mật khẩu!", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Toast.makeText(LoginActivity.this, "Lỗi kết nối server", Toast.LENGTH_LONG).show();
            }
        });
    }

    private void saveUserToLocal(User user) {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString("USER_ID", user.getId());
        editor.putString("USERNAME", user.getUsername());
        editor.putString("FULL_NAME", user.getFullName());
        editor.putString("PHONE", user.getPhoneNumber());
        editor.putString("AVATAR_URL", user.getAvatarUrl());
        editor.putInt("ROLE_ID", user.getRoleId());
        
        // Cực kỳ quan trọng: Lưu ID để các màn hình sau không bị crash
        if (user.getShop() != null) {
            editor.putInt("SHOP_ID", user.getShop().getId());
            editor.putString("SHOP_NAME", user.getShop().getName());
        } else {
            editor.putInt("SHOP_ID", -1);
        }

        if (user.getShipper() != null) {
            editor.putInt("SHIPPER_ID", user.getShipper().getId());
        } else {
            editor.putInt("SHIPPER_ID", -1);
        }

        if (user.getWallet() != null) {
            editor.putFloat("WALLET_BALANCE", (float) user.getWallet().getBalance());
        } else {
            editor.putFloat("WALLET_BALANCE", 0.0f);
        }

        // Sử dụng commit() thay vì apply() để đảm bảo dữ liệu được ghi vào disk ngay lập tức 
        // trước khi màn hình tiếp theo được mở và đọc dữ liệu này.
        editor.commit();
    }
}

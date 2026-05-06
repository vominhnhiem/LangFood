package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
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
    private TextView tvRegisterLink, tvAppTitle;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        // 1. Ánh xạ View
        etUsername = findViewById(R.id.etUsername);
        etPassword = findViewById(R.id.etPassword);
        btnLogin = findViewById(R.id.btnLogin);
        tvRegisterLink = findViewById(R.id.tvRegisterLink);
        tvAppTitle = findViewById(R.id.tvAppTitle);

        // Phím tắt bí mật: Nhấn giữ vào tiêu đề để điền tài khoản test (Seller)
        if (tvAppTitle != null) {
            tvAppTitle.setOnLongClickListener(v -> {
                etUsername.setText("seller_test");
                etPassword.setText("123456");
                Toast.makeText(this, "Đã điền tài khoản Seller Test", Toast.LENGTH_SHORT).show();
                btnLogin.performClick(); 
                return true;
            });
            
            // Nhấn bình thường vào tiêu đề để điền tài khoản Shipper test
            tvAppTitle.setOnClickListener(v -> {
                etUsername.setText("shipper_test");
                etPassword.setText("123456");
                Toast.makeText(this, "Đã điền tài khoản Shipper Test", Toast.LENGTH_SHORT).show();
            });
        }

        // 2. Xử lý sự kiện click Đăng nhập
        btnLogin.setOnClickListener(v -> {
            String username = etUsername.getText().toString().trim();
            String password = etPassword.getText().toString().trim();

            if (username.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Nhập đủ đi mày ơi!", Toast.LENGTH_SHORT).show();
            } else {
                handleLogin(username, password);
            }
        });

        // 3. Xử lý click chuyển sang màn hình Đăng ký
        if (tvRegisterLink != null) {
            tvRegisterLink.setOnClickListener(v -> {
                Intent intent = new Intent(LoginActivity.this, RegisterActivity.class);
                startActivity(intent);
            });
        }
    }

    private void handleLogin(String user, String pass) {
        // Tạo object gửi lên Backend
        User loginData = new User();
        loginData.setUsername(user);
        loginData.setPasswordHash(pass); // Backend sẽ check pass này

        ApiService apiService = ApiClient.getClient().create(ApiService.class);

        // Gọi API Login
        apiService.login(loginData).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    User userResponse = response.body();

                    // 3. Tối ưu hóa Authentication: Chặn Admin đăng nhập trên Mobile
                    if (userResponse.getRoleId() == 0) {
                        Toast.makeText(LoginActivity.this, "Tài khoản quản trị vui lòng truy cập hệ thống Web Admin", Toast.LENGTH_LONG).show();
                        return;
                    }

                    // Đăng nhập ngon lành -> Lưu lại toàn bộ thông tin để hiển thị ở Profile
                    saveUserToLocal(userResponse);

                    Toast.makeText(LoginActivity.this, "Chào mừng " + userResponse.getFullName(), Toast.LENGTH_SHORT).show();

                    // Chuyển sang Home
                    Intent intent = new Intent(LoginActivity.this, HomeActivity.class);
                    startActivity(intent);
                    finish(); // Đóng luôn màn login cho đỡ tốn ram
                } else {
                    Toast.makeText(LoginActivity.this, "Sai tài khoản hoặc mật khẩu!", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Log.e("API_ERROR", "Lỗi: " + t.getMessage());
                Toast.makeText(LoginActivity.this, "Không kết nối được với Server!", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void saveUserToLocal(User user) {
        SharedPreferences sharedPreferences = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("USER_ID", user.getId());
        editor.putString("USERNAME", user.getUsername());
        editor.putString("FULL_NAME", user.getFullName());
        editor.putString("PHONE", user.getPhoneNumber());
        editor.putString("BUILDING", user.getKtxBuilding());
        editor.putString("ROOM", user.getKtxRoom());
        editor.putInt("ROLE_ID", user.getRoleId());
        editor.apply();
    }
}
package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.style.ForegroundColorSpan;
import android.text.style.UnderlineSpan;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.User;

import java.io.IOException;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class LoginActivity extends AppCompatActivity {

    private EditText etUsername, etPassword;
    private Button btnLogin;
    private TextView tvRegisterLink, tvAppTitle, tvForgotPassword;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        etUsername = findViewById(R.id.etUsername);
        etPassword = findViewById(R.id.etPassword);
        btnLogin = findViewById(R.id.btnLogin);
        tvRegisterLink = findViewById(R.id.tvRegisterLink);
        tvAppTitle = findViewById(R.id.tvAppTitle);
        tvForgotPassword = findViewById(R.id.tvForgotPassword);

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
            tvForgotPassword.setOnClickListener(v -> {
                startActivity(new Intent(LoginActivity.this, ForgotPasswordActivity.class));
            });
        }

        setupTestShortcuts();
    }

    private void setupTestShortcuts() {
        if (tvAppTitle != null) {
            tvAppTitle.setOnLongClickListener(v -> {
                etUsername.setText("sell");
                etPassword.setText("123");
                btnLogin.performClick(); 
                return true;
            });
        }
    }

    private void handleLogin(String user, String pass) {
        User loginData = new User();
        loginData.setUsername(user);
        // Lưu ý quan trọng: Một số Backend yêu cầu tên trường là "password" khi login
        loginData.setPasswordHash(pass);

        ApiService apiService = ApiClient.getClient().create(ApiService.class);

        apiService.login(loginData).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    User userResponse = response.body();
                    if (userResponse.getRoleId() == 0) {
                        Toast.makeText(LoginActivity.this, "Admin vui lòng dùng Web", Toast.LENGTH_LONG).show();
                        return;
                    }
                    saveUserToLocal(userResponse);
                    Toast.makeText(LoginActivity.this, "Đăng nhập thành công!", Toast.LENGTH_SHORT).show();
                    startActivity(new Intent(LoginActivity.this, HomeActivity.class));
                    finish();
                } else {
                    String errorMsg = "Sai tài khoản hoặc mật khẩu!";
                    if (response.code() == 404) errorMsg = "Lỗi 404: Không tìm thấy API";
                    else if (response.code() == 500) errorMsg = "Lỗi 500: Server đang bị lỗi";
                    
                    Log.e("LOGIN_ERROR", "Code: " + response.code() + " Message: " + response.message());
                    Toast.makeText(LoginActivity.this, errorMsg, Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Log.e("LOGIN_FAILURE", t.getMessage());
                Toast.makeText(LoginActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_LONG).show();
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
        editor.putInt("ROLE_ID", user.getRoleId());
        editor.apply();
    }
}

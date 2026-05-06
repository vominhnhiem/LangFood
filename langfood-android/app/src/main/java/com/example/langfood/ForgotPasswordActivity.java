package com.example.langfood;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.google.android.material.textfield.TextInputEditText;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ForgotPasswordActivity extends AppCompatActivity {

    private TextInputEditText etUsernameForgot, etEmailForgot, etOtpForgot, etNewPassForgot;
    private Button btnSendOtp, btnResetPassword;
    private LinearLayout llStepEmail, llStepReset;
    private ImageView btnBack;
    private ApiService apiService;
    private String currentEmail;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_forgot_password);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);

        btnBack.setOnClickListener(v -> finish());

        btnSendOtp.setOnClickListener(v -> handleSendOtp());

        btnResetPassword.setOnClickListener(v -> handleResetPassword());
    }

    private void initViews() {
        etUsernameForgot = findViewById(R.id.etUsernameForgot);
        etEmailForgot = findViewById(R.id.etEmailForgot);
        etOtpForgot = findViewById(R.id.etOtpForgot);
        etNewPassForgot = findViewById(R.id.etNewPassForgot);
        btnSendOtp = findViewById(R.id.btnSendOtp);
        btnResetPassword = findViewById(R.id.btnResetPassword);
        llStepEmail = findViewById(R.id.llStepEmail);
        llStepReset = findViewById(R.id.llStepReset);
        btnBack = findViewById(R.id.btnBack);
    }

    private void handleSendOtp() {
        String username = etUsernameForgot.getText().toString().trim();
        String email = etEmailForgot.getText().toString().trim();
        
        if (username.isEmpty()) {
            etUsernameForgot.setError("Vui lòng nhập tên đăng nhập");
            return;
        }
        if (email.isEmpty()) {
            etEmailForgot.setError("Vui lòng nhập email");
            return;
        }

        btnSendOtp.setEnabled(false);
        btnSendOtp.setText("Đang kiểm tra...");

        apiService.sendOtp(email, username).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                btnSendOtp.setEnabled(true);
                btnSendOtp.setText("GỬI MÃ OTP");
                if (response.isSuccessful()) {
                    currentEmail = email;
                    llStepEmail.setVisibility(View.GONE);
                    llStepReset.setVisibility(View.VISIBLE);
                    Toast.makeText(ForgotPasswordActivity.this, "Mã OTP đã được gửi đến email của bạn", Toast.LENGTH_LONG).show();
                } else {
                    Toast.makeText(ForgotPasswordActivity.this, "Thông tin tài khoản hoặc email không khớp!", Toast.LENGTH_LONG).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                btnSendOtp.setEnabled(true);
                btnSendOtp.setText("GỬI MÃ OTP");
                Toast.makeText(ForgotPasswordActivity.this, "Lỗi kết nối", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void handleResetPassword() {
        String otp = etOtpForgot.getText().toString().trim();
        String newPass = etNewPassForgot.getText().toString().trim();

        if (otp.isEmpty()) {
            etOtpForgot.setError("Nhập mã OTP");
            return;
        }
        if (newPass.length() < 8) {
            etNewPassForgot.setError("Mật khẩu phải ít nhất 8 ký tự");
            return;
        }

        btnResetPassword.setEnabled(false);
        btnResetPassword.setText("Đang xử lý...");

        // Bước 1: Xác thực OTP
        apiService.verifyOtp(currentEmail, otp).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    // Bước 2: Đổi mật khẩu sau khi OTP đúng
                    executeReset(newPass);
                } else {
                    btnResetPassword.setEnabled(true);
                    btnResetPassword.setText("ĐẶT LẠI MẬT KHẨU");
                    Toast.makeText(ForgotPasswordActivity.this, "Mã OTP không chính xác hoặc hết hạn", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                btnResetPassword.setEnabled(true);
                btnResetPassword.setText("ĐẶT LẠI MẬT KHẨU");
                Toast.makeText(ForgotPasswordActivity.this, "Lỗi xác thực OTP", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void executeReset(String newPass) {
        apiService.resetPassword(currentEmail, newPass).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ForgotPasswordActivity.this, "Đổi mật khẩu thành công! Hãy đăng nhập lại.", Toast.LENGTH_LONG).show();
                    finish();
                } else {
                    btnResetPassword.setEnabled(true);
                    btnResetPassword.setText("ĐẶT LẠI MẬT KHẨU");
                    Toast.makeText(ForgotPasswordActivity.this, "Lỗi khi đặt lại mật khẩu", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                btnResetPassword.setEnabled(true);
                btnResetPassword.setText("ĐẶT LẠI MẬT KHẨU");
                Toast.makeText(ForgotPasswordActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

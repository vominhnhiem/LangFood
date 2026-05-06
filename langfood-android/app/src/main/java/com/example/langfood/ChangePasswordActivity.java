package com.example.langfood;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.google.android.material.textfield.TextInputEditText;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ChangePasswordActivity extends AppCompatActivity {

    private TextInputEditText etOldPassword, etNewPassword, etConfirmPassword;
    private Button btnSubmit;
    private ImageView btnBack;
    private ApiService apiService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_change_password);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);

        btnBack.setOnClickListener(v -> finish());
        btnSubmit.setOnClickListener(v -> handleChangePassword());
    }

    private void initViews() {
        etOldPassword = findViewById(R.id.etOldPassword);
        etNewPassword = findViewById(R.id.etNewPassword);
        etConfirmPassword = findViewById(R.id.etConfirmPassword);
        btnSubmit = findViewById(R.id.btnSubmit);
        btnBack = findViewById(R.id.btnBack);
    }

    private void handleChangePassword() {
        String oldPass = etOldPassword.getText().toString().trim();
        String newPass = etNewPassword.getText().toString().trim();
        String confirmPass = etConfirmPassword.getText().toString().trim();

        if (oldPass.isEmpty()) {
            etOldPassword.setError("Vui lòng nhập mật khẩu cũ");
            return;
        }
        if (newPass.length() < 8) {
            etNewPassword.setError("Mật khẩu mới phải có ít nhất 8 ký tự");
            return;
        }
        if (!newPass.equals(confirmPass)) {
            etConfirmPassword.setError("Mật khẩu xác nhận không khớp");
            return;
        }

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String userId = prefs.getString("USER_ID", "");

        btnSubmit.setEnabled(false);
        btnSubmit.setText("Đang xử lý...");

        apiService.changePassword(userId, oldPass, newPass).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                btnSubmit.setEnabled(true);
                btnSubmit.setText("CẬP NHẬT MẬT KHẨU");
                
                if (response.isSuccessful()) {
                    Toast.makeText(ChangePasswordActivity.this, "Đổi mật khẩu thành công!", Toast.LENGTH_SHORT).show();
                    finish();
                } else if (response.code() == 400) {
                    Toast.makeText(ChangePasswordActivity.this, "Mật khẩu cũ không chính xác", Toast.LENGTH_SHORT).show();
                    etOldPassword.setError("Sai mật khẩu");
                } else {
                    Log.e("API_ERROR", "Error code: " + response.code());
                    Toast.makeText(ChangePasswordActivity.this, "Lỗi Server (" + response.code() + "). Hãy kiểm tra lại Backend!", Toast.LENGTH_LONG).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                btnSubmit.setEnabled(true);
                btnSubmit.setText("CẬP NHẬT MẬT KHẨU");
                Toast.makeText(ChangePasswordActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }
}

package com.example.langfood;

import android.content.Intent;
import android.os.Bundle;
import android.text.SpannableString;
import android.text.TextUtils;
import android.text.style.UnderlineSpan;
import android.util.Patterns;
import android.view.View;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Building;
import com.example.langfood.models.User;
import com.example.langfood.models.UsernameCheckResponse;
import com.google.android.material.button.MaterialButtonToggleGroup;

import java.util.ArrayList;
import java.util.List;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class RegisterActivity extends AppCompatActivity {

    private EditText etFullName, etUsername, etEmail, etPhone, etKtxRoom, etPassword, etConfirmPassword;
    private EditText etShopName, etShopStreet, etCccd;
    private AutoCompleteTextView spinnerBuilding, spinnerArea;
    private Button btnRegister;
    private TextView tvLoginLink;
    private LinearLayout llKtxInfo, llMerchantInfo;
    private MaterialButtonToggleGroup toggleRole;
    private int selectedAccountType = 0; // 0: SinhVien KTX, 1: External Merchant
    private ApiService apiService;
    private List<Building> buildingList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Ép màn hình co lại và đẩy nội dung lên khi bàn phím hiện
        getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
        
        setContentView(R.layout.activity_register);

        apiService = ApiClient.getClient().create(ApiService.class);

        initViews();
        underlineLoginLink();
        loadBuildings();
        setupAreaSpinner();

        btnRegister.setOnClickListener(v -> handleRegister());

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
                    etEmail.setHint("Email");
                }
            }
        });

        tvLoginLink.setOnClickListener(v -> finish());
    }

    private void initViews() {
        etFullName = findViewById(R.id.etFullName);
        etUsername = findViewById(R.id.etUsername);
        etEmail = findViewById(R.id.etEmail);
        etPhone = findViewById(R.id.etPhone);
        spinnerBuilding = findViewById(R.id.spinnerBuilding);
        etKtxRoom = findViewById(R.id.etKtxRoom);
        etShopName = findViewById(R.id.etShopName);
        etShopStreet = findViewById(R.id.etShopStreet);
        spinnerArea = findViewById(R.id.spinnerArea);
        etCccd = findViewById(R.id.etCccd);
        etPassword = findViewById(R.id.etPassword);
        etConfirmPassword = findViewById(R.id.etConfirmPassword);
        btnRegister = findViewById(R.id.btnRegister);
        tvLoginLink = findViewById(R.id.tvLoginLink);
        llKtxInfo = findViewById(R.id.llKtxInfo);
        llMerchantInfo = findViewById(R.id.llMerchantInfo);
        toggleRole = findViewById(R.id.toggleRole);
    }

    private void loadBuildings() {
        apiService.getBuildings().enqueue(new Callback<List<Building>>() {
            @Override
            public void onResponse(Call<List<Building>> call, Response<List<Building>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    buildingList = response.body();
                    ArrayAdapter<Building> adapter = new ArrayAdapter<>(RegisterActivity.this,
                            android.R.layout.simple_list_item_1, buildingList);
                    spinnerBuilding.setAdapter(adapter);
                } else {
                    Toast.makeText(RegisterActivity.this, "Không thể tải danh sách tòa nhà", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<List<Building>> call, Throwable t) {
                Toast.makeText(RegisterActivity.this, "Lỗi kết nối tải tòa nhà", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupAreaSpinner() {
        String[] areas = {"Khu phố 8","Khu phố 12","Tân Quý","Tân Hòa","Khác"};
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, areas);
        spinnerArea.setAdapter(adapter);
    }

    private void underlineLoginLink() {
        String text = "Đã có tài khoản? Đăng nhập";
        SpannableString ss = new SpannableString(text);
        int start = text.indexOf("Đăng nhập");
        if (start != -1) {
            ss.setSpan(new UnderlineSpan(), start, text.length(), 0);
        }
        tvLoginLink.setText(ss);
    }

    private boolean validateData() {
        boolean isValid = true;
        if (etFullName.getText().toString().trim().isEmpty()) { etFullName.setError("Họ tên không được trống"); isValid = false; }
        if (etUsername.getText().toString().trim().isEmpty()) { etUsername.setError("Tên đăng nhập không được trống"); isValid = false; }
        String email = etEmail.getText().toString().trim();
        if (email.isEmpty() || !Patterns.EMAIL_ADDRESS.matcher(email).matches()) { etEmail.setError("Email không hợp lệ"); isValid = false; }
        String phone = etPhone.getText().toString().trim();
        if (phone.length() != 10 || !phone.startsWith("0")) { etPhone.setError("SĐT phải đúng 10 số và bắt đầu bằng 0"); isValid = false; }
        if (etPassword.getText().toString().trim().length() < 8) { etPassword.setError("Mật khẩu ít nhất 8 ký tự"); isValid = false; }
        if (!etPassword.getText().toString().trim().equals(etConfirmPassword.getText().toString().trim())) { etConfirmPassword.setError("Mật khẩu không khớp"); isValid = false; }
        
        if (selectedAccountType == 0) {
            if (spinnerBuilding.getText().toString().isEmpty()) {
                spinnerBuilding.setError("Vui lòng chọn tòa nhà");
                isValid = false;
            }
            if (etKtxRoom.getText().toString().trim().isEmpty()) { etKtxRoom.setError("Vui lòng nhập phòng"); isValid = false; }
        } else {
            if (etShopName.getText().toString().trim().isEmpty()) { etShopName.setError("Vui lòng nhập tên quán"); isValid = false; }
            if (etShopStreet.getText().toString().trim().isEmpty()) { etShopStreet.setError("Vui lòng nhập số nhà, tên đường"); isValid = false; }
            if (spinnerArea.getText().toString().isEmpty()) { spinnerArea.setError("Vui lòng chọn Khu/Ấp"); isValid = false; }
            if (etCccd.getText().toString().trim().isEmpty()) { etCccd.setError("Vui lòng nhập CCCD"); isValid = false; }
        }
        return isValid;
    }

    private void handleRegister() {
        if (!validateData()) return;

        btnRegister.setEnabled(false);
        String username = etUsername.getText().toString().trim();
        String email = etEmail.getText().toString().trim();
        String phone = etPhone.getText().toString().trim();

        Toast.makeText(this, "Đang kiểm tra thông tin...", Toast.LENGTH_SHORT).show();

        apiService.checkUsername(username).enqueue(new Callback<UsernameCheckResponse>() {
            @Override
            public void onResponse(Call<UsernameCheckResponse> call, Response<UsernameCheckResponse> response) {
                if (response.isSuccessful() && response.body() != null && response.body().isExists()) {
                    etUsername.setError("Tên đăng nhập này đã tồn tại!");
                    btnRegister.setEnabled(true);
                } else {
                    checkEmailDuplication(email, phone);
                }
            }
            @Override public void onFailure(Call<UsernameCheckResponse> call, Throwable t) { 
                btnRegister.setEnabled(true);
                Toast.makeText(RegisterActivity.this, "Lỗi kết nối Server!", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void checkEmailDuplication(String email, String phone) {
        apiService.checkEmail(email).enqueue(new Callback<UsernameCheckResponse>() {
            @Override
            public void onResponse(Call<UsernameCheckResponse> call, Response<UsernameCheckResponse> response) {
                if (response.isSuccessful() && response.body() != null && response.body().isExists()) {
                    etEmail.setError("Email này đã được sử dụng!");
                    btnRegister.setEnabled(true);
                } else {
                    checkPhoneDuplication(email, phone);
                }
            }
            @Override public void onFailure(Call<UsernameCheckResponse> call, Throwable t) { btnRegister.setEnabled(true); }
        });
    }

    private void checkPhoneDuplication(String email, String phone) {
        apiService.checkPhone(phone).enqueue(new Callback<UsernameCheckResponse>() {
            @Override
            public void onResponse(Call<UsernameCheckResponse> call, Response<UsernameCheckResponse> response) {
                if (response.isSuccessful() && response.body() != null && response.body().isExists()) {
                    etPhone.setError("Số điện thoại này đã được sử dụng!");
                    btnRegister.setEnabled(true);
                } else {
                    sendOtpToEmail(email);
                }
            }
            @Override public void onFailure(Call<UsernameCheckResponse> call, Throwable t) { btnRegister.setEnabled(true); }
        });
    }

    private void sendOtpToEmail(String email) {
        Toast.makeText(this, "Đang gửi OTP về Gmail...", Toast.LENGTH_SHORT).show();
        apiService.sendOtp(email, null).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                btnRegister.setEnabled(true);
                if (response.isSuccessful()) {
                    showOtpDialog(email);
                } else {
                    Toast.makeText(RegisterActivity.this, "Lỗi gửi mail! Kiểm tra lại Gmail.", Toast.LENGTH_SHORT).show();
                }
            }
            @Override public void onFailure(Call<ResponseBody> call, Throwable t) { btnRegister.setEnabled(true); }
        });
    }

    private void showOtpDialog(String email) {
        final EditText etOtp = new EditText(this);
        etOtp.setHint("Mã 6 số");
        etOtp.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        etOtp.setPadding(60, 40, 60, 40);

        new AlertDialog.Builder(this)
                .setTitle("Xác thực Email")
                .setMessage("Mã OTP đã được gửi đến: " + email)
                .setView(etOtp)
                .setCancelable(false)
                .setPositiveButton("Xác nhận", (dialog, which) -> {
                    String otp = etOtp.getText().toString().trim();
                    verifyOtp(email, otp);
                })
                .setNegativeButton("Hủy", (dialog, which) -> dialog.dismiss())
                .show();
    }

    private void verifyOtp(String email, String otp) {
        apiService.verifyOtp(email, otp).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    executeFinalRegistration();
                } else {
                    Toast.makeText(RegisterActivity.this, "Mã OTP sai hoặc hết hạn!", Toast.LENGTH_SHORT).show();
                    showOtpDialog(email);
                }
            }
            @Override public void onFailure(Call<ResponseBody> call, Throwable t) { }
        });
    }

    private void executeFinalRegistration() {
        User u = new User();
        u.setFullName(etFullName.getText().toString().trim());
        u.setUsername(etUsername.getText().toString().trim());
        u.setEmail(etEmail.getText().toString().trim());
        u.setPhoneNumber(etPhone.getText().toString().trim());

        if (selectedAccountType == 0) {
            String selectedBuildingName = spinnerBuilding.getText().toString();
            Building selectedBuilding = null;
            for (Building b : buildingList) {
                if (b.getName().equals(selectedBuildingName)) {
                    selectedBuilding = b;
                    break;
                }
            }
            if (selectedBuilding != null) {
                u.setBuildingId(selectedBuilding.getId());
            }
            u.setKtxRoom(etKtxRoom.getText().toString().trim());
            u.setAccountType(0); // 0: SinhVien KTX
        } else {
            u.setShopName(etShopName.getText().toString().trim());
            String address = etShopStreet.getText().toString().trim() + ", " + spinnerArea.getText().toString();
            u.setShopAddress(address);
            u.setCccdNumber(etCccd.getText().toString().trim());
            u.setAccountType(1); // 1: External Merchant
        }

        u.setPasswordHash(etPassword.getText().toString().trim());

        apiService.register(u).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(RegisterActivity.this, "Đăng ký thành công!", Toast.LENGTH_LONG).show();
                    startActivity(new Intent(RegisterActivity.this, LoginActivity.class));
                    finish();
                } else {
                    Toast.makeText(RegisterActivity.this, "Đăng ký thất bại!", Toast.LENGTH_SHORT).show();
                    btnRegister.setEnabled(true);
                }
            }
            @Override public void onFailure(Call<User> call, Throwable t) { 
                btnRegister.setEnabled(true);
                Toast.makeText(RegisterActivity.this, "Lỗi kết nối Server!", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

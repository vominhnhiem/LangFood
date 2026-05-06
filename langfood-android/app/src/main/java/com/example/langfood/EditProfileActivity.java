package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.User;
import de.hdodenhof.circleimageview.CircleImageView;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.Map;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class EditProfileActivity extends AppCompatActivity {

    private static final int PICK_IMAGE_REQUEST = 1;
    private CircleImageView ivEditAvatar;
    private EditText etFullName, etPhone, etBuilding, etRoom;
    private Button btnSave;
    private ImageView btnBack;
    private ApiService apiService;
    private String userId;
    private User currentUser;
    private Uri imageUri;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_edit_profile);

        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");

        initViews();
        loadUserDetails();

        btnBack.setOnClickListener(v -> finish());
        findViewById(R.id.btnPickAvatar).setOnClickListener(v -> openGallery());
        btnSave.setOnClickListener(v -> saveChanges());
    }

    private void initViews() {
        ivEditAvatar = findViewById(R.id.ivEditAvatar);
        etFullName = findViewById(R.id.etEditFullName);
        etPhone = findViewById(R.id.etEditPhone);
        etBuilding = findViewById(R.id.etEditBuilding);
        etRoom = findViewById(R.id.etEditRoom);
        btnSave = findViewById(R.id.btnSaveProfile);
        btnBack = findViewById(R.id.btnBack);
    }

    private void loadUserDetails() {
        apiService.getUserById(userId).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    currentUser = response.body();
                    etFullName.setText(currentUser.getFullName());
                    etPhone.setText(currentUser.getPhoneNumber());
                    etBuilding.setText(currentUser.getKtxBuilding());
                    etRoom.setText(currentUser.getKtxRoom());

                    updateAvatarUI(currentUser.getAvatarUrl());
                } else {
                    Toast.makeText(EditProfileActivity.this, "Không thể tải thông tin: " + response.message(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Toast.makeText(EditProfileActivity.this, "Lỗi kết nối tải thông tin", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void updateAvatarUI(String path) {
        String avatarUrl = path;
        if (avatarUrl != null && !avatarUrl.startsWith("http")) {
            avatarUrl = ApiClient.BASE_URL + (avatarUrl.startsWith("/") ? avatarUrl.substring(1) : avatarUrl);
        }
        Glide.with(this)
                .load(avatarUrl)
                .placeholder(R.drawable.anhavt)
                .into(ivEditAvatar);
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null) {
            imageUri = data.getData();
            uploadAvatar(); 
        }
    }

    private void uploadAvatar() {
        try {
            File file = new File(getCacheDir(), "temp_avatar.jpg");
            InputStream inputStream = getContentResolver().openInputStream(imageUri);
            FileOutputStream outputStream = new FileOutputStream(file);
            byte[] buffer = new byte[1024];
            int read;
            while ((read = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
            }
            outputStream.flush();
            outputStream.close();
            inputStream.close();

            RequestBody requestFile = RequestBody.create(MediaType.parse(getContentResolver().getType(imageUri)), file);
            MultipartBody.Part body = MultipartBody.Part.createFormData("image", file.getName(), requestFile);

            // Sửa lại ApiService để nhận về URL mới nếu cần, hoặc load lại User
            apiService.uploadAvatar(userId, body).enqueue(new Callback<Void>() {
                @Override
                public void onResponse(Call<Void> call, Response<Void> response) {
                    if (response.isSuccessful()) {
                        Toast.makeText(EditProfileActivity.this, "Đã cập nhật ảnh đại diện", Toast.LENGTH_SHORT).show();
                        // Load lại thông tin user để lấy AvatarUrl mới nhất từ server
                        loadUserDetails();
                    }
                }

                @Override
                public void onFailure(Call<Void> call, Throwable t) {
                    Toast.makeText(EditProfileActivity.this, "Lỗi upload ảnh", Toast.LENGTH_SHORT).show();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void saveChanges() {
        String fullName = etFullName.getText().toString().trim();
        String phone = etPhone.getText().toString().trim();
        String building = etBuilding.getText().toString().trim();
        String room = etRoom.getText().toString().trim();

        if (fullName.isEmpty()) {
            Toast.makeText(this, "Họ tên không được để trống", Toast.LENGTH_SHORT).show();
            return;
        }

        currentUser.setFullName(fullName);
        currentUser.setPhoneNumber(phone);
        currentUser.setKtxBuilding(building);
        currentUser.setKtxRoom(room);

        apiService.updateUser(userId, currentUser).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    updateLocalPrefs(response.body());
                    Toast.makeText(EditProfileActivity.this, "Đã lưu thay đổi", Toast.LENGTH_SHORT).show();
                    finish(); // Nhảy về màn hình Profile
                } else {
                    Toast.makeText(EditProfileActivity.this, "Lưu thất bại: " + response.message(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Toast.makeText(EditProfileActivity.this, "Lỗi kết nối khi lưu", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void updateLocalPrefs(User user) {
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString("FULL_NAME", user.getFullName());
        editor.putString("PHONE", user.getPhoneNumber());
        editor.putString("BUILDING", user.getKtxBuilding());
        editor.putString("ROOM", user.getKtxRoom());
        editor.putString("AVATAR_URL", user.getAvatarUrl()); // Lưu link ảnh mới
        editor.apply();
    }
}

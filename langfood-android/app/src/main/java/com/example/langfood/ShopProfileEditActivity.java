package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Shop;
import com.example.langfood.models.User;
import de.hdodenhof.circleimageview.CircleImageView;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ShopProfileEditActivity extends AppCompatActivity {

    private static final int PICK_IMAGE_REQUEST = 2;
    private CircleImageView ivShopAvatar;
    private EditText etShopName, etShopDescription, etShopAddress, etShopPhone;
    private Button btnSave;
    private ImageView btnBack;
    private ApiService apiService;
    private String userId;
    private int shopId;
    private Shop currentShop;
    private User currentUser;
    private Uri imageUri;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shop_profile_edit);

        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");
        shopId = prefs.getInt("SHOP_ID", -1);

        initViews();
        loadShopDetails();

        btnBack.setOnClickListener(v -> finish());
        findViewById(R.id.btnPickShopAvatar).setOnClickListener(v -> openGallery());
        btnSave.setOnClickListener(v -> saveShopProfileChanges());
    }

    private void initViews() {
        ivShopAvatar = findViewById(R.id.ivShopAvatar);
        etShopName = findViewById(R.id.etShopName);
        etShopDescription = findViewById(R.id.etShopDescription);
        etShopAddress = findViewById(R.id.etShopAddress);
        etShopPhone = findViewById(R.id.etShopPhone);
        btnSave = findViewById(R.id.btnSaveShopProfile);
        btnBack = findViewById(R.id.btnBack);
    }

    private void loadShopDetails() {
        if (userId.isEmpty()) return;

        apiService.getUserById(userId).enqueue(new Callback<User>() {
            @Override
            public void onResponse(Call<User> call, Response<User> response) {
                if (response.isSuccessful() && response.body() != null) {
                    currentUser = response.body();
                    currentShop = currentUser.getShop();

                    if (currentShop != null) {
                        etShopName.setText(currentShop.getName());
                        etShopDescription.setText(currentShop.getDescription());
                        etShopAddress.setText(currentShop.getAddress());
                        etShopPhone.setText(currentUser.getPhoneNumber());

                        updateShopAvatarUI(currentShop.getImageUrl());
                    } else {
                        Toast.makeText(ShopProfileEditActivity.this, "Không tìm thấy thông tin cửa hàng của bạn", Toast.LENGTH_SHORT).show();
                    }
                } else {
                    Toast.makeText(ShopProfileEditActivity.this, "Lỗi tải thông tin: " + response.message(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<User> call, Throwable t) {
                Toast.makeText(ShopProfileEditActivity.this, "Lỗi kết nối máy chủ", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void updateShopAvatarUI(String path) {
        String avatarUrl = path;
        if (avatarUrl != null && !avatarUrl.startsWith("http")) {
            avatarUrl = ApiClient.BASE_URL + (avatarUrl.startsWith("/") ? avatarUrl.substring(1) : avatarUrl);
        }
        Glide.with(this)
                .load(avatarUrl)
                .placeholder(R.drawable.anhavt)
                .into(ivShopAvatar);
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
            uploadShopAvatar();
        }
    }

    private void uploadShopAvatar() {
        if (shopId == -1) {
            Toast.makeText(this, "Không có ID cửa hàng để cập nhật ảnh", Toast.LENGTH_SHORT).show();
            return;
        }

        try {
            File file = new File(getCacheDir(), "temp_shop_avatar.jpg");
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

            apiService.uploadShopImage(shopId, body).enqueue(new Callback<ResponseBody>() {
                @Override
                public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                    if (response.isSuccessful()) {
                        Toast.makeText(ShopProfileEditActivity.this, "Đã cập nhật ảnh đại diện quán ăn", Toast.LENGTH_SHORT).show();
                        loadShopDetails();
                    } else {
                        Toast.makeText(ShopProfileEditActivity.this, "Upload ảnh thất bại", Toast.LENGTH_SHORT).show();
                    }
                }

                @Override
                public void onFailure(Call<ResponseBody> call, Throwable t) {
                    Toast.makeText(ShopProfileEditActivity.this, "Lỗi kết nối khi upload ảnh", Toast.LENGTH_SHORT).show();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void saveShopProfileChanges() {
        String name = etShopName.getText().toString().trim();
        String description = etShopDescription.getText().toString().trim();
        String address = etShopAddress.getText().toString().trim();
        String phone = etShopPhone.getText().toString().trim();

        if (name.isEmpty()) {
            Toast.makeText(this, "Tên quán ăn không được để trống", Toast.LENGTH_SHORT).show();
            return;
        }

        if (currentShop == null || currentUser == null) {
            Toast.makeText(this, "Không có dữ liệu để lưu thay đổi", Toast.LENGTH_SHORT).show();
            return;
        }

        currentShop.setName(name);
        currentShop.setDescription(description);
        currentShop.setAddress(address);
        currentUser.setPhoneNumber(phone);

        // Bước 1: Cập nhật thông tin quán
        apiService.updateShop(shopId, currentShop).enqueue(new Callback<Shop>() {
            @Override
            public void onResponse(Call<Shop> call, Response<Shop> response) {
                if (response.isSuccessful()) {
                    // Bước 2: Cập nhật thông tin User (Số điện thoại liên lạc)
                    apiService.updateUser(userId, currentUser).enqueue(new Callback<User>() {
                        @Override
                        public void onResponse(Call<User> call, Response<User> response) {
                            if (response.isSuccessful()) {
                                Toast.makeText(ShopProfileEditActivity.this, "Đã cập nhật thông tin thành công!", Toast.LENGTH_SHORT).show();
                                finish();
                            } else {
                                Toast.makeText(ShopProfileEditActivity.this, "Lỗi cập nhật số điện thoại", Toast.LENGTH_SHORT).show();
                            }
                        }

                        @Override
                        public void onFailure(Call<User> call, Throwable t) {
                            Toast.makeText(ShopProfileEditActivity.this, "Lỗi kết nối khi lưu số điện thoại", Toast.LENGTH_SHORT).show();
                        }
                    });
                } else {
                    Toast.makeText(ShopProfileEditActivity.this, "Lưu thông tin quán thất bại", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Shop> call, Throwable t) {
                Toast.makeText(ShopProfileEditActivity.this, "Lỗi kết nối khi lưu thông tin quán", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

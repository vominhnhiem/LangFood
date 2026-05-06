package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.util.Log;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Category;
import com.example.langfood.models.Product;
import com.google.android.material.card.MaterialCardView;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class AddFoodActivity extends AppCompatActivity {

    private static final int PICK_IMAGE_REQUEST = 1;
    private MaterialCardView cardAddImage;
    private ImageView ivFoodImage;
    private EditText etFoodName, etFoodPrice, etFoodDescription;
    private Spinner spCategory;
    private Button btnPostFood;
    private Uri imageUri;
    private ApiService apiService;
    private List<Category> categoryList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_food);

        apiService = ApiClient.getClient().create(ApiService.class);
        initViews();
        loadCategories();
        setupClickListeners();
    }

    private void initViews() {
        cardAddImage = findViewById(R.id.cardAddImage);
        ivFoodImage = findViewById(R.id.ivFoodImage);
        etFoodName = findViewById(R.id.etFoodName);
        etFoodPrice = findViewById(R.id.etFoodPrice);
        etFoodDescription = findViewById(R.id.etFoodDescription);
        spCategory = findViewById(R.id.spCategory);
        btnPostFood = findViewById(R.id.btnPostFood);
    }

    private void loadCategories() {
        apiService.getCategories().enqueue(new Callback<List<Category>>() {
            @Override
            public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    categoryList.clear();
                    categoryList.addAll(response.body());
                    setupSpinner();
                }
            }

            @Override
            public void onFailure(Call<List<Category>> call, Throwable t) {
                Toast.makeText(AddFoodActivity.this, "Lỗi tải danh mục", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupSpinner() {
        ArrayAdapter<Category> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, categoryList);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spCategory.setAdapter(adapter);
    }

    private void setupClickListeners() {
        cardAddImage.setOnClickListener(v -> openGallery());
        btnPostFood.setOnClickListener(v -> postFoodWithImage());
    }

    private void openGallery() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            imageUri = data.getData();
            ivFoodImage.setImageURI(imageUri);
            ivFoodImage.setAlpha(1.0f);
        }
    }

    private void postFoodWithImage() {
        String name = etFoodName.getText().toString().trim();
        String priceStr = etFoodPrice.getText().toString().trim();
        String description = etFoodDescription.getText().toString().trim();

        if (name.isEmpty() || priceStr.isEmpty() || description.isEmpty() || imageUri == null || spCategory.getSelectedItem() == null) {
            Toast.makeText(this, "Vui lòng nhập đủ thông tin và chọn ảnh", Toast.LENGTH_SHORT).show();
            return;
        }

        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        String sellerId = prefs.getString("USER_ID", "");
        
        Category selectedCategory = (Category) spCategory.getSelectedItem();
        String categoryIdStr = String.valueOf(selectedCategory.getId());

        // Chuyển dữ liệu sang RequestBody
        RequestBody rbName = RequestBody.create(MediaType.parse("text/plain"), name);
        RequestBody rbPrice = RequestBody.create(MediaType.parse("text/plain"), priceStr);
        RequestBody rbDescription = RequestBody.create(MediaType.parse("text/plain"), description);
        RequestBody rbSellerId = RequestBody.create(MediaType.parse("text/plain"), sellerId);
        RequestBody rbCategoryId = RequestBody.create(MediaType.parse("text/plain"), categoryIdStr);

        // Xử lý File ảnh
        MultipartBody.Part imagePart = prepareImagePart("image");

        apiService.addProductWithImage(rbName, rbPrice, rbDescription, rbSellerId, rbCategoryId, imagePart).enqueue(new Callback<Product>() {
            @Override
            public void onResponse(Call<Product> call, Response<Product> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(AddFoodActivity.this, "Đăng món thành công kèm ảnh!", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    Toast.makeText(AddFoodActivity.this, "Lỗi server: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Product> call, Throwable t) {
                Log.e("API_ERROR", t.getMessage());
                Toast.makeText(AddFoodActivity.this, "Lỗi kết nối", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private MultipartBody.Part prepareImagePart(String partName) {
        try {
            File file = new File(getCacheDir(), "temp_image.jpg");
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
            return MultipartBody.Part.createFormData(partName, file.getName(), requestFile);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}

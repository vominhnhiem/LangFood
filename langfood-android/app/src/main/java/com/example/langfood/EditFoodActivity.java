package com.example.langfood;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import com.bumptech.glide.Glide;
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

public class EditFoodActivity extends AppCompatActivity {

    private EditText etFoodName, etFoodPrice, etFoodDescription;
    private Spinner spCategory;
    private SwitchCompat swAvailable;
    private ImageView ivFoodImage, btnBack;
    private Button btnUpdateFood;
    private MaterialCardView cardEditImage;
    private ApiService apiService;
    private int productId;
    private Product currentProduct;
    private List<Category> categoryList = new ArrayList<>();
    private static final String BASE_URL = "http://192.168.100.192:5289/";
    private static final int PICK_IMAGE_REQUEST = 1;
    private Uri imageUri;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_edit_food);

        initViews();
        apiService = ApiClient.getClient().create(ApiService.class);

        productId = getIntent().getIntExtra("PRODUCT_ID", -1);
        
        loadCategories();

        btnBack.setOnClickListener(v -> finish());
        btnUpdateFood.setOnClickListener(v -> updateProduct());
        cardEditImage.setOnClickListener(v -> openGallery());
    }

    private void initViews() {
        etFoodName = findViewById(R.id.etFoodName);
        etFoodPrice = findViewById(R.id.etFoodPrice);
        etFoodDescription = findViewById(R.id.etFoodDescription);
        spCategory = findViewById(R.id.spCategory);
        swAvailable = findViewById(R.id.swAvailable);
        ivFoodImage = findViewById(R.id.ivFoodImage);
        btnBack = findViewById(R.id.btnBack);
        btnUpdateFood = findViewById(R.id.btnUpdateFood);
        cardEditImage = findViewById(R.id.cardEditImage);
    }

    private void openGallery() {
        Intent intent = new Intent();
        intent.setType("image/*");
        intent.setAction(Intent.ACTION_GET_CONTENT);
        startActivityForResult(Intent.createChooser(intent, "Chọn ảnh món ăn"), PICK_IMAGE_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            imageUri = data.getData();
            ivFoodImage.setImageURI(imageUri);
        }
    }

    private void loadCategories() {
        apiService.getCategories().enqueue(new Callback<List<Category>>() {
            @Override
            public void onResponse(Call<List<Category>> call, Response<List<Category>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    categoryList.clear();
                    categoryList.addAll(response.body());
                    setupSpinner();
                    if (productId != -1) {
                        loadProductDetails();
                    }
                }
            }

            @Override
            public void onFailure(Call<List<Category>> call, Throwable t) {
                Toast.makeText(EditFoodActivity.this, "Lỗi tải danh mục", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void setupSpinner() {
        ArrayAdapter<Category> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, categoryList);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spCategory.setAdapter(adapter);
    }

    private void loadProductDetails() {
        apiService.getProductById(productId).enqueue(new Callback<Product>() {
            @Override
            public void onResponse(Call<Product> call, Response<Product> response) {
                if (response.isSuccessful() && response.body() != null) {
                    currentProduct = response.body();
                    displayProduct(currentProduct);
                }
            }

            @Override
            public void onFailure(Call<Product> call, Throwable t) {
                Toast.makeText(EditFoodActivity.this, "Lỗi tải thông tin", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void displayProduct(Product product) {
        etFoodName.setText(product.getName());
        etFoodPrice.setText(String.valueOf((int) product.getPrice()));
        etFoodDescription.setText(product.getDescription());
        swAvailable.setChecked(product.isAvailable());

        for (int i = 0; i < categoryList.size(); i++) {
            if (categoryList.get(i).getId() == product.getCategoryId()) {
                spCategory.setSelection(i);
                break;
            }
        }

        String imageUrl = product.getImageUrl();
        if (imageUrl != null && imageUrl.startsWith("/")) {
            imageUrl = BASE_URL.substring(0, BASE_URL.length() - 1) + imageUrl;
        } else {
            imageUrl = BASE_URL + imageUrl;
        }

        Glide.with(this)
                .load(imageUrl)
                .placeholder(R.drawable.lang_food_avt)
                .error(R.drawable.lang_food_avt)
                .into(ivFoodImage);
    }

    private void updateProduct() {
        String name = etFoodName.getText().toString().trim();
        String priceStr = etFoodPrice.getText().toString().trim();
        String description = etFoodDescription.getText().toString().trim();
        boolean isAvailable = swAvailable.isChecked();
        Category selectedCategory = (Category) spCategory.getSelectedItem();

        if (name.isEmpty() || priceStr.isEmpty() || selectedCategory == null) {
            Toast.makeText(this, "Vui lòng nhập đầy đủ thông tin", Toast.LENGTH_SHORT).show();
            return;
        }

        if (imageUri != null) {
            uploadWithImage(name, priceStr, description, isAvailable, selectedCategory.getId());
        } else {
            updateOnlyText(name, priceStr, description, isAvailable, selectedCategory.getId());
        }
    }

    private void updateOnlyText(String name, String priceStr, String description, boolean isAvailable, int categoryId) {
        currentProduct.setName(name);
        currentProduct.setPrice(Double.parseDouble(priceStr));
        currentProduct.setDescription(description);
        currentProduct.setAvailable(isAvailable);
        currentProduct.setCategoryId(categoryId);

        apiService.updateProduct(productId, currentProduct).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(EditFoodActivity.this, "Cập nhật thành công", Toast.LENGTH_SHORT).show();
                    finish();
                } else {
                    Toast.makeText(EditFoodActivity.this, "Cập nhật thất bại", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(EditFoodActivity.this, "Lỗi kết nối", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void uploadWithImage(String name, String priceStr, String description, boolean isAvailable, int categoryId) {
        try {
            File file = getFileFromUri(imageUri);
            RequestBody requestFile = RequestBody.create(MediaType.parse("image/*"), file);
            MultipartBody.Part body = MultipartBody.Part.createFormData("image", file.getName(), requestFile);

            RequestBody rName = RequestBody.create(MediaType.parse("text/plain"), name);
            RequestBody rPrice = RequestBody.create(MediaType.parse("text/plain"), priceStr);
            RequestBody rDesc = RequestBody.create(MediaType.parse("text/plain"), description);
            RequestBody rSellerId = RequestBody.create(MediaType.parse("text/plain"), currentProduct.getSellerId());
            RequestBody rCategoryId = RequestBody.create(MediaType.parse("text/plain"), String.valueOf(categoryId));
            RequestBody rAvailable = RequestBody.create(MediaType.parse("text/plain"), String.valueOf(isAvailable));

            // Gọi API thêm món mới kèm ảnh
            apiService.addProductWithImage(rName, rPrice, rDesc, rSellerId, rCategoryId, body).enqueue(new Callback<Product>() {
                @Override
                public void onResponse(Call<Product> call, Response<Product> response) {
                    if (response.isSuccessful()) {
                        // Sau khi thêm mới thành công, xóa món cũ đi ngay lập tức
                        deleteOldProductAndFinish();
                    } else {
                        Toast.makeText(EditFoodActivity.this, "Lỗi upload ảnh: " + response.code(), Toast.LENGTH_SHORT).show();
                    }
                }
                @Override
                public void onFailure(Call<Product> call, Throwable t) {
                    Toast.makeText(EditFoodActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
                }
            });

        } catch (Exception e) {
            e.printStackTrace();
            Toast.makeText(this, "Lỗi xử lý file", Toast.LENGTH_SHORT).show();
        }
    }

    private void deleteOldProductAndFinish() {
        apiService.deleteProduct(productId).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(EditFoodActivity.this, "Cập nhật món ăn thành công", Toast.LENGTH_SHORT).show();
                } else {
                    Log.e("DELETE_OLD", "Không thể xóa món cũ, mã lỗi: " + response.code());
                    Toast.makeText(EditFoodActivity.this, "Đã cập nhật món mới", Toast.LENGTH_SHORT).show();
                }
                finish();
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Log.e("DELETE_OLD", "Lỗi kết nối khi xóa món cũ");
                finish();
            }
        });
    }

    private File getFileFromUri(Uri uri) throws Exception {
        InputStream inputStream = getContentResolver().openInputStream(uri);
        File tempFile = File.createTempFile("upload", ".jpg", getCacheDir());
        FileOutputStream outputStream = new FileOutputStream(tempFile);
        byte[] buffer = new byte[1024];
        int read;
        while ((read = inputStream.read(buffer)) != -1) {
            outputStream.write(buffer, 0, read);
        }
        outputStream.flush();
        outputStream.close();
        if (inputStream != null) inputStream.close();
        return tempFile;
    }
}

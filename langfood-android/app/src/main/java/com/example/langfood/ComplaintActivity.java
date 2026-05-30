package com.example.langfood;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.view.View;
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

public class ComplaintActivity extends AppCompatActivity {

    private static final int PICK_IMAGE_REQUEST = 123;

    private Spinner spinnerReason;
    private EditText etDetail;
    private Button btnUploadImage, btnSubmit;
    private ImageView ivProofPreview;
    private View layoutLoading;

    private int orderId;
    private Uri selectedImageUri;
    private ApiService apiService;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_complaint);

        orderId = getIntent().getIntExtra("ORDER_ID", -1);
        if (orderId == -1) {
            Toast.makeText(this, "Lỗi: Không tìm thấy mã đơn hàng!", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        apiService = ApiClient.getClient().create(ApiService.class);

        initViews();
        setupSpinner();

        findViewById(R.id.btnBack).setOnClickListener(v -> finish());
        btnUploadImage.setOnClickListener(v -> openImagePicker());
        btnSubmit.setOnClickListener(v -> submitComplaint());
    }

    private void initViews() {
        spinnerReason = findViewById(R.id.spinnerReason);
        etDetail = findViewById(R.id.etDetail);
        btnUploadImage = findViewById(R.id.btnUploadImage);
        btnSubmit = findViewById(R.id.btnSubmit);
        ivProofPreview = findViewById(R.id.ivProofPreview);
        layoutLoading = findViewById(R.id.layoutLoading);
    }

    private void setupSpinner() {
        String[] reasons = {
                "Thiếu món / Giao sai món",
                "Đồ ăn có dị vật / Không vệ sinh",
                "Shipper không giao hàng lên sảnh tòa nhà",
                "Đồ ăn bị hỏng / Ôi thiu / Không giống mô tả",
                "Lý do khác"
        };
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_item, reasons);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinnerReason.setAdapter(adapter);
    }

    private void openImagePicker() {
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        startActivityForResult(intent, PICK_IMAGE_REQUEST);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            selectedImageUri = data.getData();
            ivProofPreview.setVisibility(View.VISIBLE);
            ivProofPreview.setImageURI(selectedImageUri);
        }
    }

    private void submitComplaint() {
        String detailText = etDetail.getText().toString().trim();
        String reasonText = spinnerReason.getSelectedItem().toString();

        if (detailText.isEmpty()) {
            Toast.makeText(this, "Vui lòng nhập mô tả chi tiết khiếu nại!", Toast.LENGTH_SHORT).show();
            return;
        }

        if (selectedImageUri == null) {
            Toast.makeText(this, "Vui lòng tải ảnh bằng chứng lỗi!", Toast.LENGTH_SHORT).show();
            return;
        }

        File imageFile = getFileFromUri(selectedImageUri);
        if (imageFile == null) {
            Toast.makeText(this, "Không thể đọc hình ảnh, vui lòng thử lại!", Toast.LENGTH_SHORT).show();
            return;
        }

        layoutLoading.setVisibility(View.VISIBLE);
        btnSubmit.setEnabled(false);

        // Prepare Multipart request body
        RequestBody reqOrderId = RequestBody.create(MediaType.parse("text/plain"), String.valueOf(orderId));
        RequestBody reqReason = RequestBody.create(MediaType.parse("text/plain"), reasonText);
        RequestBody reqDetail = RequestBody.create(MediaType.parse("text/plain"), detailText);

        RequestBody reqFile = RequestBody.create(MediaType.parse("image/*"), imageFile);
        MultipartBody.Part bodyImage = MultipartBody.Part.createFormData("imageProof", imageFile.getName(), reqFile);

        apiService.createComplaint(reqOrderId, reqReason, reqDetail, bodyImage).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                layoutLoading.setVisibility(View.GONE);
                btnSubmit.setEnabled(true);

                if (response.isSuccessful()) {
                    Toast.makeText(ComplaintActivity.this, "Gửi khiếu nại thành công!", Toast.LENGTH_LONG).show();
                    
                    // Quay về màn lịch sử đơn hàng
                    Intent intent = new Intent(ComplaintActivity.this, HistoryActivity.class);
                    intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                    startActivity(intent);
                    finish();
                } else {
                    Toast.makeText(ComplaintActivity.this, "Lỗi gửi khiếu nại: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                layoutLoading.setVisibility(View.GONE);
                btnSubmit.setEnabled(true);
                Toast.makeText(ComplaintActivity.this, "Lỗi kết nối server: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    private File getFileFromUri(Uri uri) {
        try {
            InputStream inputStream = getContentResolver().openInputStream(uri);
            if (inputStream == null) return null;
            File file = new File(getCacheDir(), "temp_proof_" + System.currentTimeMillis() + ".jpg");
            FileOutputStream outputStream = new FileOutputStream(file);
            byte[] buffer = new byte[4096];
            int read;
            while ((read = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, read);
            }
            outputStream.flush();
            outputStream.close();
            inputStream.close();
            return file;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}

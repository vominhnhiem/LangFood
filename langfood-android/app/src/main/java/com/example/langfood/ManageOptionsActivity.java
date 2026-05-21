package com.example.langfood;

import android.os.Bundle;
import android.text.InputType;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.ProductOption;
import com.example.langfood.models.ProductOptionGroup;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ManageOptionsActivity extends AppCompatActivity {

    private RecyclerView rvGroups;
    private ManageOptionsAdapter adapter;
    private List<ProductOptionGroup> groupList = new ArrayList<>();
    private ApiService apiService;
    private int productId;
    private String productName;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_options);

        productId = getIntent().getIntExtra("PRODUCT_ID", -1);
        productName = getIntent().getStringExtra("PRODUCT_NAME");

        if (productId == -1) {
            Toast.makeText(this, "Lỗi: Không tìm thấy món ăn", Toast.LENGTH_SHORT).show();
            finish();
            return;
        }

        apiService = ApiClient.getClient().create(ApiService.class);
        initViews();
        loadOptions();
    }

    private void initViews() {
        Toolbar toolbar = findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        toolbar.setNavigationOnClickListener(v -> finish());
        toolbar.setTitle("Quản lý Topping - " + productName);

        rvGroups = findViewById(R.id.rvGroups);
        rvGroups.setLayoutManager(new LinearLayoutManager(this));
        adapter = new ManageOptionsAdapter(groupList, new ManageOptionsAdapter.OnOptionActionListener() {
            @Override
            public void onDeleteGroup(int groupId) {
                deleteGroup(groupId);
            }

            @Override
            public void onAddOption(int groupId) {
                showAddOptionDialog(groupId);
            }

            @Override
            public void onDeleteOption(int optionId) {
                deleteOption(optionId);
            }
        });
        rvGroups.setAdapter(adapter);

        findViewById(R.id.btnAddGroup).setOnClickListener(v -> showAddGroupDialog());
    }

    private void loadOptions() {
        apiService.getProductOptions(productId).enqueue(new Callback<List<ProductOptionGroup>>() {
            @Override
            public void onResponse(Call<List<ProductOptionGroup>> call, Response<List<ProductOptionGroup>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    groupList.clear();
                    groupList.addAll(response.body());
                    adapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<List<ProductOptionGroup>> call, Throwable t) {
                Toast.makeText(ManageOptionsActivity.this, "Lỗi tải dữ liệu", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showAddGroupDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Thêm nhóm lựa chọn mới");
        builder.setMessage("Ví dụ: Topping thêm, Mức độ cay, Chọn Size...");

        final EditText input = new EditText(this);
        input.setHint("Tên nhóm (VD: Topping)");
        builder.setView(input);

        builder.setPositiveButton("Thêm", (dialog, which) -> {
            String name = input.getText().toString().trim();
            if (!name.isEmpty()) {
                createNewGroup(name);
            }
        });
        builder.setNegativeButton("Hủy", null);
        builder.show();
    }

    private void createNewGroup(String name) {
        ProductOptionGroup group = new ProductOptionGroup();
        group.setProductId(productId);
        group.setName(name);
        group.setMaxSelectable(5); // Mặc định cho chọn nhiều
        group.setRequired(false);

        apiService.createOptionGroup(group).enqueue(new Callback<ProductOptionGroup>() {
            @Override
            public void onResponse(Call<ProductOptionGroup> call, Response<ProductOptionGroup> response) {
                if (response.isSuccessful()) {
                    loadOptions();
                }
            }

            @Override
            public void onFailure(Call<ProductOptionGroup> call, Throwable t) {}
        });
    }

    private void showAddOptionDialog(int groupId) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Thêm lựa chọn mới");

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(50, 20, 50, 20);

        final EditText etName = new EditText(this);
        etName.setHint("Tên (VD: Thêm trứng)");
        layout.addView(etName);

        final EditText etPrice = new EditText(this);
        etPrice.setHint("Giá cộng thêm (VD: 5000)");
        etPrice.setInputType(InputType.TYPE_CLASS_NUMBER);
        layout.addView(etPrice);

        builder.setView(layout);

        builder.setPositiveButton("Lưu", (dialog, which) -> {
            String name = etName.getText().toString().trim();
            String priceStr = etPrice.getText().toString().trim();
            if (!name.isEmpty() && !priceStr.isEmpty()) {
                createNewOption(groupId, name, Double.parseDouble(priceStr));
            }
        });
        builder.setNegativeButton("Hủy", null);
        builder.show();
    }

    private void createNewOption(int groupId, String name, double price) {
        ProductOption option = new ProductOption();
        option.setOptionGroupId(groupId);
        option.setName(name);
        option.setAdditionalPrice(price);
        option.setAvailable(true);

        apiService.createOption(option).enqueue(new Callback<ProductOption>() {
            @Override
            public void onResponse(Call<ProductOption> call, Response<ProductOption> response) {
                if (response.isSuccessful()) {
                    loadOptions();
                }
            }

            @Override
            public void onFailure(Call<ProductOption> call, Throwable t) {}
        });
    }

    private void deleteGroup(int groupId) {
        apiService.deleteOptionGroup(groupId).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                loadOptions();
            }
            @Override public void onFailure(Call<Void> call, Throwable t) {}
        });
    }

    private void deleteOption(int optionId) {
        apiService.deleteOption(optionId).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                loadOptions();
            }
            @Override public void onFailure(Call<Void> call, Throwable t) {}
        });
    }
}

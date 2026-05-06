package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Product;
import com.google.android.material.button.MaterialButton;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ManageFoodActivity extends AppCompatActivity implements ManageFoodAdapter.OnFoodItemClickListener {

    private RecyclerView rvManageFood;
    private ManageFoodAdapter adapter;
    private List<Product> productList = new ArrayList<>();
    private ImageView btnBack;
    private MaterialButton btnAddNewFood;
    private LinearLayout layoutEmpty;
    private ApiService apiService;
    private String sellerId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_manage_food);

        initViews();
        setupRecyclerView();
        
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        sellerId = prefs.getString("USER_ID", "");
        
        apiService = ApiClient.getClient().create(ApiService.class);
        
        btnBack.setOnClickListener(v -> finish());
        btnAddNewFood.setOnClickListener(v -> {
            startActivity(new Intent(ManageFoodActivity.this, AddFoodActivity.class));
        });

        loadMyFoods();
    }

    private void initViews() {
        rvManageFood = findViewById(R.id.rvManageFood);
        btnBack = findViewById(R.id.btnBack);
        btnAddNewFood = findViewById(R.id.btnAddNewFood);
        layoutEmpty = findViewById(R.id.layoutEmpty);
    }

    private void setupRecyclerView() {
        adapter = new ManageFoodAdapter(this, productList, this);
        rvManageFood.setLayoutManager(new LinearLayoutManager(this));
        rvManageFood.setAdapter(adapter);
    }

    private void loadMyFoods() {
        // Pass null to get all products, then filter by sellerId
        apiService.getProducts(null).enqueue(new Callback<List<Product>>() {
            @Override
            public void onResponse(Call<List<Product>> call, Response<List<Product>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    productList.clear();
                    for (Product p : response.body()) {
                        if (p.getSellerId() != null && p.getSellerId().equals(sellerId)) {
                            productList.add(p);
                        }
                    }
                    
                    adapter.updateList(productList);
                    layoutEmpty.setVisibility(productList.isEmpty() ? View.VISIBLE : View.GONE);
                }
            }

            @Override
            public void onFailure(Call<List<Product>> call, Throwable t) {
                Toast.makeText(ManageFoodActivity.this, "Lỗi tải dữ liệu", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onEditClick(Product product) {
        Intent intent = new Intent(this, EditFoodActivity.class);
        intent.putExtra("PRODUCT_ID", product.getId());
        startActivity(intent);
    }

    @Override
    public void onDeleteClick(Product product) {
        apiService.deleteProduct(product.getId()).enqueue(new Callback<Void>() {
            @Override
            public void onResponse(Call<Void> call, Response<Void> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(ManageFoodActivity.this, "Đã xóa món ăn", Toast.LENGTH_SHORT).show();
                    loadMyFoods();
                }
            }

            @Override
            public void onFailure(Call<Void> call, Throwable t) {
                Toast.makeText(ManageFoodActivity.this, "Lỗi khi xóa", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadMyFoods();
    }
}

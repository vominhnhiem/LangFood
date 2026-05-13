package com.example.langfood;

import android.os.Bundle;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;
import java.util.Locale;

public class ShopRevenueActivity extends AppCompatActivity {

    private TextView tvTodayOrders, tvTodayRevenue, tvMonthRevenue, tvTotalOrders;
    private ImageView btnBack;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shop_revenue);

        initViews();
        setupDummyData();

        btnBack.setOnClickListener(v -> finish());
    }

    private void initViews() {
        tvTodayOrders = findViewById(R.id.tvTodayOrders);
        tvTodayRevenue = findViewById(R.id.tvTodayRevenue);
        tvMonthRevenue = findViewById(R.id.tvMonthRevenue);
        tvTotalOrders = findViewById(R.id.tvTotalOrders);
        btnBack = findViewById(R.id.btnBack);
    }

    private void setupDummyData() {
        // Dữ liệu giả để xem giao diện
        tvTodayOrders.setText("25");
        tvTodayRevenue.setText(formatCurrency(625000));
        tvMonthRevenue.setText(formatCurrency(15750000));
        tvTotalOrders.setText("482");
    }

    private String formatCurrency(double amount) {
        return String.format(Locale.getDefault(), "%,.0fđ", amount);
    }
}

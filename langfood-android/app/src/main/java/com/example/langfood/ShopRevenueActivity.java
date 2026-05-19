package com.example.langfood;

import android.app.DatePickerDialog;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.ProductStat;
import com.example.langfood.models.Shop;
import com.example.langfood.models.ShopStats;
import com.github.mikephil.charting.charts.HorizontalBarChart;
import com.github.mikephil.charting.charts.PieChart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarData;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.PieData;
import com.github.mikephil.charting.data.PieDataSet;
import com.github.mikephil.charting.data.PieEntry;
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter;
import com.github.mikephil.charting.formatter.PercentFormatter;
import com.github.mikephil.charting.formatter.ValueFormatter;
import com.github.mikephil.charting.utils.ColorTemplate;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class ShopRevenueActivity extends AppCompatActivity {

    private TextView tvTodayOrders, tvTodayRevenue, tvMonthRevenue;
    private TextView tvFilteredRevenue, tvFilteredTotalOrders, tvFilteredSuccessOrders, tvFilteredFailedOrders, tvFilteredProcessingOrders;
    private TextView tvStartDate, tvEndDate;
    private Button btnFilter, btnTodayQuick, btnMonthQuick;
    private ImageView btnBack;
    private PieChart pieChart;
    private HorizontalBarChart barChart;

    private ApiService apiService;
    private String userId;
    private int shopId = -1;
    private Calendar calendarStart, calendarEnd;
    private SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
    private SimpleDateFormat displaySdf = new SimpleDateFormat("dd/MM/yyyy", Locale.getDefault());

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_shop_revenue);

        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");

        initViews();
        setupDatePickers();
        setupQuickFilters();

        btnBack.setOnClickListener(v -> finish());
        btnFilter.setOnClickListener(v -> {
            if (shopId != -1) {
                fetchStats();
            }
        });

        // Lấy thông tin Shop trước, sau đó mới lấy thống kê
        fetchShopInfo();
    }

    private void initViews() {
        tvTodayOrders = findViewById(R.id.tvTodayOrders);
        tvTodayRevenue = findViewById(R.id.tvTodayRevenue);
        tvMonthRevenue = findViewById(R.id.tvMonthRevenue);

        tvFilteredRevenue = findViewById(R.id.tvFilteredRevenue);
        tvFilteredTotalOrders = findViewById(R.id.tvFilteredTotalOrders);
        tvFilteredSuccessOrders = findViewById(R.id.tvFilteredSuccessOrders);
        tvFilteredFailedOrders = findViewById(R.id.tvFilteredFailedOrders);
        tvFilteredProcessingOrders = findViewById(R.id.tvFilteredProcessingOrders);

        tvStartDate = findViewById(R.id.tvStartDate);
        tvEndDate = findViewById(R.id.tvEndDate);
        btnFilter = findViewById(R.id.btnFilter);
        btnTodayQuick = findViewById(R.id.btnTodayQuick);
        btnMonthQuick = findViewById(R.id.btnMonthQuick);
        btnBack = findViewById(R.id.btnBack);
        pieChart = findViewById(R.id.pieChart);
        barChart = findViewById(R.id.barChart);

        calendarStart = Calendar.getInstance();
        calendarEnd = Calendar.getInstance();
        
        // Mặc định là tháng hiện tại
        calendarStart.set(Calendar.DAY_OF_MONTH, 1);
        tvStartDate.setText(displaySdf.format(calendarStart.getTime()));
        tvEndDate.setText(displaySdf.format(calendarEnd.getTime()));

        initPieChart();
        initBarChart();
    }

    private void setupQuickFilters() {
        btnTodayQuick.setOnClickListener(v -> {
            calendarStart = Calendar.getInstance();
            calendarEnd = Calendar.getInstance();
            updateDateTextViews();
            if (shopId != -1) fetchStats();
        });

        btnMonthQuick.setOnClickListener(v -> {
            calendarStart = Calendar.getInstance();
            calendarStart.set(Calendar.DAY_OF_MONTH, 1);
            calendarEnd = Calendar.getInstance();
            calendarEnd.set(Calendar.DAY_OF_MONTH, calendarEnd.getActualMaximum(Calendar.DAY_OF_MONTH));
            updateDateTextViews();
            if (shopId != -1) fetchStats();
        });
    }

    private void updateDateTextViews() {
        tvStartDate.setText(displaySdf.format(calendarStart.getTime()));
        tvEndDate.setText(displaySdf.format(calendarEnd.getTime()));
    }

    private void initPieChart() {
        pieChart.setUsePercentValues(true);
        pieChart.getDescription().setEnabled(false);
        pieChart.setExtraOffsets(5, 10, 5, 5);
        pieChart.setDragDecelerationFrictionCoef(0.95f);
        pieChart.setDrawHoleEnabled(true);
        pieChart.setHoleColor(Color.WHITE);
        pieChart.setTransparentCircleRadius(61f);
        pieChart.setEntryLabelTextSize(12f);
        pieChart.setEntryLabelColor(Color.BLACK);
        pieChart.setCenterText("Tỉ lệ đơn hàng");
        pieChart.setCenterTextSize(14f);
    }

    private void initBarChart() {
        barChart.getDescription().setEnabled(false);
        barChart.setDrawGridBackground(false);
        barChart.setDrawBarShadow(false);
        barChart.setDrawValueAboveBar(true);
        barChart.setPinchZoom(false);
        barChart.setDoubleTapToZoomEnabled(false);

        XAxis xAxis = barChart.getXAxis();
        xAxis.setPosition(XAxis.XAxisPosition.BOTTOM);
        xAxis.setDrawGridLines(false);
        xAxis.setGranularity(1f);
        xAxis.setLabelCount(5);

        barChart.getAxisLeft().setDrawGridLines(false);
        barChart.getAxisLeft().setAxisMinimum(0f);
        barChart.getAxisRight().setEnabled(false);
        barChart.getLegend().setEnabled(false);
    }

    private void setupDatePickers() {
        tvStartDate.setOnClickListener(v -> {
            new DatePickerDialog(this, (view, year, month, dayOfMonth) -> {
                calendarStart.set(year, month, dayOfMonth);
                tvStartDate.setText(displaySdf.format(calendarStart.getTime()));
            }, calendarStart.get(Calendar.YEAR), calendarStart.get(Calendar.MONTH), calendarStart.get(Calendar.DAY_OF_MONTH)).show();
        });

        tvEndDate.setOnClickListener(v -> {
            new DatePickerDialog(this, (view, year, month, dayOfMonth) -> {
                calendarEnd.set(year, month, dayOfMonth);
                tvEndDate.setText(displaySdf.format(calendarEnd.getTime()));
            }, calendarEnd.get(Calendar.YEAR), calendarEnd.get(Calendar.MONTH), calendarEnd.get(Calendar.DAY_OF_MONTH)).show();
        });
    }

    private void fetchShopInfo() {
        apiService.getShopByUserId(userId).enqueue(new Callback<Shop>() {
            @Override
            public void onResponse(Call<Shop> call, Response<Shop> response) {
                if (response.isSuccessful() && response.body() != null) {
                    shopId = response.body().getId();
                    fetchStats(); // Lấy thống kê lần đầu
                } else {
                    Toast.makeText(ShopRevenueActivity.this, "Không tìm thấy thông tin quán ăn", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Shop> call, Throwable t) {
                Log.e("STATS", "Error fetching shop info: " + t.getMessage());
            }
        });
    }

    private void fetchStats() {
        String startStr = sdf.format(calendarStart.getTime());
        String endStr = sdf.format(calendarEnd.getTime());

        apiService.getDetailedShopStats(shopId, startStr, endStr).enqueue(new Callback<ShopStats>() {
            @Override
            public void onResponse(Call<ShopStats> call, Response<ShopStats> response) {
                if (response.isSuccessful() && response.body() != null) {
                    updateUI(response.body());
                } else {
                    Toast.makeText(ShopRevenueActivity.this, "Lỗi tải thống kê", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<ShopStats> call, Throwable t) {
                Log.e("STATS", "Error fetching stats: " + t.getMessage());
                Toast.makeText(ShopRevenueActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void updateUI(ShopStats stats) {
        // Thống kê nhanh (Dashboard)
        tvTodayOrders.setText(String.valueOf(stats.getTodayOrderCount()));
        tvTodayRevenue.setText(formatCurrency(stats.getTodayRevenue()));
        tvMonthRevenue.setText(formatCurrency(stats.getMonthRevenue()));

        // Chi tiết theo bộ lọc
        tvFilteredRevenue.setText(formatCurrency(stats.getTotalRevenue()));
        tvFilteredTotalOrders.setText(String.valueOf(stats.getTotalOrders()));
        tvFilteredSuccessOrders.setText(String.valueOf(stats.getSuccessOrders()));
        tvFilteredFailedOrders.setText(String.valueOf(stats.getFailedOrders()));
        
        int processing = stats.getTotalOrders() - stats.getSuccessOrders() - stats.getFailedOrders();
        tvFilteredProcessingOrders.setText(String.valueOf(processing));

        updatePieChart(stats);
        updateBarChart(stats.getProductStats());
    }

    private void updatePieChart(ShopStats stats) {
        ArrayList<PieEntry> entries = new ArrayList<>();
        
        int success = stats.getSuccessOrders();
        int failed = stats.getFailedOrders();
        int others = stats.getTotalOrders() - success - failed;

        if (success > 0) entries.add(new PieEntry(success, "Thành công"));
        if (failed > 0) entries.add(new PieEntry(failed, "Thất bại"));
        if (others > 0) entries.add(new PieEntry(others, "Đang xử lý"));

        if (entries.isEmpty()) {
            pieChart.clear();
            pieChart.setNoDataText("Không có dữ liệu đơn hàng trong khoảng thời gian này");
            return;
        }

        PieDataSet dataSet = new PieDataSet(entries, "");
        dataSet.setSliceSpace(3f);
        dataSet.setSelectionShift(5f);

        ArrayList<Integer> colors = new ArrayList<>();
        colors.add(Color.parseColor("#4CAF50")); // Green
        colors.add(Color.parseColor("#F44336")); // Red
        colors.add(Color.parseColor("#2196F3")); // Blue
        dataSet.setColors(colors);

        PieData data = new PieData(dataSet);
        data.setValueFormatter(new PercentFormatter(pieChart));
        data.setValueTextSize(11f);
        data.setValueTextColor(Color.WHITE);

        pieChart.setData(data);
        pieChart.highlightValues(null);
        pieChart.invalidate(); // Refresh
        pieChart.animateY(1000);
    }

    private void updateBarChart(List<ProductStat> productStats) {
        if (productStats == null || productStats.isEmpty()) {
            barChart.clear();
            barChart.setNoDataText("Không có dữ liệu món ăn");
            return;
        }

        ArrayList<BarEntry> entries = new ArrayList<>();
        ArrayList<String> labels = new ArrayList<>();

        // MPAndroidChart HorizontalBarChart displays entries from bottom to top.
        for (int i = 0; i < productStats.size(); i++) {
            ProductStat stat = productStats.get(i);
            entries.add(new BarEntry(i, stat.getTotalQuantity()));
            labels.add(stat.getProductName());
        }

        BarDataSet dataSet = new BarDataSet(entries, "Số lượng bán");
        dataSet.setColor(Color.parseColor("#FF5722"));
        dataSet.setValueTextSize(10f);
        dataSet.setValueFormatter(new ValueFormatter() {
            @Override
            public String getFormattedValue(float value) {
                return String.valueOf((int) value);
            }
        });

        BarData data = new BarData(dataSet);
        data.setBarWidth(0.7f);

        barChart.getXAxis().setValueFormatter(new IndexAxisValueFormatter(labels));
        barChart.setData(data);
        barChart.invalidate();
        barChart.animateY(1000);
    }

    private String formatCurrency(double amount) {
        return String.format(Locale.getDefault(), "%,.0fđ", amount);
    }
}

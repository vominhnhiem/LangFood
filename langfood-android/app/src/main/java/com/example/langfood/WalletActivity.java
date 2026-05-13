package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Transaction;
import com.example.langfood.models.Wallet;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class WalletActivity extends AppCompatActivity {

    private TextView tvBalanceLarge;
    private ImageView btnBack;
    private LinearLayout btnDeposit, btnWithdraw, btnRevenue;
    private View dividerRevenue;
    private RecyclerView rvTransactions;
    private TransactionAdapter adapter;
    private List<Transaction> transactionList = new ArrayList<>();
    private ApiService apiService;
    private String userId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_wallet);

        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");
        int roleId = prefs.getInt("ROLE_ID", 0);

        initViews();
        setupRecyclerView();

        // Chỉ hiển thị nút doanh thu cho Shop (Role 2)
        if (roleId == 2) {
            btnRevenue.setVisibility(View.VISIBLE);
            dividerRevenue.setVisibility(View.VISIBLE);
        }

        btnBack.setOnClickListener(v -> finish());
        btnDeposit.setOnClickListener(v -> showDepositDialog());
        btnWithdraw.setOnClickListener(v -> showWithdrawDialog());
        btnRevenue.setOnClickListener(v -> {
            startActivity(new Intent(WalletActivity.this, ShopRevenueActivity.class));
        });

        fetchWalletData();
        fetchTransactions();
    }

    private void initViews() {
        tvBalanceLarge = findViewById(R.id.tvBalanceLarge);
        btnBack = findViewById(R.id.btnBack);
        btnDeposit = findViewById(R.id.btnDeposit);
        btnWithdraw = findViewById(R.id.btnWithdraw);
        btnRevenue = findViewById(R.id.btnRevenue);
        dividerRevenue = findViewById(R.id.dividerRevenue);
        rvTransactions = findViewById(R.id.rvTransactions);
    }

    private void setupRecyclerView() {
        adapter = new TransactionAdapter(transactionList);
        rvTransactions.setLayoutManager(new LinearLayoutManager(this));
        rvTransactions.setAdapter(adapter);
    }

    private void fetchWalletData() {
        apiService.getWallet(userId).enqueue(new Callback<Wallet>() {
            @Override
            public void onResponse(Call<Wallet> call, Response<Wallet> response) {
                if (response.isSuccessful() && response.body() != null) {
                    double balance = response.body().getBalance();
                    tvBalanceLarge.setText(String.format(Locale.getDefault(), "%,.0fđ", balance));

                    getSharedPreferences("LangFoodPrefs", MODE_PRIVATE).edit()
                            .putFloat("WALLET_BALANCE", (float) balance).apply();
                }
            }

            @Override
            public void onFailure(Call<Wallet> call, Throwable t) {
                Toast.makeText(WalletActivity.this, "Lỗi tải thông tin ví", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void fetchTransactions() {
        apiService.getTransactions(userId).enqueue(new Callback<List<Transaction>>() {
            @Override
            public void onResponse(Call<List<Transaction>> call, Response<List<Transaction>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    transactionList.clear();
                    transactionList.addAll(response.body());
                    adapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<List<Transaction>> call, Throwable t) {
                Log.e("WALLET", "Lỗi tải giao dịch: " + t.getMessage());
            }
        });
    }

    private void showDepositDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Nạp tiền vào ví");
        
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_deposit, null);
        EditText etAmount = view.findViewById(R.id.etAmount);
        ImageView ivQrCode = view.findViewById(R.id.ivQrCode);
        LinearLayout llSteps = view.findViewById(R.id.llSteps);

        etAmount.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                String amountStr = s.toString();
                if (!amountStr.isEmpty()) {
                    llSteps.setVisibility(View.VISIBLE);

                    // Tạo URL VietQR động theo yêu cầu
                    String qrUrl = "https://img.vietqr.io/image/MB-0372076779-compact.jpg?amount=" + amountStr 
                                 + "&addInfo=NAPTIEN_" + userId 
                                 + "&accountName=VO%20MINH%20NHIEM";

                    Glide.with(WalletActivity.this)
                            .load(qrUrl)
                            .into(ivQrCode);
                } else {
                    llSteps.setVisibility(View.GONE);
                }
            }

            @Override
            public void afterTextChanged(Editable s) {}
        });

        builder.setView(view);

        builder.setPositiveButton("Nạp ngay", (dialog, which) -> {
            String amountStr = etAmount.getText().toString();
            if (!amountStr.isEmpty()) {
                double amount = Double.parseDouble(amountStr);
                handleDeposit(amount);
            }
        });
        builder.setNegativeButton("Hủy", null);
        builder.show();
    }

    private void handleDeposit(double amount) {
        apiService.deposit(userId, amount).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(WalletActivity.this, "Yêu cầu đã gửi thành công. Vui lòng chờ Admin duyệt!", Toast.LENGTH_LONG).show();
                    fetchWalletData();
                    fetchTransactions();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                Toast.makeText(WalletActivity.this, "Lỗi gửi thông báo nạp tiền", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showWithdrawDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Rút tiền về tài khoản");
        
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_withdraw, null);
        EditText etAmount = view.findViewById(R.id.etAmount);
        EditText etNote = view.findViewById(R.id.etNote);
        builder.setView(view);

        builder.setPositiveButton("Gửi yêu cầu", (dialog, which) -> {
            String amountStr = etAmount.getText().toString();
            String note = etNote.getText().toString();
            if (!amountStr.isEmpty() && !note.isEmpty()) {
                double amount = Double.parseDouble(amountStr);
                handleWithdraw(amount, note);
            } else {
                Toast.makeText(this, "Vui lòng nhập đầy đủ thông tin", Toast.LENGTH_SHORT).show();
            }
        });
        builder.setNegativeButton("Hủy", null);
        builder.show();
    }

    private void handleWithdraw(double amount, String note) {
        apiService.withdraw(userId, amount, note).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(WalletActivity.this, "Yêu cầu rút tiền đã được gửi!", Toast.LENGTH_SHORT).show();
                    fetchWalletData();
                    fetchTransactions();
                } else {
                    Toast.makeText(WalletActivity.this, "Rút tiền thất bại. Kiểm tra số dư!", Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                Toast.makeText(WalletActivity.this, "Lỗi kết nối server", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

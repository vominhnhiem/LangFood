package com.example.langfood;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Transaction;
import com.example.langfood.models.Wallet;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SellerFinanceFragment extends Fragment {

    private String userId;
    private int shopId;
    private ApiService apiService;

    // Views
    private TextView tvWalletBalance;
    private android.widget.ImageView btnHideBalance;
    private View layoutWithdraw;
    private View layoutRevenue;
    private SwipeRefreshLayout swipeRefresh;
    private RecyclerView rvTransactions;

    // Data
    private List<Transaction> transactionList = new ArrayList<>();
    private TransactionAdapter adapter;
    private double currentBalance = 0.0;
    private boolean isBalanceHidden = false;
    private SharedPreferences prefs;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = requireContext().getSharedPreferences("LangFoodPrefs", Context.MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");
        shopId = prefs.getInt("SHOP_ID", -1);
        apiService = ApiClient.getClient().create(ApiService.class);
        isBalanceHidden = prefs.getBoolean("BALANCE_HIDDEN", false);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_seller_finance, container, false);

        tvWalletBalance = view.findViewById(R.id.tvWalletBalance);
        btnHideBalance = view.findViewById(R.id.btnHideBalance);
        layoutWithdraw = view.findViewById(R.id.layoutWithdrawFinance);
        layoutRevenue = view.findViewById(R.id.layoutRevenueFinance);
        swipeRefresh = view.findViewById(R.id.swipeRefreshFinance);
        rvTransactions = view.findViewById(R.id.rvTransactionsFinance);

        adapter = new TransactionAdapter(transactionList);
        rvTransactions.setLayoutManager(new LinearLayoutManager(requireContext()));
        rvTransactions.setAdapter(adapter);

        swipeRefresh.setColorSchemeResources(R.color.shopee_orange);
        swipeRefresh.setOnRefreshListener(this::loadFinanceData);

        setupListeners();
        updateBalanceDisplay();

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
        loadFinanceData();
    }

    private void setupListeners() {
        layoutWithdraw.setOnClickListener(v -> {
            Intent intent = new Intent(requireActivity(), WalletActivity.class);
            startActivity(intent);
        });

        layoutRevenue.setOnClickListener(v -> {
            if (shopId != -1) {
                Intent intent = new Intent(requireActivity(), ShopRevenueActivity.class);
                intent.putExtra("SHOP_ID", shopId);
                startActivity(intent);
            } else {
                Toast.makeText(getContext(), "Không tìm thấy thông tin cửa hàng", Toast.LENGTH_SHORT).show();
            }
        });

        btnHideBalance.setOnClickListener(v -> {
            isBalanceHidden = !isBalanceHidden;
            prefs.edit().putBoolean("BALANCE_HIDDEN", isBalanceHidden).apply();
            updateBalanceDisplay();
        });
    }

    private void updateBalanceDisplay() {
        if (isBalanceHidden) {
            tvWalletBalance.setText("******đ");
            btnHideBalance.setImageResource(R.drawable.ic_visibility_off);
        } else {
            tvWalletBalance.setText(String.format(Locale.getDefault(), "%,.0fđ", currentBalance));
            btnHideBalance.setImageResource(R.drawable.ic_visibility);
        }
    }

    private void loadFinanceData() {
        if (userId.isEmpty()) {
            if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
            return;
        }

        // 1. Tải số dư ví
        apiService.getWallet(userId).enqueue(new Callback<Wallet>() {
            @Override
            public void onResponse(Call<Wallet> call, Response<Wallet> response) {
                if (response.isSuccessful() && response.body() != null) {
                    Wallet wallet = response.body();
                    currentBalance = wallet.getBalance();
                    updateBalanceDisplay();
                }
            }

            @Override
            public void onFailure(Call<Wallet> call, Throwable t) {}
        });

        // 2. Tải biến động số dư (Transactions)
        apiService.getTransactions(userId).enqueue(new Callback<List<Transaction>>() {
            @Override
            public void onResponse(Call<List<Transaction>> call, Response<List<Transaction>> response) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                if (response.isSuccessful() && response.body() != null) {
                    transactionList.clear();
                    transactionList.addAll(response.body());
                    adapter.notifyDataSetChanged();
                }
            }

            @Override
            public void onFailure(Call<List<Transaction>> call, Throwable t) {
                if (swipeRefresh.isRefreshing()) swipeRefresh.setRefreshing(false);
                Toast.makeText(getContext(), "Lỗi tải lịch sử giao dịch", Toast.LENGTH_SHORT).show();
            }
        });
    }
}

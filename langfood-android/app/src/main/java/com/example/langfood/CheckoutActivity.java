package com.example.langfood;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.CartItem;
import com.example.langfood.models.Order;
import com.example.langfood.models.OrderItem;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class CheckoutActivity extends AppCompatActivity {

    private TextView tvStoreName, tvTotalAmount, tvPaymentMethod, tvDormitoryDetails;
    private RecyclerView rvOrderItems;
    private ImageView btnClose;
    private Button btnPlaceOrder;
    private LinearLayout layoutSelectPayment;
    private RelativeLayout layoutEditAddress;
    private CheckoutAdapter adapter;
    private CartAdapter.CartGroup cartGroup;
    private String selectedPaymentMethod = "Tiền mặt";
    private String selectedBuilding = "";
    private String selectedRoom = "";
    private ApiService apiService;
    private String userId;
    private String fullName;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_checkout);

        apiService = ApiClient.getClient().create(ApiService.class);
        SharedPreferences prefs = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE);
        userId = prefs.getString("USER_ID", "");
        fullName = prefs.getString("FULL_NAME", "Người dùng");

        cartGroup = (CartAdapter.CartGroup) getIntent().getSerializableExtra("CART_GROUP");

        initViews();
        setupData();

        btnClose.setOnClickListener(v -> finish());
        btnPlaceOrder.setOnClickListener(v -> placeOrder());

        layoutSelectPayment.setOnClickListener(v -> showPaymentSelectionDialog());
        layoutEditAddress.setOnClickListener(v -> showEditAddressDialog());
    }

    private void initViews() {
        tvStoreName = findViewById(R.id.tvCheckoutStoreName);
        tvTotalAmount = findViewById(R.id.tvTotalCheckout);
        rvOrderItems = findViewById(R.id.rvOrderItems);
        btnClose = findViewById(R.id.btnClose);
        btnPlaceOrder = findViewById(R.id.btnPlaceOrder);
        layoutSelectPayment = findViewById(R.id.layoutSelectPayment);
        tvPaymentMethod = findViewById(R.id.tvPaymentMethod);
        layoutEditAddress = findViewById(R.id.layoutEditAddress);
        tvDormitoryDetails = findViewById(R.id.tvDormitoryDetails);
    }

    private void setupData() {
        if (cartGroup != null) {
            tvStoreName.setText(cartGroup.sellerName);
            
            List<CartItem> items = cartGroup.items;
            adapter = new CheckoutAdapter(items);
            rvOrderItems.setLayoutManager(new LinearLayoutManager(this));
            rvOrderItems.setAdapter(adapter);

            double total = calculateTotal();
            tvTotalAmount.setText(String.format(Locale.getDefault(), "%,.0fđ", total));
            
            btnPlaceOrder.setEnabled(true);
            btnPlaceOrder.setBackgroundTintList(getResources().getColorStateList(R.color.teal_700));
            btnPlaceOrder.setTextColor(getResources().getColor(android.R.color.white));
        }
        
        TextView tvUserName = findViewById(R.id.tvUserName);
        if (tvUserName != null) {
            tvUserName.setText(fullName);
        }
    }

    private double calculateTotal() {
        double total = 0;
        if (cartGroup != null) {
            for (CartItem item : cartGroup.items) {
                total += item.getProduct().getPrice() * item.getQuantity();
            }
        }
        return total;
    }

    private void placeOrder() {
        if (selectedBuilding.isEmpty() || selectedRoom.isEmpty()) {
            Toast.makeText(this, "Vui lòng cập nhật tòa và phòng!", Toast.LENGTH_SHORT).show();
            showEditAddressDialog();
            return;
        }

        Order order = new Order();
        order.setBuyerId(userId);
        order.setBuyerName(fullName);
        order.setStatus("Pending");
        order.setDeliveryBuilding("Tòa " + selectedBuilding + " - Phòng " + selectedRoom);
        
        double total = calculateTotal();
        order.setTotalAmount(total);
        order.setShippingFee(15000); // Phí ship cố định hoặc tính toán tùy ý

        List<OrderItem> orderItems = new ArrayList<>();
        for (CartItem cartItem : cartGroup.items) {
            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(cartItem.getProduct().getId());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setUnitPrice(cartItem.getProduct().getPrice());
            orderItems.add(orderItem);
        }
        order.setOrderItems(orderItems);

        btnPlaceOrder.setEnabled(false);
        btnPlaceOrder.setText("Đang xử lý...");

        apiService.createOrder(order).enqueue(new Callback<Order>() {
            @Override
            public void onResponse(Call<Order> call, Response<Order> response) {
                if (response.isSuccessful()) {
                    Toast.makeText(CheckoutActivity.this, "Đặt hàng thành công!", Toast.LENGTH_LONG).show();
                    
                    // Xóa các món đã đặt khỏi giỏ hàng
                    for (CartItem item : cartGroup.items) {
                        CartManager.getInstance().removeItem(item.getProduct().getId());
                    }
                    
                    finish();
                } else {
                    btnPlaceOrder.setEnabled(true);
                    btnPlaceOrder.setText("Đặt đơn");
                    Toast.makeText(CheckoutActivity.this, "Lỗi đặt hàng: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override
            public void onFailure(Call<Order> call, Throwable t) {
                btnPlaceOrder.setEnabled(true);
                btnPlaceOrder.setText("Đặt đơn");
                Toast.makeText(CheckoutActivity.this, "Lỗi kết nối: " + t.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void showPaymentSelectionDialog() {
        String[] methods = {"Tiền mặt", "Chuyển khoản (Zalopay/Ngân hàng)"};
        
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Chọn phương thức thanh toán");
        builder.setItems(methods, (dialog, which) -> {
            selectedPaymentMethod = methods[which];
            tvPaymentMethod.setText(selectedPaymentMethod);
        });
        builder.show();
    }

    private void showEditAddressDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Thông tin phòng");

        View viewInflated = LayoutInflater.from(this).inflate(R.layout.dialog_edit_address, null);
        final EditText inputBuilding = viewInflated.findViewById(R.id.editBuilding);
        final EditText inputRoom = viewInflated.findViewById(R.id.editRoom);
        
        inputBuilding.setText(selectedBuilding);
        inputRoom.setText(selectedRoom);

        builder.setView(viewInflated);

        builder.setPositiveButton("Lưu", (dialog, which) -> {
            selectedBuilding = inputBuilding.getText().toString().trim();
            selectedRoom = inputRoom.getText().toString().trim();
            
            if (!selectedBuilding.isEmpty() && !selectedRoom.isEmpty()) {
                tvDormitoryDetails.setText("Tòa " + selectedBuilding + " - Phòng " + selectedRoom);
            } else {
                tvDormitoryDetails.setText("Chưa cập nhật tòa và phòng");
            }
        });
        builder.setNegativeButton("Hủy", (dialog, which) -> dialog.cancel());

        builder.show();
    }
}

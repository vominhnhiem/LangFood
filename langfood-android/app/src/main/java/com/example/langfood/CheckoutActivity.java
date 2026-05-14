package com.example.langfood;

import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
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
import com.bumptech.glide.Glide;
import com.example.langfood.api.ApiClient;
import com.example.langfood.api.ApiService;
import com.example.langfood.models.Building;
import com.example.langfood.models.CartItem;
import com.example.langfood.models.Order;
import com.example.langfood.models.OrderItem;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import org.json.JSONObject;

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

    private int selectedBuildingId = 0;
    private String selectedBuildingName = "";
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

        selectedBuildingId = prefs.getInt("BUILDING_ID", 0);
        selectedBuildingName = prefs.getString("BUILDING_NAME", "");
        selectedRoom = prefs.getString("ROOM", "");

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
            tvStoreName.setText(cartGroup.shopName);
            adapter = new CheckoutAdapter(cartGroup.items);
            rvOrderItems.setLayoutManager(new LinearLayoutManager(this));
            rvOrderItems.setAdapter(adapter);

            double total = calculateTotal();
            tvTotalAmount.setText(String.format(Locale.getDefault(), "%,.0fđ", total));
        }

        if (!selectedBuildingName.isEmpty() && !selectedRoom.isEmpty()) {
            tvDormitoryDetails.setText("Tòa " + selectedBuildingName + " - Phòng " + selectedRoom);
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
        if (selectedBuildingName.isEmpty() || selectedRoom.isEmpty()) {
            Toast.makeText(this, "Vui lòng cập nhật địa chỉ!", Toast.LENGTH_SHORT).show();
            showEditAddressDialog();
            return;
        }

        if (userId.isEmpty()) {
            Toast.makeText(this, "Lỗi: Bạn chưa đăng nhập!", Toast.LENGTH_SHORT).show();
            return;
        }

        Order order = new Order();
        order.setBuyerId(userId);
        order.setBuyerName(fullName);
        
        int finalShopId = cartGroup.shopId;
        if (finalShopId == 0 && cartGroup.items != null && !cartGroup.items.isEmpty()) {
            finalShopId = cartGroup.items.get(0).getProduct().getShopId();
        }
        order.setShopId(finalShopId);
        
        // Khi dùng QR, để trạng thái là "PendingPayment" để Admin dễ lọc
        if (selectedPaymentMethod.contains("Chuyển khoản")) {
            order.setStatus("PendingPayment");
        } else {
            order.setStatus("Pending");
        }

        if (selectedBuildingId > 0) {
            order.setBuildingId(selectedBuildingId);
        }
        order.setDeliveryBuilding(selectedBuildingName);
        order.setDeliveryRoom(selectedRoom);

        order.setPaymentMethod(selectedPaymentMethod.contains("Chuyển khoản") ? 1 : 0);

        double total = calculateTotal();
        order.setTotalAmount(total);
        order.setShippingFee(15000);

        List<OrderItem> orderItems = new ArrayList<>();
        for (CartItem cartItem : cartGroup.items) {
            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(cartItem.getProduct().getId());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setUnitPrice(cartItem.getProduct().getPrice());
            orderItems.add(orderItem);
        }
        order.setOrderItems(orderItems);

        if (finalShopId <= 0) {
            Toast.makeText(this, "Lỗi: Không tìm thấy ID cửa hàng!", Toast.LENGTH_SHORT).show();
            return;
        }

        btnPlaceOrder.setEnabled(false);
        btnPlaceOrder.setText("Đang xử lý...");

        apiService.createOrder(order).enqueue(new Callback<Order>() {
            @Override
            public void onResponse(Call<Order> call, Response<Order> response) {
                if (response.isSuccessful()) {
                    Order createdOrder = response.body();
                    for (CartItem item : cartGroup.items) {
                        CartManager.getInstance().removeItem(item.getProduct().getId());
                    }

                    if (order.getPaymentMethod() == 1) {
                        showOrderQrDialog(createdOrder);
                    } else {
                        Toast.makeText(CheckoutActivity.this, "Đặt hàng thành công!", Toast.LENGTH_LONG).show();
                        finish();
                    }
                } else {
                    btnPlaceOrder.setEnabled(true);
                    btnPlaceOrder.setText("Đặt đơn");
                    Toast.makeText(CheckoutActivity.this, "Lỗi Server: " + response.code(), Toast.LENGTH_SHORT).show();
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

    private void showOrderQrDialog(Order order) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Thanh toán đơn hàng #" + order.getId());
        builder.setCancelable(false);
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_deposit, null);
        EditText etAmount = view.findViewById(R.id.etAmount);
        ImageView ivQrCode = view.findViewById(R.id.ivQrCode);
        LinearLayout llSteps = view.findViewById(R.id.llSteps);

        double totalAmount = order.getTotalAmount() + order.getShippingFee();
        etAmount.setText(String.format(Locale.getDefault(), "%,.0f", totalAmount));
        etAmount.setEnabled(false);
        llSteps.setVisibility(View.VISIBLE);

        String qrUrl = "https://img.vietqr.io/image/MB-0372076779-compact.jpg?amount=" + (int)totalAmount
                + "&addInfo=THANHTOAN_DH_" + order.getId()
                + "&accountName=VO%20MINH%20NHIEM";

        Glide.with(this).load(qrUrl).into(ivQrCode);
        builder.setView(view);
        builder.setPositiveButton("Tôi đã chuyển khoản", (dialog, which) -> {
            // GỬI THÔNG BÁO CHO ADMIN
            notifyAdminPayment(order, totalAmount);
        });
        builder.setNegativeButton("Thanh toán sau", (dialog, which) -> finish());
        builder.show();
    }

    private void notifyAdminPayment(Order order, double amount) {
        apiService.deposit(userId, amount, order.getId()).enqueue(new Callback<ResponseBody>() {
            @Override
            public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
                Toast.makeText(CheckoutActivity.this, "Đã gửi thông báo thanh toán cho Admin. Vui lòng chờ duyệt!", Toast.LENGTH_LONG).show();
                finish();
            }

            @Override
            public void onFailure(Call<ResponseBody> call, Throwable t) {
                Toast.makeText(CheckoutActivity.this, "Đặt đơn thành công nhưng lỗi gửi thông báo thanh toán. Hãy liên hệ Admin!", Toast.LENGTH_LONG).show();
                finish();
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
        builder.setTitle("Thông tin địa chỉ");
        View viewInflated = LayoutInflater.from(this).inflate(R.layout.dialog_edit_address, null);
        final AutoCompleteTextView inputBuilding = viewInflated.findViewById(R.id.spinnerBuilding);
        final EditText inputRoom = viewInflated.findViewById(R.id.editRoom);

        inputBuilding.setText(selectedBuildingName);
        inputRoom.setText(selectedRoom);

        apiService.getBuildings().enqueue(new Callback<List<Building>>() {
            @Override
            public void onResponse(Call<List<Building>> call, Response<List<Building>> response) {
                if (response.isSuccessful() && response.body() != null) {
                    List<Building> buildings = response.body();
                    ArrayAdapter<Building> adapter = new ArrayAdapter<>(CheckoutActivity.this,
                            android.R.layout.simple_dropdown_item_1line, buildings);
                    inputBuilding.setAdapter(adapter);

                    inputBuilding.setOnItemClickListener((parent, view, position, id) -> {
                        Building selected = (Building) parent.getItemAtPosition(position);
                        selectedBuildingId = selected.getId();
                        selectedBuildingName = selected.getName();
                    });
                }
            }
            @Override public void onFailure(Call<List<Building>> call, Throwable t) {}
        });

        builder.setView(viewInflated);
        builder.setPositiveButton("Lưu", (dialog, which) -> {
            selectedRoom = inputRoom.getText().toString().trim();
            if (!selectedBuildingName.isEmpty() && !selectedRoom.isEmpty()) {
                tvDormitoryDetails.setText("Tòa " + selectedBuildingName + " - Phòng " + selectedRoom);
                SharedPreferences.Editor editor = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE).edit();
                editor.putInt("BUILDING_ID", selectedBuildingId);
                editor.putString("BUILDING_NAME", selectedBuildingName);
                editor.putString("ROOM", selectedRoom);
                editor.apply();
            }
        });
        builder.setNegativeButton("Hủy", null);
        builder.show();
    }
}

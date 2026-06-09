package com.example.langfood;

import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
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
import com.example.langfood.models.ProductOption;
import com.example.langfood.models.ProductOptionGroup;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class CheckoutActivity extends AppCompatActivity implements CheckoutAdapter.OnItemUpdateListener {

    private TextView tvStoreName, tvTotalAmount, tvPaymentMethod, tvDormitoryDetails;
    private TextView tvSubtotal, tvShippingFee, tvServiceFee;
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
    private String selectedPhone = "";

    private ApiService apiService;
    private String userId;
    private String fullName;

    private final double SYSTEM_SERVICE_FEE = 3000; 

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
        selectedPhone = prefs.getString("DELIVERY_PHONE", "");

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

        tvSubtotal = findViewById(R.id.tvSubtotal);
        tvShippingFee = findViewById(R.id.tvShippingFee);
        tvServiceFee = findViewById(R.id.tvServiceFee);
    }

    private void setupData() {
        if (cartGroup != null) {
            tvStoreName.setText(cartGroup.shopName);
            adapter = new CheckoutAdapter(cartGroup.items, this);
            rvOrderItems.setLayoutManager(new LinearLayoutManager(this));
            rvOrderItems.setAdapter(adapter);

            updatePriceSummary();
            btnPlaceOrder.setEnabled(!cartGroup.items.isEmpty());
        }
        updateAddressDisplay();
    }

    private void updatePriceSummary() {
        double subtotal = calculateTotal();
        double total = subtotal + SYSTEM_SERVICE_FEE;

        tvSubtotal.setText(String.format(Locale.getDefault(), "%,.0fđ", subtotal));
        tvShippingFee.setText("Miễn phí");
        tvShippingFee.setTextColor(Color.parseColor("#4CAF50")); 
        tvServiceFee.setText(String.format(Locale.getDefault(), "%,.0fđ", SYSTEM_SERVICE_FEE));
        tvTotalAmount.setText(String.format(Locale.getDefault(), "%,.0fđ", total));
    }

    private void updateAddressDisplay() {
        if (!selectedBuildingName.isEmpty() && !selectedRoom.isEmpty()) {
            String address = "Tòa " + selectedBuildingName + " - Phòng " + selectedRoom;
            if (!selectedPhone.isEmpty()) {
                address += "\nSĐT: " + selectedPhone;
            }
            tvDormitoryDetails.setText(address);
        } else {
            tvDormitoryDetails.setText("Chưa cập nhật địa chỉ");
        }
    }

    private double calculateTotal() {
        double total = 0;
        if (cartGroup != null) {
            Gson gson = new Gson();
            for (CartItem item : cartGroup.items) {
                double itemPrice = item.getProduct().getPrice();
                if (item.getSelectedOptionsJson() != null && !item.getSelectedOptionsJson().isEmpty()) {
                    try {
                        List<Integer> selectedIds = gson.fromJson(item.getSelectedOptionsJson(), 
                            new TypeToken<List<Integer>>(){}.getType());
                        if (selectedIds != null && item.getProduct().getOptionGroups() != null) {
                            for (ProductOptionGroup group : item.getProduct().getOptionGroups()) {
                                for (ProductOption option : group.getOptions()) {
                                    if (selectedIds.contains(option.getId())) {
                                        itemPrice += option.getAdditionalPrice();
                                    }
                                }
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                total += itemPrice * item.getQuantity();
            }
        }
        return total;
    }

    @Override
    public void onItemDeleted(CartItem item) {
        if (cartGroup != null) {
            cartGroup.items.remove(item);
            adapter.notifyDataSetChanged();
            updatePriceSummary();
            CartManager.getInstance().removeItem(item.getProduct().getId());
            if (cartGroup.items.isEmpty()) {
                btnPlaceOrder.setEnabled(false);
                Toast.makeText(this, "Giỏ hàng trống", Toast.LENGTH_SHORT).show();
            }
        }
    }

    @Override
    public void onQuantityChanged() {
        updatePriceSummary();
    }

    private void placeOrder() {
        if (selectedBuildingName.isEmpty() || selectedRoom.isEmpty() || selectedPhone.isEmpty()) {
            Toast.makeText(this, "Vui lòng cập nhật đầy đủ thông tin địa chỉ và SĐT!", Toast.LENGTH_SHORT).show();
            return;
        }

        if (cartGroup == null || cartGroup.items.isEmpty()) {
            Toast.makeText(this, "Giỏ hàng trống!", Toast.LENGTH_SHORT).show();
            return;
        }

        Order order = new Order();
        order.setBuyerId(userId);
        order.setBuyerName(fullName);
        order.setShopId(cartGroup.shopId);
        
        if (selectedPaymentMethod.contains("Chuyển khoản")) {
            order.setStatus("PendingPayment");
        } else {
            order.setStatus("Pending");
        }

        order.setDeliveryBuilding(selectedBuildingName);
        order.setDeliveryRoom(selectedRoom);
        order.setDeliveryPhone(selectedPhone);
        order.setPaymentMethod(selectedPaymentMethod.contains("Chuyển khoản") ? 1 : 0);

        double subtotal = calculateTotal();
        order.setTotalAmount(subtotal);
        order.setShippingFee(SYSTEM_SERVICE_FEE);

        List<OrderItem> orderItems = new ArrayList<>();
        Gson gson = new Gson();
        for (CartItem cartItem : cartGroup.items) {
            OrderItem orderItem = new OrderItem();
            orderItem.setProductId(cartItem.getProduct().getId());
            orderItem.setQuantity(cartItem.getQuantity());
            orderItem.setNote(cartItem.getNote());
            
            StringBuilder optionsSummary = new StringBuilder();
            double finalUnitPrice = cartItem.getProduct().getPrice();
            
            if (cartItem.getSelectedOptionsJson() != null && !cartItem.getSelectedOptionsJson().isEmpty()) {
                try {
                    List<Integer> selectedIds = gson.fromJson(cartItem.getSelectedOptionsJson(), 
                        new TypeToken<List<Integer>>(){}.getType());
                    if (selectedIds != null && cartItem.getProduct().getOptionGroups() != null) {
                        for (ProductOptionGroup group : cartItem.getProduct().getOptionGroups()) {
                            for (ProductOption option : group.getOptions()) {
                                if (selectedIds.contains(option.getId())) {
                                    if (optionsSummary.length() > 0) optionsSummary.append(", ");
                                    optionsSummary.append(option.getName());
                                    finalUnitPrice += option.getAdditionalPrice();
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            
            orderItem.setUnitPrice(finalUnitPrice);
            orderItem.setOptionsSummary(optionsSummary.toString());
            orderItems.add(orderItem);
        }
        order.setOrderItems(orderItems);

        btnPlaceOrder.setEnabled(false);
        btnPlaceOrder.setText("Đang đặt đơn...");

        apiService.createOrder(order).enqueue(new Callback<Order>() {
            @Override
            public void onResponse(Call<Order> call, Response<Order> response) {
                if (response.isSuccessful()) {
                    // XÓA CHÍNH XÁC CÁC MÓN VỪA ĐẶT KHỎI GIỎ HÀNG (Local & Server)
                    CartManager.getInstance().removeItems(cartGroup.items);
                    
                    if (order.getPaymentMethod() == 1) {
                        showOrderQrDialog(response.body());
                    } else {
                        Toast.makeText(CheckoutActivity.this, "Đặt hàng thành công!", Toast.LENGTH_LONG).show();
                        finish();
                    }
                } else {
                    btnPlaceOrder.setEnabled(true);
                    btnPlaceOrder.setText("Đặt đơn");
                    Toast.makeText(CheckoutActivity.this, "Lỗi: " + response.code(), Toast.LENGTH_SHORT).show();
                }
            }

            @Override public void onFailure(Call<Order> call, Throwable t) {
                btnPlaceOrder.setEnabled(true);
                btnPlaceOrder.setText("Đặt đơn");
            }
        });
    }

    private void showOrderQrDialog(Order order) {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Thanh toán đơn hàng #" + order.getId());
        
        View view = LayoutInflater.from(this).inflate(R.layout.dialog_deposit, null);
        EditText etAmount = view.findViewById(R.id.etAmount);
        ImageView ivQrCode = view.findViewById(R.id.ivQrCode);
        LinearLayout llSteps = view.findViewById(R.id.llSteps);

        double totalToPay = order.getTotalAmount() + order.getShippingFee();
        
        etAmount.setText(String.format(Locale.getDefault(), "%,.0f", totalToPay));
        etAmount.setEnabled(false);
        etAmount.setFocusable(false);
        
        if (llSteps != null) {
            llSteps.setVisibility(View.VISIBLE);
        }

        String qrUrl = "https://img.vietqr.io/image/MB-0372076779-compact.jpg?amount=" + (int)totalToPay
                + "&addInfo=THANHTOAN_DH_" + order.getId()
                + "&accountName=VO%20MINH%20NHIEM";

        Glide.with(this).load(qrUrl).into(ivQrCode);
        builder.setView(view);
        
        builder.setPositiveButton("Xác nhận đã chuyển", (dialog, which) -> notifyAdminPayment(order, totalToPay));
        builder.setNegativeButton("Đóng", (dialog, which) -> finish());
        
        builder.setCancelable(false);
        builder.show();
    }

    private void notifyAdminPayment(Order order, double amount) {
        apiService.deposit(userId, amount, order.getId()).enqueue(new Callback<ResponseBody>() {
            @Override public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) { finish(); }
            @Override public void onFailure(Call<ResponseBody> call, Throwable t) { finish(); }
        });
    }

    private void showPaymentSelectionDialog() {
        String[] methods = {"Tiền mặt", "Chuyển khoản (Ngân hàng)"};
        new AlertDialog.Builder(this).setTitle("Chọn phương thức thanh toán").setItems(methods, (dialog, which) -> {
            selectedPaymentMethod = methods[which];
            tvPaymentMethod.setText(selectedPaymentMethod);
            updatePriceSummary();
        }).show();
    }

    private void showEditAddressDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Thông tin địa chỉ");
        View viewInflated = LayoutInflater.from(this).inflate(R.layout.dialog_edit_address, null);
        final AutoCompleteTextView inputBuilding = viewInflated.findViewById(R.id.spinnerBuilding);
        final EditText inputRoom = viewInflated.findViewById(R.id.editRoom);
        final EditText inputPhone = viewInflated.findViewById(R.id.editPhone);

        inputBuilding.setText(selectedBuildingName);
        inputRoom.setText(selectedRoom);
        inputPhone.setText(selectedPhone);

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
        builder.setPositiveButton("Lưu", null); 
        builder.setNegativeButton("Hủy", null);

        final AlertDialog dialog = builder.create();
        dialog.show();

        dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
            String typedBuilding = inputBuilding.getText().toString().trim();
            String typedRoom = inputRoom.getText().toString().trim();
            String typedPhone = inputPhone.getText().toString().trim();

            if (typedBuilding.isEmpty() || typedRoom.isEmpty() || typedPhone.isEmpty()) {
                Toast.makeText(this, "Vui lòng nhập đầy đủ thông tin!", Toast.LENGTH_SHORT).show();
                return;
            }

            if (!typedPhone.matches("^0\\d{9}$")) {
                Toast.makeText(this, "Số điện thoại phải bắt đầu bằng số 0 và có đúng 10 chữ số!", Toast.LENGTH_SHORT).show();
                return;
            }

            selectedBuildingName = typedBuilding;
            selectedRoom = typedRoom;
            selectedPhone = typedPhone;
            updateAddressDisplay();
            
            SharedPreferences.Editor editor = getSharedPreferences("LangFoodPrefs", MODE_PRIVATE).edit();
            editor.putInt("BUILDING_ID", selectedBuildingId);
            editor.putString("BUILDING_NAME", selectedBuildingName);
            editor.putString("ROOM", selectedRoom);
            editor.putString("DELIVERY_PHONE", selectedPhone);
            editor.apply();
            
            dialog.dismiss();
        });
    }
}

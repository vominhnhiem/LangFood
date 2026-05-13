package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

public class Order implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private int id;

    @SerializedName(value = "buyerId", alternate = {"BuyerId"})
    private String buyerId;

    @SerializedName(value = "buyerName", alternate = {"BuyerName"})
    private String buyerName;

    @SerializedName(value = "shopId", alternate = {"ShopId"})
    private int shopId;

    @SerializedName(value = "shipperId", alternate = {"ShipperId"})
    private Integer shipperId;

    @SerializedName(value = "buildingId", alternate = {"BuildingId"})
    private Integer buildingId;

    @SerializedName(value = "status", alternate = {"Status"})
    private String status;

    @SerializedName(value = "shopName", alternate = {"ShopName"})
    private String shopName;

    @SerializedName(value = "totalAmount", alternate = {"TotalAmount"})
    private double totalAmount;

    @SerializedName(value = "shippingFee", alternate = {"ShippingFee"})
    private double shippingFee;

    @SerializedName(value = "deliveryBuilding", alternate = {"DeliveryBuilding"})
    private String deliveryBuilding;

    @SerializedName(value = "deliveryRoom", alternate = {"DeliveryRoom"})
    private String deliveryRoom;

    @SerializedName(value = "createdAt", alternate = {"CreatedAt"})
    private String createdAt;

    @SerializedName(value = "deliveredAt", alternate = {"DeliveredAt"})
    private String deliveredAt;

    @SerializedName(value = "paymentMethod", alternate = {"PaymentMethod"})
    private int paymentMethod; // 0: Cash, 1: Wallet, 2: QR Transfer

    @SerializedName(value = "orderItems", alternate = {"Items", "items", "OrderItems"})
    private List<OrderItem> orderItems;

    public Order() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getBuyerId() { return buyerId; }
    public void setBuyerId(String buyerId) { this.buyerId = buyerId; }

    public String getBuyerName() { return buyerName; }
    public void setBuyerName(String buyerName) { this.buyerName = buyerName; }

    public int getShopId() { return shopId; }
    public void setShopId(int shopId) { this.shopId = shopId; }

    public Integer getShipperId() { return shipperId; }
    public void setShipperId(Integer shipperId) { this.shipperId = shipperId; }

    public Integer getBuildingId() { return buildingId; }
    public void setBuildingId(Integer buildingId) { this.buildingId = buildingId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(double totalAmount) { this.totalAmount = totalAmount; }

    public double getShippingFee() { return shippingFee; }
    public void setShippingFee(double shippingFee) { this.shippingFee = shippingFee; }

    public String getDeliveryBuilding() { return deliveryBuilding; }
    public void setDeliveryBuilding(String deliveryBuilding) { this.deliveryBuilding = deliveryBuilding; }

    public String getDeliveryRoom() { return deliveryRoom; }
    public void setDeliveryRoom(String deliveryRoom) { this.deliveryRoom = deliveryRoom; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getDeliveredAt() { return deliveredAt; }
    public void setDeliveredAt(String deliveredAt) { this.deliveredAt = deliveredAt; }

    public int getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(int paymentMethod) { this.paymentMethod = paymentMethod; }

    public List<OrderItem> getOrderItems() { return orderItems; }
    public void setOrderItems(List<OrderItem> orderItems) { this.orderItems = orderItems; }
}

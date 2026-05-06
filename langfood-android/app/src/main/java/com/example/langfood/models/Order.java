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

    @SerializedName(value = "shipperId", alternate = {"ShipperId"})
    private String shipperId;

    @SerializedName(value = "status", alternate = {"Status"})
    private String status;

    @SerializedName(value = "totalAmount", alternate = {"TotalAmount"})
    private double totalAmount;

    @SerializedName(value = "shippingFee", alternate = {"ShippingFee"})
    private double shippingFee;

    @SerializedName(value = "deliveryBuilding", alternate = {"DeliveryBuilding"})
    private String deliveryBuilding;

    @SerializedName(value = "createdAt", alternate = {"CreatedAt"})
    private String createdAt;

    @SerializedName(value = "orderItems", alternate = {"OrderItems"})
    private List<OrderItem> orderItems;

    public Order() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getBuyerId() { return buyerId; }
    public void setBuyerId(String buyerId) { this.buyerId = buyerId; }

    public String getBuyerName() { return buyerName; }
    public void setBuyerName(String buyerName) { this.buyerName = buyerName; }

    public String getShipperId() { return shipperId; }
    public void setShipperId(String shipperId) { this.shipperId = shipperId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(double totalAmount) { this.totalAmount = totalAmount; }

    public double getShippingFee() { return shippingFee; }
    public void setShippingFee(double shippingFee) { this.shippingFee = shippingFee; }

    public String getDeliveryBuilding() { return deliveryBuilding; }
    public void setDeliveryBuilding(String deliveryBuilding) { this.deliveryBuilding = deliveryBuilding; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public List<OrderItem> getOrderItems() { return orderItems; }
    public void setOrderItems(List<OrderItem> orderItems) { this.orderItems = orderItems; }
}

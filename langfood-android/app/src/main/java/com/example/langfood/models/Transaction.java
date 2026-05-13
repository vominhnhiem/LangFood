package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Transaction implements Serializable {
    @SerializedName("id")
    private int id;

    @SerializedName("walletId")
    private int walletId;

    @SerializedName("amount")
    private double amount;

    @SerializedName("type")
    private String type; // PAYMENT, RECEIVE, DEPOSIT, WITHDRAW

    @SerializedName("description")
    private String description;

    @SerializedName("orderId")
    private Integer orderId;

    @SerializedName("createdAt")
    private String createdAt;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getWalletId() { return walletId; }
    public void setWalletId(int walletId) { this.walletId = walletId; }

    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Integer getOrderId() { return orderId; }
    public void setOrderId(Integer orderId) { this.orderId = orderId; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}

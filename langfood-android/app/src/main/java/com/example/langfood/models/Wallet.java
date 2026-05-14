package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Wallet implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private int id;

    @SerializedName(value = "userId", alternate = {"UserId"})
    private String userId;

    @SerializedName(value = "balance", alternate = {"Balance"})
    private double balance;

    @SerializedName(value = "qrCodeUrl", alternate = {"QrCodeUrl"})
    private String qrCodeUrl;

    public Wallet() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public double getBalance() { return balance; }
    public void setBalance(double balance) { this.balance = balance; }

    public String getQrCodeUrl() { return qrCodeUrl; }
    public void setQrCodeUrl(String qrCodeUrl) { this.qrCodeUrl = qrCodeUrl; }
}

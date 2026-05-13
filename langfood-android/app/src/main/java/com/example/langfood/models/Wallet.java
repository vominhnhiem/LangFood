package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Wallet implements Serializable {
    @SerializedName("id")
    private int id;

    @SerializedName("userId")
    private String userId;

    @SerializedName("balance")
    private double balance;

    @SerializedName("qrCodeUrl")
    private String qrCodeUrl;

    public int getId() { return id; }
    public String getUserId() { return userId; }
    public double getBalance() { return balance; }
    public String getQrCodeUrl() { return qrCodeUrl; }

    public void setBalance(double balance) { this.balance = balance; }
    public void setQrCodeUrl(String qrCodeUrl) { this.qrCodeUrl = qrCodeUrl; }
}

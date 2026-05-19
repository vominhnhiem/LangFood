package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class WithdrawalRequest implements Serializable {
    @SerializedName("id")
    private int id;

    @SerializedName("userId")
    private String userId;

    @SerializedName("amount")
    private double amount;

    @SerializedName("bankName")
    private String bankName;

    @SerializedName("bankAccountNumber")
    private String bankAccountNumber;

    @SerializedName("bankAccountName")
    private String bankAccountName;

    @SerializedName("note")
    private String note;

    @SerializedName("status")
    private int status; // 0: Pending, 1: Success, 2: Rejected

    @SerializedName("adminBillImageUrl")
    private String adminBillImageUrl;

    @SerializedName("createdAt")
    private String createdAt;

    public WithdrawalRequest() {}

    // Constructor for creating a request
    public WithdrawalRequest(String userId, double amount, String bankName, String bankAccountNumber, String bankAccountName, String note) {
        this.userId = userId;
        this.amount = amount;
        this.bankName = bankName;
        this.bankAccountNumber = bankAccountNumber;
        this.bankAccountName = bankAccountName;
        this.note = note;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }

    public String getBankName() { return bankName; }
    public void setBankName(String bankName) { this.bankName = bankName; }

    public String getBankAccountNumber() { return bankAccountNumber; }
    public void setBankAccountNumber(String bankAccountNumber) { this.bankAccountNumber = bankAccountNumber; }

    public String getBankAccountName() { return bankAccountName; }
    public void setBankAccountName(String bankAccountName) { this.bankAccountName = bankAccountName; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public String getAdminBillImageUrl() { return adminBillImageUrl; }
    public void setAdminBillImageUrl(String adminBillImageUrl) { this.adminBillImageUrl = adminBillImageUrl; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }
}

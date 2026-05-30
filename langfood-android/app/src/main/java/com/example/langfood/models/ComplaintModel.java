package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class ComplaintModel implements Serializable {
    @SerializedName("id")
    private int id;

    @SerializedName("orderId")
    private int orderId;

    @SerializedName("reason")
    private String reason;

    @SerializedName("detail")
    private String detail;

    @SerializedName("imageProof")
    private String imageProof;

    @SerializedName("status")
    private int status;

    @SerializedName("adminReply")
    private String adminReply;

    @SerializedName("penaltyAmount")
    private double penaltyAmount;

    @SerializedName("createdAt")
    private String createdAt;

    @SerializedName("resolvedAt")
    private String resolvedAt;

    public ComplaintModel() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getDetail() { return detail; }
    public void setDetail(String detail) { this.detail = detail; }

    public String getImageProof() { return imageProof; }
    public void setImageProof(String imageProof) { this.imageProof = imageProof; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public String getAdminReply() { return adminReply; }
    public void setAdminReply(String adminReply) { this.adminReply = adminReply; }

    public double getPenaltyAmount() { return penaltyAmount; }
    public void setPenaltyAmount(double penaltyAmount) { this.penaltyAmount = penaltyAmount; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(String resolvedAt) { this.resolvedAt = resolvedAt; }
}

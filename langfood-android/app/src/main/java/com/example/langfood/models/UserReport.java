package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;

public class UserReport {
    @SerializedName("id")
    private int id;

    @SerializedName("reporterId")
    private String reporterId;

    @SerializedName("reportedUserId")
    private String reportedUserId;

    @SerializedName("orderId")
    private int orderId;

    @SerializedName("reason")
    private String reason;

    @SerializedName("status")
    private String status; // Mặc định thường là "Open"

    @SerializedName("adminResolutionNote")
    private String adminResolutionNote;

    @SerializedName("createdAt")
    private String createdAt;

    @SerializedName("resolvedAt")
    private String resolvedAt;

    // Constructor không tham số cho Retrofit
    public UserReport() {}

    // --- GETTER AND SETTER ---
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getReporterId() { return reporterId; }
    public void setReporterId(String reporterId) { this.reporterId = reporterId; }

    public String getReportedUserId() { return reportedUserId; }
    public void setReportedUserId(String reportedUserId) { this.reportedUserId = reportedUserId; }

    public int getOrderId() { return orderId; }
    public void setOrderId(int orderId) { this.orderId = orderId; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAdminResolutionNote() { return adminResolutionNote; }
    public void setAdminResolutionNote(String adminResolutionNote) { this.adminResolutionNote = adminResolutionNote; }

    public String getCreatedAt() { return createdAt; }
    public void setCreatedAt(String createdAt) { this.createdAt = createdAt; }

    public String getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(String resolvedAt) { this.resolvedAt = resolvedAt; }
}
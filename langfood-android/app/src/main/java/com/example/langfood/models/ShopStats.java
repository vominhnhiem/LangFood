package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.util.List;

public class ShopStats {
    @SerializedName("todayOrderCount")
    private int todayOrderCount;

    @SerializedName("todayRevenue")
    private double todayRevenue;

    @SerializedName("monthRevenue")
    private double monthRevenue;

    @SerializedName("totalOrders")
    private int totalOrders;

    @SerializedName("totalRevenue")
    private double totalRevenue;

    @SerializedName("successOrders")
    private int successOrders;

    @SerializedName("failedOrders")
    private int failedOrders;

    @SerializedName("averageRating")
    private double averageRating;

    @SerializedName("productStats")
    private List<ProductStat> productStats;

    public int getTodayOrderCount() {
        return todayOrderCount;
    }

    public double getTodayRevenue() {
        return todayRevenue;
    }

    public double getMonthRevenue() {
        return monthRevenue;
    }

    public int getTotalOrders() {
        return totalOrders;
    }

    public double getTotalRevenue() {
        return totalRevenue;
    }

    public int getSuccessOrders() {
        return successOrders;
    }

    public int getFailedOrders() {
        return failedOrders;
    }

    public double getAverageRating() {
        return averageRating;
    }

    public List<ProductStat> getProductStats() {
        return productStats;
    }
}

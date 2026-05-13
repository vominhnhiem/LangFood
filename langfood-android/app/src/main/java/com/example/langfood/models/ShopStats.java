package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;

public class ShopStats {
    @SerializedName("todayOrderCount")
    private int todayOrderCount;

    @SerializedName("todayRevenue")
    private double todayRevenue;

    @SerializedName("monthRevenue")
    private double monthRevenue;

    @SerializedName("totalOrders")
    private int totalOrders;

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
}

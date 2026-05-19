package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;

public class ProductStat {
    @SerializedName("productName")
    private String productName;

    @SerializedName("totalQuantity")
    private int totalQuantity;

    @SerializedName("totalRevenue")
    private double totalRevenue;

    public String getProductName() {
        return productName;
    }

    public int getTotalQuantity() {
        return totalQuantity;
    }

    public double getTotalRevenue() {
        return totalRevenue;
    }
}

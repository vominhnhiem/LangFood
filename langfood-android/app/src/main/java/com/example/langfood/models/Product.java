package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Product implements Serializable {
    @SerializedName(value = "id", alternate = {"Id", "ID"})
    private int id;

    @SerializedName(value = "name", alternate = {"Name"})
    private String name;

    @SerializedName(value = "description", alternate = {"Description"})
    private String description;

    @SerializedName(value = "price", alternate = {"Price"})
    private double price;

    @SerializedName(value = "imageUrl", alternate = {"ImageUrl"})
    private String imageUrl;

    @SerializedName(value = "isAvailable", alternate = {"IsAvailable"})
    private boolean isAvailable;

    @SerializedName(value = "shopId", alternate = {"ShopId"})
    private int shopId;

    @SerializedName(value = "shopName", alternate = {"ShopName", "SellerName"})
    private String shopName;

    @SerializedName(value = "categoryId", alternate = {"CategoryId", "CategoryID"})
    private int categoryId;

    @SerializedName(value = "categoryName", alternate = {"CategoryName"})
    private String categoryName;

    @SerializedName(value = "status", alternate = {"Status"})
    private int status;

    public Product() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public double getPrice() { return price; }
    public void setPrice(double price) { this.price = price; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public boolean isAvailable() { return isAvailable; }
    public void setAvailable(boolean available) { isAvailable = available; }

    public int getShopId() { return shopId; }
    public void setShopId(int shopId) { this.shopId = shopId; }

    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }
}

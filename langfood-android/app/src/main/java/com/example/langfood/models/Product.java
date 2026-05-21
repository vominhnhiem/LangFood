package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

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

    @SerializedName(value = "shopId", alternate = {"ShopId", "ShopID", "shop_id", "Shop_Id"})
    private int shopId;

    @SerializedName(value = "shopName", alternate = {"ShopName", "SellerName"})
    private String shopName;

    @SerializedName(value = "shop", alternate = {"Shop"})
    private ShopInfo shop;

    @SerializedName(value = "categoryId", alternate = {"CategoryId", "CategoryID"})
    private int categoryId;

    @SerializedName(value = "categoryName", alternate = {"CategoryName"})
    private String categoryName;

    @SerializedName(value = "status", alternate = {"Status"})
    private int status; // Changed from String to int to match Backend

    @SerializedName(value = "sellerId", alternate = {"SellerId"})
    private String sellerId;

    // --- NEW FIELD FOR TOPPINGS/OPTIONS ---
    @SerializedName("optionGroups")
    private List<ProductOptionGroup> optionGroups;

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

    public int getShopId() { 
        if (shopId <= 0 && shop != null) return shop.id;
        return shopId; 
    }
    public void setShopId(int shopId) { this.shopId = shopId; }
    
    public String getShopName() { 
        if (shopName != null && !shopName.isEmpty()) return shopName;
        if (shop != null && shop.name != null) return shop.name;
        return "Quán ăn Lang Food";
    }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public String getSellerName() { return getShopName(); }
    public void setSellerName(String sellerName) { this.shopName = sellerName; }

    public String getSellerId() { return sellerId; }
    public void setSellerId(String sellerId) { this.sellerId = sellerId; }

    public int getCategoryId() { return categoryId; }
    public void setCategoryId(int categoryId) { this.categoryId = categoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }

    public List<ProductOptionGroup> getOptionGroups() { return optionGroups; }
    public void setOptionGroups(List<ProductOptionGroup> optionGroups) { this.optionGroups = optionGroups; }

    public static class ShopInfo implements Serializable {
        @SerializedName(value = "id", alternate = {"Id"})
        public int id;
        @SerializedName(value = "name", alternate = {"Name"})
        public String name;
    }
}

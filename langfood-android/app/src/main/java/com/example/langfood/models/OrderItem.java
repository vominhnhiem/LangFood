package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class OrderItem implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private int id;

    @SerializedName(value = "productId", alternate = {"ProductId"})
    private int productId;

    @SerializedName(value = "quantity", alternate = {"Quantity"})
    private int quantity;

    @SerializedName(value = "unitPrice", alternate = {"UnitPrice"})
    private double unitPrice;

    @SerializedName(value = "product", alternate = {"Product"})
    private Product product;

    public OrderItem() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public double getUnitPrice() { return unitPrice; }
    public void setUnitPrice(double unitPrice) { this.unitPrice = unitPrice; }

    public Product getProduct() { return product; }
    public void setProduct(Product product) { this.product = product; }

    public String getProductName() {
        return (product != null) ? product.getName() : "Món ăn #" + productId;
    }
}

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

    @SerializedName(value = "note", alternate = {"Note"})
    private String note;

    @SerializedName(value = "optionsSummary", alternate = {"OptionsSummary"})
    private String optionsSummary;

    @SerializedName(value = "optionsPrice", alternate = {"OptionsPrice"})
    private double optionsPrice;

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

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public String getOptionsSummary() { return optionsSummary; }
    public void setOptionsSummary(String optionsSummary) { this.optionsSummary = optionsSummary; }

    public double getOptionsPrice() { return optionsPrice; }
    public void setOptionsPrice(double optionsPrice) { this.optionsPrice = optionsPrice; }
}

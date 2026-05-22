package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class CartItem implements Serializable {
    @SerializedName("product")
    private Product product;
    
    @SerializedName("quantity")
    private int quantity;

    @SerializedName(value = "note", alternate = {"Note"})
    private String note;

    @SerializedName("selectedOptionsJson")
    private String selectedOptionsJson;

    public CartItem(Product product, int quantity) {
        this.product = product;
        this.quantity = quantity;
    }

    public CartItem(Product product, int quantity, String note, String selectedOptionsJson) {
        this.product = product;
        this.quantity = quantity;
        this.note = note;
        this.selectedOptionsJson = selectedOptionsJson;
    }

    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public String getSelectedOptionsJson() {
        return selectedOptionsJson;
    }

    public void setSelectedOptionsJson(String selectedOptionsJson) {
        this.selectedOptionsJson = selectedOptionsJson;
    }
}

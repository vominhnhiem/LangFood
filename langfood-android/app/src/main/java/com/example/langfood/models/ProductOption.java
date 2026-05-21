package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class ProductOption implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private int id;
    
    @SerializedName(value = "optionGroupId", alternate = {"OptionGroupId"})
    private int optionGroupId;
    
    @SerializedName(value = "name", alternate = {"Name"})
    private String name;
    
    @SerializedName(value = "additionalPrice", alternate = {"AdditionalPrice"})
    private double additionalPrice;
    
    @SerializedName(value = "isAvailable", alternate = {"IsAvailable"})
    private boolean isAvailable;
    
    private boolean isSelected = false;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getOptionGroupId() { return optionGroupId; }
    public void setOptionGroupId(int optionGroupId) { this.optionGroupId = optionGroupId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public double getAdditionalPrice() { return additionalPrice; }
    public void setAdditionalPrice(double additionalPrice) { this.additionalPrice = additionalPrice; }

    public boolean isAvailable() { return isAvailable; }
    public void setAvailable(boolean available) { isAvailable = available; }

    public boolean isSelected() { return isSelected; }
    public void setSelected(boolean selected) { isSelected = selected; }
}

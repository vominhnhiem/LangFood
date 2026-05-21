package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;
import java.util.List;

public class ProductOptionGroup implements Serializable {
    @SerializedName("id")
    private int id;
    
    @SerializedName("productId")
    private int productId;
    
    @SerializedName("name")
    private String name;
    
    @SerializedName("isRequired")
    private boolean isRequired;
    
    @SerializedName("minSelectable")
    private int minSelectable;
    
    @SerializedName("maxSelectable")
    private int maxSelectable;
    
    @SerializedName("options")
    private List<ProductOption> options;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public boolean isRequired() { return isRequired; }
    public void setRequired(boolean required) { isRequired = required; }

    public int getMinSelectable() { return minSelectable; }
    public void setMinSelectable(int minSelectable) { this.minSelectable = minSelectable; }

    public int getMaxSelectable() { return maxSelectable; }
    public void setMaxSelectable(int maxSelectable) { this.maxSelectable = maxSelectable; }

    public List<ProductOption> getOptions() { return options; }
    public void setOptions(List<ProductOption> options) { this.options = options; }
}

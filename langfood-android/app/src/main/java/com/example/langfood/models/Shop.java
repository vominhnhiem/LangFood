package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Shop implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private int id;

    @SerializedName(value = "userId", alternate = {"UserId"})
    private String userId;

    @SerializedName(value = "name", alternate = {"Name"})
    private String name;

    @SerializedName(value = "address", alternate = {"Address"})
    private String address;

    @SerializedName(value = "description", alternate = {"Description"})
    private String description;

    @SerializedName(value = "imageUrl", alternate = {"ImageUrl"})
    private String imageUrl;

    @SerializedName(value = "isActive", alternate = {"IsActive"})
    private boolean isActive;

    @SerializedName(value = "isOpen", alternate = {"IsOpen"})
    private boolean isOpen;

    public Shop() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

    public boolean isOpen() { return isOpen; }
    public void setOpen(boolean open) { isOpen = open; }
}

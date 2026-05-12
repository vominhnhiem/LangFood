package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import androidx.annotation.NonNull;

public class Category {
    @SerializedName(value = "id", alternate = {"Id", "ID"})
    private int id;

    @SerializedName(value = "name", alternate = {"Name"})
    private String name;

    @SerializedName(value = "description", alternate = {"Description"})
    private String description;

    @SerializedName(value = "imageUrl", alternate = {"ImageUrl"})
    private String imageUrl;

    public Category() {}

    public Category(int id, String name) {
        this.id = id;
        this.name = name;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    @NonNull
    @Override
    public String toString() { return name != null ? name : ""; }
}

package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;

public class UsernameCheckResponse {
    @SerializedName("exists")
    private boolean exists;

    public boolean isExists() {
        return exists;
    }

    public void setExists(boolean exists) {
        this.exists = exists;
    }
}

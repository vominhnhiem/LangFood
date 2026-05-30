package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class OrderStatusResponse implements Serializable {
    @SerializedName("status")
    private String status;

    public OrderStatusResponse() {}

    public OrderStatusResponse(String status) {
        this.status = status;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}

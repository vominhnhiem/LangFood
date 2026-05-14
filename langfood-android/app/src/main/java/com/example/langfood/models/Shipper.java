package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class Shipper implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private int id;

    @SerializedName(value = "userId", alternate = {"UserId"})
    private String userId;

    @SerializedName(value = "mssv", alternate = {"Mssv"})
    private String mssv;

    @SerializedName(value = "isOnline", alternate = {"IsOnline"})
    private boolean isOnline;

    @SerializedName(value = "isApproved", alternate = {"IsApproved"})
    private boolean isApproved;

    public Shipper() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getMssv() { return mssv; }
    public void setMssv(String mssv) { this.mssv = mssv; }

    public boolean isOnline() { return isOnline; }
    public void setOnline(boolean online) { isOnline = online; }

    public boolean isApproved() { return isApproved; }
    public void setApproved(boolean approved) { isApproved = approved; }
}

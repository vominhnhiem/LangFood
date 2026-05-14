package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;
import java.io.Serializable;

public class User implements Serializable {
    @SerializedName(value = "id", alternate = {"Id"})
    private String id;

    @SerializedName(value = "username", alternate = {"Username"})
    private String username;

    @SerializedName(value = "passwordHash", alternate = {"PasswordHash", "password", "Password"})
    private String passwordHash;

    @SerializedName(value = "roleId", alternate = {"RoleId"})
    private Integer roleId;

    @SerializedName(value = "fullName", alternate = {"FullName"})
    private String fullName;

    @SerializedName(value = "email", alternate = {"Email"})
    private String email;

    @SerializedName(value = "phoneNumber", alternate = {"PhoneNumber"})
    private String phoneNumber;

    @SerializedName(value = "buildingId", alternate = {"BuildingId"})
    private Integer buildingId;

    @SerializedName(value = "ktxRoom", alternate = {"KtxRoom"})
    private String ktxRoom;

    @SerializedName(value = "avatarUrl", alternate = {"AvatarUrl"})
    private String avatarUrl;

    @SerializedName(value = "shopName", alternate = {"ShopName"})
    private String shopName;

    @SerializedName(value = "shopAddress", alternate = {"ShopAddress"})
    private String shopAddress;

    @SerializedName(value = "accountType", alternate = {"AccountType"})
    private Integer accountType;

    @SerializedName(value = "cccdNumber", alternate = {"CccdNumber"})
    private String cccdNumber;

    @SerializedName(value = "shop", alternate = {"Shop"})
    private Shop shop;

    @SerializedName(value = "shipper", alternate = {"Shipper"})
    private Shipper shipper;

    @SerializedName(value = "wallet", alternate = {"Wallet"})
    private Wallet wallet;

    public User() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public int getRoleId() { return roleId != null ? roleId : 0; }
    public void setRoleId(Integer roleId) { this.roleId = roleId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public Integer getBuildingId() { return buildingId; }
    public void setBuildingId(Integer buildingId) { this.buildingId = buildingId; }

    public String getKtxRoom() { return ktxRoom; }
    public void setKtxRoom(String ktxRoom) { this.ktxRoom = ktxRoom; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public String getShopAddress() { return shopAddress; }
    public void setShopAddress(String shopAddress) { this.shopAddress = shopAddress; }

    public int getAccountType() { return accountType != null ? accountType : 0; }
    public void setAccountType(Integer accountType) { this.accountType = accountType; }

    public String getCccdNumber() { return cccdNumber; }
    public void setCccdNumber(String cccdNumber) { this.cccdNumber = cccdNumber; }

    public Shop getShop() { return shop; }
    public void setShop(Shop shop) { this.shop = shop; }

    public Shipper getShipper() { return shipper; }
    public void setShipper(Shipper shipper) { this.shipper = shipper; }

    public Wallet getWallet() { return wallet; }
    public void setWallet(Wallet wallet) { this.wallet = wallet; }
}

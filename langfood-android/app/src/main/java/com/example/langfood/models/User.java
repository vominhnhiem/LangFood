package com.example.langfood.models;

import com.google.gson.annotations.SerializedName;

public class User {
    // Sử dụng camelCase làm tên chính để khớp với mặc định của ASP.NET Core JSON
    @SerializedName(value = "id", alternate = {"Id"})
    private String id;

    @SerializedName(value = "username", alternate = {"Username"})
    private String username;

    @SerializedName(value = "passwordHash", alternate = {"PasswordHash", "password", "Password"})
    private String passwordHash;

    @SerializedName(value = "roleId", alternate = {"RoleId"})
    private int roleId;

    @SerializedName(value = "fullName", alternate = {"FullName"})
    private String fullName;

    @SerializedName(value = "email", alternate = {"Email"})
    private String email;

    @SerializedName(value = "phoneNumber", alternate = {"PhoneNumber"})
    private String phoneNumber;

    @SerializedName(value = "buildingId", alternate = {"BuildingId"})
    private Integer buildingId;

    @SerializedName(value = "ktxBuilding", alternate = {"KtxBuilding"})
    private String ktxBuilding;

    @SerializedName(value = "ktxRoom", alternate = {"KtxRoom"})
    private String ktxRoom;

    @SerializedName(value = "isVerifiedResident", alternate = {"IsVerifiedResident"})
    private boolean isVerifiedResident;

    @SerializedName(value = "studentCardImageUrl", alternate = {"StudentCardImageUrl"})
    private String studentCardImageUrl;

    @SerializedName(value = "avatarUrl", alternate = {"AvatarUrl"})
    private String avatarUrl;

    @SerializedName(value = "accountType", alternate = {"AccountType"})
    private int accountType;

    @SerializedName(value = "shopName", alternate = {"ShopName"})
    private String shopName;

    @SerializedName(value = "shopAddress", alternate = {"ShopAddress"})
    private String shopAddress;

    @SerializedName(value = "cccdNumber", alternate = {"CccdNumber"})
    private String cccdNumber;

    public User() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPasswordHash() { return passwordHash; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }

    public int getRoleId() { return roleId; }
    public void setRoleId(int roleId) { this.roleId = roleId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public Integer getBuildingId() { return buildingId; }
    public void setBuildingId(Integer buildingId) { this.buildingId = buildingId; }

    public String getKtxBuilding() { return ktxBuilding; }
    public void setKtxBuilding(String ktxBuilding) { this.ktxBuilding = ktxBuilding; }

    public String getKtxRoom() { return ktxRoom; }
    public void setKtxRoom(String ktxRoom) { this.ktxRoom = ktxRoom; }

    public boolean isVerifiedResident() { return isVerifiedResident; }
    public void setVerifiedResident(boolean verifiedResident) { isVerifiedResident = verifiedResident; }

    public String getStudentCardImageUrl() { return studentCardImageUrl; }
    public void setStudentCardImageUrl(String studentCardImageUrl) { this.studentCardImageUrl = studentCardImageUrl; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public int getAccountType() { return accountType; }
    public void setAccountType(int accountType) { this.accountType = accountType; }

    public String getShopName() { return shopName; }
    public void setShopName(String shopName) { this.shopName = shopName; }

    public String getShopAddress() { return shopAddress; }
    public void setShopAddress(String shopAddress) { this.shopAddress = shopAddress; }

    public String getCccdNumber() { return cccdNumber; }
    public void setCccdNumber(String cccdNumber) { this.cccdNumber = cccdNumber; }
}

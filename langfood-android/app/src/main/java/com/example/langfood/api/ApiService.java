package com.example.langfood.api;

import com.example.langfood.models.CartItem;
import com.example.langfood.models.Category;
import com.example.langfood.models.Product;
import com.example.langfood.models.User;
import com.example.langfood.models.Order;
import com.example.langfood.models.UsernameCheckResponse;

import java.util.List;

import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.Multipart;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Part;
import retrofit2.http.Path;
import retrofit2.http.Query;

public interface ApiService {

    @GET("api/Products")
    Call<List<Product>> getProducts(@Query("categoryId") Integer categoryId);

    @GET("api/Users/check-username")
    Call<UsernameCheckResponse> checkUsername(@Query("username") String username);

    @GET("api/Users/check-email")
    Call<UsernameCheckResponse> checkEmail(@Query("email") String email);

    @GET("api/Users/check-phone")
    Call<UsernameCheckResponse> checkPhone(@Query("phone") String phone);

    @GET("api/Products/{id}")
    Call<Product> getProductById(@Path("id") int id);

    @POST("api/Users/login")
    Call<User> login(@Body User user);

    @POST("api/Users/register")
    Call<User> register(@Body User user);

    @PUT("api/Users/{id}")
    Call<User> updateUser(@Path("id") String id, @Body User user);

    @POST("api/Users/upload-avatar/{userId}")
    @Multipart
    Call<Void> uploadAvatar(@Path("userId") String userId, @Part MultipartBody.Part image);

    @GET("api/Users/{id}")
    Call<User> getUserById(@Path("id") String id);

    @POST("api/Orders")
    Call<Order> createOrder(@Body Order order);

    @GET("api/Orders/buyer/{buyerId}")
    Call<List<Order>> getOrdersByBuyer(@Path("buyerId") String buyerId);

    @GET("api/Orders")
    Call<List<Order>> getAllOrders();

    @PUT("api/Orders/accept/{id}")
    Call<Void> acceptOrder(@Path("id") int id, @Query("shipperId") String shipperId);

    @PUT("api/Orders/complete/{id}")
    Call<Void> completeOrder(@Path("id") int id);

    // --- API GIỎ HÀNG (SERVER) ---
    @GET("api/Cart/{userId}")
    Call<List<CartItem>> getCart(@Path("userId") String userId);

    @POST("api/Cart")
    Call<Void> addToCart(@Query("userId") String userId, @Query("productId") int productId, @Query("quantity") int quantity);

    @DELETE("api/Cart/{userId}/{productId}")
    Call<Void> removeFromCart(@Path("userId") String userId, @Path("productId") int productId);

    @DELETE("api/Cart/{userId}")
    Call<Void> clearCart(@Path("userId") String userId);

    // --- API MỚI CHO SHIPPER ---
    @GET("api/Orders/available")
    Call<List<Order>> getAvailableOrders();

    @POST("api/Products/upload")
    @Multipart
    Call<Product> addProductWithImage(
            @Part("name") RequestBody name,
            @Part("price") RequestBody price,
            @Part("description") RequestBody description,
            @Part("sellerId") RequestBody sellerId,
            @Part("categoryId") RequestBody categoryId,
            @Part MultipartBody.Part image
    );

    @DELETE("api/Products/{id}")
    Call<Void> deleteProduct(@Path("id") int id);

    @PUT("api/Products/{id}")
    Call<Void> updateProduct(@Path("id") int id, @Body Product product);

    // --- API CATEGORY ---
    @GET("api/Categories")
    Call<List<Category>> getCategories();

    @Multipart
    @POST("api/Users/apply-shipper")
    Call<ResponseBody> applyShipper(
            @Part("userId") RequestBody userId,
            @Part MultipartBody.Part imageProof
    );

    // --- API OTP ---
    @POST("api/Users/send-otp")
    Call<ResponseBody> sendOtp(@Query("email") String email, @Query("username") String username);

    @POST("api/Users/verify-otp")
    Call<ResponseBody> verifyOtp(@Query("email") String email, @Query("otp") String otp);

    @POST("api/Users/reset-password")
    Call<ResponseBody> resetPassword(@Query("email") String email, @Query("newPassword") String newPassword);

    @POST("api/Users/change-password")
    Call<ResponseBody> changePassword(
            @Query("id") String id,
            @Query("oldPassword") String oldPassword,
            @Query("newPassword") String newPassword
    );
}

package com.example.langfood.api;

import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class ApiClient {
    // Nếu dùng máy ảo Android (Emulator), dùng IP: 10.0.2.2
    // Nếu dùng máy thật, phải dùng IP của máy tính (ví dụ: 192.168.1.x)
    // Sửa IP ở đây khi đổi mạng. IP hiện tại từ ipconfig: 192.168.61.39
    public static final String BASE_URL = "http://192.168.100.192:5289/";
    private static Retrofit retrofit = null;

    public static Retrofit getClient() {
        if (retrofit == null) {
            retrofit = new Retrofit.Builder()
                    .baseUrl(BASE_URL)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();
        }
        return retrofit;
    }
}

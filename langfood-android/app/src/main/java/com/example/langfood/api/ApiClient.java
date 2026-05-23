package com.example.langfood.api;

import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

/**
 * Singleton class to manage the Retrofit instance for network requests.
 */
public class ApiClient {
    /**
     * The base URL of the backend API.
     */
    public static final String BASE_URL = "http://192.168.100.192:5289/";

    /**
     * Static instance of Retrofit.
     */
    private static Retrofit retrofit = null;

    /**
     * Returns the singleton Retrofit client instance.
     * Returns the singleton Retrofit client instance.
     * If the instance doesn't exist, it creates a new one using the {@link #BASE_URL}.
     *
     * @return The Retrofit instance.
     */
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

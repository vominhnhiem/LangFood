package com.example.langfood;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;

public class OrderPagerAdapter extends FragmentStateAdapter {

    public OrderPagerAdapter(@NonNull FragmentActivity fragmentActivity) {
        super(fragmentActivity);
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        switch (position) {
            case 0:
                return new ActiveOrdersFragment();
            case 1:
                return new OrderHistoryFragment();
            case 2:
                return PlaceholderTabFragment.newInstance(
                        "Chưa có đánh giá nào",
                        "Sau khi nhận món ăn, bạn hãy chia sẻ trải nghiệm đánh giá tại đây nhé!"
                );
            case 3:
            default:
                return PlaceholderTabFragment.newInstance(
                        "Chưa có đơn nháp nào",
                        "Các đơn nháp bạn chưa hoàn thành đặt món sẽ lưu giữ tại đây."
                );
        }
    }

    @Override
    public int getItemCount() {
        return 4;
    }
}

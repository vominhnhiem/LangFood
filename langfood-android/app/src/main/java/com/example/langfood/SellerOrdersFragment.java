package com.example.langfood;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;
import java.util.ArrayList;
import java.util.List;

public class SellerOrdersFragment extends Fragment {

    private TabLayout tabLayout;
    private ViewPager2 viewPager;
    private OrdersPagerAdapter pagerAdapter;
    private final List<Fragment> activeFragments = new ArrayList<>();

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_seller_orders, container, false);

        tabLayout = view.findViewById(R.id.tabLayoutOrders);
        viewPager = view.findViewById(R.id.viewPagerOrders);

        pagerAdapter = new OrdersPagerAdapter(this);
        viewPager.setAdapter(pagerAdapter);

        new TabLayoutMediator(tabLayout, viewPager, (tab, position) -> {
            switch (position) {
                case 0:
                    tab.setText("Đơn mới");
                    break;
                case 1:
                    tab.setText("Đang nấu");
                    break;
                case 2:
                    tab.setText("Lịch sử");
                    break;
            }
        }).attach();

        return view;
    }

    @Override
    public void onDestroyView() {
        if (viewPager != null) {
            viewPager.setAdapter(null);
        }
        activeFragments.clear();
        super.onDestroyView();
    }

    public void refreshAllTabs() {
        for (Fragment f : activeFragments) {
            if (f instanceof SubOrdersFragment) {
                ((SubOrdersFragment) f).loadOrders();
            }
        }
    }

    private class OrdersPagerAdapter extends FragmentStateAdapter {

        public OrdersPagerAdapter(@NonNull Fragment fragment) {
            super(fragment.getChildFragmentManager(), fragment.getLifecycle());
            activeFragments.clear();
        }

        @NonNull
        @Override
        public Fragment createFragment(int position) {
            SubOrdersFragment fragment;
            switch (position) {
                case 0:
                    fragment = SubOrdersFragment.newInstance(SubOrdersFragment.TYPE_PENDING);
                    break;
                case 1:
                    fragment = SubOrdersFragment.newInstance(SubOrdersFragment.TYPE_PREPARING);
                    break;
                case 2:
                default:
                    fragment = SubOrdersFragment.newInstance(SubOrdersFragment.TYPE_HISTORY);
                    break;
            }
            activeFragments.add(fragment);
            return fragment;
        }

        @Override
        public int getItemCount() {
            return 3;
        }
    }
}

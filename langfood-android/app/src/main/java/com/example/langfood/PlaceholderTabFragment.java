package com.example.langfood;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

public class PlaceholderTabFragment extends Fragment {

    private static final String ARG_TITLE = "title";
    private static final String ARG_SUBTITLE = "subtitle";

    public static PlaceholderTabFragment newInstance(String title, String subtitle) {
        PlaceholderTabFragment fragment = new PlaceholderTabFragment();
        Bundle args = new Bundle();
        args.putString(ARG_TITLE, title);
        args.putString(ARG_SUBTITLE, subtitle);
        fragment.setArguments(args);
        return fragment;
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_placeholder_tab, container, false);
        
        TextView tvTitle = view.findViewById(R.id.tvPlaceholderTitle);
        TextView tvSubtitle = view.findViewById(R.id.tvPlaceholderSubtitle);

        if (getArguments() != null) {
            String title = getArguments().getString(ARG_TITLE, "Không tìm thấy thông tin");
            String subtitle = getArguments().getString(ARG_SUBTITLE, "");
            tvTitle.setText(title);
            tvSubtitle.setText(subtitle);
        }

        return view;
    }
}

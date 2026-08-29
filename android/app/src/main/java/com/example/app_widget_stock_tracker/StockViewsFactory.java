package com.example.app_widget_stock_tracker;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.view.View;
import android.widget.RemoteViews;
import android.widget.RemoteViewsService;

import org.json.JSONArray;
import org.json.JSONObject;

import java.text.NumberFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

public class StockViewsFactory implements RemoteViewsService.RemoteViewsFactory {

    private final Context context;
    private final List<StockItemData> items = new ArrayList<>();

    public StockViewsFactory(Context context, Intent intent) {
        this.context = context;
    }

    @Override
    public void onCreate() {
        loadData();
    }

    @Override
    public void onDataSetChanged() {
        loadData();
    }

    private void loadData() {
        items.clear();
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        String jsonStr = prefs.getString("saved_widget_model", null);
        if (jsonStr == null || jsonStr.isEmpty()) {
            SharedPreferences flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
            jsonStr = flutterPrefs.getString("flutter.saved_widget_model", null);
        }

        if (jsonStr == null || jsonStr.isEmpty()) {
            return;
        }

        try {
            JSONObject obj = new JSONObject(jsonStr);
            JSONArray arr = obj.optJSONArray("items");
            if (arr != null) {
                for (int i = 0; i < arr.length(); i++) {
                    JSONObject itemObj = arr.getJSONObject(i);
                    String symbol = itemObj.optString("symbol", "");
                    String customName = itemObj.optString("customName", symbol);
                    double initialPrice = itemObj.optDouble("initialPrice", 0.0);
                    double currentPrice = itemObj.optDouble("currentPrice", 0.0);
                    items.add(new StockItemData(symbol, customName, initialPrice, currentPrice));
                }
            }

            // Sort by variation descending (highest % on top, lowest on bottom)
            Collections.sort(items, new Comparator<StockItemData>() {
                @Override
                public int compare(StockItemData o1, StockItemData o2) {
                    return Double.compare(o2.getVariationPercentage(), o1.getVariationPercentage());
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public void onDestroy() {
        items.clear();
    }

    @Override
    public int getCount() {
        return items.size();
    }

    @Override
    public RemoteViews getViewAt(int position) {
        if (position < 0 || position >= items.size()) {
            return null;
        }

        StockItemData item = items.get(position);
        RemoteViews rv = new RemoteViews(context.getPackageName(), R.layout.stock_widget_item);

        rv.setTextViewText(R.id.item_name, item.customName);
        if (item.customName.equalsIgnoreCase(item.symbol)) {
            rv.setViewVisibility(R.id.item_symbol, View.GONE);
        } else {
            rv.setViewVisibility(R.id.item_symbol, View.VISIBLE);
            rv.setTextViewText(R.id.item_symbol, item.symbol);
        }

        // Format price in EUR
        NumberFormat nf = NumberFormat.getNumberInstance(Locale.FRANCE);
        nf.setMinimumFractionDigits(2);
        nf.setMaximumFractionDigits(2);
        rv.setTextViewText(R.id.item_price, nf.format(item.currentPrice) + " €");

        // Format variation
        double var = item.getVariationPercentage();
        boolean isPositive = var >= 0;
        String sign = isPositive ? "+" : "";
        String varStr = sign + String.format(Locale.US, "%.2f%%", var);
        rv.setTextViewText(R.id.item_variation, varStr);

        if (isPositive) {
            rv.setInt(R.id.item_variation, "setBackgroundResource", R.drawable.badge_positive);
            rv.setTextColor(R.id.item_variation, Color.parseColor("#1B873F"));
        } else {
            rv.setInt(R.id.item_variation, "setBackgroundResource", R.drawable.badge_negative);
            rv.setTextColor(R.id.item_variation, Color.parseColor("#D93025"));
        }

        // Fill-in intent for item click
        Intent fillInIntent = new Intent();
        rv.setOnClickFillInIntent(R.id.item_root, fillInIntent);

        return rv;
    }

    @Override
    public RemoteViews getLoadingView() {
        return null;
    }

    @Override
    public int getViewTypeCount() {
        return 1;
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public boolean hasStableIds() {
        return true;
    }

    static class StockItemData {
        final String symbol;
        final String customName;
        final double initialPrice;
        final double currentPrice;

        StockItemData(String symbol, String customName, double initialPrice, double currentPrice) {
            this.symbol = symbol;
            this.customName = customName;
            this.initialPrice = initialPrice;
            this.currentPrice = currentPrice;
        }

        double getVariationPercentage() {
            if (initialPrice <= 0) return 0.0;
            return ((currentPrice - initialPrice) / initialPrice) * 100.0;
        }
    }
}

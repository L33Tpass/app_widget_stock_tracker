package com.example.app_widget_stock_tracker;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import es.antonborri.home_widget.HomeWidgetBackgroundReceiver;
import es.antonborri.home_widget.HomeWidgetProvider;

public class StockWidgetProvider extends HomeWidgetProvider {

    public static final String ACTION_REFRESH = "com.example.app_widget_stock_tracker.ACTION_REFRESH";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (ACTION_REFRESH.equals(intent.getAction())) {
            int appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID);
            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);

            // 1. Immediately switch the refresh icon to a spinner in the native widget
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.stock_widget_layout);
            views.setViewVisibility(R.id.widget_progress_bar, View.VISIBLE);
            views.setViewVisibility(R.id.widget_refresh_button, View.GONE);

            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                appWidgetManager.partiallyUpdateAppWidget(appWidgetId, views);
            } else {
                ComponentName componentName = new ComponentName(context, StockWidgetProvider.class);
                int[] allIds = appWidgetManager.getAppWidgetIds(componentName);
                if (allIds != null && allIds.length > 0) {
                    appWidgetManager.partiallyUpdateAppWidget(allIds, views);
                }
            }

            // 2. Trigger the Flutter background refresh worker
            Intent bgIntent = new Intent(context, HomeWidgetBackgroundReceiver.class);
            bgIntent.setAction("es.antonborri.home_widget.action.BACKGROUND");
            bgIntent.setData(Uri.parse("stockTracker://refresh"));
            context.sendBroadcast(bgIntent);
            return;
        }

        super.onReceive(context, intent);
    }

    @Override
    public void onUpdate(
            Context context,
            AppWidgetManager appWidgetManager,
            int[] appWidgetIds,
            SharedPreferences widgetData) {

        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.stock_widget_layout);

            // Open MainActivity on header click
            Intent intent = new Intent(context, MainActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            PendingIntent launchIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widget_header, launchIntent);

            // Refresh action on button click
            Intent refreshIntent = new Intent(context, StockWidgetProvider.class);
            refreshIntent.setAction(ACTION_REFRESH);
            refreshIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId);
            PendingIntent refreshPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent);

            // Ensure progress bar is hidden and refresh icon is visible on normal update
            views.setViewVisibility(R.id.widget_progress_bar, View.GONE);
            views.setViewVisibility(R.id.widget_refresh_button, View.VISIBLE);

            // Set last updated time
            String dateStr = "--/--/---- --:--";
            String jsonStr = widgetData.getString("saved_widget_model", null);
            if (jsonStr == null || jsonStr.isEmpty()) {
                SharedPreferences flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
                jsonStr = flutterPrefs.getString("flutter.saved_widget_model", null);
            }

            if (jsonStr != null && !jsonStr.isEmpty()) {
                try {
                    JSONObject jsonObj = new JSONObject(jsonStr);
                    String lastUpdated = jsonObj.optString("lastUpdated", "");
                    if (!lastUpdated.isEmpty()) {
                        SimpleDateFormat isoFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault());
                        SimpleDateFormat displayFormat = new SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.FRANCE);
                        Date date = isoFormat.parse(lastUpdated);
                        if (date != null) {
                            dateStr = displayFormat.format(date);
                        }
                    }
                } catch (Exception ignored) {
                }
            }
            views.setTextViewText(R.id.widget_last_updated, dateStr);

            // Configure native RemoteViews adapter for the ListView
            Intent serviceIntent = new Intent(context, StockWidgetService.class);
            serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId);
            serviceIntent.setData(Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME)));
            views.setRemoteAdapter(R.id.stock_list_view, serviceIntent);
            views.setEmptyView(R.id.stock_list_view, R.id.widget_empty_view);

            // Set click handler for list items to launch app
            Intent itemClickIntent = new Intent(context, MainActivity.class);
            itemClickIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            PendingIntent itemPendingIntent = PendingIntent.getActivity(
                context,
                0,
                itemClickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setPendingIntentTemplate(R.id.stock_list_view, itemPendingIntent);

            appWidgetManager.updateAppWidget(appWidgetId, views);
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.stock_list_view);
        }
    }
}

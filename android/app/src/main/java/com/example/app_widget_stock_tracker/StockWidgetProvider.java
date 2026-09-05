package com.example.app_widget_stock_tracker;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.SystemClock;
import android.util.Log;
import android.view.View;
import android.widget.RemoteViews;

import org.json.JSONObject;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import es.antonborri.home_widget.HomeWidgetBackgroundReceiver;
import es.antonborri.home_widget.HomeWidgetProvider;

public class StockWidgetProvider extends HomeWidgetProvider {

    private static final String TAG = "StockWidgetProvider";
    public static final String ACTION_REFRESH = "com.example.app_widget_stock_tracker.ACTION_REFRESH";
    public static final String ACTION_AUTO_UPDATE = "com.example.app_widget_stock_tracker.ACTION_AUTO_UPDATE";
    public static final String PREF_NAME = "HomeWidgetPreferences";
    public static final String KEY_LAST_REFRESH = "last_auto_refresh_timestamp";
    public static final long UPDATE_INTERVAL_MILLIS = 30 * 60 * 1000L; // 30 minutes
    public static final long STALE_THRESHOLD_MILLIS = 25 * 60 * 1000L; // 25 minutes

    /**
     * Schedules inexact 30-minute repeating updates using Android AlarmManager.
     */
    public static void schedulePeriodicUpdate(Context context) {
        try {
            AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
            if (alarmManager == null) return;

            Intent intent = new Intent(context, StockWidgetProvider.class);
            intent.setAction(ACTION_AUTO_UPDATE);

            PendingIntent pendingIntent = PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );

            long triggerAtMillis = SystemClock.elapsedRealtime() + UPDATE_INTERVAL_MILLIS;

            alarmManager.setInexactRepeating(
                AlarmManager.ELAPSED_REALTIME,
                triggerAtMillis,
                UPDATE_INTERVAL_MILLIS,
                pendingIntent
            );
            Log.d(TAG, "Periodic 30-minute update scheduled successfully");
        } catch (Exception e) {
            Log.e(TAG, "Error scheduling periodic update", e);
        }
    }

    /**
     * Cancels scheduled repeating updates when no widgets remain on the home screen.
     */
    public static void cancelPeriodicUpdate(Context context) {
        try {
            AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
            if (alarmManager == null) return;

            Intent intent = new Intent(context, StockWidgetProvider.class);
            intent.setAction(ACTION_AUTO_UPDATE);

            PendingIntent pendingIntent = PendingIntent.getBroadcast(
                context,
                1001,
                intent,
                PendingIntent.FLAG_NO_CREATE | PendingIntent.FLAG_IMMUTABLE
            );

            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent);
                pendingIntent.cancel();
                Log.d(TAG, "Periodic 30-minute update cancelled");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error cancelling periodic update", e);
        }
    }

    /**
     * Dispatches refresh broadcast to HomeWidgetBackgroundReceiver to trigger Flutter isolate.
     */
    public static void triggerBackgroundRefresh(Context context) {
        try {
            SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
            prefs.edit().putLong(KEY_LAST_REFRESH, System.currentTimeMillis()).apply();

            Intent bgIntent = new Intent(context, HomeWidgetBackgroundReceiver.class);
            bgIntent.setAction("es.antonborri.home_widget.action.BACKGROUND");
            bgIntent.setData(Uri.parse("stockTracker://refresh"));
            context.sendBroadcast(bgIntent);
            Log.d(TAG, "Dispatched refresh broadcast to HomeWidgetBackgroundReceiver");
        } catch (Exception e) {
            Log.e(TAG, "Error triggering background refresh", e);
        }
    }

    /**
     * Checks if cached stock data is older than 25 minutes or missing, and triggers refresh if needed.
     */
    public static void checkAndTriggerRefreshIfStale(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        long lastRefresh = prefs.getLong(KEY_LAST_REFRESH, 0);
        long now = System.currentTimeMillis();

        if (lastRefresh == 0 || (now - lastRefresh) >= STALE_THRESHOLD_MILLIS) {
            Log.d(TAG, "Stock data is stale. Triggering background refresh.");
            triggerBackgroundRefresh(context);
        }
    }

    private void showLoadingState(Context context, int appWidgetId) {
        try {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.stock_widget_layout);
            views.setViewVisibility(R.id.widget_progress_bar, View.VISIBLE);
            views.setViewVisibility(R.id.widget_refresh_button, View.GONE);

            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                appWidgetManager.partiallyUpdateAppWidget(appWidgetId, views);
            } else {
                ComponentName componentName = new ComponentName(context, StockWidgetProvider.class);
                int[] allIds = appWidgetManager.getAppWidgetIds(componentName);
                if (allIds != null && allIds.length > 0) {
                    appWidgetManager.partiallyUpdateAppWidget(allIds, views);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error showing loading state", e);
        }
    }

    @Override
    public void onEnabled(Context context) {
        super.onEnabled(context);
        Log.d(TAG, "First widget added to home screen. Starting 30m periodic scheduler.");
        schedulePeriodicUpdate(context);
        checkAndTriggerRefreshIfStale(context);
    }

    @Override
    public void onDisabled(Context context) {
        super.onDisabled(context);
        Log.d(TAG, "Last widget removed from home screen. Cancelling periodic scheduler.");
        cancelPeriodicUpdate(context);
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null || intent.getAction() == null) {
            super.onReceive(context, intent);
            return;
        }

        String action = intent.getAction();

        // 1. Manual user refresh requested via UI button
        if (ACTION_REFRESH.equals(action)) {
            int appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID);
            showLoadingState(context, appWidgetId);
            triggerBackgroundRefresh(context);
            schedulePeriodicUpdate(context);
            return;
        }

        // 2. Scheduled 30-minute automatic update from AlarmManager
        if (ACTION_AUTO_UPDATE.equals(action)) {
            Log.d(TAG, "Received ACTION_AUTO_UPDATE, triggering background refresh");
            triggerBackgroundRefresh(context);
            return;
        }

        // 3. System reboot or package update -> restore alarm schedule
        if (Intent.ACTION_BOOT_COMPLETED.equals(action) || Intent.ACTION_MY_PACKAGE_REPLACED.equals(action)) {
            AppWidgetManager appWidgetManager = AppWidgetManager.getInstance(context);
            ComponentName componentName = new ComponentName(context, StockWidgetProvider.class);
            int[] allIds = appWidgetManager.getAppWidgetIds(componentName);
            if (allIds != null && allIds.length > 0) {
                Log.d(TAG, "Restoring periodic schedule after reboot/package update");
                schedulePeriodicUpdate(context);
                checkAndTriggerRefreshIfStale(context);
            }
            return;
        }

        // 4. Standard AppWidget update (system updatePeriodMillis or Flutter background refresh completion)
        if (AppWidgetManager.ACTION_APPWIDGET_UPDATE.equals(action)) {
            boolean triggeredFromHomeWidget = intent.getBooleanExtra("triggeredFromHomeWidget", false);
            if (triggeredFromHomeWidget) {
                // Update dispatched from Flutter with fresh data
                SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
                prefs.edit().putLong(KEY_LAST_REFRESH, System.currentTimeMillis()).apply();
                schedulePeriodicUpdate(context);
            } else {
                // Update dispatched by Android OS (30-min updatePeriodMillis or initial placement)
                schedulePeriodicUpdate(context);
                checkAndTriggerRefreshIfStale(context);
            }
        }

        super.onReceive(context, intent);
    }

    @Override
    public void onUpdate(
            Context context,
            AppWidgetManager appWidgetManager,
            int[] appWidgetIds,
            SharedPreferences widgetData) {

        schedulePeriodicUpdate(context);

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

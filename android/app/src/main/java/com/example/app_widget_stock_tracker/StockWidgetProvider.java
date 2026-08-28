package com.example.app_widget_stock_tracker;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.view.View;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetBackgroundIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

public class StockWidgetProvider extends HomeWidgetProvider {

    @Override
    public void onUpdate(
            Context context,
            AppWidgetManager appWidgetManager,
            int[] appWidgetIds,
            SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.stock_widget_layout);

            // Open MainActivity on widget body click
            Intent intent = new Intent(context, MainActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            PendingIntent launchIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent);

            // Background refresh without opening app when clicking the top-right refresh area
            PendingIntent refreshIntent = HomeWidgetBackgroundIntent.INSTANCE.getBroadcast(
                context,
                Uri.parse("stockTracker://refresh")
            );
            views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshIntent);

            // Load rendered image from HomeWidget.renderFlutterWidget
            String imagePath = widgetData.getString("stock_widget_image", null);
            if (imagePath != null) {
                Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.widget_image, bitmap);
                    views.setViewVisibility(R.id.widget_image, View.VISIBLE);
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}

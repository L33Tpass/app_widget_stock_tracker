import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/stock_widget_model.dart';
import '../models/widget_stock_item.dart';
import '../services/market_data_service.dart';
import '../services/widget_storage_service.dart';

class NativeWidgetService {
  static final NativeWidgetService _instance = NativeWidgetService._internal();
  factory NativeWidgetService() => _instance;
  NativeWidgetService._internal();

  /// Updates native Android AppWidget by persisting the JSON model and notifying the native provider
  Future<void> updateNativeWidget(StockWidgetModel widgetModel) async {
    try {
      // Save widget model in shared storage for the native StockViewsFactory
      await HomeWidget.saveWidgetData<String>('saved_widget_model', widgetModel.toJsonString());

      // Notify native Android StockWidgetProvider
      await HomeWidget.updateWidget(
        name: 'StockWidgetProvider',
        androidName: 'StockWidgetProvider',
        qualifiedAndroidName: 'com.example.app_widget_stock_tracker.StockWidgetProvider',
      );
    } catch (e) {
      debugPrint('Native home widget update error: $e');
    }
  }

  /// Refreshes quotes in the background upon periodic automatic refresh or when user taps the refresh button
  Future<void> refreshFromBackground() async {
    try {
      final jsonStr = await HomeWidget.getWidgetData<String>('saved_widget_model');
      StockWidgetModel? model;
      if (jsonStr != null && jsonStr.isNotEmpty) {
        model = StockWidgetModel.fromJsonString(jsonStr);
      } else {
        final savedWidgets = await WidgetStorageService().loadWidgets();
        if (savedWidgets.isNotEmpty) {
          model = savedWidgets.firstWhere((w) => w.isPinned, orElse: () => savedWidgets.first);
        }
      }

      if (model != null) {
        await MarketDataService().refreshWidgetLivePrices(model);
        await updateNativeWidget(model);

        // Keep WidgetStorageService in sync so Flutter app also shows updated prices
        try {
          final storage = WidgetStorageService();
          final allWidgets = await storage.loadWidgets();
          final idx = allWidgets.indexWhere((w) => w.id == model!.id);
          if (idx != -1) {
            allWidgets[idx] = model;
            await storage.saveWidgets(allWidgets);
          }
        } catch (_) {}
      } else {
        await HomeWidget.updateWidget(
          name: 'StockWidgetProvider',
          androidName: 'StockWidgetProvider',
          qualifiedAndroidName: 'com.example.app_widget_stock_tracker.StockWidgetProvider',
        );
      }
    } catch (e) {
      debugPrint('Error refreshing widget in background: $e');
      try {
        await HomeWidget.updateWidget(
          name: 'StockWidgetProvider',
          androidName: 'StockWidgetProvider',
          qualifiedAndroidName: 'com.example.app_widget_stock_tracker.StockWidgetProvider',
        );
      } catch (_) {}
    }
  }

  /// Prompts Android launcher to pin the widget directly to the home screen
  Future<bool> pinToHomeScreen() async {
    try {
      final isSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isSupported == true) {
        await HomeWidget.requestPinWidget(
          androidName: 'StockWidgetProvider',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Native home widget pin ignored: $e');
    }
    return false;
  }

  /// Checks if any widget instance is currently pinned to the Android home screen
  Future<bool> isWidgetPinned() async {
    try {
      final installedWidgets = await HomeWidget.getInstalledWidgets();
      return installedWidgets.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking installed widgets: $e');
      return false;
    }
  }

  /// Returns stock items from the widget model whose variation is strictly greater than [threshold] percent (defaults to +10.0%)
  List<WidgetStockItem> getItemsWithPositiveVariation(StockWidgetModel model, {double threshold = 10.0}) {
    return model.items.where((item) => item.variationPercentage > threshold).toList();
  }

  /// Requests notification permission on the Flutter side using permission_handler
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
}

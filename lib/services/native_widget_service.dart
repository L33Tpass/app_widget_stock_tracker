import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/stock_widget_model.dart';
import '../services/market_data_service.dart';

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
      );
    } catch (e) {
      debugPrint('Native home widget update error: $e');
    }
  }

  /// Refreshes quotes in the background when user taps the refresh button on the Android home screen
  Future<void> refreshFromBackground() async {
    try {
      final jsonStr = await HomeWidget.getWidgetData<String>('saved_widget_model');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final model = StockWidgetModel.fromJsonString(jsonStr);
        await MarketDataService().refreshWidgetLivePrices(model);
        await updateNativeWidget(model);
      }
    } catch (e) {
      debugPrint('Error refreshing widget in background: $e');
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
}

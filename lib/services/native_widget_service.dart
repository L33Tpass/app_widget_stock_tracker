import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../models/stock_widget_model.dart';
import '../widgets/static_stock_widget_card.dart';

class NativeWidgetService {
  static final NativeWidgetService _instance = NativeWidgetService._internal();
  factory NativeWidgetService() => _instance;
  NativeWidgetService._internal();

  /// Renders the Flutter widget to an image and sends it to the Android AppWidget
  Future<void> updateNativeWidget(StockWidgetModel widgetModel) async {
    try {
      final itemCount = widgetModel.items.length;
      final targetHeight = (90.0 + (itemCount * 65.0)).clamp(220.0, 800.0);

      await HomeWidget.renderFlutterWidget(
        Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: StaticStockWidgetCard(
              widgetModel: widgetModel,
            ),
          ),
        ),
        key: 'stock_widget_image',
        logicalSize: Size(380, targetHeight),
      );

      await HomeWidget.updateWidget(
        name: 'StockWidgetProvider',
        androidName: 'StockWidgetProvider',
      );
    } catch (e) {
      debugPrint('Native home widget update ignored: $e');
    }
  }

  /// Prompts Android to pin the widget directly onto the phone launcher home screen
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

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/stock_widget_model.dart';

class WidgetStorageService {
  static final WidgetStorageService _instance = WidgetStorageService._internal();
  factory WidgetStorageService() => _instance;
  WidgetStorageService._internal();

  static const String _widgetsKey = 'configured_widgets_list';
  static const String _legacyKey = 'saved_widget_model';

  // In-memory fallback (used in unit tests or when native plugin is unavailable)
  final Map<String, String> _memoryStore = {};

  /// Saves the list of all configured widgets to persistent storage
  Future<void> saveWidgets(List<StockWidgetModel> widgets) async {
    final jsonList = widgets.map((w) => w.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    _memoryStore[_widgetsKey] = jsonStr;

    try {
      await HomeWidget.saveWidgetData<String>(_widgetsKey, jsonStr);

      // Keep native Android widget in sync with the primary widget model
      if (widgets.isNotEmpty) {
        final activeWidget = widgets.firstWhere((w) => w.isPinned, orElse: () => widgets.first);
        await HomeWidget.saveWidgetData<String>(_legacyKey, activeWidget.toJsonString());
      } else {
        await HomeWidget.saveWidgetData<String>(_legacyKey, '');
      }
    } catch (e) {
      debugPrint('Error saving widgets to storage: $e');
    }
  }

  /// Loads the list of all configured widgets from persistent storage
  Future<List<StockWidgetModel>> loadWidgets() async {
    try {
      final jsonStr = await HomeWidget.getWidgetData<String>(_widgetsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        return decoded
            .map((item) => StockWidgetModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Fallback: Check if there was a single widget saved previously
      final legacyJsonStr = await HomeWidget.getWidgetData<String>(_legacyKey);
      if (legacyJsonStr != null && legacyJsonStr.isNotEmpty) {
        final model = StockWidgetModel.fromJsonString(legacyJsonStr);
        return [model];
      }
    } catch (e) {
      debugPrint('Error loading widgets from storage: $e');
    }

    if (_memoryStore.containsKey(_widgetsKey)) {
      final jsonStr = _memoryStore[_widgetsKey]!;
      if (jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List<dynamic>;
        return decoded
            .map((item) => StockWidgetModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }
}

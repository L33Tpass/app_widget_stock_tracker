import 'package:flutter/material.dart';
import '../models/stock_widget_model.dart';
import '../services/market_data_service.dart';
import '../services/native_widget_service.dart';
import '../widgets/stock_widget_card.dart';
import 'widget_config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<StockWidgetModel> _widgets = [];
  final MarketDataService _marketService = MarketDataService();
  final NativeWidgetService _nativeWidgetService = NativeWidgetService();

  Future<void> _openWidgetConfig({StockWidgetModel? existingWidget}) async {
    final result = await Navigator.of(context).push<StockWidgetModel>(
      MaterialPageRoute(
        builder: (ctx) => WidgetConfigScreen(initialWidget: existingWidget),
      ),
    );

    if (result != null) {
      setState(() {
        if (existingWidget != null) {
          final index = _widgets.indexWhere((w) => w.id == existingWidget.id);
          if (index != -1) {
            _widgets[index] = result;
          }
        } else {
          _widgets.add(result);
        }
      });
      await _nativeWidgetService.updateNativeWidget(result);
    }
  }

  Future<void> _refreshWidget(StockWidgetModel widgetModel) async {
    await _marketService.refreshWidgetLivePrices(widgetModel);
    await _nativeWidgetService.updateNativeWidget(widgetModel);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pinWidget(StockWidgetModel widgetModel) async {
    await _nativeWidgetService.updateNativeWidget(widgetModel);
    final success = await _nativeWidgetService.pinToHomeScreen();
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pour ajouter le widget : restez appuyé sur l\'écran d\'accueil de votre téléphone et choisissez Widgets > Stock Tracker'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _deleteWidget(String id) {
    setState(() {
      _widgets.removeWhere((w) => w.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Widget supprimé'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasWidgets = _widgets.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFEFEF),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          hasWidgets ? 'Accueil' : '',
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: hasWidgets
          ? _buildWidgetsList()
          : _buildEmptyStateWithFullScreenClick(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FloatingActionButton.extended(
          onPressed: () => _openWidgetConfig(),
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'Ajouter un Widget',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state: Entire screen is clickable to launch configuration
  Widget _buildEmptyStateWithFullScreenClick() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openWidgetConfig(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: 34,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ajoutez votre premier Widget sur votre accueil en cliquant n’importe où sur cette page',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Populated state: Widgets are displayed, only the bottom button adds new ones
  Widget _buildWidgetsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: _widgets.length,
      itemBuilder: (context, index) {
        final widgetModel = _widgets[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: StockWidgetCard(
            widgetModel: widgetModel,
            onRefresh: () => _refreshWidget(widgetModel),
            onPin: () => _pinWidget(widgetModel),
            onEdit: () => _openWidgetConfig(existingWidget: widgetModel),
            onDelete: () => _deleteWidget(widgetModel.id),
          ),
        );
      },
    );
  }
}

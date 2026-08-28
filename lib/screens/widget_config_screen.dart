import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_widget_model.dart';
import '../models/widget_stock_item.dart';
import '../widgets/stock_widget_card.dart';
import '../widgets/add_stock_dialog.dart';

import '../services/market_data_service.dart';
import '../services/native_widget_service.dart';

class WidgetConfigScreen extends StatefulWidget {
  final StockWidgetModel? initialWidget;

  const WidgetConfigScreen({
    super.key,
    this.initialWidget,
  });

  @override
  State<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends State<WidgetConfigScreen> {
  late StockWidgetModel _widgetModel;
  final MarketDataService _marketService = MarketDataService();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialWidget != null) {
      _widgetModel = widget.initialWidget!.copyWith();
      _titleController.text = _widgetModel.title;
    } else {
      _widgetModel = StockWidgetModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Suivi des Actions',
        items: [],
        lastUpdated: DateTime.now(),
      );
      _titleController.text = _widgetModel.title;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addDefaultSampleAssets();
      });
    }
  }

  void _addDefaultSampleAssets() {
    if (_widgetModel.items.isEmpty) {
      final now = DateTime.now();
      setState(() {
        _widgetModel.items.addAll([
          WidgetStockItem(
            id: '1',
            symbol: 'BTC/EUR',
            customName: 'Mon Bitcoin',
            purchaseDate: now.subtract(const Duration(days: 180)),
            initialPrice: 42300.0,
            currentPrice: 58450.0,
          ),
          WidgetStockItem(
            id: '2',
            symbol: 'AAPL',
            customName: 'Apple PEA',
            purchaseDate: now.subtract(const Duration(days: 90)),
            initialPrice: 175.50,
            currentPrice: 210.20,
          ),
          WidgetStockItem(
            id: '3',
            symbol: 'TSLA',
            customName: 'Tesla Motors',
            purchaseDate: now.subtract(const Duration(days: 45)),
            initialPrice: 220.00,
            currentPrice: 197.10,
          ),
        ]);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _openAddStockSheet({WidgetStockItem? existingItem}) async {
    final result = await AddStockDialog.show(context, existingItem: existingItem);
    if (result != null) {
      setState(() {
        if (existingItem != null) {
          final index = _widgetModel.items.indexWhere((it) => it.id == existingItem.id);
          if (index != -1) {
            _widgetModel.items[index] = result;
          }
        } else {
          _widgetModel.items.add(result);
        }
        _widgetModel.lastUpdated = DateTime.now();
      });
    }
  }

  void _removeItem(String id) {
    setState(() {
      _widgetModel.items.removeWhere((it) => it.id == id);
      _widgetModel.lastUpdated = DateTime.now();
    });
  }

  Future<void> _saveWidget() async {
    if (_widgetModel.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une action à suivre.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    _widgetModel.title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Suivi des Actions';
    _widgetModel.lastUpdated = DateTime.now();

    // Update the native Android AppWidget on the phone home screen
    await NativeWidgetService().updateNativeWidget(_widgetModel);
    await NativeWidgetService().pinToHomeScreen();

    if (mounted) {
      Navigator.of(context).pop(_widgetModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          widget.initialWidget != null ? 'Modifier le Widget' : 'Configurer le Widget',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Checkmark button in top right to validate widget configuration
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              tooltip: 'Valider le Widget',
              onPressed: _saveWidget,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF4F46E5)),
                    SizedBox(width: 6),
                    Text(
                      'Prévisualisation du Widget',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'En direct',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Live Preview Card (Top section)
            StockWidgetCard(
              widgetModel: _widgetModel,
              isPreview: true,
              onRefresh: () async {
                await _marketService.refreshWidgetLivePrices(_widgetModel);
                if (mounted) {
                  setState(() {});
                }
              },
            ),

            const SizedBox(height: 24),

            // Configuration section: List of actions to track
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Actions suivies (${_widgetModel.items.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAddStockSheet(),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Ajouter une action'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Empty state or configured items list
            if (_widgetModel.items.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_chart_rounded, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune action configurée',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ajoutez des actions US ou le Bitcoin pour composer votre widget.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openAddStockSheet(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter une action'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _widgetModel.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final item = _widgetModel.items[index];
                  final isPositive = item.isPositive;
                  final color = isPositive ? const Color(0xFF1B873F) : const Color(0xFFD93025);
                  final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(item.purchaseDate);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.customName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPositive ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.formattedVariation,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Text(
                                    item.symbol,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '• Acheté le $dateFormatted',
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Action Buttons: Edit and Delete
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4B5563)),
                          tooltip: 'Modifier',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => _openAddStockSheet(existingItem: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                          tooltip: 'Supprimer',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onPressed: () => _removeItem(item.id),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Bottom validation button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'Valider et ajouter à l\'accueil',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _saveWidget,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

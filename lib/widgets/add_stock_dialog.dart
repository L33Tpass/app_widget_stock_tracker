import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_asset.dart';
import '../models/widget_stock_item.dart';
import '../services/market_data_service.dart';

class AddStockDialog extends StatefulWidget {
  final WidgetStockItem? existingItem;

  const AddStockDialog({
    super.key,
    this.existingItem,
  });

  static Future<WidgetStockItem?> show(BuildContext context, {WidgetStockItem? existingItem}) {
    return showModalBottomSheet<WidgetStockItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddStockDialog(existingItem: existingItem),
    );
  }

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final MarketDataService _marketService = MarketDataService();
  late List<StockAsset> _allAssets;
  late List<StockAsset> _filteredAssets;

  StockAsset? _selectedAsset;
  late TextEditingController _customNameController;
  late TextEditingController _searchController;
  late TextEditingController _initialPriceController;
  late DateTime _selectedDateTime;
  double _calculatedInitialPrice = 0.0;
  double _liveCurrentPrice = 0.0;
  bool _isLoadingPrice = false;
  String _selectedCategoryFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _allAssets = _marketService.getAllAssets();
    _filteredAssets = _allAssets;
    _searchController = TextEditingController();

    if (widget.existingItem != null) {
      _selectedAsset = _marketService.getAssetBySymbol(widget.existingItem!.symbol) ?? _allAssets.first;
      _customNameController = TextEditingController(text: widget.existingItem!.customName);
      _selectedDateTime = widget.existingItem!.purchaseDate;
      _calculatedInitialPrice = widget.existingItem!.initialPrice;
      _liveCurrentPrice = widget.existingItem!.currentPrice;
      _initialPriceController = TextEditingController(text: _calculatedInitialPrice.toStringAsFixed(2));
      _fetchLiveCurrentPrice();
    } else {
      _selectedAsset = _allAssets.firstWhere((a) => a.symbol == 'AAPL', orElse: () => _allAssets.first);
      _customNameController = TextEditingController(text: _selectedAsset!.name);
      _selectedDateTime = DateTime.now().subtract(const Duration(days: 24, hours: 12));
      _liveCurrentPrice = _selectedAsset!.currentPrice;
      _calculatedInitialPrice = _selectedAsset!.currentPrice;
      _initialPriceController = TextEditingController(text: _calculatedInitialPrice.toStringAsFixed(2));
      _recalculatePriceAsync();
      _fetchLiveCurrentPrice();
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _searchController.dispose();
    _initialPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveCurrentPrice() async {
    if (_selectedAsset == null) return;
    final symbol = _selectedAsset!.symbol;
    final livePrice = await _marketService.fetchLivePriceInEur(symbol);
    if (mounted && _selectedAsset?.symbol == symbol) {
      setState(() {
        _liveCurrentPrice = livePrice;
      });
    }
  }

  Future<void> _recalculatePriceAsync() async {
    if (_selectedAsset == null) return;
    final symbol = _selectedAsset!.symbol;
    final targetDate = _selectedDateTime;

    setState(() {
      _isLoadingPrice = true;
    });

    final price = await _marketService.fetchHistoricalPriceInEur(symbol, targetDate);

    if (mounted && _selectedAsset?.symbol == symbol) {
      setState(() {
        _calculatedInitialPrice = price;
        _initialPriceController.text = price.toStringAsFixed(2);
        _isLoadingPrice = false;
      });
    }
  }

  void _onManualPriceChanged(String val) {
    final sanitized = val.replaceAll(',', '.').trim();
    final parsed = double.tryParse(sanitized);
    if (parsed != null && parsed > 0) {
      setState(() {
        _calculatedInitialPrice = parsed;
      });
    }
  }

  void _filterAssets() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredAssets = _allAssets.where((asset) {
        final matchesQuery = asset.symbol.toLowerCase().contains(query) ||
            asset.name.toLowerCase().contains(query);
        if (!matchesQuery) return false;

        if (_selectedCategoryFilter == 'US') {
          return asset.category == AssetCategory.usStock;
        } else if (_selectedCategoryFilter == 'CRYPTO') {
          return asset.category == AssetCategory.crypto || asset.category == AssetCategory.marketIndex;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime.isAfter(now) ? now : _selectedDateTime,
      firstDate: DateTime(2010),
      lastDate: now,
      helpText: "Sélectionner la date d'achat initial",
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
      _recalculatePriceAsync();
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedDateTime.hour, minute: _selectedDateTime.minute),
      helpText: "Sélectionner l'heure d'achat",
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
      _recalculatePriceAsync();
    }
  }

  void _applyQuickDate(Duration duration) {
    setState(() {
      _selectedDateTime = DateTime.now().subtract(duration);
    });
    _recalculatePriceAsync();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    const currency = '€';
    final currentPrice = _liveCurrentPrice > 0 ? _liveCurrentPrice : (_selectedAsset?.currentPrice ?? 0.0);

    double variation = 0.0;
    if (_calculatedInitialPrice > 0) {
      variation = ((currentPrice - _calculatedInitialPrice) / _calculatedInitialPrice) * 100;
    }
    final isPositive = variation >= 0;
    final varColor = isPositive ? const Color(0xFF1B873F) : const Color(0xFFD93025);

    return Container(
      height: mediaQuery.size.height * 0.90,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingItem != null ? "Modifier l'action" : "Ajouter une action",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Choose stock asset
                  const Text(
                    "1. Choisir l'action / crypto",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterAssets(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher (ex: Apple, Nvidia, Bitcoin)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Tous', 'ALL'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Actions USA', 'US'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Cryptos & Indices', 'CRYPTO'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Asset selector list
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _filteredAssets.isEmpty
                        ? const Center(child: Text("Aucun résultat trouvé"))
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredAssets.length,
                            separatorBuilder: (context, idx) => const Divider(height: 1, indent: 48),
                            itemBuilder: (ctx, idx) {
                              final asset = _filteredAssets[idx];
                              final isSelected = _selectedAsset?.symbol == asset.symbol;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedAsset = asset;
                                    _liveCurrentPrice = asset.currentPrice;
                                    if (_customNameController.text.isEmpty ||
                                        _allAssets.any((a) => a.name == _customNameController.text || a.symbol == _customNameController.text)) {
                                      _customNameController.text = asset.name;
                                    }
                                  });
                                  _fetchLiveCurrentPrice();
                                  _recalculatePriceAsync();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.12) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: asset.color.withValues(alpha: 0.15),
                                        child: Icon(
                                          asset.icon ?? Icons.show_chart,
                                          size: 18,
                                          color: asset.color,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              asset.symbol,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                                color: isSelected ? const Color(0xFF4338CA) : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              asset.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${asset.currentPrice.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Section 2: Custom Name
                  const Text(
                    "2. Nom personnalisé",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customNameController,
                    decoration: InputDecoration(
                      hintText: "Ex: Mes actions Apple, Portefeuille BTC...",
                      prefixIcon: const Icon(Icons.label_outline, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section 3: Purchase Date and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "3. Date & heure d'achat initial",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      Text(
                        'UTC${DateTime.now().timeZoneOffset.isNegative ? '' : '+'}${DateTime.now().timeZoneOffset.inHours}h (France)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Point de comparaison pour étudier la variation par rapport au cours actuel.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),

                  // Quick presets
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickPresetChip('Aujourd\'hui', const Duration(hours: 4)),
                        const SizedBox(width: 6),
                        _buildQuickPresetChip('Hier', const Duration(days: 1)),
                        const SizedBox(width: 6),
                        _buildQuickPresetChip('Il y a 1 mois', const Duration(days: 30)),
                        const SizedBox(width: 6),
                        _buildQuickPresetChip('Il y a 6 mois', const Duration(days: 182)),
                        const SizedBox(width: 6),
                        _buildQuickPresetChip('Il y a 1 an', const Duration(days: 365)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Date & Time pickers
                  Row(
                    children: [
                      // Date Selector
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(_selectedDateTime),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Time Selector
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat('HH:mm').format(_selectedDateTime),
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Section 4: Editable Initial Purchase Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Prix d'achat initial (€) :",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      if (_isLoadingPrice)
                        const Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 6),
                            Text("Calcul cours réel...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _initialPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: _onManualPriceChanged,
                    decoration: InputDecoration(
                      hintText: "Ex: 263.75",
                      suffixText: "€",
                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      prefixIcon: const Icon(Icons.euro_symbol_rounded, size: 19),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      helperText: "Calculé automatiquement selon la date & heure, ou modifiable manuellement.",
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Preview of calculated price and variation
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isPositive ? const Color(0xFFE6F4EA).withValues(alpha: 0.6) : const Color(0xFFFCE8E6).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: varColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Prix d'achat retenu :",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            Text(
                              '${_calculatedInitialPrice.toStringAsFixed(2)} $currency',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Cours actuel réel :",
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            ),
                            Text(
                              '${currentPrice.toStringAsFixed(2)} $currency',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Variation calculée :",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              isPositive
                                  ? '+${variation.toStringAsFixed(2)}%'
                                  : '${variation.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: varColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  widget.existingItem != null ? "Enregistrer les modifications" : "Ajouter au Widget",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  if (_selectedAsset == null) return;
                  final customName = _customNameController.text.trim().isNotEmpty
                      ? _customNameController.text.trim()
                      : _selectedAsset!.name;

                  final item = WidgetStockItem(
                    id: widget.existingItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    symbol: _selectedAsset!.symbol,
                    customName: customName,
                    purchaseDate: _selectedDateTime,
                    initialPrice: _calculatedInitialPrice,
                    currentPrice: currentPrice,
                  );

                  Navigator.of(context).pop(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategoryFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategoryFilter = value;
          });
          _filterAssets();
        }
      },
      selectedColor: const Color(0xFF111827),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : Colors.grey.shade800,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildQuickPresetChip(String label, Duration duration) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _applyQuickDate(duration),
      backgroundColor: const Color(0xFFEEF2FF),
      labelStyle: const TextStyle(
        fontSize: 11.5,
        color: Color(0xFF4F46E5),
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFC7D2FE)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

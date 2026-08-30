import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_widget_model.dart';
import '../models/widget_stock_item.dart';
import 'stock_item_tile.dart';

class StockWidgetCard extends StatefulWidget {
  final StockWidgetModel widgetModel;
  final FutureOr<void> Function()? onRefresh;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final bool isPreview;

  const StockWidgetCard({
    super.key,
    required this.widgetModel,
    this.onRefresh,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.isPreview = false,
  });

  @override
  State<StockWidgetCard> createState() => _StockWidgetCardState();
}

class _StockWidgetCardState extends State<StockWidgetCard> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final futures = <Future<dynamic>>[
        Future.delayed(const Duration(milliseconds: 650)),
      ];
      if (widget.onRefresh != null) {
        futures.add(Future.sync(() => widget.onRefresh!()));
      }
      await Future.wait(futures);

      if (mounted) {
        setState(() {
          widget.widgetModel.lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Refresh error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildStocksContent(List<WidgetStockItem> sortedItems) {
    if (sortedItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Aucune action configurée',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedItems.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 48,
        color: Color(0xFFF3F4F6),
      ),
      itemBuilder: (context, index) {
        final item = sortedItems[index];
        return StockItemTile(
          item: item,
          showEditControls: false,
          isLoading: _isRefreshing,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = widget.widgetModel.sortedItems;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(widget.widgetModel.lastUpdated);
    final isInactive = !widget.isPreview && !widget.widgetModel.isPinned;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: widget.isPreview
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
          width: widget.isPreview ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Top-left date/time & Top-right refresh button + 3-dots menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top-left: Date & Time of last update
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Color(0xFF4B5563),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top-right: Refresh icon (or loader) + 3-dots options menu
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRefreshing)
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          iconSize: 24,
                          color: const Color(0xFF111827),
                          tooltip: 'Actualiser les cours',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          onPressed: _handleRefresh,
                        ),
                      if (!widget.isPreview && (widget.onEdit != null || widget.onDelete != null))
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 22,
                            color: Color(0xFF374151),
                          ),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          onSelected: (val) {
                            if (val == 'edit' && widget.onEdit != null) {
                              widget.onEdit!();
                            } else if (val == 'delete' && widget.onDelete != null) {
                              widget.onDelete!();
                            }
                          },
                          itemBuilder: (context) => [
                            if (widget.onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Modifier'),
                                  ],
                                ),
                              ),
                            if (widget.onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),
              const Divider(height: 12, thickness: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 2),

              // Body: Stocks content (Grayed out with clickable prompt if inactive)
              if (isInactive)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: widget.onPin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Colors.grey,
                              BlendMode.saturation,
                            ),
                            child: Opacity(
                              opacity: 0.30,
                              child: _buildStocksContent(sortedItems),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.96),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFC7D2FE)),
                                    ),
                                    child: const Icon(
                                      Icons.touch_app_rounded,
                                      size: 18,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Flexible(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Widget inactif',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Cliquer pour l’ajouter à l’écran d’accueil',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF4B5563),
                                          ),
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _buildStocksContent(sortedItems),
            ],
          ),
        ),
      ),
    );
  }
}

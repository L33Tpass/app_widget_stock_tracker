import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_widget_model.dart';
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

  @override
  Widget build(BuildContext context) {
    final sortedItems = widget.widgetModel.sortedItems;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.widgetModel.lastUpdated);

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
              // Header: Top-left date/time & Top-right refresh button (loader when loading) + options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top-left: Date & Time of last update
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top-right: Refresh icon replaced with smooth loader during refresh
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRefreshing)
                        Container(
                          width: 38,
                          height: 38,
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
                          iconSize: 26,
                          color: const Color(0xFF1F2937),
                          tooltip: 'Actualiser les cours',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 38,
                            minHeight: 38,
                          ),
                          onPressed: _handleRefresh,
                        ),
                      if (!widget.isPreview && (widget.onEdit != null || widget.onDelete != null))
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onSelected: (val) {
                            if (val == 'pin' && widget.onPin != null) {
                              widget.onPin!();
                            } else if (val == 'edit' && widget.onEdit != null) {
                              widget.onEdit!();
                            } else if (val == 'delete' && widget.onDelete != null) {
                              widget.onDelete!();
                            }
                          },
                          itemBuilder: (context) => [
                            if (widget.onPin != null)
                              const PopupMenuItem(
                                value: 'pin',
                                child: Row(
                                  children: [
                                    Icon(Icons.push_pin_outlined, size: 18, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 8),
                                    Text('Épingler sur l\'accueil'),
                                  ],
                                ),
                              ),
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

              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 4),

              // Sorted List of stocks: Highest variation on top, lowest on bottom
              if (sortedItems.isEmpty)
                const Padding(
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
                )
              else
                ListView.separated(
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}

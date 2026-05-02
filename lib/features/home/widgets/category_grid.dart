import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../../data/database/category_dao.dart';
import 'category_item.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final List<CategoryItem> items;
  final bool editMode;
  final int columns;
  final Function(List<Category>) onReorder;
  final Function(int id)? onDelete;
  final Function(String label)? onEdit;
  final Function(String label)? onLongPress;
  final Function(String label)? onTap;
  /// Insieme di nomi di categorie che NON possono essere cancellate.
  final Set<String> nonDeletable;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.items,
    required this.editMode,
    required this.columns,
    required this.onReorder,
    this.onDelete,
    this.onEdit,
    this.onLongPress,
    this.onTap,
    this.nonDeletable = const {},
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        final List<Category> updatedList = List.from(categories);
        final Category movedItem = updatedList.removeAt(oldIndex);
        updatedList.insert(newIndex, movedItem);
        onReorder(updatedList);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        // Recuperiamo il CategoryItem corrispondente creato nella HomePage
        final item = index < items.length ? items[index] : null;
        
        if (item == null) return const SizedBox.shrink();

        final isDeletable = !nonDeletable.contains(category.name);

        return _WigglingItem(
          key: ValueKey('grid_item_${category.id}'),
          editMode: editMode,
          isDeletable: isDeletable,
          onDelete: isDeletable ? () => onDelete?.call(category.id!) : null,
          onEdit: () => onEdit?.call(category.name),
          onLongPress: () => onLongPress?.call(category.name),
          onTap: editMode ? null : () => onTap?.call(category.name),
          child: _buildCategoryCell(item),
        );
      },
    );
  }

  Widget _buildCategoryCell(CategoryItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.65, 
                    heightFactor: 0.65,
                    child: Center(
                      child: _buildLeading(item),
                    ),
                  ),
                  if (item.count > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: _Badge(count: item.count),
                    ),
                  if (item.label == 'I ❤️ Abitini')
                    Positioned(
                      bottom: -8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E8C),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Partnership',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        ),
      ],
    );
  }

  // Funzione di supporto per decidere cosa mostrare nel cerchio
  Widget _buildLeading(CategoryItem item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      return Image.asset(
        item.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(item.icon, color: Colors.black54),
      );
    }
    if (item.emoji != null && item.emoji!.isNotEmpty) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(item.emoji!),
        ),
      );
    }
    return Icon(item.icon, color: Colors.black54);
  }
}

class _WigglingItem extends StatefulWidget {
  final Widget child;
  final bool editMode;
  final bool isDeletable;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  const _WigglingItem({super.key, required this.child, required this.editMode, this.isDeletable = true, this.onDelete, this.onEdit, this.onLongPress, this.onTap});

  @override
  State<_WigglingItem> createState() => _WigglingItemState();
}

class _WigglingItemState extends State<_WigglingItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    if (widget.editMode) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _WigglingItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editMode) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.rotate(
        angle: widget.editMode ? (_controller.value - 0.5) * 0.04 : 0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              onLongPress: widget.editMode ? null : widget.onLongPress,
              child: widget.child
            ),
            if (widget.editMode && widget.isDeletable)
              Positioned(
                top: -2, left: -2,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white, size: 10),
                  ),
                ),
              ),
            if (widget.editMode)
              Positioned(
                top: -2, right: -2,
                child: GestureDetector(
                  onTap: widget.onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1.0)),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Center(child: Text(count.toString(), style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold))),
    );
  }
}
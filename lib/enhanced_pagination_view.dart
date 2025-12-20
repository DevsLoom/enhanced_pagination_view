library;

/// Enhanced Pagination View - A powerful pagination package for Flutter
///
/// This package provides a flexible pagination solution with:
/// - Dual mode: Infinite scroll OR traditional pagination buttons
/// - Direct item updates without full refresh (O(1) lookup)
/// - Comprehensive state management
/// - Pull-to-refresh support
/// - Customizable UI for all states
/// - Built-in error handling and retry
/// - Facebook-style prefetch with item-based or pixel-based control
/// - Smart cache management (all/none/limited)
///
/// Example usage:
/// ```dart
/// // Create controller
/// final controller = PagingController<MyModel>(
///   config: PagingConfig(
///     pageSize: 20,
///     infiniteScroll: true,
///     prefetchItemCount: 5, // Load when last 5 items visible
///     cacheMode: CacheMode.limited, // Keep only 500 items
///     maxCachedItems: 500,
///   ),
///   pageFetcher: (page) async {
///     return await api.fetchData(page);
///   },
///   itemKeyGetter: (item) => item.id, // For O(1) updates
/// );
///
/// // Use in widget
/// EnhancedPaginationView<MyModel>(
///   controller: controller,
///   itemBuilder: (context, item, index) {
///     return ListTile(title: Text(item.name));
///   },
/// )
///
/// // Update individual item
/// controller.updateItem(
///   updatedItem,
///   where: (item) => item.id == targetId,
/// );
/// ```

export 'src/paging_controller.dart';
export 'src/enhanced_pagination_view.dart'
    show EnhancedPaginationView, PaginationLayoutMode;

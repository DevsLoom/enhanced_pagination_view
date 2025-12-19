import 'package:flutter/material.dart';
import 'paging_controller.dart';

/// A highly customizable pagination view widget that supports both
/// infinite scroll and traditional pagination.
///
/// Features:
/// - Dual mode: Infinite scroll or pagination buttons
/// - Pull-to-refresh support
/// - Item-level updates without full refresh
/// - Customizable loading, error, and empty states
/// - Automatic or manual pagination control
///
/// Example:
/// ```dart
/// EnhancedPaginationView<ProfileModel>(
///   controller: pagingController,
///   itemBuilder: (context, item, index) {
///     return ListTile(title: Text(item.name));
///   },
///   onEmpty: Center(child: Text('No data')),
///   onError: (error) => Text('Error: $error'),
/// )
/// ```
class EnhancedPaginationView<T> extends StatefulWidget {
  /// Controller that manages pagination state and data
  final PagingController<T> controller;

  /// Builder for individual list items
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Widget to show when list is empty
  final Widget? onEmpty;

  /// Builder for error state
  final Widget Function(Object error)? onError;

  /// Widget to show while loading first page
  final Widget? initialLoader;

  /// Widget to show at the bottom while loading more items
  final Widget? bottomLoader;

  /// Enable pull-to-refresh
  final bool enablePullToRefresh;

  /// Scroll direction
  final Axis scrollDirection;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Padding around the list
  final EdgeInsetsGeometry? padding;

  /// Item separator builder
  final Widget Function(BuildContext, int)? separatorBuilder;

  /// Shrink wrap the scroll view
  final bool shrinkWrap;

  /// Scroll controller (optional, for external scroll control)
  final ScrollController? scrollController;

  /// Show pagination buttons at bottom (only when infiniteScroll is false)
  final bool showPaginationButtons;

  /// Custom widget for pagination controls
  final Widget Function(PagingController<T> controller)? paginationBuilder;

  const EnhancedPaginationView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.onEmpty,
    this.onError,
    this.initialLoader,
    this.bottomLoader,
    this.enablePullToRefresh = true,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.padding,
    this.separatorBuilder,
    this.shrinkWrap = false,
    this.scrollController,
    this.showPaginationButtons = true,
    this.paginationBuilder,
  });

  @override
  State<EnhancedPaginationView<T>> createState() =>
      _EnhancedPaginationViewState<T>();
}

class _EnhancedPaginationViewState<T> extends State<EnhancedPaginationView<T>> {
  late ScrollController _scrollController;
  bool _isInternalScrollController = false;

  @override
  void initState() {
    super.initState();

    // Use provided controller or create new one
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _isInternalScrollController = true;
    }

    // Add scroll listener for infinite scroll
    if (widget.controller.config.infiniteScroll) {
      _scrollController.addListener(_onScroll);
    }

    // Listen to controller changes
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);

    if (widget.controller.config.infiniteScroll) {
      _scrollController.removeListener(_onScroll);
    }

    if (_isInternalScrollController) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  // Called when controller state changes
  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  // Infinite scroll listener
  void _onScroll() {
    if (!widget.controller.config.infiniteScroll) return;

    // Check if we're near the end of the list
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent -
            (widget.controller.config.invisibleItemsThreshold * 100)) {
      // Load more if not already loading and has more data
      if (!widget.controller.isLoading && widget.controller.hasMoreData) {
        widget.controller.loadNextPage();
      }
    }
  }

  // Handle refresh
  Future<void> _onRefresh() async {
    await widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final items = widget.controller.items;

    // Show initial loader
    if (state == PagingState.loading) {
      return widget.initialLoader ??
          const Center(child: CircularProgressIndicator());
    }

    // Show error state for first page
    if (state == PagingState.error && items.isEmpty) {
      return widget.onError?.call(widget.controller.error!) ??
          _buildDefaultError();
    }

    // Show empty state
    if (state == PagingState.empty) {
      return widget.onEmpty ?? _buildDefaultEmpty();
    }

    // Build the list
    Widget listView = ListView.separated(
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      itemCount: _getItemCount(),
      separatorBuilder:
          widget.separatorBuilder ?? (_, __) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        // Show regular items
        if (index < items.length) {
          return widget.itemBuilder(context, items[index], index);
        }

        // Show bottom loader for infinite scroll
        if (widget.controller.config.infiniteScroll) {
          if (state == PagingState.loadingMore) {
            return widget.bottomLoader ??
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
          }

          // Show error at bottom
          if (state == PagingState.error) {
            return _buildBottomError();
          }

          // Show "no more data" indicator
          if (state == PagingState.completed) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No more items',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
        }

        return const SizedBox.shrink();
      },
    );

    // Wrap with RefreshIndicator if enabled
    if (widget.enablePullToRefresh) {
      listView = RefreshIndicator(onRefresh: _onRefresh, child: listView);
    }

    // Add pagination buttons if not infinite scroll
    if (!widget.controller.config.infiniteScroll &&
        widget.showPaginationButtons) {
      return Column(
        children: [
          Expanded(child: listView),
          _buildPaginationControls(),
        ],
      );
    }

    return listView;
  }

  int _getItemCount() {
    final itemCount = widget.controller.items.length;

    // Add extra slot for loader/error/completed indicator in infinite scroll
    if (widget.controller.config.infiniteScroll) {
      if (widget.controller.state == PagingState.loadingMore ||
          widget.controller.state == PagingState.error ||
          widget.controller.state == PagingState.completed) {
        return itemCount + 1;
      }
    }

    return itemCount;
  }

  Widget _buildDefaultError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.error?.toString() ?? 'Unknown error',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.controller.retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomError() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Failed to load more items',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.controller.retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    // Use custom builder if provided
    if (widget.paginationBuilder != null) {
      return widget.paginationBuilder!(widget.controller);
    }

    // Default pagination controls
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          TextButton.icon(
            onPressed:
                widget.controller.currentPage >
                    widget.controller.config.initialPage
                ? () {
                    // Note: Going to previous page requires reimplementation
                    // For now, just refresh
                    widget.controller.refresh();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),

          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${widget.controller.currentPage + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Next button
          TextButton.icon(
            onPressed:
                widget.controller.hasMoreData && !widget.controller.isLoading
                ? widget.controller.loadNextPage
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

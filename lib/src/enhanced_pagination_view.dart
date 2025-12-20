import 'package:flutter/material.dart';
import 'paging_controller.dart';

/// Layout mode for the pagination view
enum PaginationLayoutMode {
  /// List layout (default)
  list,

  /// Grid layout
  grid,

  /// Wrap layout (for tags, chips, etc.)
  wrap,
}

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

  /// Widget to show when all data has been loaded (completed state)
  final Widget? onCompleted;

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

  /// Header widget to show at the top of the list
  final Widget? header;

  /// Footer widget to show at the bottom of the list (before pagination controls)
  final Widget? footer;

  /// Layout mode: list, grid, or wrap
  final PaginationLayoutMode layoutMode;

  /// Grid delegate for grid layout (required when layoutMode is grid)
  final SliverGridDelegate? gridDelegate;

  /// Spacing for wrap layout
  final double wrapSpacing;

  /// Run spacing for wrap layout
  final double wrapRunSpacing;

  /// Alignment for wrap layout
  final WrapAlignment wrapAlignment;

  /// Cross axis alignment for wrap layout
  final WrapCrossAlignment wrapCrossAlignment;

  /// Enable item animations (fade-in effect)
  final bool enableItemAnimations;

  /// Animation duration for items
  final Duration animationDuration;

  /// Animation curve for items
  final Curve animationCurve;

  const EnhancedPaginationView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.onEmpty,
    this.onError,
    this.initialLoader,
    this.bottomLoader,
    this.onCompleted,
    this.enablePullToRefresh = true,
    this.scrollDirection = Axis.vertical,
    this.physics,
    this.padding,
    this.separatorBuilder,
    this.shrinkWrap = false,
    this.scrollController,
    this.showPaginationButtons = true,
    this.paginationBuilder,
    this.header,
    this.footer,
    this.layoutMode = PaginationLayoutMode.list,
    this.gridDelegate,
    this.wrapSpacing = 8.0,
    this.wrapRunSpacing = 8.0,
    this.wrapAlignment = WrapAlignment.start,
    this.wrapCrossAlignment = WrapCrossAlignment.start,
    this.enableItemAnimations = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  }) : assert(
         layoutMode != PaginationLayoutMode.grid || gridDelegate != null,
         'gridDelegate is required when layoutMode is grid',
       );

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

  // Infinite scroll listener with prefetch support
  void _onScroll() {
    if (!widget.controller.config.infiniteScroll) return;

    final config = widget.controller.config;
    final items = widget.controller.items;

    // Priority 1: Item-based prefetch (Facebook-style)
    if (config.prefetchItemCount > 0) {
      // Calculate first visible item index
      final scrollController = _scrollController;
      final itemCount = items.length;

      // Estimate visible items based on scroll position
      // This is approximate - for exact calculation would need item heights
      final scrollPercentage =
          scrollController.position.pixels /
          scrollController.position.maxScrollExtent;
      final approximateVisibleIndex = (itemCount * scrollPercentage).floor();

      // Check if we're within last N items
      final remainingItems = itemCount - approximateVisibleIndex;
      if (remainingItems <= config.prefetchItemCount) {
        // Load more if not already loading and has more data
        if (!widget.controller.isLoading && widget.controller.hasMoreData) {
          widget.controller.loadNextPage();
        }
      }
      return;
    }

    // Priority 2: Pixel-based prefetch
    if (config.prefetchDistance > 0) {
      final threshold = config.prefetchDistance;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - threshold) {
        if (!widget.controller.isLoading && widget.controller.hasMoreData) {
          widget.controller.loadNextPage();
        }
      }
      return;
    }

    // Priority 3: Default behavior using invisibleItemsThreshold
    final threshold = config.invisibleItemsThreshold * 100.0;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold) {
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

    // Build the list using CustomScrollView for better performance
    Widget listView = CustomScrollView(
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      slivers: [
        // Add header if provided
        if (widget.header != null) SliverToBoxAdapter(child: widget.header!),

        // Add padding if provided
        if (widget.padding != null)
          SliverPadding(
            padding: widget.padding!,
            sliver: _buildSliverList(items, state),
          )
        else
          _buildSliverList(items, state),

        // Add footer if provided
        if (widget.footer != null) SliverToBoxAdapter(child: widget.footer!),

        // Show bottom loader/error/completed for infinite scroll
        if (widget.controller.config.infiniteScroll)
          SliverToBoxAdapter(child: _buildInfiniteScrollIndicator(state)),
      ],
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

  Widget _buildSliverList(List<T> items, PagingState state) {
    if (widget.separatorBuilder != null) {
      // Use SliverList with separators
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final itemIndex = index ~/ 2;
          if (index.isEven) {
            return _buildAnimatedItem(context, items[itemIndex], itemIndex);
          }
          return widget.separatorBuilder!(context, itemIndex);
        }, childCount: items.length * 2 - 1),
      );
    }

    // Use SliverList without separators
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildAnimatedItem(context, items[index], index),
        childCount: items.length,
      ),
    );
  }

  /// Build item with optional animation
  Widget _buildAnimatedItem(BuildContext context, T item, int index) {
    final child = widget.itemBuilder(context, item, index);

    if (!widget.enableItemAnimations) {
      return child;
    }

    // Animate items with staggered delay based on index
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildInfiniteScrollIndicator(PagingState state) {
    if (state == PagingState.loadingMore) {
      return widget.bottomLoader ??
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
    }

    if (state == PagingState.error) {
      return _buildBottomError();
    }

    if (state == PagingState.completed) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No more items', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return const SizedBox.shrink();
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
            color: Colors.black.withValues(alpha: 0.1),
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
                ? widget.controller.loadPreviousPage
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),

          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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

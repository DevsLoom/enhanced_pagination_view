import 'package:flutter/foundation.dart';

/// Cache management mode for infinite scroll
enum CacheMode {
  /// Keep all previous items in memory (default)
  all,

  /// Don't cache any previous items
  none,

  /// Keep only a specific number of items (use maxCachedItems)
  limited,
}

/// Represents the current state of pagination
enum PagingState {
  /// Initial state before any data is loaded
  initial,

  /// Currently loading the first page
  loading,

  /// Data loaded successfully
  loaded,

  /// Currently loading more data (for pagination/infinite scroll)
  loadingMore,

  /// An error occurred
  error,

  /// No data available (empty state)
  empty,

  /// All data has been loaded (no more pages)
  completed,
}

/// Configuration for pagination behavior
class PagingConfig {
  /// Page size for each request
  final int pageSize;

  /// Whether to use infinite scroll (true) or pagination buttons (false)
  final bool infiniteScroll;

  /// Initial page number (usually 0 or 1 based on your API)
  final int initialPage;

  /// Whether to automatically load the first page
  final bool autoLoadFirstPage;

  /// Invisible threshold for infinite scroll
  /// When user scrolls within this many items from the end, load next page
  final int invisibleItemsThreshold;

  /// Prefetch distance in pixels from the bottom
  /// When user scrolls within this distance, trigger next page load
  /// Set to 0 to disable prefetch (use prefetchItemCount or invisibleItemsThreshold instead)
  final double prefetchDistance;

  /// Prefetch based on item count (Facebook-style)
  /// When user reaches last N items, trigger next page load
  /// Example: prefetchItemCount = 5 means load starts when last 5 items are visible
  /// Set to 0 to disable item-based prefetch
  final int prefetchItemCount;

  /// Keep alive recent pages in memory for faster back navigation
  /// Set to 0 to disable caching
  final int keepAlivePages;

  /// Cache management mode for infinite scroll
  /// Controls how many previous items to keep in memory
  final CacheMode cacheMode;

  /// Maximum number of items to cache when cacheMode is CacheMode.limited
  /// Example: maxCachedItems = 500 keeps only last 500 items in memory
  final int maxCachedItems;

  const PagingConfig({
    this.pageSize = 20,
    this.infiniteScroll = true,
    this.initialPage = 0,
    this.autoLoadFirstPage = true,
    this.invisibleItemsThreshold = 3,
    this.prefetchDistance = 0.0,
    this.prefetchItemCount = 0,
    this.keepAlivePages = 0,
    // Default to a bounded cache for realistic production usage.
    // This avoids unbounded memory growth when scrolling through large datasets.
    this.cacheMode = CacheMode.limited,
    this.maxCachedItems = 500,
  });
}

/// Optional callbacks for observing paging behavior (analytics/telemetry).
///
/// Kept separate from [PagingConfig] so existing `const PagingConfig(...)` usage
/// remains valid.
class PagingAnalytics<T> {
  /// Called right before a page request starts.
  final void Function(int page)? onPageRequest;

  /// Called when a page request succeeds.
  final void Function(int page, List<T> newItems, {required bool isFirstPage})?
  onPageSuccess;

  /// Called when a page request fails.
  final void Function(
    int page,
    Object error,
    StackTrace stackTrace, {
    required bool isFirstPage,
  })?
  onPageError;

  /// Called whenever [PagingController.state] changes.
  final void Function(PagingState previous, PagingState next)? onStateChanged;

  const PagingAnalytics({
    this.onPageRequest,
    this.onPageSuccess,
    this.onPageError,
    this.onStateChanged,
  });
}

/// A snapshot of [PagingController] state that can be cached in memory and
/// restored later.
///
/// This is intentionally not JSON-serializable because [T] may not be.
class PagingSnapshot<T> {
  final List<T> items;
  final PagingState state;
  final int currentPage;
  final bool hasMoreData;

  const PagingSnapshot({
    required this.items,
    required this.state,
    required this.currentPage,
    required this.hasMoreData,
  });
}

/// Controller for managing paginated data with state management
///
/// This controller maintains the list of items, current page, and loading states.
/// It provides methods to update, remove, and insert items without full refresh.
///
/// Example:
/// ```dart
/// final controller = PagingController<ProfileModel>(
///   config: PagingConfig(pageSize: 20, infiniteScroll: true),
///   pageFetcher: (page) async {
///     return await fetchProfiles(page);
///   },
/// );
/// ```
class PagingController<T> extends ChangeNotifier {
  /// Configuration for pagination behavior
  final PagingConfig config;

  /// Function to fetch a page of data
  /// Takes current page number and returns list of items
  final Future<List<T>> Function(int page) pageFetcher;

  /// Optional: Get unique key for each item (for efficient updates)
  /// If not provided, uses item instance equality
  final String Function(T item)? itemKeyGetter;

  /// Optional analytics callbacks.
  final PagingAnalytics<T>? analytics;

  PagingController({
    required this.pageFetcher,
    PagingConfig? config,
    this.itemKeyGetter,
    this.analytics,
  }) : config = config ?? const PagingConfig() {
    if (this.config.autoLoadFirstPage) {
      loadFirstPage();
    }
  }

  // Internal state
  PagingState _state = PagingState.initial;
  List<T> _items = [];
  int _currentPage = 0;
  Object? _error;
  bool _hasMoreData = true;
  bool _disposed = false;

  // Concurrency/race protection.
  // Any time we want to invalidate in-flight requests (refresh/restore),
  // increment this value so stale results are ignored.
  int _generation = 0;

  // Map for O(1) item lookup by key
  Map<String, int>? _itemIndexMap;

  /// Current pagination state
  PagingState get state => _state;

  /// List of all loaded items
  /// This list can be modified directly for item updates
  List<T> get items => List.unmodifiable(_items);

  /// Current page number
  int get currentPage => _currentPage;

  /// Whether there's more data to load
  bool get hasMoreData => _hasMoreData;

  /// Last error that occurred
  Object? get error => _error;

  /// Whether currently loading any data
  bool get isLoading =>
      _state == PagingState.loading || _state == PagingState.loadingMore;

  /// Total number of items loaded
  int get itemCount => _items.length;

  void _setState(PagingState next) {
    if (_state == next) return;
    final previous = _state;
    _state = next;
    analytics?.onStateChanged?.call(previous, next);
  }

  /// Create an in-memory snapshot of the current controller state.
  PagingSnapshot<T> snapshot() {
    return PagingSnapshot<T>(
      items: List<T>.of(_items, growable: true),
      state: _state,
      currentPage: _currentPage,
      hasMoreData: _hasMoreData,
    );
  }

  /// Restore controller state from a previously taken [PagingSnapshot].
  ///
  /// This invalidates any in-flight requests.
  void restoreFromSnapshot(PagingSnapshot<T> snapshot, {bool notify = true}) {
    _generation++;
    _error = null;
    _items = List<T>.of(snapshot.items, growable: true);
    _currentPage = snapshot.currentPage;
    _hasMoreData = snapshot.hasMoreData;
    _setState(snapshot.state);
    _buildIndexMap();
    if (notify) {
      _safeNotifyListeners();
    }
  }

  // Build item index map if key getter is provided
  void _buildIndexMap() {
    if (itemKeyGetter != null) {
      _itemIndexMap = {};
      for (int i = 0; i < _items.length; i++) {
        _itemIndexMap![itemKeyGetter!(_items[i])] = i;
      }
    }
  }

  void _ensureIndexMap() {
    if (itemKeyGetter == null) return;
    _itemIndexMap ??= <String, int>{};
    if (_itemIndexMap!.length != _items.length) {
      _buildIndexMap();
    }
  }

  void _reindexFrom(int startIndex) {
    if (itemKeyGetter == null || _itemIndexMap == null) return;
    for (int i = startIndex; i < _items.length; i++) {
      _itemIndexMap![itemKeyGetter!(_items[i])] = i;
    }
  }

  /// Load the first page of data
  Future<void> loadFirstPage({bool force = false}) async {
    if (!force && isLoading) return;

    final requestGeneration = ++_generation;
    _setState(PagingState.loading);
    _error = null;
    _safeNotifyListeners();

    try {
      _currentPage = config.initialPage;
      analytics?.onPageRequest?.call(_currentPage);
      final newItems = await pageFetcher(_currentPage);

      // Ignore stale results.
      if (requestGeneration != _generation) return;

      // Ensure internal list remains growable even if the fetcher returns a
      // fixed-length list (e.g., List.generate(..., growable: false)).
      _items = List<T>.of(newItems, growable: true);
      _buildIndexMap();

      // Check if we received less items than page size (means no more data)
      _hasMoreData = newItems.length >= config.pageSize;

      _setState(_items.isEmpty ? PagingState.empty : PagingState.loaded);
      analytics?.onPageSuccess?.call(
        _currentPage,
        List<T>.unmodifiable(newItems),
        isFirstPage: true,
      );
    } catch (e, stackTrace) {
      if (requestGeneration != _generation) return;
      _error = e;
      _setState(PagingState.error);
      analytics?.onPageError?.call(
        _currentPage,
        e,
        stackTrace,
        isFirstPage: true,
      );
      debugPrint('Error loading first page: $e\n$stackTrace');
    }

    _safeNotifyListeners();
  }

  /// Load the next page of data (for infinite scroll or pagination)
  Future<void> loadNextPage() async {
    // Don't load if already loading or no more data
    if (isLoading || !_hasMoreData) return;

    // Don't load more if in error or empty state
    if (_state == PagingState.error || _state == PagingState.empty) return;

    final requestGeneration = _generation;
    _setState(PagingState.loadingMore);
    _safeNotifyListeners();

    try {
      final nextPage = _currentPage + 1;
      analytics?.onPageRequest?.call(nextPage);
      final newItems = await pageFetcher(nextPage);

      // Ignore stale results.
      if (requestGeneration != _generation) return;

      _currentPage = nextPage;

      // For pagination buttons mode, replace items instead of appending
      if (!config.infiniteScroll) {
        // Keep list growable for later mutations (update/remove/insert).
        _items = List<T>.of(newItems, growable: true);
        _buildIndexMap();
      } else {
        final oldLength = _items.length;
        _items.addAll(newItems);

        // Apply cache management based on cacheMode.
        // If trimming occurs, indices shift and we must rebuild the index map.
        final didTrim = _applyCacheManagement();

        if (itemKeyGetter != null) {
          if (didTrim) {
            _buildIndexMap();
          } else {
            _ensureIndexMap();
            // Only index the newly appended items.
            for (int i = oldLength; i < _items.length; i++) {
              _itemIndexMap![itemKeyGetter!(_items[i])] = i;
            }
          }
        }
      }

      // Check if we got less than page size
      if (newItems.length < config.pageSize) {
        _hasMoreData = false;
        _setState(PagingState.completed);
      } else {
        _setState(PagingState.loaded);
      }

      analytics?.onPageSuccess?.call(
        _currentPage,
        List<T>.unmodifiable(newItems),
        isFirstPage: false,
      );
    } catch (e, stackTrace) {
      if (requestGeneration != _generation) return;
      _error = e;
      _setState(PagingState.error);
      debugPrint('Error loading next page: $e\n$stackTrace');

      // Keep current page unchanged since we only commit on success.
      analytics?.onPageError?.call(
        _currentPage + 1,
        e,
        stackTrace,
        isFirstPage: false,
      );
    }

    _safeNotifyListeners();
  }

  /// Apply cache management to limit memory usage
  bool _applyCacheManagement() {
    var didTrim = false;
    if (config.cacheMode == CacheMode.none) {
      // Keep only the current page items
      final currentPageItems = config.pageSize;
      if (_items.length > currentPageItems) {
        _items = List<T>.of(
          _items.sublist(_items.length - currentPageItems),
          growable: true,
        );
        didTrim = true;
      }
    } else if (config.cacheMode == CacheMode.limited) {
      // Keep only maxCachedItems
      if (_items.length > config.maxCachedItems) {
        _items = List<T>.of(
          _items.sublist(_items.length - config.maxCachedItems),
          growable: true,
        );
        didTrim = true;
      }
    }
    // CacheMode.all keeps everything (no action needed)

    return didTrim;
  }

  /// Load the previous page of data (for pagination buttons mode only)
  Future<void> loadPreviousPage() async {
    // Only works for pagination buttons mode
    if (config.infiniteScroll) return;

    // Can't go before initial page
    if (_currentPage <= config.initialPage) return;

    // Don't load if already loading
    if (isLoading) return;

    final requestGeneration = _generation;
    _setState(PagingState.loadingMore);
    _safeNotifyListeners();

    try {
      final previousPage = _currentPage - 1;
      analytics?.onPageRequest?.call(previousPage);
      final newItems = await pageFetcher(previousPage);

      if (requestGeneration != _generation) return;

      _currentPage = previousPage;
      _items = List<T>.of(newItems, growable: true);
      _buildIndexMap();

      // Reset hasMoreData since we went back
      _hasMoreData = true;
      _setState(PagingState.loaded);

      analytics?.onPageSuccess?.call(
        _currentPage,
        List<T>.unmodifiable(newItems),
        isFirstPage: false,
      );
    } catch (e, stackTrace) {
      if (requestGeneration != _generation) return;
      _error = e;
      _setState(PagingState.error);
      debugPrint('Error loading previous page: $e\n$stackTrace');

      analytics?.onPageError?.call(
        _currentPage - 1,
        e,
        stackTrace,
        isFirstPage: false,
      );
    }

    _safeNotifyListeners();
  }

  /// Refresh the entire list (reload from first page)
  Future<void> refresh() async {
    // Invalidate any in-flight requests.
    _generation++;
    _items.clear();
    _itemIndexMap?.clear();
    _hasMoreData = true;
    _error = null;
    await loadFirstPage(force: true);
  }

  /// Update a single item by key or predicate
  ///
  /// If [itemKeyGetter] is provided, uses O(1) lookup by key
  /// Otherwise, uses O(n) search by predicate
  ///
  /// Returns true if item was found and updated
  bool updateItem(T newItem, {bool Function(T item)? where}) {
    int index = -1;

    // Try key-based lookup first (O(1))
    if (itemKeyGetter != null && _itemIndexMap != null) {
      final key = itemKeyGetter!(newItem);
      index = _itemIndexMap![key] ?? -1;
    }

    // Fall back to predicate search (O(n))
    if (index == -1 && where != null) {
      index = _items.indexWhere(where);
    }

    if (index != -1) {
      final oldKey = itemKeyGetter != null
          ? itemKeyGetter!(_items[index])
          : null;
      _items[index] = newItem;

      // Update index map if key changed
      if (itemKeyGetter != null && _itemIndexMap != null) {
        final newKey = itemKeyGetter!(newItem);
        if (oldKey != null && oldKey != newKey) {
          _itemIndexMap!.remove(oldKey);
        }
        _itemIndexMap![newKey] = index;
      }

      _safeNotifyListeners();
      return true;
    }

    return false;
  }

  /// Remove an item by key or predicate
  ///
  /// Returns true if item was found and removed
  bool removeItem({String? key, bool Function(T item)? where}) {
    int index = -1;

    // Try key-based lookup first
    if (key != null && _itemIndexMap != null) {
      index = _itemIndexMap![key] ?? -1;
    }

    // Fall back to predicate search
    if (index == -1 && where != null) {
      index = _items.indexWhere(where);
    }

    if (index != -1) {
      final removedKey = itemKeyGetter != null
          ? itemKeyGetter!(_items[index])
          : null;
      _items.removeAt(index);

      // Maintain index map without full rebuild.
      if (itemKeyGetter != null) {
        _ensureIndexMap();
        if (removedKey != null) {
          _itemIndexMap?.remove(removedKey);
        }
        _reindexFrom(index);
      }

      // Update empty state if needed
      if (_items.isEmpty) {
        _state = PagingState.empty;
      }

      _safeNotifyListeners();
      return true;
    }

    return false;
  }

  /// Insert an item at a specific position
  void insertItem(int index, T item) {
    _items.insert(index, item);

    // Maintain index map without full rebuild.
    if (itemKeyGetter != null) {
      _ensureIndexMap();
      _reindexFrom(index);
    }

    // Update state if was empty
    if (_state == PagingState.empty) {
      _setState(PagingState.loaded);
    }

    _safeNotifyListeners();
  }

  /// Append an item to the end of the list
  void appendItem(T item) {
    _items.add(item);

    // Update index map
    if (itemKeyGetter != null && _itemIndexMap != null) {
      _itemIndexMap![itemKeyGetter!(item)] = _items.length - 1;
    }

    // Update state if was empty
    if (_state == PagingState.empty) {
      _setState(PagingState.loaded);
    }

    _safeNotifyListeners();
  }

  /// Retry loading after an error
  Future<void> retry() async {
    if (_state == PagingState.error) {
      if (_items.isEmpty) {
        // Retry first page
        await loadFirstPage(force: true);
      } else {
        // Retry next page
        await loadNextPage();
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _items.clear();
    _itemIndexMap?.clear();
    super.dispose();
  }

  /// Safely call notifyListeners only if not disposed
  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

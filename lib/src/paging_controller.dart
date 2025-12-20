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
    this.cacheMode = CacheMode.all,
    this.maxCachedItems = 500,
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

  PagingController({
    required this.pageFetcher,
    PagingConfig? config,
    this.itemKeyGetter,
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

  // Build item index map if key getter is provided
  void _buildIndexMap() {
    if (itemKeyGetter != null) {
      _itemIndexMap = {};
      for (int i = 0; i < _items.length; i++) {
        _itemIndexMap![itemKeyGetter!(_items[i])] = i;
      }
    }
  }

  /// Load the first page of data
  Future<void> loadFirstPage() async {
    if (isLoading) return;

    _state = PagingState.loading;
    _error = null;
    notifyListeners();

    try {
      _currentPage = config.initialPage;
      final newItems = await pageFetcher(_currentPage);

      _items = newItems;
      _buildIndexMap();

      // Check if we received less items than page size (means no more data)
      _hasMoreData = newItems.length >= config.pageSize;

      _state = _items.isEmpty ? PagingState.empty : PagingState.loaded;
    } catch (e, stackTrace) {
      _error = e;
      _state = PagingState.error;
      debugPrint('Error loading first page: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Load the next page of data (for infinite scroll or pagination)
  Future<void> loadNextPage() async {
    // Don't load if already loading or no more data
    if (isLoading || !_hasMoreData) return;

    // Don't load more if in error or empty state
    if (_state == PagingState.error || _state == PagingState.empty) return;

    _state = PagingState.loadingMore;
    notifyListeners();

    try {
      _currentPage++;
      final newItems = await pageFetcher(_currentPage);

      // For pagination buttons mode, replace items instead of appending
      if (!config.infiniteScroll) {
        _items = newItems;
      } else {
        _items.addAll(newItems);
        // Apply cache management based on cacheMode
        _applyCacheManagement();
      }

      _buildIndexMap();

      // Check if we got less than page size
      if (newItems.length < config.pageSize) {
        _hasMoreData = false;
        _state = PagingState.completed;
      } else {
        _state = PagingState.loaded;
      }
    } catch (e, stackTrace) {
      _error = e;
      _state = PagingState.error;
      _currentPage--; // Rollback page increment on error
      debugPrint('Error loading next page: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Apply cache management to limit memory usage
  void _applyCacheManagement() {
    if (config.cacheMode == CacheMode.none) {
      // Keep only the current page items
      final currentPageItems = config.pageSize;
      if (_items.length > currentPageItems) {
        _items = _items.sublist(_items.length - currentPageItems);
      }
    } else if (config.cacheMode == CacheMode.limited) {
      // Keep only maxCachedItems
      if (_items.length > config.maxCachedItems) {
        _items = _items.sublist(_items.length - config.maxCachedItems);
      }
    }
    // CacheMode.all keeps everything (no action needed)
  }

  /// Load the previous page of data (for pagination buttons mode only)
  Future<void> loadPreviousPage() async {
    // Only works for pagination buttons mode
    if (config.infiniteScroll) return;

    // Can't go before initial page
    if (_currentPage <= config.initialPage) return;

    // Don't load if already loading
    if (isLoading) return;

    _state = PagingState.loadingMore;
    notifyListeners();

    try {
      _currentPage--;
      final newItems = await pageFetcher(_currentPage);

      _items = newItems;
      _buildIndexMap();

      // Reset hasMoreData since we went back
      _hasMoreData = true;
      _state = PagingState.loaded;
    } catch (e, stackTrace) {
      _error = e;
      _state = PagingState.error;
      _currentPage++; // Rollback page decrement on error
      debugPrint('Error loading previous page: $e\n$stackTrace');
    }

    notifyListeners();
  }

  /// Refresh the entire list (reload from first page)
  Future<void> refresh() async {
    _items.clear();
    _itemIndexMap?.clear();
    _hasMoreData = true;
    await loadFirstPage();
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
      _items[index] = newItem;

      // Update index map if key changed
      if (itemKeyGetter != null && _itemIndexMap != null) {
        _itemIndexMap![itemKeyGetter!(newItem)] = index;
      }

      notifyListeners();
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
      _items.removeAt(index);

      // Rebuild index map
      if (_itemIndexMap != null) {
        _buildIndexMap();
      }

      // Update empty state if needed
      if (_items.isEmpty) {
        _state = PagingState.empty;
      }

      notifyListeners();
      return true;
    }

    return false;
  }

  /// Insert an item at a specific position
  void insertItem(int index, T item) {
    _items.insert(index, item);

    // Rebuild index map
    if (_itemIndexMap != null) {
      _buildIndexMap();
    }

    // Update state if was empty
    if (_state == PagingState.empty) {
      _state = PagingState.loaded;
    }

    notifyListeners();
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
      _state = PagingState.loaded;
    }

    notifyListeners();
  }

  /// Retry loading after an error
  Future<void> retry() async {
    if (_state == PagingState.error) {
      if (_items.isEmpty) {
        // Retry first page
        await loadFirstPage();
      } else {
        // Retry next page
        await loadNextPage();
      }
    }
  }

  @override
  void dispose() {
    _items.clear();
    _itemIndexMap?.clear();
    super.dispose();
  }
}

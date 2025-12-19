import 'package:flutter/foundation.dart';

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

  const PagingConfig({
    this.pageSize = 20,
    this.infiniteScroll = true,
    this.initialPage = 0,
    this.autoLoadFirstPage = true,
    this.invisibleItemsThreshold = 3,
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

      _items.addAll(newItems);
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

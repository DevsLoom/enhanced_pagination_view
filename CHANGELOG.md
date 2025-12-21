## 1.2.0 - 2025-12-20

### ⚡ Developer Experience Improvements

#### Breaking Change
- **`itemKeyGetter` is now optional**: No longer required for basic pagination use cases
  - Only needed when using `updateItem()` or `removeItem(key: ...)`
  - Basic pagination (load, refresh, append, insert) works without it
  - Clear error messages guide developers when key-based operations require `itemKeyGetter`

#### Added
- `PagingController.simple()` factory constructor for beginner-friendly usage
- Helpful error messages when attempting key-based operations without `itemKeyGetter`
- Better parameter documentation with clear descriptions and examples

#### Improved
- Simplified all examples to remove unnecessary `itemKeyGetter` usage
- Updated README with clear "Simple" vs "Advanced" usage patterns
- Parameter documentation now explains when each feature is needed
- All configuration parameters have improved descriptions

#### Migration Guide
No migration needed! This is a backward-compatible breaking change:
- Existing code with `itemKeyGetter` continues to work exactly the same
- New code can omit `itemKeyGetter` for simpler usage
- Key-based `updateItem()` and `removeItem()` still require `itemKeyGetter`

## 1.1.0 - 2025-12-19

### Added
- `PagingController.snapshot()` / `restoreFromSnapshot(...)` to cache and restore paging state (items, page index, flags).
- `PagingAnalytics<T>` hooks for page request/success/error and state-change tracking.
- `EnhancedPaginationView.scrollViewKey` to support scroll position restoration via `PageStorageKey`.

### Improved
- Concurrency safety: stale in-flight page results are ignored after `refresh()`/restore.

## 1.0.0 - 2025-12-19

### 🎉 Initial Release

### Changed
- Default `PagingConfig.cacheMode` is `CacheMode.limited` (default `maxCachedItems` stays 500) to prevent unbounded memory growth in infinite scroll.

### Improved
- `PagingController` keeps its internal item list growable (safer when fetchers return fixed-length lists).
- `PagingController.loadNextPage()` updates the key→index map incrementally when possible; rebuilds only when cache trimming shifts indices.

### Fixed
- Example: SnackBars replace the previous one immediately and reliably auto-dismiss.
- Example: Replaced deprecated `withOpacity` usage.

#### Features
- ✅ **Dual Mode Support**: Infinite scroll or pagination buttons
- ✅ **O(1) Item Updates**: Direct item manipulation using key-based lookup
- ✅ **Comprehensive State Management**: 7 states (initial, loading, loaded, loadingMore, error, empty, completed)
- ✅ **Item Management Methods**:
  - `updateItem()`: Update single item without refresh
  - `removeItem()`: Remove item from list
  - `insertItem()`: Insert at specific position
  - `appendItem()`: Add to end of list
- ✅ **Pull-to-Refresh**: Built-in refresh functionality
- ✅ **Error Handling**: Automatic retry mechanism with custom error widgets
- ✅ **Customizable UI**: Custom loaders, empty states, pagination controls
- ✅ **Type Safe**: Full generic type support
- ✅ **Performance Optimized**: Map-based tracking for O(1) lookups
- ✅ **Well Documented**: Comprehensive comments and README

#### Why This Package?
Solves major limitations of `pagination_view`:
- No direct item access ❌ → Direct access ✅
- No item updates ❌ → O(1) updates ✅
- Limited state management ❌ → 7 states ✅
- No pagination mode ❌ → Dual mode ✅

#### Technical Details
- Minimum Flutter SDK: 3.0.0
- Dart SDK: >=3.0.0 <4.0.0
- Zero external dependencies (except Flutter)
- Null-safe
- Well-tested

### Credits
Built with ❤️ to solve real-world pagination challenges in Flutter apps.

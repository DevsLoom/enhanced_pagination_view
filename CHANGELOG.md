## 1.2.3 - 2025-12-23

### Documentation
- Rewrote README in a more beginner-friendly tone and added clearer explanations/examples.
- Added a clickable LICENSE link in README.

## 1.2.2 - 2025-12-23

### Fixed
- **Long scroll “jump/overscroll”**: Added safer infinite-scroll trigger guards (clamped scroll percentage, `hasClients` checks, and `maxScrollExtent` edge case handling).
- **Next-page retry**: `retry()` now correctly retries the next page when an error occurs after items already exist.

### Improved
- **Default caching**: `PagingConfig.cacheMode` default changed to `CacheMode.all` to avoid scroll-position jumps caused by head trimming.
- **Optional scroll stabilization**: Added `PagingConfig.compensateForTrimmedItems` to best-effort compensate for head trimming (requires `PagingController.itemKeyGetter`).
- **Logging**: Removed internal error `debugPrint` calls; apps should use controller state / analytics hooks to log.

### Tests
- Added long-scroll stability tests (List/Grid/Wrap) and expanded widget coverage for real-life flows (empty, error/retry, completed, pagination buttons, refresh).

## 1.2.1 - 2025-12-22

### Fixed
- **Grid and Wrap layouts**: Fixed `_buildSliverList` method to properly handle grid and wrap layout modes
  - Grid layout now correctly uses `SliverGrid` with the provided `gridDelegate`
  - Wrap layout now properly wraps items using `SliverToBoxAdapter` with `Wrap` widget
  - Both vertical and horizontal scroll directions now work correctly for grid layouts

### Documentation
- Added comprehensive layout examples to README with List, Grid, and Wrap configurations
- Added layouts example to the demo app showcase
- Updated feature list to highlight multiple layout support

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

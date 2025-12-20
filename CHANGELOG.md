## 1.0.0 - 2024-12-19

## 1.0.1 - 2025-12-19

### Changed
- Default `PagingConfig.cacheMode` is now `CacheMode.limited` (default `maxCachedItems` stays 500) to prevent unbounded memory growth in infinite scroll.

### Improved
- `PagingController` keeps its internal item list growable (safer when fetchers return fixed-length lists).
- `PagingController.loadNextPage()` now updates the key→index map incrementally when possible; rebuilds only when cache trimming shifts indices.

### Fixed
- Example: SnackBars now replace the previous one immediately and reliably auto-dismiss.
- Example: Replaced deprecated `withOpacity` usage.

### 🎉 Initial Release

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

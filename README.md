
# Enhanced Pagination View

Enhanced Pagination View is a Flutter pagination package that supports both:

- Infinite scrolling (load more as the user scrolls)
- Pagination buttons (Next/Previous)

It also gives you direct access to loaded items, so you can update/remove/insert items without reloading the whole list.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  enhanced_pagination_view: ^1.2.3
```

## Manual pagination control

Sometimes your API provides explicit pagination metadata (like `hasNextPage` flag), or the last page has exactly `pageSize` items. In these cases, automatic detection won't work correctly. Use `PageResult` for manual control:

```dart
final controller = PagingController<User>(
  config: const PagingConfig(
    pageSize: 10,
    initialPage: 1, // API pages start from 1
  ),
  pageFetcher: (page) async {
    final response = await api.getUsers(page);
    
    // Manual control: tell the controller if there are more pages
    return PageResult<User>(
      items: response.users,
      hasMore: response.hasNextPage, // From API metadata
    );
  },
);
```

**Backward compatible**: If you just return `List<T>`, it works as before (automatic detection based on `items.length < pageSize`):

```dart
final controller = PagingController<User>(
  pageFetcher: (page) async {
    final users = await api.getUsers(page);
    return users; // Automatic detection
  },
);
```

## Quick start (infinite scroll)

This is the most common setup.

```dart
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

final controller = PagingController<Profile>(
  pageFetcher: (page) => api.fetchProfiles(page),
);

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedPaginationView<Profile>(
      controller: controller,
      itemBuilder: (context, item, index) {
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.email),
        );
      },
    );
  }
}
```

You can also use the simpler constructor:

```dart
final controller = PagingController.simple<Profile>(
  fetchPage: (page) => api.fetchProfiles(page),
  pageSize: 20,
);
```

## Pagination with buttons (Next/Previous)

If you prefer classic pagination controls:

```dart
final controller = PagingController<Profile>(
  config: const PagingConfig(
    pageSize: 20,
    infiniteScroll: false,
  ),
  pageFetcher: (page) => api.fetchProfiles(page),
);

EnhancedPaginationView<Profile>(
  controller: controller,
  showPaginationButtons: true,
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

## Updating items (without full refresh)

### Fast updates (recommended)

If your items have a stable unique ID (like `id`), pass `itemKeyGetter`. Then updates/removals are very fast.

```dart
final controller = PagingController<Profile>(
  pageFetcher: (page) => api.fetchProfiles(page),
  itemKeyGetter: (item) => item.id,
);

controller.updateItem(updatedProfile);
controller.removeItem(key: updatedProfile.id);
```

### Updates without keys

If you can’t provide a key, you can still update/remove by giving a condition (the controller will search the list).

```dart
controller.updateItem(
  updatedProfile,
  where: (p) => p.id == updatedProfile.id,
);

controller.removeItem(
  where: (p) => p.id == updatedProfile.id,
);
```

Other useful operations:

```dart
controller.insertItem(0, newProfile);
controller.appendItem(newProfile);
```

## Layout modes (List / Grid / Wrap)

EnhancedPaginationView supports multiple layouts.

### List

```dart
EnhancedPaginationView<User>(
  controller: controller,
  layoutMode: PaginationLayoutMode.list,
  scrollDirection: Axis.vertical, // or Axis.horizontal
  itemBuilder: (context, user, index) => UserTile(user),
)
```

### Grid

```dart
EnhancedPaginationView<User>(
  controller: controller,
  layoutMode: PaginationLayoutMode.grid,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemBuilder: (context, user, index) => UserCard(user),
)
```

### Wrap (chips/tags)

```dart
EnhancedPaginationView<Tag>(
  controller: controller,
  layoutMode: PaginationLayoutMode.wrap,
  wrapSpacing: 8,
  wrapRunSpacing: 8,
  itemBuilder: (context, tag, index) => Chip(label: Text(tag.name)),
)
```

## Common UI customizations

You can plug in your own widgets for loading/empty/error states.

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  itemBuilder: (context, item, index) => ProfileCard(item),
  initialLoader: const Center(child: CircularProgressIndicator()),
  bottomLoader: const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  ),
  onEmpty: const Center(child: Text('No items')),
  onError: (error) => Center(child: Text('Error: $error')),
)
```

Pull-to-refresh:

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  enablePullToRefresh: true,
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

Header / footer:

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  header: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Header'),
  ),
  footer: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Footer'),
  ),
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

## Caching and memory (important)

When you use infinite scroll, the controller keeps items in memory.

### Default (safe for scroll stability)

By default the package keeps all loaded items:

```dart
const PagingConfig(
  cacheMode: CacheMode.all,
)
```

This avoids “scroll jumps” that can happen if old items are removed from the start.

### For very large feeds (Facebook-style bounded cache)

If you have a huge feed and you want to limit memory usage, use a limited cache.

Important: when the controller removes old items from the start (to save memory), scrolling can feel like it “jumps”.
To reduce that, provide a stable key and enable `compensateForTrimmedItems`.

```dart
final controller = PagingController<Post>(
  pageFetcher: (page) => api.fetchPosts(page),
  itemKeyGetter: (post) => post.id,
  config: const PagingConfig(
    cacheMode: CacheMode.limited,
    maxCachedItems: 500,
    compensateForTrimmedItems: true,
  ),
);
```

Notes:

- `itemKeyGetter` must be unique and stable.
- `compensateForTrimmedItems` is best-effort (especially if item heights/widths vary), but it greatly reduces perceived jumps.
- Works with both vertical and horizontal scrolling.

## More options (optional, but useful)

If you’re a beginner, you can ignore this section at first. Use it when you need extra control.

### Prefetch (when to load the next page)

You can control when the next page starts loading:

- `invisibleItemsThreshold`: start loading when you are N items away from the end (simple)
- `prefetchItemCount`: start loading when the last N items are already visible on screen
- `prefetchDistance`: start loading when you are within X pixels of the end

Beginner tip: usually you pick ONE approach. For example:

- If you set `prefetchItemCount: 5`, the controller starts loading the next page when the last 5 items become visible.
- If you set `prefetchDistance: 300`, the controller starts loading when you are ~300px away from the end.

```dart
final controller = PagingController<Post>(
  pageFetcher: (page) => api.fetchPosts(page),
  config: const PagingConfig(
    pageSize: 20,
    // Pick one strategy (or keep defaults):
    invisibleItemsThreshold: 3,
    prefetchItemCount: 0,
    prefetchDistance: 0,
  ),
);
```

### Separators (List layout)

If you want dividers between items:

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  layoutMode: PaginationLayoutMode.list,
  separatorBuilder: (_, __) => const Divider(height: 1),
  itemBuilder: (context, item, index) => ProfileTile(item),
)
```

### Completed state ("no more items")

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  onCompleted: const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: Text('You reached the end')),
  ),
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

### Custom pagination controls (when `infiniteScroll: false`)

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  showPaginationButtons: true,
  paginationBuilder: (c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: c.currentPage > c.config.initialPage ? c.refresh : null,
          child: const Text('First'),
        ),
        const SizedBox(width: 12),
        Text('Page ${c.currentPage}'),
        const SizedBox(width: 12),
        TextButton(
          onPressed: c.hasMoreData ? c.loadNextPage : null,
          child: const Text('Next'),
        ),
      ],
    );
  },
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

### Scroll control + preserving scroll position

- `scrollController`: pass your own controller if you want to scroll programmatically.
- `scrollViewKey`: pass a `PageStorageKey` to let Flutter restore scroll offset automatically.

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  scrollViewKey: const PageStorageKey('profiles-feed'),
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

### Item animations

```dart
EnhancedPaginationView<Profile>(
  controller: controller,
  enableItemAnimations: true,
  animationDuration: const Duration(milliseconds: 250),
  animationCurve: Curves.easeOut,
  itemBuilder: (context, item, index) => ProfileCard(item),
)
```

### Analytics hooks (optional)

If you want to log page loading (for debugging or metrics):

```dart
final controller = PagingController<Post>(
  pageFetcher: (page) => api.fetchPosts(page),
  analytics: PagingAnalytics<Post>(
    onPageRequest: (page) => debugPrint('Request page $page'),
    onPageSuccess: (page, items, {required isFirstPage}) {
      debugPrint('Loaded page $page (${items.length} items)');
    },
    onPageError: (page, error, stack, {required isFirstPage}) {
      debugPrint('Page $page failed: $error');
    },
  ),
);
```

## Snapshot / restore

If you want to save what’s currently loaded (for example: navigate away and come back without losing the feed):

```dart
final snapshot = controller.snapshot();
controller.restoreFromSnapshot(snapshot);
```

## Useful controller methods

```dart
controller.loadFirstPage();
controller.loadNextPage();
controller.refresh();
controller.retry();

controller.items;
controller.currentPage;
controller.hasMoreData;
controller.isLoading;
controller.error;
```

## Contributing

PRs are welcome. If you find a bug, please open an issue with a small repro.

## License

MIT. See [LICENSE](LICENSE).


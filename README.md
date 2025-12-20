# Enhanced Pagination View 📜

A powerful and flexible pagination package for Flutter that solves common pagination challenges with elegance.

## ✨ Features

- 🔄 **Dual Mode Support**: Choose between infinite scroll or traditional pagination buttons
- ⚡ **O(1) Item Updates**: Update, remove, or insert items without full page refresh
- 🎯 **Smart State Management**: Comprehensive states (loading, error, empty, completed)
- 🔄 **Pull-to-Refresh**: Built-in refresh functionality
- 🎨 **Fully Customizable**: Custom widgets for loading, error, empty, and pagination controls
- 🚦 **Error Handling**: Automatic retry mechanism with error states
- 📱 **Responsive**: Works with any scroll direction and physics
- 🧩 **Type Safe**: Full TypeScript-like type safety with generics

## 🚀 Why Enhanced Pagination View?

Traditional pagination packages (like `pagination_view`) have limitations:
- ❌ No direct access to loaded items
- ❌ Can't update individual items without full refresh
- ❌ Limited state management
- ❌ No built-in item tracking

**Enhanced Pagination View solves these:**
- ✅ Direct item list access and manipulation
- ✅ O(1) item updates using key-based lookup
- ✅ Comprehensive state management
- ✅ Built-in Map-based item tracking

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  enhanced_pagination_view: ^1.1.0
```

## 🎯 Quick Start

### 1. Basic Infinite Scroll

```dart
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

// Create controller
final controller = PagingController<ProfileModel>(
  config: PagingConfig(
    pageSize: 20,
    infiniteScroll: true,
  ),
  pageFetcher: (page) async {
    final response = await api.fetchProfiles(page);
    return response.data;
  },
  itemKeyGetter: (item) => item.id, // For O(1) updates
);

// Use in widget
EnhancedPaginationView<ProfileModel>(
  controller: controller,
  itemBuilder: (context, item, index) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text(item.email),
    );
  },
)
```

### 2. Pagination with Buttons
## 💾 Cache + Restore State (Snapshot)

```dart
final controller = PagingController<ProfileModel>(
  config: PagingConfig(
    pageSize: 20,
    infiniteScroll: false, // Traditional pagination
  ),
  pageFetcher: (page) async {
    return await api.fetchProfiles(page);
  },
);

EnhancedPaginationView<ProfileModel>(
  controller: controller,
  itemBuilder: (context, item, index) => ProfileCard(item),
  showPaginationButtons: true,
)
```

## 📊 Analytics Hooks
### 3. Update Items Without Refresh ⚡

The killer feature! Update individual items in the list:

```dart
// Update a single item (O(1) with key getter)
controller.updateItem(
  updatedProfile,
  where: (profile) => profile.id == targetId,
);

// Remove an item
controller.removeItem(
  where: (profile) => profile.id == targetId,
);

// Insert at specific position
controller.insertItem(0, newProfile);

// Append to end
## 🧭 Restore Scroll Position
controller.appendItem(newProfile);
```

## 🎨 Customization

### Custom Loading States

```dart
EnhancedPaginationView<ProfileModel>(
  controller: controller,
  itemBuilder: (context, item, index) => ProfileCard(item),
  
  // Custom initial loader
  initialLoader: Center(
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading profiles...'),

      ],
    ),
  ),
  
  // Custom bottom loader (infinite scroll)
  bottomLoader: Padding(
    padding: EdgeInsets.all(16),
    child: CircularProgressIndicator(),
  ),
  
  // Custom empty state
  onEmpty: Center(
    child: Column(
      children: [
        Icon(Icons.inbox, size: 64, color: Colors.grey),
        Text('No profiles found'),
      ],
    ),
  ),
  
  // Custom error state
  onError: (error) => ErrorWidget(error: error),
)
```

### Custom Pagination Controls

```dart
EnhancedPaginationView<ProfileModel>(
  controller: controller,
  itemBuilder: (context, item, index) => ProfileCard(item),
  paginationBuilder: (controller) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: controller.currentPage > 0
                ? controller.refresh
                : null,
            child: Text('First'),
          ),
          SizedBox(width: 8),
          Text('Page ${controller.currentPage + 1}'),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: controller.hasMoreData
                ? controller.loadNextPage
                : null,
            child: Text('Next'),
          ),
        ],
      ),
    );
  },
)
```

## 🔧 Configuration

### PagingConfig Options

```dart
PagingConfig(
  pageSize: 20,                      // Items per page
  infiniteScroll: true,              // true for infinite, false for buttons
  initialPage: 0,                    // Starting page number
  autoLoadFirstPage: true,           // Auto-load on init
  invisibleItemsThreshold: 3,        // Trigger next page when 3 items from end
  // Cache behavior (infiniteScroll only):
  // Default is a bounded window to avoid unbounded memory growth.
  // Set cacheMode: CacheMode.all if you intentionally want to keep everything.
  cacheMode: CacheMode.limited,
  maxCachedItems: 500,
)
```

Notes:
- If you use a large `pageSize`, set `maxCachedItems >= pageSize`.
- For “very large total datasets” (e.g. 1M+ over time), prefer `CacheMode.limited` or `CacheMode.none`.

### Controller Methods

```dart
// Loading
controller.loadFirstPage()         // Load first page
controller.loadNextPage()          // Load next page
controller.refresh()               // Refresh from start
controller.retry()                 // Retry after error

// Item Management
controller.updateItem(item)        // Update single item
controller.removeItem(where: ...)  // Remove item
controller.insertItem(index, item) // Insert at position
controller.appendItem(item)        // Add to end

// State Access
controller.items                   // List of all items
controller.state                   // Current PagingState
controller.currentPage             // Current page number
controller.hasMoreData             // More pages available
controller.error                   // Last error
controller.isLoading               // Currently loading
controller.itemCount               // Total items loaded
```

### PagingState Enum

```dart
enum PagingState {
  initial,      // Before any data loaded
  loading,      // Loading first page
  loaded,       // Data loaded successfully
  loadingMore,  // Loading additional pages
  error,        // Error occurred
  empty,        // No data available
  completed,    // All data loaded
}
```

## 💡 Real-World Example

Here's how to use it in a voter management app:

```dart
class VotersController extends GetxController {
  late PagingController<ProfileModel> pagingController;

  @override
  void onInit() {
    super.onInit();
    
    pagingController = PagingController<ProfileModel>(
      config: PagingConfig(
        pageSize: 20,
        infiniteScroll: true,
      ),
      pageFetcher: (page) => fetchVoters(page),
      itemKeyGetter: (voter) => voter.id!,
    );
  }

  Future<List<ProfileModel>> fetchVoters(int page) async {
    final response = await api.get('/voters', 
      params: {'page': page, 'limit': 20}
    );
    return (response.data as List)
        .map((json) => ProfileModel.fromJson(json))
        .toList();
  }

  // Update voter religion and reflect in UI immediately
  Future<void> updateVoterReligion(String voterId, String religionId) async {
    await api.patch('/voters/$voterId', {'religion_id': religionId});
    
    // Update local data - UI updates automatically!
    pagingController.updateItem(
      pagingController.items
          .firstWhere((v) => v.id == voterId)
          .copyWith(religionId: religionId),
      where: (v) => v.id == voterId,
    );
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }
}

class VotersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EnhancedPaginationView<ProfileModel>(
        controller: controller.pagingController,
        itemBuilder: (context, voter, index) {
          return VoterCard(voter: voter);
        },
        enablePullToRefresh: true,
      ),
    );
  }
}
```

## 🆚 Comparison with pagination_view

| Feature | enhanced_pagination_view | pagination_view |
|---------|-------------------------|-----------------|
| Infinite Scroll | ✅ | ✅ |
| Pagination Buttons | ✅ | ❌ |
| Direct Item Access | ✅ | ❌ |
| Update Single Item | ✅ (O(1)) | ❌ |
| Remove Item | ✅ | ❌ |
| Insert Item | ✅ | ❌ |
| State Management | ✅ Comprehensive | ⚠️ Limited |
| Error Retry | ✅ Built-in | ⚠️ Manual |
| Pull-to-Refresh | ✅ | ❌ |
| Custom Pagination UI | ✅ | ❌ |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details

## 💬 Support

If you find this package helpful, please ⭐ star the repo!

For issues and feature requests, please use GitHub Issues.

### 6. Header & Footer Support

Add sticky headers and footers to your pagination view:

```dart
EnhancedPaginationView<User>(
  controller: controller,
  
  // Sticky header widget
  header: Container(
    padding: EdgeInsets.all(16),
    color: Colors.blue.shade50,
    child: Column(
      children: [
        Text('Search Users', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          decoration: InputDecoration(hintText: 'Search...'),
        ),
      ],
    ),
  ),
  
  // Footer widget (before pagination controls)
  footer: Container(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat('Total', totalCount),
        _buildStat('Active', activeCount),
        _buildStat('Inactive', inactiveCount),
      ],
    ),
  ),
  
  itemBuilder: (context, user, index) {
    return ListTile(title: Text(user.name));
  },
)
```

**Header/Footer Features:**
- 📌 Sticky header that stays at top
- 📊 Footer for stats/info display
- 🎨 Fully customizable widgets
- 🔄 Works with both infinite scroll and pagination modes
- ⚡ Uses CustomScrollView for optimal performance


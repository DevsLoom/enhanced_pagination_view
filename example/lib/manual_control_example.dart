import 'package:flutter/material.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

/// Example showing manual pagination control using PageResult
///
/// This is useful when:
/// - Your API provides hasNextPage flag
/// - Last page has exactly pageSize items
/// - You need custom logic to determine end of pagination
class ManualControlExample extends StatefulWidget {
  const ManualControlExample({super.key});

  @override
  State<ManualControlExample> createState() => _ManualControlExampleState();
}

class _ManualControlExampleState extends State<ManualControlExample> {
  late final PagingController<User> _controller;

  @override
  void initState() {
    super.initState();

    _controller = PagingController<User>(
      config: const PagingConfig(
        pageSize: 10,
        initialPage: 1, // API pages start from 1
      ),
      // Using PageResult for manual control
      pageFetcher: (page) async {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 1));

        final response = await _fetchUsersFromApi(page);

        // Return PageResult with manual hasMore control
        return PageResult<User>(
          items: response.users,
          hasMore: response.hasNextPage, // Manual control from API
        );
      },
    );
  }

  // Simulated API response
  Future<ApiResponse> _fetchUsersFromApi(int page) async {
    // Simulate: Total 20 items, 10 per page
    final totalItems = 20;
    final startIndex = (page - 1) * 10;

    if (startIndex >= totalItems) {
      return ApiResponse(users: [], hasNextPage: false);
    }

    final endIndex = (startIndex + 10).clamp(0, totalItems);
    final users = List.generate(
      endIndex - startIndex,
      (index) => User(
        id: startIndex + index + 1,
        name: 'User ${startIndex + index + 1}',
        email: 'user${startIndex + index + 1}@example.com',
      ),
    );

    // hasNextPage is true if there are more items after this page
    final hasNextPage = endIndex < totalItems;

    return ApiResponse(users: users, hasNextPage: hasNextPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Pagination Control')),
      body: EnhancedPaginationView<User>(
        controller: _controller,
        itemBuilder: (context, user, index) {
          return ListTile(
            leading: CircleAvatar(child: Text('${user.id}')),
            title: Text(user.name),
            subtitle: Text(user.email),
          );
        },
        onEmpty: const Center(child: Text('No users found')),
        onError: (error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example: Automatic control (backward compatible)
class AutomaticControlExample extends StatefulWidget {
  const AutomaticControlExample({super.key});

  @override
  State<AutomaticControlExample> createState() =>
      _AutomaticControlExampleState();
}

class _AutomaticControlExampleState extends State<AutomaticControlExample> {
  late final PagingController<User> _controller;

  @override
  void initState() {
    super.initState();

    _controller = PagingController<User>(
      config: const PagingConfig(pageSize: 10, initialPage: 0),
      // Automatic control: just return List<User>
      pageFetcher: (page) async {
        await Future.delayed(const Duration(seconds: 1));

        // Simulate API that returns less items on last page
        final startIndex = page * 10;
        final totalItems = 25;

        if (startIndex >= totalItems) {
          return []; // No more items
        }

        final endIndex = (startIndex + 10).clamp(0, totalItems);
        final users = List.generate(
          endIndex - startIndex,
          (index) => User(
            id: startIndex + index + 1,
            name: 'User ${startIndex + index + 1}',
            email: 'user${startIndex + index + 1}@example.com',
          ),
        );

        // Automatic detection: if users.length < pageSize, no more pages
        return users;
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automatic Pagination Control')),
      body: EnhancedPaginationView<User>(
        controller: _controller,
        itemBuilder: (context, user, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('${user.id}'),
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
            ),
          );
        },
      ),
    );
  }
}

// Models
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

class ApiResponse {
  final List<User> users;
  final bool hasNextPage;

  ApiResponse({required this.users, required this.hasNextPage});
}

// Demo app to run both examples
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pagination Control Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagination Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Manual Control'),
              subtitle: const Text(
                'Use PageResult with hasMore flag for manual control',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualControlExample(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('Automatic Control'),
              subtitle: const Text(
                'Return List<T> for automatic pagination detection',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AutomaticControlExample(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

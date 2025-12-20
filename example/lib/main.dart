import 'header_footer_example.dart';
import 'package:flutter/material.dart';
import 'layouts_example.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Pagination Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Pagination Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            'Infinite Scroll',
            'Classic infinite scrolling with O(1) item updates',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const InfiniteScrollExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Pagination Buttons',
            'Traditional pagination with next/previous buttons',
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaginationButtonsExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Item Updates',
            'Demonstrate O(1) update, remove, insert operations',
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ItemUpdatesExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Error Handling',
            'Test error states and retry mechanism',
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ErrorHandlingExample(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_forward, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// Model class
class User {
  final String id;
  final String name;
  final String email;
  final bool isOnline;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isOnline = false,
  });

  User copyWith({String? name, String? email, bool? isOnline}) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

// Fake API service
class FakeApiService {
  static Future<List<User>> fetchUsers(int page, {bool simulateError = false}) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (simulateError) {
      throw Exception('Failed to fetch users. Please try again.');
    }

    // Generate 20 users per page
    final List<User> users = [];
    final startIndex = page * 20;
    
    for (int i = 0; i < 20; i++) {
      final userIndex = startIndex + i;
      // Stop at 100 users (5 pages)
      if (userIndex >= 100) break;
      
      users.add(
        User(
          id: 'user_$userIndex',
          name: 'User ${userIndex + 1}',
          email: 'user${userIndex + 1}@example.com',
          isOnline: userIndex % 3 == 0,
        ),
      );
    }

    return users;
  }
}

// Example 1: Infinite Scroll
class InfiniteScrollExample extends StatefulWidget {
  const InfiniteScrollExample({super.key});

  @override
  State<InfiniteScrollExample> createState() => _InfiniteScrollExampleState();
}

class _InfiniteScrollExampleState extends State<InfiniteScrollExample> {
  late PagingController<User> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<User>(
      config: const PagingConfig(
        pageSize: 20,
        infiniteScroll: true,
        invisibleItemsThreshold: 5,
      ),
      pageFetcher: (page) => FakeApiService.fetchUsers(page),
      itemKeyGetter: (user) => user.id,
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
      appBar: AppBar(
        title: const Text('Infinite Scroll'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.refresh(),
          ),
        ],
      ),
      body: EnhancedPaginationView<User>(
        controller: _controller,
        itemBuilder: (context, user, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: user.isOnline ? Colors.green : Colors.grey,
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.name),
            subtitle: Text(user.email),
            trailing: user.isOnline
                ? const Chip(
                    label: Text('Online', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                : null,
          );
        },
        enablePullToRefresh: true,
      ),
    );
  }
}

// Example 2: Pagination Buttons
class PaginationButtonsExample extends StatefulWidget {
  const PaginationButtonsExample({super.key});

  @override
  State<PaginationButtonsExample> createState() =>
      _PaginationButtonsExampleState();
}

class _PaginationButtonsExampleState extends State<PaginationButtonsExample> {
  late PagingController<User> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<User>(
      config: const PagingConfig(
        pageSize: 20,
        infiniteScroll: false, // Use pagination buttons
      ),
      pageFetcher: (page) => FakeApiService.fetchUsers(page),
      itemKeyGetter: (user) => user.id,
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
      appBar: AppBar(
        title: const Text('Pagination Buttons'),
      ),
      body: EnhancedPaginationView<User>(
        controller: _controller,
        itemBuilder: (context, user, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user.name.substring(0, 1)),
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
            ),
          );
        },
        showPaginationButtons: true,
      ),
    );
  }
}

// Example 3: Item Updates
class ItemUpdatesExample extends StatefulWidget {
  const ItemUpdatesExample({super.key});

  @override
  State<ItemUpdatesExample> createState() => _ItemUpdatesExampleState();
}

class _ItemUpdatesExampleState extends State<ItemUpdatesExample> {
  late PagingController<User> _controller;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<User>(
      config: const PagingConfig(pageSize: 20),
      pageFetcher: (page) => FakeApiService.fetchUsers(page),
      itemKeyGetter: (user) => user.id,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleOnlineStatus(User user) {
    // O(1) update!
    _controller.updateItem(
      user.copyWith(isOnline: !user.isOnline),
      where: (u) => u.id == user.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updated ${user.name} - ${!user.isOnline ? "Online" : "Offline"}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeUser(User user) {
    _controller.removeItem(key: user.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${user.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Add back at the end
            _controller.appendItem(user);
          },
        ),
      ),
    );
  }

  void _addNewUser() {
    final newUser = User(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      name: 'New User',
      email: 'newuser@example.com',
      isOnline: true,
    );

    _controller.insertItem(0, newUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added new user at top')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Updates (O(1))'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewUser,
            tooltip: 'Add User',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      '${_controller.itemCount}',
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Online',
                      '${_controller.items.where((u) => u.isOnline).length}',
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Offline',
                      '${_controller.items.where((u) => !u.isOnline).length}',
                      Colors.grey,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: EnhancedPaginationView<User>(
                  controller: _controller,
                  itemBuilder: (context, user, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              user.isOnline ? Colors.green : Colors.grey,
                          child: Text(
                            user.name.substring(0, 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                user.isOnline
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                                color: user.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              onPressed: () => _toggleOnlineStatus(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeUser(user),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// Example 4: Error Handling
class ErrorHandlingExample extends StatefulWidget {
  const ErrorHandlingExample({super.key});

  @override
  State<ErrorHandlingExample> createState() => _ErrorHandlingExampleState();
}

class _ErrorHandlingExampleState extends State<ErrorHandlingExample> {
  late PagingController<User> _controller;
  bool _simulateError = false;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<User>(
      config: const PagingConfig(pageSize: 20),
      pageFetcher: (page) => FakeApiService.fetchUsers(
        page,
        simulateError: _simulateError,
      ),
      itemKeyGetter: (user) => user.id,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleErrorSimulation() {
    setState(() {
      _simulateError = !_simulateError;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _simulateError ? 'Error simulation ON' : 'Error simulation OFF',
        ),
        backgroundColor: _simulateError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling'),
        actions: [
          IconButton(
            icon: Icon(
              _simulateError ? Icons.error : Icons.check_circle,
              color: _simulateError ? Colors.red : Colors.green,
            ),
            onPressed: _toggleErrorSimulation,
            tooltip: 'Toggle Error Simulation',
          ),
        ],
      ),
      body: EnhancedPaginationView<User>(
        controller: _controller,
        itemBuilder: (context, user, index) {
          return ListTile(
            leading: CircleAvatar(child: Text(user.name.substring(0, 1))),
            title: Text(user.name),
            subtitle: Text(user.email),
          );
        },
        onError: (error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _controller.retry(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        onEmpty: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
        enablePullToRefresh: true,
      ),
    );
  }
}

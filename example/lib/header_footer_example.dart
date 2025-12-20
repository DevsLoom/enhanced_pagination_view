import 'package:flutter/material.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'main.dart'; // For User model and FakeApiService

class HeaderFooterExample extends StatefulWidget {
  const HeaderFooterExample({super.key});

  @override
  State<HeaderFooterExample> createState() => _HeaderFooterExampleState();
}

class _HeaderFooterExampleState extends State<HeaderFooterExample> {
  late PagingController<User> _controller;
  String _searchQuery = '';
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<User>(
      config: PagingConfig(pageSize: 20, infiniteScroll: true),
      pageFetcher: (page) async {
        final users = await FakeApiService.fetchUsers(page);
        _totalItems += users.length;
        setState(() {});
        return users;
      },
      itemKeyGetter: (u) => u.id,
      analytics: PagingAnalytics<User>(
        onPageRequest: (page) =>
            debugPrint('[HeaderFooter] Request page $page'),
        onPageError: (page, error, _, {required isFirstPage}) => debugPrint(
          '[HeaderFooter] Error page $page (first=$isFirstPage): $error',
        ),
      ),
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
        title: const Text('Header & Footer Demo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: EnhancedPaginationView<User>(
        controller: _controller,
        scrollViewKey: const PageStorageKey<String>(
          'header-footer-example-scroll',
        ),

        // Header widget - Search bar
        header: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.teal.shade200, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Users Loaded: $_totalItems',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Footer widget - Stats & Info
        footer: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            border: Border(
              top: BorderSide(color: Colors.teal.shade200, width: 2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total', _totalItems, Icons.people),
                  _buildStatCard(
                    'Online',
                    _controller.items.where((u) => u.isOnline).length,
                    Icons.circle,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    'Offline',
                    _controller.items.where((u) => !u.isOnline).length,
                    Icons.circle_outlined,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Powered by Enhanced Pagination View',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        itemBuilder: (context, user, index) {
          // Filter by search query
          if (_searchQuery.isNotEmpty &&
              !user.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !user.email.toLowerCase().contains(_searchQuery.toLowerCase())) {
            return const SizedBox.shrink();
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.isOnline ? Colors.green : Colors.grey,
                child: Text(
                  user.name[0],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(user.email),
              trailing: user.isOnline
                  ? const Icon(Icons.circle, color: Colors.green, size: 12)
                  : const Icon(Icons.circle, color: Colors.grey, size: 12),
            ),
          );
        },

        onEmpty: const Center(child: Text('No users found')),

        enablePullToRefresh: true,
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.teal, size: 24),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

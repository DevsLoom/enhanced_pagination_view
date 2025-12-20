import 'package:flutter/material.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'main.dart';

class LayoutsExample extends StatefulWidget {
  const LayoutsExample({super.key});

  @override
  State<LayoutsExample> createState() => _LayoutsExampleState();
}

class _LayoutsExampleState extends State<LayoutsExample> {
  late PagingController<User> _controller;
  PaginationLayoutMode _layoutMode = PaginationLayoutMode.list;
  Axis _scrollDirection = Axis.vertical;
  int _gridCrossAxisCount = 2;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<User>(
      config: PagingConfig(
        pageSize: 20,
        infiniteScroll: true,
      ),
      pageFetcher: (page) => FakeApiService.fetchUsers(page),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changeLayout(PaginationLayoutMode mode) {
    setState(() {
      _layoutMode = mode;
      // Reset to vertical for wrap layout
      if (mode == PaginationLayoutMode.wrap) {
        _scrollDirection = Axis.vertical;
      }
    });
  }

  void _toggleDirection() {
    if (_layoutMode != PaginationLayoutMode.wrap) {
      setState(() {
        _scrollDirection = _scrollDirection == Axis.vertical
            ? Axis.horizontal
            : Axis.vertical;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layout Examples'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          // Direction toggle
          if (_layoutMode != PaginationLayoutMode.wrap)
            IconButton(
              icon: Icon(_scrollDirection == Axis.vertical
                  ? Icons.swap_horiz
                  : Icons.swap_vert),
              onPressed: _toggleDirection,
              tooltip: 'Toggle Direction',
            ),
          // Grid columns
          if (_layoutMode == PaginationLayoutMode.grid &&
              _scrollDirection == Axis.vertical)
            PopupMenuButton<int>(
              icon: const Icon(Icons.grid_3x3),
              onSelected: (value) {
                setState(() {
                  _gridCrossAxisCount = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 2, child: Text('2 Columns')),
                const PopupMenuItem(value: 3, child: Text('3 Columns')),
                const PopupMenuItem(value: 4, child: Text('4 Columns')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Layout mode selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Row(
              children: [
                Expanded(
                  child: _buildLayoutButton(
                    'List',
                    Icons.list,
                    PaginationLayoutMode.list,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLayoutButton(
                    'Grid',
                    Icons.grid_view,
                    PaginationLayoutMode.grid,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLayoutButton(
                    'Wrap',
                    Icons.wrap_text,
                    PaginationLayoutMode.wrap,
                  ),
                ),
              ],
            ),
          ),

          // Direction indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.purple.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _scrollDirection == Axis.vertical
                      ? Icons.arrow_downward
                      : Icons.arrow_forward,
                  size: 16,
                  color: Colors.purple,
                ),
                const SizedBox(width: 8),
                Text(
                  _scrollDirection == Axis.vertical
                      ? 'Vertical Scroll'
                      : 'Horizontal Scroll',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                if (_layoutMode == PaginationLayoutMode.grid &&
                    _scrollDirection == Axis.vertical)
                  Text(
                    ' • $_gridCrossAxisCount columns',
                    style: TextStyle(color: Colors.purple.shade700),
                  ),
              ],
            ),
          ),

          // Pagination view
          Expanded(
            child: EnhancedPaginationView<User>(
              controller: _controller,
              layoutMode: _layoutMode,
              scrollDirection: _scrollDirection,
              
              // Grid configuration
              gridDelegate: _layoutMode == PaginationLayoutMode.grid
                  ? (_scrollDirection == Axis.vertical
                      ? SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridCrossAxisCount,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        )
                      : SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ))
                  : null,
              
              // Wrap configuration
              wrapSpacing: 8,
              wrapRunSpacing: 8,
              wrapAlignment: WrapAlignment.start,
              
              padding: const EdgeInsets.all(16),
              
              itemBuilder: (context, user, index) {
                return _buildUserCard(user, index);
              },
              
              onEmpty: const Center(
                child: Text('No users found'),
              ),
              
              enablePullToRefresh: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutButton(
    String label,
    IconData icon,
    PaginationLayoutMode mode,
  ) {
    final isSelected = _layoutMode == mode;
    return ElevatedButton.icon(
      onPressed: () => _changeLayout(mode),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.purple : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.purple,
        elevation: isSelected ? 4 : 1,
      ),
    );
  }

  Widget _buildUserCard(User user, int index) {
    // For wrap layout - compact chips
    if (_layoutMode == PaginationLayoutMode.wrap) {
      return Chip(
        avatar: CircleAvatar(
          backgroundColor: user.isOnline ? Colors.green : Colors.grey,
          child: Text(
            user.name[0],
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        label: Text(user.name),
        backgroundColor: Colors.purple.shade50,
      );
    }

    // For grid and list layouts - full cards
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: _scrollDirection == Axis.horizontal
          ? _buildHorizontalCard(user)
          : _buildVerticalCard(user),
    );
  }

  Widget _buildVerticalCard(User user) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: _layoutMode == PaginationLayoutMode.grid ? 30 : 25,
            backgroundColor: user.isOnline ? Colors.green : Colors.grey,
            child: Text(
              user.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (_layoutMode == PaginationLayoutMode.list) ...[
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Icon(
            Icons.circle,
            size: 10,
            color: user.isOnline ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(User user) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: user.isOnline ? Colors.green : Colors.grey,
            child: Text(
              user.name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: user.isOnline ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

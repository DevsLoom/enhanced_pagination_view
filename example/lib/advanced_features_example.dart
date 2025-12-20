import 'package:flutter/material.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'main.dart';

class AdvancedFeaturesExample extends StatefulWidget {
  const AdvancedFeaturesExample({super.key});

  @override
  State<AdvancedFeaturesExample> createState() =>
      _AdvancedFeaturesExampleState();
}

class _AdvancedFeaturesExampleState extends State<AdvancedFeaturesExample> {
  late PagingController<User> _controller;
  double _prefetchDistance = 200.0;
  bool _showCustomViews = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = PagingController<User>(
      config: PagingConfig(
        pageSize: 15,
        infiniteScroll: true,
        prefetchDistance: _prefetchDistance,
        invisibleItemsThreshold: 3,
      ),
      pageFetcher: (page) async {
        // Simulate varying delays to show prefetch benefit
        await Future.delayed(Duration(milliseconds: 800 + (page * 200)));
        return await FakeApiService.fetchUsers(page);
      },
    );
  }

  void _updatePrefetch(double distance) {
    setState(() {
      _prefetchDistance = distance;
    });
    // Recreate controller with new config
    _controller.dispose();
    _initController();
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
        title: const Text('Advanced Features'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control Panel
          _buildControlPanel(),

          // Status Info
          _buildStatusInfo(),

          // Pagination View
          Expanded(
            child: EnhancedPaginationView<User>(
              controller: _controller,

              // 🎨 Custom Status Views
              initialLoader: _showCustomViews
                  ? _buildCustomInitialLoader()
                  : null,

              bottomLoader: _showCustomViews
                  ? _buildCustomBottomLoader()
                  : null,

              onCompleted: _showCustomViews ? _buildCustomCompleted() : null,

              onEmpty: _showCustomViews ? _buildCustomEmpty() : null,

              onError: _showCustomViews
                  ? (error) => _buildCustomError(error)
                  : null,

              itemBuilder: (context, user, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.isOnline
                          ? Colors.green
                          : Colors.grey,
                      child: Text(user.name[0]),
                    ),
                    title: Text(user.name),
                    subtitle: Text('Item #$index'),
                    trailing: Text(
                      user.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: user.isOnline ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },

              enablePullToRefresh: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.indigo.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                'Prefetch Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Switch(
                value: _showCustomViews,
                onChanged: (value) {
                  setState(() {
                    _showCustomViews = value;
                  });
                },
              ),
              const Text('Custom Views'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Prefetch Distance: '),
              Text(
                '${_prefetchDistance.toInt()}px',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          Slider(
            value: _prefetchDistance,
            min: 0,
            max: 1000,
            divisions: 10,
            label: '${_prefetchDistance.toInt()}px',
            onChanged: (value) {
              _updatePrefetch(value);
            },
          ),
          Text(
            _prefetchDistance == 0
                ? '⚠️ Prefetch disabled - loads when items visible'
                : '✅ Loads ${_prefetchDistance.toInt()}px before reaching bottom',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.indigo.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusBadge(
            'State',
            _getStateLabel(_controller.state),
            _getStateColor(_controller.state),
          ),
          _buildStatusBadge(
            'Items',
            '${_controller.items.length}',
            Colors.blue,
          ),
          _buildStatusBadge(
            'Page',
            '${_controller.currentPage + 1}',
            Colors.purple,
          ),
          _buildStatusBadge(
            'Has More',
            _controller.hasMoreData ? 'Yes' : 'No',
            _controller.hasMoreData ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  String _getStateLabel(PagingState state) {
    switch (state) {
      case PagingState.initial:
        return 'Initial';
      case PagingState.loading:
        return 'Loading';
      case PagingState.loaded:
        return 'Loaded';
      case PagingState.loadingMore:
        return 'Loading More';
      case PagingState.error:
        return 'Error';
      case PagingState.empty:
        return 'Empty';
      case PagingState.completed:
        return 'Completed';
    }
  }

  Color _getStateColor(PagingState state) {
    switch (state) {
      case PagingState.initial:
        return Colors.grey;
      case PagingState.loading:
      case PagingState.loadingMore:
        return Colors.orange;
      case PagingState.loaded:
        return Colors.green;
      case PagingState.error:
        return Colors.red;
      case PagingState.empty:
        return Colors.amber;
      case PagingState.completed:
        return Colors.blue;
    }
  }

  // 🎨 Custom Status Widgets

  Widget _buildCustomInitialLoader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(seconds: 2),
            builder: (context, double value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: Colors.indigo.shade100,
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '🚀 Loading your data...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prefetch enabled for smoother experience',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomLoader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading more items...',
            style: TextStyle(
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCompleted() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            '🎉 All data loaded!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ve reached the end',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'No Data Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing to load data',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomError(Object error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 24),
          const Text(
            '❌ Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _controller.retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

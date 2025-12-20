import 'package:flutter/material.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'main.dart'; // For User model and FakeApiService

/// Example demonstrating Facebook-style infinite scroll with cache management
class FacebookScrollExample extends StatefulWidget {
  const FacebookScrollExample({super.key});

  @override
  State<FacebookScrollExample> createState() => _FacebookScrollExampleState();
}

class _FacebookScrollExampleState extends State<FacebookScrollExample> {
  late PagingController<User> _controller;
  int _prefetchItemCount = 5;
  CacheMode _cacheMode = CacheMode.all;
  int _maxCachedItems = 500;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = PagingController<User>(
      config: PagingConfig(
        pageSize: 20,
        infiniteScroll: true,
        prefetchItemCount: _prefetchItemCount,
        cacheMode: _cacheMode,
        maxCachedItems: _maxCachedItems,
      ),
      pageFetcher: (page) async {
        await Future.delayed(const Duration(milliseconds: 800));
        return await FakeApiService.fetchUsers(page);
      },
      itemKeyGetter: (u) => u.id,
      analytics: PagingAnalytics<User>(
        onPageRequest: (page) =>
            debugPrint('[FacebookScroll] Request page $page'),
        onPageError: (page, error, _, {required isFirstPage}) => debugPrint(
          '[FacebookScroll] Error page $page (first=$isFirstPage): $error',
        ),
      ),
    );
  }

  void _updateConfig() {
    setState(() {
      _controller.dispose();
      _initController();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facebook-Style Scroll'), elevation: 2),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    const Icon(Icons.facebook, color: Colors.blue, size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'Facebook-Style Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prefetch Item Count
                Text(
                  'Prefetch Item Count: $_prefetchItemCount items',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _prefetchItemCount.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '$_prefetchItemCount items',
                        onChanged: (value) {
                          setState(() {
                            _prefetchItemCount = value.toInt();
                          });
                        },
                        onChangeEnd: (value) => _updateConfig(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_prefetchItemCount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '⚡ Loads next page when $_prefetchItemCount items from bottom',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                // Cache Mode
                const Text(
                  'Cache Management',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCacheModeChip(
                      'All Items',
                      CacheMode.all,
                      'Keep everything in memory',
                    ),
                    _buildCacheModeChip(
                      'None',
                      CacheMode.none,
                      'Keep only current page',
                    ),
                    _buildCacheModeChip(
                      'Limited',
                      CacheMode.limited,
                      'Keep last $_maxCachedItems items',
                    ),
                  ],
                ),

                // Max Cached Items (only show when limited mode)
                if (_cacheMode == CacheMode.limited) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Max Cached Items: $_maxCachedItems',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: _maxCachedItems.toDouble(),
                    min: 100,
                    max: 1000,
                    divisions: 18,
                    label: '$_maxCachedItems items',
                    onChanged: (value) {
                      setState(() {
                        _maxCachedItems = value.toInt();
                      });
                    },
                    onChangeEnd: (value) => _updateConfig(),
                  ),
                ],

                // Info
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[800]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getCacheModeDescription(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              children: [
                _buildStatusBadge(
                  'Items',
                  '${_controller.items.length}',
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(
                  'State',
                  _getStateLabel(_controller.state),
                  _getStateColor(_controller.state),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(
                  'Has More',
                  _controller.hasMoreData ? 'Yes' : 'No',
                  _controller.hasMoreData ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: EnhancedPaginationView<User>(
              controller: _controller,
              scrollViewKey: const PageStorageKey<String>(
                'facebook-scroll-example',
              ),
              itemBuilder: (context, user, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.primaries[index % Colors.primaries.length],
                      child: Text(
                        user.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user.email),
                    trailing: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              initialLoader: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        '📱 Loading Facebook-style...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottomLoader: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading more (prefetch: $_prefetchItemCount items)...',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              onCompleted: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.green[600],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '✅ All posts loaded!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheModeChip(String label, CacheMode mode, String tooltip) {
    final isSelected = _cacheMode == mode;
    return Tooltip(
      message: tooltip,
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _cacheMode = mode;
            });
            _updateConfig();
          }
        },
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[800],
      ),
    );
  }

  Widget _buildStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getCacheModeDescription() {
    switch (_cacheMode) {
      case CacheMode.all:
        return 'All previous items kept in memory. Best for small datasets.';
      case CacheMode.none:
        return 'Only current page kept. Minimal memory usage, scrolling up reloads.';
      case CacheMode.limited:
        return 'Keeps last $_maxCachedItems items. Balance between memory & UX.';
    }
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
}

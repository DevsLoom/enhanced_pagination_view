import 'package:flutter/material.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

/// Example demonstrating item animations
class AnimationsExample extends StatefulWidget {
  const AnimationsExample({super.key});

  @override
  State<AnimationsExample> createState() => _AnimationsExampleState();
}

class _AnimationsExampleState extends State<AnimationsExample> {
  late PagingController<UserModel> _pagingController;
  bool _animationsEnabled = true;
  Duration _animationDuration = const Duration(milliseconds: 300);
  Curve _animationCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _pagingController = PagingController<UserModel>(
      config: const PagingConfig(pageSize: 10, infiniteScroll: true),
      pageFetcher: _fetchPage,
    );
  }

  Future<List<UserModel>> _fetchPage(int pageKey) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    final newItems = List.generate(10, (index) {
      final id = (pageKey - 1) * 10 + index + 1;
      return UserModel(
        id: id,
        name: 'User $id',
        email: 'user$id@example.com',
        isOnline: index % 3 == 0,
        avatarColor: Colors.primaries[id % Colors.primaries.length],
      );
    });

    // Stop at 5 pages
    if (pageKey >= 5) {
      return []; // Return empty to mark as last page
    }

    return newItems;
  }

  void _updateAnimationSettings() {
    setState(() {
      // Dispose old controller
      _pagingController.dispose();
      // Create new controller to trigger rebuild
      _initController();
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Animations'), elevation: 2),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enable/Disable Animations
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Enable Animations',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch(
                      value: _animationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _animationsEnabled = value;
                        });
                        _updateAnimationSettings();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Animation Duration
                Text(
                  'Duration: ${_animationDuration.inMilliseconds}ms',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Slider(
                  value: _animationDuration.inMilliseconds.toDouble(),
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  label: '${_animationDuration.inMilliseconds}ms',
                  onChanged: (value) {
                    setState(() {
                      _animationDuration = Duration(
                        milliseconds: value.toInt(),
                      );
                    });
                  },
                  onChangeEnd: (value) {
                    _updateAnimationSettings();
                  },
                ),
                const SizedBox(height: 8),

                // Animation Curve
                const Text(
                  'Animation Curve',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCurveChip('easeInOut', Curves.easeInOut),
                    _buildCurveChip('easeIn', Curves.easeIn),
                    _buildCurveChip('easeOut', Curves.easeOut),
                    _buildCurveChip('bounceIn', Curves.bounceIn),
                    _buildCurveChip('bounceOut', Curves.bounceOut),
                    _buildCurveChip('elasticIn', Curves.elasticIn),
                    _buildCurveChip('elasticOut', Curves.elasticOut),
                  ],
                ),
              ],
            ),
          ),

          // Animated List
          Expanded(
            child: EnhancedPaginationView<UserModel>(
              controller: _pagingController,
              enableItemAnimations: _animationsEnabled,
              animationDuration: _animationDuration,
              animationCurve: _animationCurve,
              itemBuilder: (context, item, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor: item.avatarColor,
                      child: Text(
                        item.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(item.email),
                    trailing: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.isOnline ? Colors.green : Colors.grey,
                        boxShadow: item.isOnline
                            ? [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
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
                        '🎬 Loading animated items...',
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
                      'Loading more with ${_animationsEnabled ? "animations" : "no animations"}...',
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
                      '🎉 All items loaded!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Animations demo completed',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              onEmpty: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Data Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onError: (error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _pagingController.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurveChip(String label, Curve curve) {
    final isSelected = _animationCurve == curve;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _animationCurve = curve;
          });
          _updateAnimationSettings();
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[800],
    );
  }
}

// Model class
class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isOnline;
  final Color avatarColor;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isOnline,
    required this.avatarColor,
  });
}

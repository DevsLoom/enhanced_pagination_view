import 'package:flutter_test/flutter_test.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

void main() {
  group('PageResult Manual Control Tests', () {
    test('Manual control with PageResult respects hasMore flag', () async {
      final controller = PagingController<int>(
        config: const PagingConfig(pageSize: 10, autoLoadFirstPage: false),
        pageFetcher: (page) async {
          if (page == 0) {
            // First page: 10 items, has more
            return PageResult<int>(
              items: List.generate(10, (i) => i),
              hasMore: true,
            );
          } else if (page == 1) {
            // Second page: 10 items, but no more pages
            return PageResult<int>(
              items: List.generate(10, (i) => i + 10),
              hasMore: false, // Manual control: no more pages
            );
          }
          return PageResult<int>(items: [], hasMore: false);
        },
      );

      // Load first page
      await controller.loadFirstPage();
      expect(controller.items.length, 10);
      expect(controller.hasMoreData, true);
      expect(controller.state, PagingState.loaded);

      // Load second page
      await controller.loadNextPage();
      expect(controller.items.length, 20);
      expect(controller.hasMoreData, false); // Manual control
      expect(controller.state, PagingState.completed);

      controller.dispose();
    });

    test(
      'Automatic control with List<T> detects end when items < pageSize',
      () async {
        final controller = PagingController<int>(
          config: const PagingConfig(pageSize: 10, autoLoadFirstPage: false),
          pageFetcher: (page) async {
            if (page == 0) {
              // First page: 10 items
              return List.generate(10, (i) => i);
            } else if (page == 1) {
              // Second page: only 5 items (automatic detection)
              return List.generate(5, (i) => i + 10);
            }
            return [];
          },
        );

        // Load first page
        await controller.loadFirstPage();
        expect(controller.items.length, 10);
        expect(controller.hasMoreData, true);

        // Load second page
        await controller.loadNextPage();
        expect(controller.items.length, 15);
        expect(controller.hasMoreData, false); // Automatic detection
        expect(controller.state, PagingState.completed);

        controller.dispose();
      },
    );

    test('Manual control fixes issue #5 scenario', () async {
      // Issue #5: API has 20 items total, 10 per page, pages start at 1
      final controller = PagingController<int>(
        config: const PagingConfig(
          pageSize: 10,
          initialPage: 1,
          autoLoadFirstPage: false,
        ),
        pageFetcher: (page) async {
          // Simulate API
          final totalItems = 20;
          final startIndex = (page - 1) * 10;

          if (startIndex >= totalItems) {
            return PageResult<int>(items: [], hasMore: false);
          }

          final endIndex = (startIndex + 10).clamp(0, totalItems);
          final items = List.generate(
            endIndex - startIndex,
            (i) => startIndex + i,
          );

          final hasMore = endIndex < totalItems;

          return PageResult<int>(items: items, hasMore: hasMore);
        },
      );

      // Load page 1 (items 0-9)
      await controller.loadFirstPage();
      expect(controller.items.length, 10);
      expect(controller.hasMoreData, true);
      expect(controller.currentPage, 1);

      // Load page 2 (items 10-19)
      await controller.loadNextPage();
      expect(controller.items.length, 20);
      expect(controller.hasMoreData, false); // No page 3!
      expect(controller.state, PagingState.completed);
      expect(controller.currentPage, 2);

      // Try to load page 3 - should not trigger
      final beforeState = controller.state;
      await controller.loadNextPage();
      expect(controller.state, beforeState); // State unchanged
      expect(controller.currentPage, 2); // Page unchanged

      controller.dispose();
    });

    test('Backward compatibility: List<T> still works', () async {
      final controller = PagingController<String>(
        config: const PagingConfig(pageSize: 5, autoLoadFirstPage: false),
        pageFetcher: (page) async {
          // Old style: just return List<T>
          if (page == 0) {
            return ['A', 'B', 'C', 'D', 'E'];
          } else if (page == 1) {
            return ['F', 'G', 'H']; // Less than pageSize
          }
          return [];
        },
      );

      await controller.loadFirstPage();
      expect(controller.items, ['A', 'B', 'C', 'D', 'E']);
      expect(controller.hasMoreData, true);

      await controller.loadNextPage();
      expect(controller.items, ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']);
      expect(controller.hasMoreData, false); // Auto-detected
      expect(controller.state, PagingState.completed);

      controller.dispose();
    });

    test(
      'Manual control with empty items still sets hasMore correctly',
      () async {
        final controller = PagingController<int>(
          config: const PagingConfig(pageSize: 10, autoLoadFirstPage: false),
          pageFetcher: (page) async {
            if (page == 0) {
              // Edge case: no items but API says has more
              return PageResult<int>(items: [], hasMore: true);
            }
            return PageResult<int>(items: [], hasMore: false);
          },
        );

        await controller.loadFirstPage();
        expect(controller.items.length, 0);
        expect(controller.state, PagingState.empty);
        expect(controller.hasMoreData, true); // Respects manual flag

        controller.dispose();
      },
    );

    test('PageResult with pagination buttons mode', () async {
      final controller = PagingController<int>(
        config: const PagingConfig(
          pageSize: 5,
          infiniteScroll: false, // Pagination buttons mode
          autoLoadFirstPage: false,
        ),
        pageFetcher: (page) async {
          return PageResult<int>(
            items: List.generate(5, (i) => page * 5 + i),
            hasMore: page < 3, // Only 4 pages total
          );
        },
      );

      await controller.loadFirstPage();
      expect(controller.items.length, 5);
      expect(controller.hasMoreData, true);

      await controller.loadNextPage();
      expect(controller.items.length, 5); // Replaced, not appended
      expect(controller.items.first, 5);
      expect(controller.hasMoreData, true);

      await controller.loadNextPage();
      expect(controller.items.length, 5);
      expect(controller.items.first, 10);
      expect(controller.hasMoreData, true);

      await controller.loadNextPage();
      expect(controller.items.length, 5);
      expect(controller.items.first, 15);
      expect(controller.hasMoreData, false); // Last page
      expect(controller.state, PagingState.completed);

      controller.dispose();
    });
  });
}

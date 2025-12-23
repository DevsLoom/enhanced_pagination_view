import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int? topMostVisibleItemNumber({required double viewportHeight}) {
    String? bestText;
    var bestDy = double.infinity;

    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget;
      if (widget is! Text || widget.data == null) continue;

      final renderObject = element.renderObject;
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;

      final dy = renderObject.localToGlobal(Offset.zero).dy;
      if (dy >= 0 && dy < viewportHeight && dy < bestDy) {
        bestDy = dy;
        bestText = widget.data;
      }
    }

    if (bestText == null) return null;

    final match = RegExp(r'^Item\s+(\d+)$').firstMatch(bestText);
    return match == null ? null : int.parse(match.group(1)!);
  }

  PagingController<String> makeController() {
    return PagingController<String>(
      config: const PagingConfig(
        pageSize: 20,
        autoLoadFirstPage: false,
        infiniteScroll: true,
        prefetchDistance: 200,
        cacheMode: CacheMode.limited,
        maxCachedItems: 100,
        compensateForTrimmedItems: true,
      ),
      pageFetcher: (page) async {
        if (page >= 60) return const <String>[];
        return List<String>.generate(
          20,
          (i) => 'Item ${page * 20 + i}',
          growable: false,
        );
      },
      itemKeyGetter: (s) => s,
    );
  }

  PagingController<String> makeControllerWithCacheMode(CacheMode cacheMode) {
    return PagingController<String>(
      config: PagingConfig(
        pageSize: 20,
        autoLoadFirstPage: false,
        infiniteScroll: true,
        prefetchDistance: 200,
        cacheMode: cacheMode,
        maxCachedItems: 100,
        compensateForTrimmedItems: true,
      ),
      pageFetcher: (page) async {
        if (page >= 60) return const <String>[];
        return List<String>.generate(
          20,
          (i) => 'Item ${page * 20 + i}',
          growable: false,
        );
      },
      itemKeyGetter: (s) => s,
    );
  }

  Future<void> scrollManyTimes(
    WidgetTester tester, {
    required int times,
  }) async {
    for (var i = 0; i < times; i++) {
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -900),
        2500,
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> assertNoVisibleBackwardJump(
    WidgetTester tester, {
    required double viewportHeight,
    required int iterations,
  }) async {
    int? lastTop;

    for (var i = 0; i < iterations; i++) {
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -900),
        2500,
      );
      await tester.pumpAndSettle();

      final top = topMostVisibleItemNumber(viewportHeight: viewportHeight);
      if (top == null) continue;

      if (lastTop != null) {
        expect(top, greaterThanOrEqualTo(lastTop));
      }
      lastTop = top;
    }
  }

  Future<void> assertNoVisibleForwardJumpWhenScrollingUp(
    WidgetTester tester, {
    required double viewportHeight,
    required int iterations,
  }) async {
    int? lastTop;

    for (var i = 0; i < iterations; i++) {
      // Positive dy drags the content down (scrolling up).
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 700),
        2500,
      );
      await tester.pumpAndSettle();

      final top = topMostVisibleItemNumber(viewportHeight: viewportHeight);
      if (top == null) continue;

      if (lastTop != null) {
        expect(top, lessThanOrEqualTo(lastTop));
      }
      lastTop = top;
    }
  }

  testWidgets('Windowed mode (List): no visible backward jump', (
    WidgetTester tester,
  ) async {
    const viewportHeight = 600.0;
    final controller = makeController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewportHeight,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              physics: const ClampingScrollPhysics(),
              enableItemAnimations: false,
              layoutMode: PaginationLayoutMode.list,
              itemBuilder: (context, item, index) {
                final height = 44.0 + ((index % 9) * 7.0);
                return SizedBox(
                  height: height,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(item),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    await assertNoVisibleBackwardJump(
      tester,
      viewportHeight: viewportHeight,
      iterations: 25,
    );
    await scrollManyTimes(tester, times: 40);

    controller.dispose();
  });

  testWidgets('Windowed mode (Grid): no visible backward jump', (
    WidgetTester tester,
  ) async {
    const viewportHeight = 600.0;
    final controller = makeController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewportHeight,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              physics: const ClampingScrollPhysics(),
              enableItemAnimations: false,
              layoutMode: PaginationLayoutMode.grid,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, item, index) {
                // Variable-ish height inside grid tile.
                final padding = 8.0 + ((index % 5) * 2.0);
                return Container(
                  padding: EdgeInsets.all(padding),
                  alignment: Alignment.centerLeft,
                  child: Text(item),
                );
              },
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    await assertNoVisibleBackwardJump(
      tester,
      viewportHeight: viewportHeight,
      iterations: 30,
    );
    await scrollManyTimes(tester, times: 40);

    controller.dispose();
  });

  testWidgets('Windowed mode (Wrap): no visible backward jump', (
    WidgetTester tester,
  ) async {
    const viewportHeight = 600.0;
    final controller = makeController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewportHeight,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              physics: const ClampingScrollPhysics(),
              enableItemAnimations: false,
              layoutMode: PaginationLayoutMode.wrap,
              wrapSpacing: 8,
              wrapRunSpacing: 8,
              itemBuilder: (context, item, index) {
                final w = 90.0 + ((index % 4) * 25.0);
                final h = 32.0 + ((index % 6) * 6.0);
                return SizedBox(
                  width: w,
                  height: h,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    await assertNoVisibleBackwardJump(
      tester,
      viewportHeight: viewportHeight,
      iterations: 30,
    );
    await scrollManyTimes(tester, times: 40);

    controller.dispose();
  });

  testWidgets(
    'Windowed mode (CacheMode.none): down + up scrolling stays stable',
    (WidgetTester tester) async {
      const viewportHeight = 600.0;
      final controller = makeControllerWithCacheMode(CacheMode.none);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: viewportHeight,
              child: EnhancedPaginationView<String>(
                controller: controller,
                enablePullToRefresh: false,
                physics: const ClampingScrollPhysics(),
                enableItemAnimations: false,
                layoutMode: PaginationLayoutMode.list,
                itemBuilder: (context, item, index) {
                  final height = 44.0 + ((index % 9) * 7.0);
                  return SizedBox(
                    height: height,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await controller.loadFirstPage();
      await tester.pumpAndSettle();

      // Scroll down for a while; top-most visible item should never go backwards.
      await assertNoVisibleBackwardJump(
        tester,
        viewportHeight: viewportHeight,
        iterations: 25,
      );

      // Now scroll back up; within the current window, we should be able to
      // scroll upward without sudden forward jumps.
      await assertNoVisibleForwardJumpWhenScrollingUp(
        tester,
        viewportHeight: viewportHeight,
        iterations: 10,
      );

      controller.dispose();
    },
  );

  testWidgets(
    'Windowed mode (CacheMode.limited): heavy down + up scrolling stays stable',
    (WidgetTester tester) async {
      const viewportHeight = 600.0;
      final controller = makeControllerWithCacheMode(CacheMode.limited);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: viewportHeight,
              child: EnhancedPaginationView<String>(
                controller: controller,
                enablePullToRefresh: false,
                physics: const ClampingScrollPhysics(),
                enableItemAnimations: false,
                layoutMode: PaginationLayoutMode.list,
                itemBuilder: (context, item, index) {
                  final height = 44.0 + ((index % 9) * 7.0);
                  return SizedBox(
                    height: height,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(item),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await controller.loadFirstPage();
      await tester.pumpAndSettle();

      // Heavy downward scrolling should not produce any visible backward jump.
      await assertNoVisibleBackwardJump(
        tester,
        viewportHeight: viewportHeight,
        iterations: 35,
      );

      // Push further down to ensure cache trimming kicks in.
      await scrollManyTimes(tester, times: 60);

      // Now scroll upward; within the cached window the visible top item should
      // move backward (or stay), but never jump forward unexpectedly.
      await assertNoVisibleForwardJumpWhenScrollingUp(
        tester,
        viewportHeight: viewportHeight,
        iterations: 25,
      );

      controller.dispose();
    },
  );
}

import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PagingController<String> makeController() {
    return PagingController<String>(
      config: const PagingConfig(
        pageSize: 10,
        autoLoadFirstPage: false,
        infiniteScroll: true,
        cacheMode: CacheMode.limited,
        maxCachedItems: 15,
        compensateForTrimmedItems: true,
      ),
      pageFetcher: (page) async {
        if (page >= 3) return const <String>[];
        return List<String>.generate(
          10,
          (i) => 'Item ${page * 10 + i}',
          growable: false,
        );
      },
      itemKeyGetter: (s) => s,
    );
  }

  Future<void> pumpHorizontalView(
    WidgetTester tester, {
    required PagingController<String> controller,
    required PaginationLayoutMode layoutMode,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            width: 400,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              enableItemAnimations: false,
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              layoutMode: layoutMode,
              gridDelegate: layoutMode == PaginationLayoutMode.grid
                  ? const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.0,
                    )
                  : null,
              wrapSpacing: 8,
              wrapRunSpacing: 8,
              itemBuilder: (context, item, index) {
                // Give items a width so horizontal scrolling has something to do.
                return SizedBox(
                  width: 60,
                  height: 60,
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
  }

  testWidgets('horizontal List renders and can scroll', (tester) async {
    final controller = makeController();
    await pumpHorizontalView(
      tester,
      controller: controller,
      layoutMode: PaginationLayoutMode.list,
    );

    expect(find.text('Item 0'), findsOneWidget);

    // Capture an on-screen anchor position before trimming.
    final anchor = find.text('Item 5');
    expect(anchor, findsOneWidget);
    final beforeDx = tester.getTopLeft(anchor).dx;

    // Trigger a load that causes trimming (maxCachedItems=15, pageSize=10).
    await controller.loadNextPage();
    await tester.pumpAndSettle();

    // Anchor should remain roughly in the same screen position.
    expect(anchor, findsOneWidget);
    final afterDx = tester.getTopLeft(anchor).dx;
    expect((afterDx - beforeDx).abs(), lessThan(2.0));

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(-900, 0),
      2500,
    );
    await tester.pumpAndSettle();

    // Ensure no crash and still showing some items.
    expect(find.byType(CustomScrollView), findsOneWidget);

    controller.dispose();
  });

  testWidgets('horizontal Grid renders and can scroll', (tester) async {
    final controller = makeController();
    await pumpHorizontalView(
      tester,
      controller: controller,
      layoutMode: PaginationLayoutMode.grid,
    );

    expect(find.text('Item 0'), findsOneWidget);

    // Ensure trim-compensation path can run without crashing.
    await controller.loadNextPage();
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(-900, 0),
      2500,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomScrollView), findsOneWidget);

    controller.dispose();
  });

  testWidgets('horizontal Wrap renders and can scroll', (tester) async {
    final controller = makeController();
    await pumpHorizontalView(
      tester,
      controller: controller,
      layoutMode: PaginationLayoutMode.wrap,
    );

    expect(find.text('Item 0'), findsOneWidget);

    // Ensure trim-compensation path can run without crashing.
    await controller.loadNextPage();
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(-900, 0),
      2500,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomScrollView), findsOneWidget);

    controller.dispose();
  });
}

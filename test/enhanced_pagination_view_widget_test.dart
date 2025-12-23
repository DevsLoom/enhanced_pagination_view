import 'dart:async';

import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows initial loader, then renders items', (
    WidgetTester tester,
  ) async {
    final completer = Completer<List<String>>();
    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 2, autoLoadFirstPage: true),
      pageFetcher: (page) => completer.future,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<String>(
            controller: controller,
            enablePullToRefresh: false,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text(item),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const ['A', 'B']);
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('empty state shows default empty widget', (
    WidgetTester tester,
  ) async {
    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 20, autoLoadFirstPage: false),
      pageFetcher: (page) async => const <String>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<String>(
            controller: controller,
            enablePullToRefresh: false,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text(item),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    expect(find.text('No data available'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('first page error shows Retry and can recover', (
    WidgetTester tester,
  ) async {
    var attempts = 0;

    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 2, autoLoadFirstPage: false),
      pageFetcher: (page) async {
        attempts++;
        if (attempts == 1) throw StateError('boom');
        return const ['OK-1', 'OK-2'];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<String>(
            controller: controller,
            enablePullToRefresh: false,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text(item),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    expect(find.text('Failed to load data'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('OK-1'), findsOneWidget);
    expect(find.text('OK-2'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('next-page error shows bottom Retry and can recover', (
    WidgetTester tester,
  ) async {
    var page1Attempts = 0;

    final controller = PagingController<String>(
      config: const PagingConfig(
        pageSize: 2,
        autoLoadFirstPage: false,
        infiniteScroll: true,
      ),
      pageFetcher: (page) async {
        if (page == 0) return const ['p0-1', 'p0-2'];
        if (page == 1) {
          page1Attempts++;
          if (page1Attempts == 1) throw StateError('boom');
          return const ['p1-1', 'p1-2'];
        }
        return const <String>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              enableItemAnimations: false,
              // Disable scroll-driven auto-load; we trigger manually.
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    await controller.loadNextPage();
    await tester.pumpAndSettle();

    expect(find.text('Failed to load more items'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(page1Attempts, 2);
    expect(find.text('p1-1'), findsOneWidget);
    expect(find.text('p1-2'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('completed state shows "No more items" indicator', (
    WidgetTester tester,
  ) async {
    final controller = PagingController<String>(
      config: const PagingConfig(
        pageSize: 3,
        autoLoadFirstPage: false,
        infiniteScroll: true,
      ),
      pageFetcher: (page) async {
        if (page == 0) return const ['a', 'b', 'c'];
        // Less than pageSize => completed.
        if (page == 1) return const ['d'];
        return const <String>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              enableItemAnimations: false,
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();
    await controller.loadNextPage();
    await tester.pumpAndSettle();

    expect(find.text('No more items'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('pagination buttons mode: Next/Previous swaps pages', (
    WidgetTester tester,
  ) async {
    final controller = PagingController<String>(
      config: const PagingConfig(
        pageSize: 2,
        autoLoadFirstPage: false,
        infiniteScroll: false,
      ),
      pageFetcher: (page) async {
        if (page == 0) return const ['p0-1', 'p0-2'];
        if (page == 1) return const ['p1-1', 'p1-2'];
        return const <String>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: false,
              enableItemAnimations: false,
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();

    expect(find.text('p0-1'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('p1-1'), findsOneWidget);
    expect(find.text('Page 2'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('p0-1'), findsOneWidget);
    expect(find.text('Page 1'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('pull-to-refresh triggers controller.refresh()', (
    WidgetTester tester,
  ) async {
    var firstPageCalls = 0;

    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 2, autoLoadFirstPage: false),
      pageFetcher: (page) async {
        if (page == 0) {
          firstPageCalls++;
          return const ['x', 'y'];
        }
        return const <String>[];
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: EnhancedPaginationView<String>(
              controller: controller,
              enablePullToRefresh: true,
              enableItemAnimations: false,
              physics: const AlwaysScrollableScrollPhysics(),
              itemBuilder: (context, item, index) => Text(item),
            ),
          ),
        ),
      ),
    );

    await controller.loadFirstPage();
    await tester.pumpAndSettle();
    expect(firstPageCalls, 1);

    // Trigger RefreshIndicator.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(firstPageCalls, 2);

    controller.dispose();
  });
}

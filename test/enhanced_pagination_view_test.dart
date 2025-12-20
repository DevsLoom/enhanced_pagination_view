import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';

void main() {
  test('PagingController should initialize with correct state', () {
    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 20, autoLoadFirstPage: false),
      pageFetcher: (page) async => ['item1', 'item2'],
    );

    expect(controller.state, PagingState.initial);
    expect(controller.items, isEmpty);
    expect(controller.currentPage, 0);
    expect(controller.hasMoreData, true);

    controller.dispose();
  });

  test(
    'PagingController snapshot/restore should restore items and paging flags',
    () async {
      final controller = PagingController<String>(
        config: const PagingConfig(pageSize: 2, autoLoadFirstPage: false),
        pageFetcher: (page) async => ['p$page-1', 'p$page-2'],
        itemKeyGetter: (s) => s,
      );

      await controller.loadFirstPage();
      expect(controller.items, ['p0-1', 'p0-2']);
      expect(controller.currentPage, 0);
      expect(controller.hasMoreData, true);

      final snap = controller.snapshot();

      await controller.loadNextPage();
      expect(controller.items, ['p0-1', 'p0-2', 'p1-1', 'p1-2']);
      expect(controller.currentPage, 1);

      controller.restoreFromSnapshot(snap);
      expect(controller.items, ['p0-1', 'p0-2']);
      expect(controller.currentPage, 0);

      controller.dispose();
    },
  );

  test('PagingController analytics should emit page request/success', () async {
    final requestedPages = <int>[];
    final succeededPages = <int>[];

    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 2, autoLoadFirstPage: false),
      pageFetcher: (page) async => ['a$page', 'b$page'],
      analytics: PagingAnalytics<String>(
        onPageRequest: requestedPages.add,
        onPageSuccess: (page, items, {required isFirstPage}) {
          succeededPages.add(page);
        },
      ),
    );

    await controller.loadFirstPage();
    await controller.loadNextPage();

    expect(requestedPages, [0, 1]);
    expect(succeededPages, [0, 1]);

    controller.dispose();
  });

  test('refresh should ignore in-flight next page results', () async {
    final nextPageCompleter = Completer<List<String>>();

    final controller = PagingController<String>(
      config: const PagingConfig(pageSize: 2, autoLoadFirstPage: false),
      pageFetcher: (page) {
        if (page == 0) return Future.value(['p0-1', 'p0-2']);
        if (page == 1) return nextPageCompleter.future;
        return Future.value([]);
      },
    );

    await controller.loadFirstPage();
    expect(controller.items, ['p0-1', 'p0-2']);

    // Start next page load but do not complete it yet.
    final nextLoad = controller.loadNextPage();

    // Refresh should invalidate the in-flight next page.
    await controller.refresh();
    expect(controller.items, ['p0-1', 'p0-2']);
    expect(controller.currentPage, 0);

    // Complete the old next page request; it should be ignored.
    nextPageCompleter.complete(['stale-1', 'stale-2']);
    await nextLoad;

    expect(controller.items, ['p0-1', 'p0-2']);
    expect(controller.currentPage, 0);

    controller.dispose();
  });

  test('PagingConfig should have correct defaults', () {
    const config = PagingConfig();

    expect(config.pageSize, 20);
    expect(config.infiniteScroll, true);
    expect(config.initialPage, 0);
    expect(config.autoLoadFirstPage, true);
    expect(config.invisibleItemsThreshold, 3);
  });
}

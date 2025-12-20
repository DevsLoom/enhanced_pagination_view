// ignore_for_file: avoid_print

import 'dart:math';

import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter_test/flutter_test.dart';

class PerfItem {
  final String id;
  final int value;

  const PerfItem(this.id, this.value);

  PerfItem copyWith({int? value}) => PerfItem(id, value ?? this.value);
}

void main() {
  test(
    'PagingController perf (realistic: small pages + limited cache)',
    () async {
      // A more realistic profile:
      // - load in pages (API pagination)
      // - keep only a bounded window in memory
      // - do some typical item updates while scrolling
      const totalItems = 1 * 1000 * 1000;

      await _runRealistic(
        totalItems: totalItems,
        pageSize: 50,
        maxCachedItems: 1000,
        pagesToLoad: 2000, // 100k items traversed; cache stays at 1k.
        updatesPerPage: 20,
      );

      print('');

      await _runRealistic(
        totalItems: totalItems,
        pageSize: 100,
        maxCachedItems: 5000,
        pagesToLoad: 1000, // 100k items traversed; cache stays at 5k.
        updatesPerPage: 50,
      );

      print('');
      await _runScrollBackComparison(
        totalItems: totalItems,
        pageSize: 50,
        pagesToLoad: 500, // 25k traversed
        limitedMaxCachedItems: 1000, // 20 pages worth
      );

      print('');
      print(
        'Tip: UI smoothness for “1M+ total items” comes from bounding memory (CacheMode.limited/none) + small pages; not from holding 1,000,000 objects at once.',
      );
    },
  );

  test(
    'PagingController perf (worst-case: 1M in memory)',
    () async {
      const sizes = <int>[10 * 1000, 100 * 1000, 1000 * 1000];
      for (final size in sizes) {
        await _runForSize(size);
        print('');
      }
    },
    skip:
        'Slow + unrealistic for typical pagination UIs; run manually when needed.',
  );
}

Future<void> _runRealistic({
  required int totalItems,
  required int pageSize,
  required int maxCachedItems,
  required int pagesToLoad,
  required int updatesPerPage,
}) async {
  print(
    '=== Realistic perf (total=$totalItems, pageSize=$pageSize, cache=$maxCachedItems, pages=$pagesToLoad) ===',
  );

  final controller = PagingController<PerfItem>(
    config: PagingConfig(
      pageSize: pageSize,
      infiniteScroll: true,
      initialPage: 0,
      autoLoadFirstPage: false,
      cacheMode: CacheMode.limited,
      maxCachedItems: maxCachedItems,
    ),
    pageFetcher: (page) async {
      final start = page * pageSize;
      if (start >= totalItems) return const <PerfItem>[];
      final endExclusive = (start + pageSize) > totalItems
          ? totalItems
          : (start + pageSize);
      final len = endExclusive - start;
      return List<PerfItem>.generate(len, (i) {
        final idx = start + i;
        return PerfItem('id_$idx', idx);
      }, growable: false);
    },
    itemKeyGetter: (it) => it.id,
  );

  final rand = Random(1);

  final swFirst = Stopwatch()..start();
  await controller.loadFirstPage();
  swFirst.stop();
  print(
    'loadFirstPage: ${swFirst.elapsedMilliseconds}ms (items=${controller.itemCount})',
  );

  final swPages = Stopwatch()..start();
  final swUpdates = Stopwatch();

  int loadedPages = 0;
  while (loadedPages < pagesToLoad && controller.hasMoreData) {
    await controller.loadNextPage();
    loadedPages++;

    // Simulate typical UI operations while scrolling: update a few visible items.
    swUpdates.start();
    final count = controller.itemCount;
    if (count > 0) {
      for (int i = 0; i < updatesPerPage; i++) {
        final idx = rand.nextInt(count);
        final old = controller.items[idx];
        controller.updateItem(old.copyWith(value: old.value + 1));
      }
    }
    swUpdates.stop();
  }
  swPages.stop();

  final avgPageMs = loadedPages == 0
      ? 0
      : (swPages.elapsedMilliseconds / loadedPages).toStringAsFixed(2);
  final avgUpdatesMs = loadedPages == 0
      ? 0
      : (swUpdates.elapsedMilliseconds / loadedPages).toStringAsFixed(2);

  print(
    'loadNextPage x$loadedPages: ${swPages.elapsedMilliseconds}ms (avg ${avgPageMs}ms/page)',
  );
  print(
    'updateItem x${loadedPages * updatesPerPage}: ${swUpdates.elapsedMilliseconds}ms (avg ${avgUpdatesMs}ms/page)',
  );
  print('final cached items: ${controller.itemCount}');

  controller.dispose();
}

Future<void> _runScrollBackComparison({
  required int totalItems,
  required int pageSize,
  required int pagesToLoad,
  required int limitedMaxCachedItems,
}) async {
  print(
    '=== Scroll-back comparison (pageSize=$pageSize, pages=$pagesToLoad) ===',
  );
  await _runScrollBackCase(
    label: 'CacheMode.none',
    totalItems: totalItems,
    pageSize: pageSize,
    pagesToLoad: pagesToLoad,
    cacheMode: CacheMode.none,
    maxCachedItems: limitedMaxCachedItems,
  );
  await _runScrollBackCase(
    label: 'CacheMode.limited (max=$limitedMaxCachedItems)',
    totalItems: totalItems,
    pageSize: pageSize,
    pagesToLoad: pagesToLoad,
    cacheMode: CacheMode.limited,
    maxCachedItems: limitedMaxCachedItems,
  );
}

Future<void> _runScrollBackCase({
  required String label,
  required int totalItems,
  required int pageSize,
  required int pagesToLoad,
  required CacheMode cacheMode,
  required int maxCachedItems,
}) async {
  final controller = PagingController<PerfItem>(
    config: PagingConfig(
      pageSize: pageSize,
      infiniteScroll: true,
      initialPage: 0,
      autoLoadFirstPage: false,
      cacheMode: cacheMode,
      maxCachedItems: maxCachedItems,
    ),
    pageFetcher: (page) async {
      final start = page * pageSize;
      if (start >= totalItems) return const <PerfItem>[];
      final endExclusive = (start + pageSize) > totalItems
          ? totalItems
          : (start + pageSize);
      final len = endExclusive - start;
      return List<PerfItem>.generate(len, (i) {
        final idx = start + i;
        return PerfItem('id_$idx', idx);
      }, growable: false);
    },
    itemKeyGetter: (it) => it.id,
  );

  await controller.loadFirstPage();
  for (int i = 0; i < pagesToLoad; i++) {
    await controller.loadNextPage();
    if (!controller.hasMoreData) break;
  }

  // After scrolling forward, "scroll-back" typically targets items that are
  // still in memory. CacheMode.none keeps ~1 page; limited keeps a window.
  final int count = controller.itemCount;
  final String? currentKey = count == 0 ? null : controller.items[count - 1].id;
  final String? oldestCachedKey = count == 0 ? null : controller.items[0].id;

  bool hitCurrent = false;
  bool hitOldest = false;
  final sw = Stopwatch()..start();
  if (currentKey != null) {
    hitCurrent = controller.updateItem(PerfItem(currentKey, -1));
  }
  if (oldestCachedKey != null) {
    hitOldest = controller.updateItem(PerfItem(oldestCachedKey, -2));
  }
  sw.stop();

  print(
    '$label: cached=$count, update(current)= ${hitCurrent ? 'hit' : 'miss'}, update(oldestCached)= ${hitOldest ? 'hit' : 'miss'}, time=${sw.elapsedMicroseconds}µs',
  );

  controller.dispose();
}

Future<void> _runForSize(int size) async {
  print('=== PagingController perf (size=$size) ===');

  final items = List<PerfItem>.generate(
    size,
    (i) => PerfItem('id_$i', i),
    growable: true,
  );

  final controller = PagingController<PerfItem>(
    config: PagingConfig(
      pageSize: size,
      infiniteScroll: true,
      autoLoadFirstPage: false,
      cacheMode: CacheMode.all,
    ),
    // Return a growable list so remove/insert can mutate it.
    pageFetcher: (_) async => List<PerfItem>.of(items, growable: true),
    itemKeyGetter: (it) => it.id,
  );

  final swLoad = Stopwatch()..start();
  await controller.loadFirstPage();
  swLoad.stop();
  print('loadFirstPage: ${swLoad.elapsedMilliseconds}ms');

  final rand = Random(1);

  final swUpdate = Stopwatch()..start();
  for (int i = 0; i < 5000; i++) {
    final idx = rand.nextInt(size);
    final old = controller.items[idx];
    controller.updateItem(old.copyWith(value: old.value + 1));
  }
  swUpdate.stop();
  print('updateItem x5000: ${swUpdate.elapsedMilliseconds}ms');

  final swRemoveEnd = Stopwatch()..start();
  for (int i = 0; i < 200; i++) {
    final idx = controller.itemCount - 1 - (i % 50);
    final id = controller.items[idx].id;
    controller.removeItem(key: id);
  }
  swRemoveEnd.stop();
  print('removeItem x200 (near end): ${swRemoveEnd.elapsedMilliseconds}ms');

  final swInsertEnd = Stopwatch()..start();
  for (int i = 0; i < 200; i++) {
    controller.insertItem(controller.itemCount - 1, PerfItem('ins_end_$i', i));
  }
  swInsertEnd.stop();
  print('insertItem x200 (near end): ${swInsertEnd.elapsedMilliseconds}ms');

  controller.dispose();

  // Keep output readable between runs.
}

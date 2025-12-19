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

  test('PagingConfig should have correct defaults', () {
    const config = PagingConfig();

    expect(config.pageSize, 20);
    expect(config.infiniteScroll, true);
    expect(config.initialPage, 0);
    expect(config.autoLoadFirstPage, true);
    expect(config.invisibleItemsThreshold, 3);
  });
}

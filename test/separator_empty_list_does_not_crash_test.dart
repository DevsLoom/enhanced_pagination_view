import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('separatorBuilder does not crash with zero items', (
    tester,
  ) async {
    final controller = PagingController<int>(
      config: const PagingConfig(
        infiniteScroll: true,
        autoLoadFirstPage: false,
      ),
      itemKeyGetter: (v) => v.toString(),
      pageFetcher: (_) async => <int>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EnhancedPaginationView<int>(
            controller: controller,
            enableItemAnimations: false,
            itemBuilder: (context, item, index) => Text('item:$item'),
            separatorBuilder: (context, index) => const Divider(height: 1),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(EnhancedPaginationView<int>), findsOneWidget);
  });
}

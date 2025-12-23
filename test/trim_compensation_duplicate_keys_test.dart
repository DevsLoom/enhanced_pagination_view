import 'package:enhanced_pagination_view/enhanced_pagination_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'does not crash when compensateForTrimmedItems enabled but duplicate item keys are present',
    (tester) async {
      final controller = PagingController<int>(
        config: const PagingConfig(
          pageSize: 10,
          infiniteScroll: true,
          cacheMode: CacheMode.limited,
          maxCachedItems: 50,
          compensateForTrimmedItems: true,
          autoLoadFirstPage: true,
        ),
        itemKeyGetter: (item) => item.toString(),
        pageFetcher: (page) async {
          if (page == 0) {
            // Duplicate keys: "1" appears twice.
            return <int>[1, 1, 2, 3];
          }
          return <int>[];
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedPaginationView<int>(
              controller: controller,
              enableItemAnimations: false,
              itemBuilder: (context, item, index) =>
                  ListTile(title: Text('item:$item')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('item:1'), findsWidgets);
      expect(find.text('item:2'), findsOneWidget);
      expect(find.text('item:3'), findsOneWidget);
    },
  );
}

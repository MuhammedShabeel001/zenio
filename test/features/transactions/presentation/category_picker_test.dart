import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/transactions/domain/models/category_item_model.dart';
import 'package:zenio/features/transactions/presentation/widgets/category_picker.dart';

const _categories = [
  CategoryItemModel(id: '1', name: 'Food', emoji: '🍔'),
  CategoryItemModel(id: '2', name: 'Travel', emoji: '🚕'),
];

void main() {
  Future<List<String?>> pump(
    WidgetTester tester, {
    required String? selected,
    bool optional = false,
  }) async {
    final picked = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryPicker(
            categories: _categories,
            selected: selected,
            optional: optional,
            onSelected: picked.add,
          ),
        ),
      ),
    );
    return picked;
  }

  testWidgets('spending needs a category; tapping picks it', (tester) async {
    final picked = await pump(tester, selected: 'Food');

    expect(find.text('Category'), findsOneWidget);
    await tester.tap(find.text('Travel'));
    await tester.tap(find.text('Food'));

    // The chosen one stays chosen.
    expect(picked, ['Travel', 'Food']);
  });

  testWidgets('income may have none, and a second tap clears it',
      (tester) async {
    final picked = await pump(tester, selected: 'Food', optional: true);

    expect(find.text('Category (optional)'), findsOneWidget);
    await tester.tap(find.text('Food'));

    expect(picked, [null]);
  });

  testWidgets('screen readers hear which category is chosen, and Manage',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selected: 'Travel');

    final travel = tester.getSemantics(find.bySemanticsLabel('Travel'));
    final food = tester.getSemantics(find.bySemanticsLabel('Food'));
    expect(
      travel.getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      food.getSemanticsData().flagsCollection.isSelected,
      Tristate.isFalse,
    );
    final manage = tester.getRect(find.bySemanticsLabel('Manage categories'));
    expect(manage.height, greaterThanOrEqualTo(44));
    semantics.dispose();
  });
}

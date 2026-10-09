import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';
import 'package:zenio/features/vault/presentation/widgets/vault_note_item.dart';

void main() {
  testWidgets('the copy action has a full-size target and copies securely',
      (tester) async {
    final copied = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.auren.zenio/security'),
      (call) async {
        if (call.method == 'copySensitive') copied.add(call.arguments);
        return null;
      },
    );
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
        ..setMockMethodCallHandler(
          const MethodChannel('com.auren.zenio/security'),
          null,
        )
        ..setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: VaultNoteItem(
              note: const VaultNoteModel(
                id: 'n1',
                date: '30 Sep 2026',
                content: 'Locker PIN 4821',
              ),
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    final target = tester.getRect(find.bySemanticsLabel('Copy note'));
    final icon = tester.getRect(find.byIcon(Icons.copy_rounded));
    expect(target.width, greaterThanOrEqualTo(48));
    expect(target.height, greaterThanOrEqualTo(48));
    expect(target.contains(icon.center), isTrue);
    // The card keeps its size.
    expect(
      tester.getSize(find.byType(VaultNoteItem)).height,
      120 + 16, // card and its bottom margin
    );

    // A tap in the target but off the small icon still copies.
    await tester.tapAt(target.bottomLeft + const Offset(4, -4));
    await tester.pump();

    expect(copied, hasLength(1));
    expect((copied.single! as Map)['text'], 'Locker PIN 4821');
    expect(find.text('Note copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}

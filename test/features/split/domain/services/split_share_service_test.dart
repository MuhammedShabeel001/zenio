import 'package:flutter_test/flutter_test.dart';
import 'package:zenio/features/split/controller/split/split_state.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/features/split/domain/services/split_share_service.dart';

void main() {
  group('SplitShareService', () {
    test('generates catchy equal split message for multiple people', () {
      const state = SplitState(
        billAmount: 400,
        peopleCount: 4,
        returnersCount: 2,
        mode: SplitMode.equal,
        isLoading: false,
      );

      final message = SplitShareService.generateShareMessage(state);

      expect(message, contains('Bill Split Alert via Zenio'));
      expect(message, contains('Total Bill:* ₹400.00'));
      expect(message, contains('Split Between:* 4 people'));
      expect(message, contains('Each Person Pays:* ₹100.00'));
      expect(message, contains('Calculated smoothly with Zenio'));
    });

    test('generates catchy equal split message for single person', () {
      const state = SplitState(
        billAmount: 250,
        peopleCount: 1,
        returnersCount: 1,
        mode: SplitMode.equal,
        isLoading: false,
      );

      final message = SplitShareService.generateShareMessage(state);

      expect(message, contains('Bill Summary via Zenio'));
      expect(message, contains('Total Bill:* ₹250.00'));
      expect(message, contains('Just You:* 1 person'));
      expect(message, contains('Total Amount:* ₹250.00'));
    });

    test('generates catchy trip split message with one-way and returners', () {
      const state = SplitState(
        billAmount: 400,
        peopleCount: 4,
        returnersCount: 1,
        mode: SplitMode.trip,
        isLoading: false,
      );

      final message = SplitShareService.generateShareMessage(state);

      expect(message, contains('Road Trip Split via Zenio'));
      expect(message, contains('Total Trip Bill:* ₹400.00'));
      expect(message, contains('Total Travelers (Going):* 4'));
      expect(message, contains('Returning Crew:* 1'));
      expect(message, contains('One-Way Travelers (3):* ₹50.00 each'));
      expect(message, contains('Round-Trip Crew (1):* ₹250.00 each'));
      expect(message, contains('Calculated seamlessly with Zenio'));
    });

    test('generates trip split message when all travelers return', () {
      const state = SplitState(
        billAmount: 600,
        peopleCount: 3,
        returnersCount: 3,
        mode: SplitMode.trip,
        isLoading: false,
      );

      final message = SplitShareService.generateShareMessage(state);

      expect(message, contains('Round-Trip Crew (all 3):* ₹200.00 each'));
      expect(message, isNot(contains('One-Way Travelers')));
    });
  });
}

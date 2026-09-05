import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenio/features/split/controller/split/split_state.dart';
import 'package:zenio/features/split/domain/models/split_calculation_model.dart';
import 'package:zenio/shared/utils/alert.dart';

class SplitShareService {
  const SplitShareService();

  static final NumberFormat _currencyFormatter = NumberFormat('#,##0.00');

  static String _formatAmount(double amount, [String currencySymbol = '₹']) {
    return '$currencySymbol${_currencyFormatter.format(amount)}';
  }

  /// Generates a catchy, stylish, and informative shareable message.
  static String generateShareMessage(SplitState state, [String currencySymbol = '₹']) {
    final totalFormatted = _formatAmount(state.billAmount, currencySymbol);

    if (state.mode == SplitMode.equal) {
      return _generateEqualSplitMessage(state, totalFormatted, currencySymbol);
    } else {
      return _generateTripSplitMessage(state, totalFormatted, currencySymbol);
    }
  }

  static String _generateEqualSplitMessage(
    SplitState state,
    String totalFormatted, [
    String currencySymbol = '₹',
  ]) {
    final people = state.peopleCount;
    final eachPay = _formatAmount(state.eachPersonPay, currencySymbol);

    if (people <= 1) {
      return '''
🧾 *Bill Summary via Zenio* 💸

💰 *Total Bill:* $totalFormatted
👤 *Just You:* 1 person
👉 *Total Amount:* $totalFormatted

“Treating yourself is always worth every penny! 🥳”

⚡ *Calculated with Zenio*''';
    }

    return '''
🧾 *Bill Split Alert via Zenio* 💸

Hey squad! Here’s the clean breakdown for our bill:

💰 *Total Bill:* $totalFormatted
👥 *Split Between:* $people people
👉 *Each Person Pays:* $eachPay

━━━━━━━━━━━━━━━━━━━━━
“Good food, great laughs, zero money drama!
Let's settle up before we forget.” ✨
━━━━━━━━━━━━━━━━━━━━━
⚡ *Calculated smoothly with Zenio*''';
  }

  static String _generateTripSplitMessage(
    SplitState state,
    String totalFormatted, [
    String currencySymbol = '₹',
  ]) {
    final totalPeople = state.peopleCount;
    final returners = state.returnersCount;
    final oneWayCount = totalPeople - returners;

    final oneWayPay = _formatAmount(state.oneWayPay, currencySymbol);
    final returnersPay = _formatAmount(state.returnersPay, currencySymbol);

    final breakdown = StringBuffer();

    if (oneWayCount > 0) {
      breakdown
        ..writeln(
          '📍 *One-Way Travelers ($oneWayCount):* $oneWayPay each',
        )
        ..writeln(
          '🔁 *Round-Trip Crew ($returners):* $returnersPay each',
        );
    } else {
      breakdown.writeln(
        '🔁 *Round-Trip Crew (all $totalPeople):* $returnersPay each',
      );
    }

    return '''
🚗💨 *Road Trip Split via Zenio* 🛣️

The ride was awesome, now let's settle the tabs fairly!

💰 *Total Trip Bill:* $totalFormatted
👥 *Total Travelers (Going):* $totalPeople
🔄 *Returning Crew:* $returners

━━━━━━━━━━━━━━━━━━━━━
${breakdown.toString().trim()}
━━━━━━━━━━━━━━━━━━━━━

“Priceless memories, fair & square splits!
Drop your share & let’s hit the road again soon.” 🚀
━━━━━━━━━━━━━━━━━━━━━
⚡ *Calculated seamlessly with Zenio*''';
  }

  /// Triggers the native system share sheet.
  /// Falls back to copying to clipboard if the native platform channel is unavailable.
  /// [sharePositionOrigin] is recommended on iPad and Mac to anchor the popover.
  static Future<ShareResult?> share({
    required SplitState state,
    String currencySymbol = '₹',
    Rect? sharePositionOrigin,
  }) async {
    final message = generateShareMessage(state, currencySymbol);
    final subject = state.mode == SplitMode.equal
        ? '🧾 Bill Split breakdown'
        : '🚗 Road Trip Split breakdown';

    try {
      return await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: subject,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: message));
      Alert.showSnackBar('Split details copied to clipboard!');
      return null;
    }
  }
}

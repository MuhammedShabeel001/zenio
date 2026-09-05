import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/settings/controller/settings/settings_notifier.dart';
import 'package:zenio/shared/providers/currency_provider/currency_provider.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class CurrencyPickerBottomSheet extends ConsumerWidget {
  const CurrencyPickerBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CurrencyPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCurrency = ref.watch(currencyCodeProvider);

    final currencies = [
      _CurrencyOption(
        code: 'INR',
        name: 'Indian Rupee',
        symbol: '₹',
        bgColor: const Color(0xFFFDF3E7),
        icon: Assets.icons.currency.svg(
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFF111111),
            BlendMode.srcIn,
          ),
        ),
      ),
      _CurrencyOption(
        code: 'DLR',
        name: 'US Dollar',
        symbol: r'$',
        bgColor: const Color(0xFFE8F8F0),
        icon: const Text(
          r'$',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111111),
          ),
        ),
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          const Text(
            'Primary Currency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111111),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose your default currency across the app',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 20),

          // Currency Options
          ...currencies.map((currency) {
            final isSelected = currentCurrency.toUpperCase() == currency.code;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF9F9FB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEEEEF2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () async {
                    await ref
                        .read(settingsNotifierProvider.notifier)
                        .updatePrimaryCurrency(currency.code);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Icon Circle
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: currency.bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: currency.icon),
                        ),
                        const SizedBox(width: 14),

                        // Code & Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currency.code,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${currency.symbol})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currency.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Selection Checkmark
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD1D1D6),
                                width: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CurrencyOption {
  const _CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
    required this.bgColor,
    required this.icon,
  });

  final String code;
  final String name;
  final String symbol;
  final Color bgColor;
  final Widget icon;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/subscriptions/presentation/subscriptions/subscriptions_mobile.dart';

class SubscriptionsScreenWeb extends ConsumerStatefulWidget {
  const SubscriptionsScreenWeb({super.key});

  @override
  ConsumerState<SubscriptionsScreenWeb> createState() =>
      _SubscriptionsScreenWebState();
}

class _SubscriptionsScreenWebState
    extends ConsumerState<SubscriptionsScreenWeb> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 920),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: const SubscriptionsScreenMobile(),
        ),
      ),
    );
  }
}

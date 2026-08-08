import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/home/home.dart';
import 'package:zenio/shared/shared.dart';

export 'home_mobile.dart';
export 'home_web.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: ResponsiveWidget(
        smallScreen: HomeScreenMobile(), 
        largeScreen: HomeScreenWeb(), 
      ),
    );
  }
}

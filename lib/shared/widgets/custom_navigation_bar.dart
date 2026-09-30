import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/assets.gen.dart';
import 'package:zenio/shared/widgets/add_transaction_bottom_sheet.dart';

/// The floating tab bar with the add-transaction button in the middle.
class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({
    required this.selectedIndex,
    required this.onTabSelected,
    this.onAddTap,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onAddTap;

  static const Color _activeColor = ZenioColors.primary;
  static const Color _inactiveColor = Color(0xFF1C1C1E);
  static const double _barHeight = 60;

  /// Distance of the bar from the bottom edge: above the home indicator or
  /// gesture area where there is one.
  static double _bottomOffset(BuildContext context) =>
      math.max(25, MediaQuery.viewPaddingOf(context).bottom + 8);

  /// How much of the bottom of the screen the bar covers. Scrolling content
  /// underneath should end at least this far from the bottom.
  static double reservedHeight(BuildContext context) =>
      _barHeight + _bottomOffset(context) + 12;

  Widget _buildNavItem({
    required int index,
    required SvgGenImage iconGen,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? _activeColor : _inactiveColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: () => onTabSelected(index),
      child: InkResponse(
        onTap: () => onTabSelected(index),
        radius: 28,
        child: SizedBox(
          width: 56,
          height: _barHeight,
          child: Center(
            child: iconGen.svg(
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onAdd = onAddTap ?? () => AddTransactionBottomSheet.show(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 30,
        right: 30,
        bottom: _bottomOffset(context),
      ),
      child: SizedBox(
        height: _barHeight,
        child: Row(
          children: [
            // Left Capsule Container
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 0,
                      iconGen: Assets.icons.home,
                      label: 'Home',
                    ),
                    _buildNavItem(
                      index: 1,
                      iconGen: Assets.icons.wallet,
                      label: 'Wallets',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Center Green Floating Action Button
            Semantics(
              button: true,
              label: 'Add transaction',
              excludeSemantics: true,
              onTap: onAdd,
              child: Material(
                color: _activeColor,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onAdd,
                  child: SizedBox.square(
                    dimension: _barHeight,
                    child: Center(
                      child: Assets.icons.add.svg(
                        width: 22,
                        height: 22,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Right Capsule Container
            Expanded(
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 2,
                      iconGen: Assets.icons.analytics,
                      label: 'Analytics',
                    ),
                    _buildNavItem(
                      index: 3,
                      iconGen: Assets.icons.more,
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

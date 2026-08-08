import 'package:flutter/material.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

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

  static const Color _activeColor = Color(0xFF10B981);
  static const Color _inactiveColor = Color(0xFF1C1C1E);

  Widget _buildNavItem({
    required int index,
    required SvgGenImage iconGen,
  }) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? _activeColor : _inactiveColor;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: iconGen.svg(
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 30, bottom: 25),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Left Capsule Container
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(index: 0, iconGen: Assets.icons.home),
                    _buildNavItem(index: 1, iconGen: Assets.icons.wallet),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Center Green Floating Action Button
            GestureDetector(
              onTap: onAddTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: _activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3310B981),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
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
            const SizedBox(width: 4),

            // Right Capsule Container
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(index: 2, iconGen: Assets.icons.analytics),
                    _buildNavItem(index: 3, iconGen: Assets.icons.more),
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

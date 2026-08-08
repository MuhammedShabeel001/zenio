import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsItemTile extends StatelessWidget {
  const SettingsItemTile({
    required this.title,
    required this.icon,
    this.trailing,
    this.badgeText,
    this.isSwitch = false,
    this.switchValue = false,
    this.onSwitchChanged,
    this.onTap,
    this.iconBgColor = const Color(0xFFF2F2F5),
    this.isDestructive = false,
    super.key,
  });

  final String title;
  final Widget icon;
  final Widget? trailing;
  final String? badgeText;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final VoidCallback? onTap;
  final Color iconBgColor;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isSwitch ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Icon Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 14),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? const Color(0xFF111111)
                          : const Color(0xFF111111),
                    ),
                  ),
                ),

                // Trailing Widget
                if (isSwitch)
                  CupertinoSwitch(
                    value: switchValue,
                    activeTrackColor: const Color(0xFF10B981),
                    onChanged: onSwitchChanged,
                  )
                else if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      badgeText!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  )
                else if (trailing != null)
                  trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

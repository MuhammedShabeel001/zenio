import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zenio/shared/shared.dart';

class SettingsItemTile extends StatelessWidget {
  const SettingsItemTile({
    required this.title,
    required this.icon,
    this.subtitle,
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

  /// A short explanation under the title.
  final String? subtitle;
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
    // A switch row is one item for screen readers: its title names the
    // switch ("Vault Lock, off").
    final tile = LayoutBuilder(builder: _buildTile);
    return isSwitch ? MergeSemantics(child: tile) : tile;
  }

  Widget _buildTile(BuildContext context, BoxConstraints constraints) {
    // On a narrow row with large text, a picker goes under the title rather
    // than squeezing it to a few letters per line.
    final stacked = trailing != null &&
        !isSwitch &&
        badgeText == null &&
        constraints.maxWidth < MediaQuery.textScalerOf(context).scale(280);
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: isSwitch
              ? (onSwitchChanged != null
                  ? () => onSwitchChanged!(!switchValue)
                  : null)
              : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 20, 5),
            child: Row(
              children: [
                // 60x60 Circle Badge (Exact match to Subscriptions, Debts, Transactions)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 14),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDestructive
                              ? ZenioColors.danger
                              : const Color(0xFF000000),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: ZenioFontSizes.caption,
                            color: ZenioColors.textSecondary,
                          ),
                        ),
                      ],
                      if (stacked) ...[
                        const SizedBox(height: ZenioSpacing.sm),
                        trailing!,
                      ],
                    ],
                  ),
                ),

                // Trailing Widget
                if (isSwitch)
                  CupertinoSwitch(
                    value: switchValue,
                    activeTrackColor: ZenioColors.primary,
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText!,
                      style: AppFonts.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textSecondary,
                      ),
                    ),
                  )
                else if (trailing != null && !stacked)
                  trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

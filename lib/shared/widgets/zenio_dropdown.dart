import 'package:flutter/material.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';
import 'package:zenio/shared/utils/app_fonts.dart';
import 'package:zenio/shared/utils/assets.gen.dart';

class ZenioDropdownItem<T> {
  const ZenioDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.trailing,
    this.labelColor,
    this.subtitleColor,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final Color? labelColor;
  final Color? subtitleColor;
}

class ZenioDropdown<T> extends StatelessWidget {
  const ZenioDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.leadingIcon,
    this.label,
    this.hintText,
    this.trailing,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    super.key,
  });

  final T value;
  final List<ZenioDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Widget? leadingIcon;

  /// Says what the field is for, shown before the chosen value ("From").
  final String? label;
  final String? hintText;
  final Widget? trailing;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final selectedItem = items.cast<ZenioDropdownItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;

        return Theme(
          data: Theme.of(context).copyWith(
            cardColor: Colors.white,
            popupMenuTheme: const PopupMenuThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 10,
            ),
          ),
          child: PopupMenuButton<T>(
            tooltip: '',
            offset: const Offset(0, 56),
            elevation: 10,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE5E5EA), width: 1.2),
            ),
            constraints: BoxConstraints(
              minWidth: menuWidth,
              maxWidth: menuWidth,
              maxHeight: 280,
            ),
            padding: EdgeInsets.zero,
            onSelected: onChanged,
            itemBuilder: (context) {
              return items.map((item) {
                final isSelected = item.value == value;
                return PopupMenuItem<T>(
                  value: item.value,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? ZenioColors.fieldFill : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          item.icon!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _LabelAndSubtitle(
                            label: item.label,
                            labelStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: item.labelColor ??
                                  ZenioColors.textPrimary,
                            ),
                            subtitle: item.subtitle,
                            subtitleStyle: AppFonts.numeric(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: item.subtitleColor ??
                                  ZenioColors.textSecondary,
                            ),
                          ),
                        ),
                        if (item.trailing != null) ...[
                          const SizedBox(width: 8),
                          item.trailing!,
                        ],
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: ZenioColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList();
            },
            child: Container(
              margin: margin,
              padding: padding,
              decoration: BoxDecoration(
                color: ZenioColors.fieldFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: 12),
                  ],
                  if (label != null) ...[
                    Text(
                      label!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ZenioColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: _LabelAndSubtitle(
                      label: selectedItem?.label ?? hintText ?? '',
                      labelStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selectedItem != null
                            ? (selectedItem.labelColor ??
                                ZenioColors.textPrimary)
                            : ZenioColors.textPlaceholder,
                      ),
                      subtitle: selectedItem?.subtitle,
                      subtitleStyle: AppFonts.numeric(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selectedItem?.subtitleColor ??
                            ZenioColors.textSecondary,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ],
                  Assets.icons.dropDown.svg(
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      ZenioColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A choice's name and, in brackets, its detail (such as a wallet's balance).
/// The detail goes under the name when both do not fit on one line, so the
/// name is not squeezed out and the amount is never cut short.
class _LabelAndSubtitle extends StatelessWidget {
  const _LabelAndSubtitle({
    required this.label,
    required this.labelStyle,
    required this.subtitle,
    required this.subtitleStyle,
  });

  final String label;
  final TextStyle labelStyle;
  final String? subtitle;
  final TextStyle subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final name = Text(
      label,
      style: labelStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (subtitle == null) return name;
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [name, Text('($subtitle)', style: subtitleStyle)],
    );
  }
}

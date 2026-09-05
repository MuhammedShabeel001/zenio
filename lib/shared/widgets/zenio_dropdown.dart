import 'package:flutter/material.dart';
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
    this.hintText,
    this.trailing,
    this.margin = const EdgeInsets.only(bottom: 6),
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    super.key,
  });

  final T value;
  final List<ZenioDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final Widget? leadingIcon;
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
                      color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          item.icon!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: item.labelColor ?? const Color(0xFF111111),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.subtitle != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: item.subtitleColor ?? const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                        if (item.trailing != null) ...[
                          const SizedBox(width: 8),
                          item.trailing!,
                        ],
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: Color(0xFF10B981),
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
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      selectedItem?.label ?? hintText ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selectedItem != null
                            ? (selectedItem.labelColor ?? const Color(0xFF111111))
                            : const Color(0xFF9E9EA5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[
                    trailing!,
                    const SizedBox(width: 8),
                  ] else if (selectedItem?.subtitle != null) ...[
                    Text(
                      selectedItem!.subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selectedItem.subtitleColor ?? const Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Assets.icons.dropDown.svg(
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF111111),
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

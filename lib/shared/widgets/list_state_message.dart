import 'package:flutter/material.dart';
import 'package:zenio/shared/theme/zenio_tokens.dart';

/// What a list shows instead of items: that it is loading, that it could not
/// be loaded, or that it is empty (what is missing, why, and what to do).
class ListStateMessage extends StatelessWidget {
  const ListStateMessage({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : _loading = false;

  /// Shown while the items are being read.
  const ListStateMessage.loading({super.key})
      : title = '',
        message = null,
        icon = Icons.hourglass_empty_rounded,
        actionLabel = null,
        onAction = null,
        _loading = true;

  /// Shown when the items could not be read, with a way to try again.
  const ListStateMessage.error({
    required VoidCallback onRetry,
    String this.message = 'Please try again.',
    super.key,
  })  : title = "Couldn't load this",
        icon = Icons.error_outline_rounded,
        actionLabel = 'Try again',
        onAction = onRetry,
        _loading = false;

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: ZenioColors.primary,
              semanticsLabel: 'Loading',
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEDEDF0),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: const Color(0xFF6E6E73)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ZenioColors.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF6E6E73),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

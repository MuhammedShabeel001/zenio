import 'package:flutter/material.dart';
import 'package:zenio/shared/services/secure_platform.dart';

/// Covers the whole app, dialogs and sheets included, while a sensitive
/// screen (the Vault) is open and the app is not in the foreground. That
/// keeps it out of the iOS app switcher; Android also uses FLAG_SECURE.
class PrivacyShield extends StatefulWidget {
  const PrivacyShield({required this.child, super.key});

  final Widget child;

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield>
    with WidgetsBindingObserver {
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inForeground = state == AppLifecycleState.resumed;
    if (inForeground != _inForeground) {
      setState(() => _inForeground = inForeground);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        SecurePlatform.sensitiveScreenOpen,
        SecurePlatform.coverUntilClosed,
      ]),
      builder: (context, child) {
        final cover = SecurePlatform.sensitiveScreenOpen.value &&
            (!_inForeground || SecurePlatform.coverUntilClosed.value);
        return Stack(
          children: [
            child!,
            if (cover)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 40,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

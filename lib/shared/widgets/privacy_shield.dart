import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  bool _rebuildScheduled = false;

  final Listenable _protection = Listenable.merge([
    SecurePlatform.sensitiveScreenOpen,
    SecurePlatform.coverUntilClosed,
  ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _protection.addListener(_onProtectionChanged);
  }

  @override
  void dispose() {
    _protection.removeListener(_onProtectionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The Vault holds and releases its protection from `initState` and
  /// `dispose`, while the frame is being built, when this ancestor cannot
  /// rebuild. The change is then shown once the frame is done.
  void _onProtectionChanged() {
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      setState(() {});
      return;
    }
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    scheduler.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) setState(() {});
    });
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
    final cover = SecurePlatform.sensitiveScreenOpen.value &&
        (!_inForeground || SecurePlatform.coverUntilClosed.value);
    return Stack(
      children: [
        widget.child,
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
  }
}

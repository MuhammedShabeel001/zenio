import 'package:app/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hancod_theme/hancod_theme.dart';

class NoInternet extends StatelessWidget {
  const NoInternet({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ooops!',
                  style: AppText.heading3,
                ),
                const SizedBox(height: 40),
                const Text(
                  "You're offline",
                  textAlign: TextAlign.center,
                  style: AppText.heading5,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: AppText.largeM,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppButton(
              onPress: () {
                Navigator.of(context).pop();
              },
              label: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget to display the upgrade dialog.
/// Override the [createState] method to provide a custom class
/// with overridden methods.
class NoInternetAlert extends ConsumerStatefulWidget {
  /// Creates a new [NoInternetAlert].
  const NoInternetAlert({
    super.key,
    this.barrierDismissible = true,
    this.dialogKey,
    this.navigatorKey,
    this.child,
  });

  /// The `barrierDismissible` argument is used to indicate whether tapping
  ///  on the barrier will dismiss the dialog. (default: false)
  final bool barrierDismissible;

  /// The [Key] assigned to the dialog when it is shown.
  final GlobalKey? dialogKey;

  /// For use by the Router architecture as part of the RouterDelegate.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The [child] contained by the widget.
  final Widget? child;

  @override
  UpgradeAlertState createState() => UpgradeAlertState();
}

/// The [NoInternetAlert] widget state.
class UpgradeAlertState extends ConsumerState<NoInternetAlert> {
  /// Is the alert dialog being displayed right now?
  bool displayed = false;

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    final checkContext = widget.navigatorKey != null &&
            widget.navigatorKey!.currentContext != null
        ? widget.navigatorKey!.currentContext!
        : context;
    ref.listen(
      connectivityProvider.select((value) => value),
      (previous, next) {
        switch (next) {
          // Display all the messages in a scrollable list view.
          case AsyncData(:final value):
            if (!value) {
              showDialog<void>(
                context: checkContext,
                barrierDismissible: widget.barrierDismissible,
                builder: (context) {
                  return const NoInternet();
                },
              );
            }
          case AsyncError(:final error):
            debugPrint('Internet Error $error');
        }
      },
    );

    return widget.child ?? const SizedBox.shrink();
  }

  void popNavigator(BuildContext context) {
    Navigator.of(context).pop();
    displayed = false;
  }
}

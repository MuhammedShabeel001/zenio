import 'package:hancod_theme/hancod_theme.dart';
import 'package:zenio/shared/shared.dart';

class Alert {
  static void showSnackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
  }) {
    final zType = switch (type) {
      SnackBarType.success => ZenioSnackBarType.success,
      SnackBarType.error => ZenioSnackBarType.error,
      SnackBarType.warning => ZenioSnackBarType.warning,
      SnackBarType.info => ZenioSnackBarType.info,
    };
    ZenioSnackBar.show(AppRouter.rootContext, message: message, type: zType);
  }
}

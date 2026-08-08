import 'package:app/shared/shared.dart';
import 'package:hancod_theme/hancod_theme.dart';

class Alert {
  static void showSnackBar(
    String message, {
    SnackBarType type = SnackBarType.info,
  }) {
    AppRouter.rootContext.showSnackBar(message, type: type);
  }
}

import 'package:app/app/app.dart';
import 'package:app/bootstrap.dart';
import 'package:app/env.dart';
// import 'package:app/firebase_options_prod.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:scaled_app/scaled_app.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  tz.initializeTimeZones();

  // for scaling purposes, if required use the below code
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (deviceSize) {
      const widthOfDesign = 375;
      return deviceSize.width / widthOfDesign;
    },
  );

  // In case ScaledWidgetsFlutterBinding is not used
  // WidgetsFlutterBinding.ensureInitialized();

  // For analytics
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Used to remove trailing # in urls
  setUrlStrategy(const PathUrlStrategy());

  // Envrionment
  const env = StagingEnv();

  await bootstrap(() => App(environment: env));
}

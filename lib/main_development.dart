// import 'package:zenio/firebase_options_dev.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
// import 'package:scaled_app/scaled_app.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:zenio/app/app.dart';
import 'package:zenio/bootstrap.dart';
import 'package:zenio/env.dart';

Future<void> main() async {
  tz.initializeTimeZones();

  // for scaling purposes, if required use the below code
  // ScaledWidgetsFlutterBinding.ensureInitialized(
  //   scaleFactor: (deviceSize) {
  //     const widthOfDesign = 375;
  //     return deviceSize.width / widthOfDesign;
  //   },
  // );

  // In case ScaledWidgetsFlutterBinding is not used
  WidgetsFlutterBinding.ensureInitialized();

  // For analytics
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Used to remove trailing # in urls
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());

  // Envrionment
  const env = DevelopmentEnv();

  await bootstrap(() => App(environment: env));
}

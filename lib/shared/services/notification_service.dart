// // Copyright 2025. All rights reserved.

// import 'dart:async';
// import 'dart:convert';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:http/http.dart' as http;

// import 'package:app/firebase_options_dev.dart' as dev;
// import 'package:app/firebase_options_prod.dart' as prod;

// /// A service to handle Firebase Cloud Messaging (FCM) notifications
// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();

//   /// Singleton instance of the notification service
//   factory NotificationService() => _instance;

//   NotificationService._internal();

//   /// Firebase Messaging instance
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

//   /// Stream controller for messages
//   final StreamController<RemoteMessage> _messageStreamController =
//       StreamController<RemoteMessage>.broadcast();

//   /// Stream of incoming messages
//   Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

//   /// The current FCM token
//   String? _token;

//   /// Get the current FCM token
//   String? get token => _token;

//   /// Android notification channel
//   late AndroidNotificationChannel _channel;

//   /// Flutter local notifications plugin
//   late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

//   /// Flag to track if local notifications are initialized
//   bool _isFlutterLocalNotificationsInitialized = false;

//   /// Initialize the notification service
//   Future<void> initialize() async {
//     // Initialize Firebase
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );

//     // Set background message handler
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     // Setup local notifications for non-web platforms
//     if (!kIsWeb) {
//       await _setupFlutterNotifications();
//     }

//     // Listen for incoming foreground messages
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showFlutterNotification(message);
//       _messageStreamController.add(message);
//     });

//     // Listen for messages when app is opened from terminated state
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//       _messageStreamController.add(message);
//     });

//     // Get initial message if app was opened from a notification
//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((RemoteMessage? message) {
//       if (message != null) {
//         _messageStreamController.add(message);
//       }
//     });

//     // Get and monitor FCM token
//     _getToken();
//     _monitorToken();
//   }

//   /// Setup Flutter local notifications
//   Future<void> _setupFlutterNotifications() async {
//     if (_isFlutterLocalNotificationsInitialized) {
//       return;
//     }

//     _channel = const AndroidNotificationChannel(
//       'high_importance_channel', // id
//       'High Importance Notifications', // title
//       description:
//           'This channel is used for important notifications.', // description
//       importance: Importance.high,
//     );

//     _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

//     // Create an Android Notification Channel
//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(_channel);

//     // Update iOS foreground notification presentation options
//     await _firebaseMessaging.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     _isFlutterLocalNotificationsInitialized = true;
//   }

//   /// Show a local notification for a remote message
//   void _showFlutterNotification(RemoteMessage message) {
//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;

//     if (notification != null && android != null && !kIsWeb) {
//       _flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             _channel.id,
//             _channel.name,
//             channelDescription: _channel.description,
//             icon: 'launch_background',
//           ),
//         ),
//       );
//     }
//   }

//   /// Get the current FCM token
//   Future<String?> _getToken() async {
//     try {
//       _token = await _firebaseMessaging.getToken();
//       return _token;
//     } catch (e) {
//       debugPrint('Failed to get FCM token: $e');
//       return null;
//     }
//   }

//   /// Monitor token refreshes
//   void _monitorToken() {
//     _firebaseMessaging.onTokenRefresh.listen((String newToken) {
//       _token = newToken;
//     });
//   }

//   /// Request notification permissions
//   Future<NotificationSettings> requestPermissions({
//     bool alert = true,
//     bool announcement = false,
//     bool badge = true,
//     bool carPlay = false,
//     bool criticalAlert = false,
//     bool provisional = false,
//     bool sound = true,
//   }) async {
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: alert,
//       announcement: announcement,
//       badge: badge,
//       carPlay: carPlay,
//       criticalAlert: criticalAlert,
//       provisional: provisional,
//       sound: sound,
//     );

//     return settings;
//   }

//   /// Get current notification settings
//   Future<NotificationSettings> getNotificationSettings() async {
//     return await _firebaseMessaging.getNotificationSettings();
//   }

//   /// Subscribe to a topic
//   Future<void> subscribeToTopic(String topic) async {
//     await _firebaseMessaging.subscribeToTopic(topic);
//   }

//   /// Unsubscribe from a topic
//   Future<void> unsubscribeFromTopic(String topic) async {
//     await _firebaseMessaging.unsubscribeFromTopic(topic);
//   }

//   /// Get APNs token (iOS only)
//   Future<String?> getAPNSToken() async {
//     if (defaultTargetPlatform == TargetPlatform.iOS ||
//         defaultTargetPlatform == TargetPlatform.macOS) {
//       return await _firebaseMessaging.getAPNSToken();
//     }
//     return null;
//   }

//   /// Send a test FCM message (for development purposes)
//   Future<void> sendPushMessage({String? customToken, String? serverUrl}) async {
//     final String? tokenToUse = customToken ?? _token;

//     if (tokenToUse == null) {
//       debugPrint('Unable to send FCM message, no token exists.');
//       return;
//     }

//     try {
//       final url = serverUrl ?? 'https://api.rnfirebase.io/messaging/send';
//       await http.post(
//         Uri.parse(url),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode({
//           'token': tokenToUse,
//           'data': {
//             'via': 'NotificationService',
//             'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
//           },
//           'notification': {
//             'title': 'Test Notification',
//             'body': 'This is a test notification sent from NotificationService',
//           },
//         }),
//       );

//       debugPrint('FCM request for device sent!');
//     } catch (e) {
//       debugPrint('Error sending FCM message: $e');
//     }
//   }

//   /// Dispose resources
//   void dispose() {
//     _messageStreamController.close();
//   }
// }

// /// Background message handler that must be top-level function
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   // Initialize the notification service
//   await NotificationService()._setupFlutterNotifications();
//   NotificationService()._showFlutterNotification(message);

//   debugPrint('Handling a background message ${message.messageId}');
// }

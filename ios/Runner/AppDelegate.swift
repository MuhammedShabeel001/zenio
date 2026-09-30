import Flutter
import UIKit
import UserNotifications
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets flutter_local_notifications receive reminder taps and show
    // reminders while the app is open (see its README).
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ZenioSecurity") {
      ZenioSecurityChannel.register(with: registrar.messenger())
    }
  }
}

/// Native helpers for the vault. Must match `SecurePlatform` in Dart.
enum ZenioSecurityChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.aurea.zenio/security",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "copySensitive":
        let args = call.arguments as? [String: Any]
        let text = args?["text"] as? String ?? ""
        let seconds = args?["clearAfterSeconds"] as? Int ?? 60
        // Expires on its own (even if Zenio is killed) and never syncs to
        // other devices through Universal Clipboard.
        UIPasteboard.general.setItems(
          [[UTType.utf8PlainText.identifier: text]],
          options: [
            .localOnly: true,
            .expirationDate: Date().addingTimeInterval(TimeInterval(seconds)),
          ]
        )
        result(nil)
      case "setSecureScreen":
        // iOS has no screenshot flag; the vault covers its content whenever
        // the app is not active, which also hides it in the app switcher.
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

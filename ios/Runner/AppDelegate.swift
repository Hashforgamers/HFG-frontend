import Flutter
import UIKit
import GoogleMaps
import FBSDKCoreKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, MessagingDelegate {
  private let metaAppEventsChannelName = "com.hfg.hash/meta_app_events"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    ApplicationDelegate.shared.initializeSDK()
    Settings.shared.graphAPIVersion = "v24.0"
    Settings.shared.isAutoLogAppEventsEnabled = true
    Settings.shared.isAdvertiserIDCollectionEnabled = true

    GMSServices.provideAPIKey("AIzaSyDjaI5XOoq4r0AbJVfDSz9tiQqLGBC_yNU")
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "pem_channel", binaryMessenger: controller.binaryMessenger)
    let metaChannel = FlutterMethodChannel(
      name: metaAppEventsChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getPrivateKey":
        if let key = self?.readPemFile(named: "flutter_private", withExtension: "pem") {
          result(key)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "Private key not found", details: nil))
        }

      case "getPublicKey":
        if let key = self?.readPemFile(named: "public_key", withExtension: "pem") {
          result(key)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "Public key not found", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    metaChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "activateApp":
        let arguments = call.arguments as? [String: Any] ?? [:]
        if let applicationId = arguments["applicationId"] as? String, !applicationId.isEmpty {
          AppEvents.shared.loggingOverrideAppID = applicationId
        }
        AppEvents.shared.activateApp()
        result(nil)

      case "logEvent":
        let arguments = call.arguments as? [String: Any] ?? [:]
        guard let eventName = arguments["name"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Event name is required", details: nil))
          return
        }

        let rawParams = arguments["parameters"] as? [String: Any] ?? [:]
        let parameters: [AppEvents.ParameterName: Any] = Dictionary(
          uniqueKeysWithValues: rawParams.map { key, value in
            (AppEvents.ParameterName(key), value)
          }
        )

        if let valueToSum = arguments["_valueToSum"] as? Double {
          AppEvents.shared.logEvent(AppEvents.Name(eventName), valueToSum: valueToSum, parameters: parameters)
        } else {
          AppEvents.shared.logEvent(AppEvents.Name(eventName), parameters: parameters)
        }
        result(nil)

      case "setAdvertiserTracking":
        let arguments = call.arguments as? [String: Any] ?? [:]
        let enabled = arguments["enabled"] as? Bool ?? false
        let collectId = arguments["collectId"] as? Bool ?? true
        Settings.shared.isAdvertiserTrackingEnabled = enabled
        Settings.shared.isAdvertiserIDCollectionEnabled = enabled && collectId
        result(nil)

      case "setGraphApiVersion":
        guard let version = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Graph API version string is required", details: nil))
          return
        }
        Settings.shared.graphAPIVersion = version
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Remote notification registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let fcmToken {
      print("FCM registration token refreshed: \(fcmToken)")
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .badge, .sound])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if ApplicationDelegate.shared.application(app, open: url, options: options) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  private func readPemFile(named: String, withExtension: String) -> String? {
    if let filePath = Bundle.main.path(forResource: named, ofType: withExtension) {
      do {
        let contents = try String(contentsOfFile: filePath, encoding: .utf8)
        return contents
      } catch {
        print("Error reading PEM file: \(error)")
      }
    }
    return nil
  }
}

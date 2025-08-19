import Flutter
import UIKit
import GoogleMaps
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    GMSServices.provideAPIKey("AIzaSyDjaI5XOoq4r0AbJVfDSz9tiQqLGBC_yNU")

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "pem_channel", binaryMessenger: controller.binaryMessenger)

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

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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

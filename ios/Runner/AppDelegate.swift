import Flutter
import UIKit
import GoogleMaps   // keep this so the SDK links correctly

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?

  ) -> Bool {
      GMSServices.provideAPIKey("AIzaSyDjaI5XOoq4r0AbJVfDSz9tiQqLGBC_yNU")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

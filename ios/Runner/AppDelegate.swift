import Flutter
import UIKit
import GoogleMaps   // keep this so the SDK links correctly

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?

  ) -> Bool {
      GMSServices.provideAPIKey("AIzaSyCXO-uoxj4l3avsid_N5rxUDRbSPK0z2B0")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

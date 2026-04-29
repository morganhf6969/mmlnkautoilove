import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // Tenuto come variabile di istanza per evitare che venga deallocato
  private var sharingChannel: FlutterMethodChannel?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MemoLinkSharingPlugin") else {
      return
    }

    let channel = FlutterMethodChannel(
      name: "com.memolink.sharing/channel",
      binaryMessenger: registrar.messenger()
    )
    // IMPORTANTE: salviamo il riferimento per evitare la deallocazione
    self.sharingChannel = channel

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "getSharedUrl" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let defaults = UserDefaults(suiteName: "group.com.memolink.sharing"),
         let sharedUrl = defaults.string(forKey: "shared_url") {
        defaults.removeObject(forKey: "shared_url")
        defaults.synchronize()
        result(sharedUrl)
      } else {
        result(nil)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "memolink" {
      sharingChannel?.invokeMethod("openFromShare", arguments: nil)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

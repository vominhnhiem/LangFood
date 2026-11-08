import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var sellerPlayer: AVAudioPlayer?
  private var sellerHaptics: [DispatchWorkItem] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let sellerChannel = FlutterMethodChannel(
      name: "langfood/seller_order_alert",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    sellerChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "play":
        do {
          try self.playSellerAlert()
          result(nil)
        } catch {
          result(FlutterError(code: "seller_alert", message: error.localizedDescription, details: nil))
        }
      case "stop":
        self.stopSellerAlert()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func playSellerAlert() throws {
    stopSellerAlert()
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    for delay in [0, 280, 560] {
      let impact = DispatchWorkItem { generator.impactOccurred() }
      sellerHaptics.append(impact)
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay), execute: impact)
    }

    let key = FlutterDartProject.lookupKey(forAsset: "assets/audio/seller_new_order.wav")
    guard let url = Bundle.main.url(forResource: key, withExtension: nil) else {
      throw CocoaError(.fileNoSuchFile)
    }
    try AVAudioSession.sharedInstance().setCategory(.ambient)
    let player = try AVAudioPlayer(contentsOf: url)
    sellerPlayer = player
    player.play()
  }

  private func stopSellerAlert() {
    sellerPlayer?.stop()
    sellerPlayer = nil
    sellerHaptics.forEach { $0.cancel() }
    sellerHaptics.removeAll()
  }
}

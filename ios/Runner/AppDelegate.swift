import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DreamSpaceNativeTabs") {
      registrar.register(DreamTabFactory(messenger: registrar.messenger()),
                         withId: "dreamspace/native-tabs")
    }
  }
}

// Kept in the Runner source already registered with Xcode's Sources build phase.
final class DreamTabFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64,
              arguments args: Any?) -> FlutterPlatformView {
    DreamNativeTabs(frame: frame, id: viewId, messenger: messenger,
                    configuration: args as? [String: Any] ?? [:])
  }
}

final class DreamNativeTabs: NSObject, FlutterPlatformView {
  private let root: UIView
  private let effect = UIVisualEffectView()
  private let stack = UIStackView()
  private let channel: FlutterMethodChannel
  private var buttons: [UIButton] = []
  private var configuration: [String: Any] = [:]

  init(frame: CGRect, id: Int64, messenger: FlutterBinaryMessenger,
       configuration: [String: Any]) {
    root = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "dreamspace/native-tabs/\(id)",
                                   binaryMessenger: messenger)
    super.init()
    root.backgroundColor = .clear
    effect.translatesAutoresizingMaskIntoConstraints = false
    effect.layer.cornerRadius = 34
    effect.layer.borderWidth = 0.5
    effect.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
    effect.layer.cornerCurve = .continuous
    effect.clipsToBounds = true
    root.addSubview(effect)
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.spacing = 2
    effect.contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      effect.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      effect.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      effect.topAnchor.constraint(equalTo: root.topAnchor),
      effect.bottomAnchor.constraint(equalTo: root.bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: effect.contentView.leadingAnchor, constant: 5),
      stack.trailingAnchor.constraint(equalTo: effect.contentView.trailingAnchor, constant: -5),
      stack.topAnchor.constraint(equalTo: effect.contentView.topAnchor, constant: 5),
      stack.bottomAnchor.constraint(equalTo: effect.contentView.bottomAnchor, constant: -5)
    ])
    let symbols = ["house.fill", "book.closed.fill", "map.fill", "person.fill"]
    for (index, symbol) in symbols.enumerated() {
      let button = UIButton(type: .system)
      button.tag = index
      if #available(iOS 15.0, *) {
      var config = UIButton.Configuration.plain()
      config.image = UIImage(systemName: symbol)
      config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 25, weight: .medium)
      config.imagePlacement = .top
      config.imagePadding = 3
      config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 1, bottom: 4, trailing: 1)
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var outgoing = incoming
        outgoing.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        return outgoing
      }
      button.configuration = config
      } else {
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        button.tintColor = .label
      }
      button.layer.cornerRadius = 26
      button.layer.cornerCurve = .continuous
      button.addTarget(self, action: #selector(selectTab(_:)), for: .touchUpInside)
      stack.addArrangedSubview(button)
      buttons.append(button)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      if call.method == "update", let config = call.arguments as? [String: Any] {
        self.update(config)
        result(nil)
      } else { result(FlutterMethodNotImplemented) }
    }
    NotificationCenter.default.addObserver(self, selector: #selector(accessibilityChanged),
      name: UIAccessibility.reduceTransparencyStatusDidChangeNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(accessibilityChanged),
      name: UIAccessibility.darkerSystemColorsStatusDidChangeNotification, object: nil)
    update(configuration)
  }

  func view() -> UIView { root }

  private func update(_ config: [String: Any]) {
    configuration = config
    root.overrideUserInterfaceStyle = (config["dark"] as? Bool ?? true) ? .dark : .light
    let opaque = (config["opaque"] as? Bool ?? false)
      || UIAccessibility.isReduceTransparencyEnabled || UIAccessibility.isDarkerSystemColorsEnabled
    effect.backgroundColor = opaque ? .secondarySystemBackground : .clear
    if opaque {
      effect.effect = nil
    } else if #available(iOS 26.0, *) {
      let glass = UIGlassEffect(style: .regular)
      // The shared background must not compete with its UIButton children.
      glass.isInteractive = false
      effect.effect = glass
    } else {
      effect.effect = UIBlurEffect(style: .systemMaterial)
    }
    let labels = config["labels"] as? [String] ?? ["Home", "Journal", "Map", "Profile"]
    let selected = config["index"] as? Int ?? 0
    for (index, button) in buttons.enumerated() {
      let title = labels.indices.contains(index) ? labels[index] : ""
      if #available(iOS 15.0, *) {
      var appearance = button.configuration
      appearance?.title = title
      appearance?.baseForegroundColor = .label
      button.configuration = appearance
      } else {
        button.setTitle(title, for: .normal)
      }
      button.backgroundColor = index == selected
        ? UIColor(red: 0.65, green: 0.58, blue: 0.96, alpha: 0.16) : .clear
      button.layer.borderWidth = index == selected ? 0.7 : 0
      button.layer.borderColor = UIColor(red: 0.72, green: 0.65, blue: 1, alpha: 0.4).cgColor
      button.accessibilityLabel = title
      button.accessibilityTraits = index == selected ? [.button, .selected] : [.button]
    }
  }

  @objc private func selectTab(_ sender: UIButton) {
    var next = configuration
    next["index"] = sender.tag
    update(next)
    channel.invokeMethod("select", arguments: sender.tag)
  }
  @objc private func accessibilityChanged() { update(configuration) }
  deinit {
    NotificationCenter.default.removeObserver(self)
    channel.setMethodCallHandler(nil)
  }
}

import Flutter
import UIKit
import UserNotifications
import CoreHaptics

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var presentations: DreamPresentations?
  private var launchHaptics: DreamLaunchHaptics?
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
      registrar.register(DreamGlassFactory(messenger: registrar.messenger()),
                         withId: "dreamspace/native-glass")
      presentations = DreamPresentations(messenger: registrar.messenger())
      launchHaptics = DreamLaunchHaptics(messenger: registrar.messenger())
    }
  }
}

/// A quiet, audio-free tactile envelope synchronized with the crescent fill.
/// Flutter starts this once; no per-frame messages or repeating vibration timers.
final class DreamLaunchHaptics: NSObject {
  private let channel: FlutterMethodChannel
  private var engine: CHHapticEngine?
  private var player: CHHapticPatternPlayer?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dreamspace/launch-haptics", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(false); return }
      switch call.method {
      case "prepare": result(self.prepare())
      case "play":
        let options = call.arguments as? [String: Any] ?? [:]
        self.play(duration: (options["duration"] as? NSNumber)?.doubleValue ?? 1.75,
                   reduced: options["reducedMotion"] as? Bool ?? false)
        result(nil)
      case "stop": self.stop(); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    NotificationCenter.default.addObserver(self, selector: #selector(backgrounded),
      name: UIApplication.willResignActiveNotification, object: nil)
  }

  private func prepare() -> Bool {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
          UIApplication.shared.applicationState == .active else { return false }
    do {
      if engine == nil {
        let next = try CHHapticEngine()
        next.playsHapticsOnly = true
        next.isAutoShutdownEnabled = true
        next.resetHandler = { [weak self] in
          DispatchQueue.main.async { self?.player = nil; self?.engine = nil }
        }
        engine = next
      }
      try engine?.start()
      return true
    } catch { stop(); return false }
  }

  /// A "dream heartbeat": three soft transient taps land where the crescent
  /// visibly crosses its fill milestones, and a rounded continuous swell
  /// breathes underneath them, rising with the water level and fading before
  /// the final tap. Sharpness stays low so the whole envelope feels organic
  /// rather than mechanical.
  private func play(duration requested: Double, reduced: Bool) {
    guard requested.isFinite, engine != nil,
          UIApplication.shared.applicationState == .active else { return }
    let duration = min(2.2, max(1, requested))
    func tap(_ time: Double, _ intensity: Float, sharpness: Float = 0.12) -> CHHapticEvent {
      CHHapticEvent(eventType: .hapticTransient, parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
      ], relativeTime: time)
    }
    // Milestones match the crescent painter: fill begins ~0.09, crests ~0.55,
    // completes ~0.82 of the launch timeline.
    var events: [CHHapticEvent] = [
      tap(duration * 0.10, 0.32),
      tap(duration * 0.50, 0.46),
      tap(duration * 0.82, 0.60, sharpness: 0.2)
    ]
    var curves: [CHHapticParameterCurve] = []
    if !reduced {
      // Soft heartbeat-echo after the crest, before the final tap.
      events.append(tap(duration * 0.56, 0.18))
      events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
      ], relativeTime: duration * 0.12, duration: duration * 0.52))
      // The swell breathes: in, hold, out — like a sleeping rhythm.
      curves = [CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
        .init(relativeTime: 0, value: 0),
        .init(relativeTime: duration * 0.16, value: 0.42),
        .init(relativeTime: duration * 0.34, value: 0.50),
        .init(relativeTime: duration * 0.46, value: 0.28),
        .init(relativeTime: duration * 0.55, value: 0.16),
        .init(relativeTime: duration * 0.58, value: 0.0),
        .init(relativeTime: duration * 0.60, value: 1),
        .init(relativeTime: duration * 0.66, value: 0.55),
        .init(relativeTime: duration * 0.76, value: 0.0),
        .init(relativeTime: duration * 0.78, value: 1)
      ], relativeTime: duration * 0.12)]
    } else {
      // Reduce Motion keeps meaning without the wave: quieter, crisper taps.
      events = [tap(duration * 0.10, 0.18, sharpness: 0.16),
                tap(duration * 0.82, 0.26, sharpness: 0.24)]
    }
    do {
      let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
      player = try engine?.makePlayer(with: pattern)
      try player?.start(atTime: CHHapticTimeImmediate)
    } catch { stop() }
  }

  private func stop() {
    try? player?.stop(atTime: CHHapticTimeImmediate)
    player = nil
    engine?.stop(completionHandler: nil)
    engine = nil
  }
  @objc private func backgrounded() { stop() }
  deinit {
    NotificationCenter.default.removeObserver(self)
    stop()
    channel.setMethodCallHandler(nil)
  }
}

/// System modal presentation keeps menus, alerts and pickers in UIKit's material
/// hierarchy instead of drawing a Cupertino-shaped Flutter overlay.
final class DreamPresentations {
  private let channel: FlutterMethodChannel
  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dreamspace/presentation", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.present(call, result: result)
    }
  }
  private func present(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let config = call.arguments as? [String: Any],
          let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows }).first(where: { $0.isKeyWindow }),
          var presenter = window.rootViewController else {
      result(FlutterError(code: "no_presenter", message: "No active window", details: nil))
      return
    }
    while let presented = presenter.presentedViewController { presenter = presented }
    let style: UIUserInterfaceStyle = (config["dark"] as? Bool ?? true) ? .dark : .light
    let title = config["title"] as? String
    let message = config["message"] as? String
    if call.method == "date" {
      let picker = DreamDateController(configuration: config, result: result)
      let navigation = UINavigationController(rootViewController: picker)
      navigation.overrideUserInterfaceStyle = style
      navigation.modalPresentationStyle = .pageSheet
      if #available(iOS 15.0, *), let sheet = navigation.sheetPresentationController {
        sheet.detents = [.medium()]
        sheet.prefersGrabberVisible = true
      }
      presenter.present(navigation, animated: !UIAccessibility.isReduceMotionEnabled)
      navigation.presentationController?.delegate = picker
      return
    }
    if call.method == "filters" {
      let filters = DreamFiltersController(configuration: config, result: result)
      let navigation = UINavigationController(rootViewController: filters)
      navigation.overrideUserInterfaceStyle = style
      navigation.modalPresentationStyle = .pageSheet
      if #available(iOS 15.0, *), let sheet = navigation.sheetPresentationController {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
      }
      presenter.present(navigation, animated: !UIAccessibility.isReduceMotionEnabled)
      navigation.presentationController?.delegate = filters
      return
    }
    let sheet = call.method == "actions"
    let alert = UIAlertController(title: title, message: message, preferredStyle: sheet ? .actionSheet : .alert)
    alert.overrideUserInterfaceStyle = style
    var completed = false
    let complete: (Any?) -> Void = { [weak alert] value in
      guard !completed else { return }
      completed = true
      guard let alert = alert else { result(value); return }
      alert.dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { result(value) }
    }
    switch call.method {
    case "actions":
      for action in config["actions"] as? [[String: Any]] ?? [] {
        alert.addAction(UIAlertAction(title: action["label"] as? String,
          style: (action["destructive"] as? Bool ?? false) ? .destructive : .default) { _ in
          complete(action["id"] as? String)
        })
      }
      alert.addAction(UIAlertAction(title: config["cancel"] as? String, style: .cancel) { _ in complete(nil) })
    case "confirm":
      alert.addAction(UIAlertAction(title: config["cancel"] as? String, style: .cancel) { _ in complete(false) })
      alert.addAction(UIAlertAction(title: config["accept"] as? String, style: .destructive) { _ in complete(true) })
    case "prompt":
      alert.addTextField { field in
        field.text = config["value"] as? String
        field.autocapitalizationType = .sentences
        field.clearButtonMode = .whileEditing
      }
      alert.addAction(UIAlertAction(title: config["cancel"] as? String, style: .cancel) { _ in complete(nil) })
      alert.addAction(UIAlertAction(title: config["accept"] as? String, style: .default) { [weak alert] _ in
        complete(alert?.textFields?.first?.text)
      })
    case "alert":
      alert.addAction(UIAlertAction(title: config["close"] as? String, style: .default) { _ in complete(nil) })
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    // Action sheets on iPad need an anchor; use the bottom center of the active view.
    if let popover = alert.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.maxY - 60, width: 1, height: 1)
    }
    presenter.present(alert, animated: !UIAccessibility.isReduceMotionEnabled)
  }
}

class DreamSheetController: UIViewController, UIAdaptivePresentationControllerDelegate {
  let configuration: [String: Any]
  private var completion: FlutterResult?
  var english: Bool { configuration["language"] as? String == "en" }
  init(configuration: [String: Any], result: @escaping FlutterResult) {
    self.configuration = configuration
    completion = result
    super.init(nibName: nil, bundle: nil)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: english ? "Cancel" : "Отмена", style: .plain,
      target: self, action: #selector(cancel))
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: english ? "Done" : "Готово", style: .done,
      target: self, action: #selector(done))
  }
  func finish(_ value: Any?) {
    guard let complete = completion else { return }
    completion = nil
    // Return only after dismissing so Flutter may immediately push a route or share.
    dismiss(animated: !UIAccessibility.isReduceMotionEnabled) { complete(value) }
  }
  @objc func cancel() { finish(nil) }
  @objc func done() { finish(nil) }
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    completion?(nil)
    completion = nil
  }
}

final class DreamDateController: DreamSheetController {
  private let picker = UIDatePicker()
  override func viewDidLoad() {
    super.viewDidLoad()
    let mode = configuration["mode"] as? String ?? "dateAndTime"
    title = mode == "time" ? (english ? "Reminder time" : "Время напоминания") : (english ? "Dream date" : "Дата сна")
    picker.datePickerMode = mode == "time" ? .time : mode == "date" ? .date : .dateAndTime
    if #available(iOS 13.4, *) { picker.preferredDatePickerStyle = .wheels }
    picker.locale = Locale(identifier: english ? "en_GB" : "ru_RU")
    if let milliseconds = configuration["initial"] as? NSNumber {
      picker.date = Date(timeIntervalSince1970: milliseconds.doubleValue / 1000)
    }
    if mode != "time" { picker.minimumDate = Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1)) }
    if let maximum = configuration["maximum"] as? NSNumber {
      picker.maximumDate = Date(timeIntervalSince1970: maximum.doubleValue / 1000)
    }
    picker.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(picker)
    NSLayoutConstraint.activate([
      picker.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      picker.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      picker.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
    ])
  }
  @objc override func done() { finish(Int64(picker.date.timeIntervalSince1970 * 1000)) }
}

final class DreamFiltersController: DreamSheetController {
  private let sort = UISegmentedControl()
  private let moods = UIPickerView()
  private let categories = UIPickerView()
  private var moodLabels: [String] = []
  private var categoryLabels: [String] = []
  override func viewDidLoad() {
    super.viewDidLoad()
    title = english ? "Journal options" : "Параметры дневника"
    moodLabels = configuration["moods"] as? [String] ?? []
    categoryLabels = configuration["categories"] as? [String] ?? []
    let sortTitles: [String] = english
      ? ["Newest first", "Oldest first"]
      : ["Сначала новые", "Сначала старые"]
    for index in sortTitles.indices {
      sort.insertSegment(withTitle: sortTitles[index], at: index, animated: false)
    }
    sort.selectedSegmentIndex = (configuration["oldest"] as? Bool ?? false) ? 1 : 0
    for picker in [moods, categories] { picker.dataSource = self; picker.delegate = self }
    moods.selectRow(configuration["moodIndex"] as? Int ?? 0, inComponent: 0, animated: false)
    categories.selectRow(configuration["categoryIndex"] as? Int ?? 0, inComponent: 0, animated: false)
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scroll)
    scroll.addSubview(stack)
    func label(_ title: String) -> UILabel {
      let label = UILabel()
      label.text = title
      label.font = .preferredFont(forTextStyle: .headline)
      label.adjustsFontForContentSizeCategory = true
      return label
    }
    let reset = UIButton(type: .system)
    reset.setTitle(english ? "Reset filters" : "Сбросить фильтры", for: .normal)
    reset.addTarget(self, action: #selector(resetFilters), for: .touchUpInside)
    let controls: [UIView] = [label(english ? "Sort by date" : "Порядок записей"), sort,
                  label(english ? "Mood" : "Настроение"), moods,
                  label(english ? "Category" : "Категория"), categories, reset]
    for child in controls {
      stack.addArrangedSubview(child)
    }
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
      sort.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
      moods.heightAnchor.constraint(equalToConstant: max(130, UIFont.preferredFont(forTextStyle: .body).lineHeight * 6)),
      categories.heightAnchor.constraint(equalToConstant: max(130, UIFont.preferredFont(forTextStyle: .body).lineHeight * 6)),
      reset.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
    ])
  }
  @objc private func resetFilters() {
    sort.selectedSegmentIndex = 0
    moods.selectRow(0, inComponent: 0, animated: !UIAccessibility.isReduceMotionEnabled)
    categories.selectRow(0, inComponent: 0, animated: !UIAccessibility.isReduceMotionEnabled)
  }
  @objc override func done() {
    finish(["oldest": sort.selectedSegmentIndex == 1,
            "moodIndex": moods.selectedRow(inComponent: 0),
            "categoryIndex": categories.selectedRow(inComponent: 0)])
  }
}

extension DreamFiltersController: UIPickerViewDataSource, UIPickerViewDelegate {
  func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    pickerView === moods ? moodLabels.count : categoryLabels.count
  }
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    let label = (view as? UILabel) ?? UILabel()
    label.text = (pickerView === moods ? moodLabels : categoryLabels)[row]
    label.textAlignment = .center
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .body)
    label.adjustsFontForContentSizeCategory = true
    return label
  }
  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    max(44, UIFont.preferredFont(forTextStyle: .body).lineHeight * 2)
  }
}

// These types stay in Runner's existing Sources entry so both CI providers build them.
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

/// A real tab bar owns the selection lens, SF Symbols, accessibility and gestures.
/// Do not wrap it in a second glass effect or clip its system-drawn floating shape.
final class DreamTabHost: UIView {
  let bar = UITabBar()
  var heightChanged: ((CGFloat) -> Void)?
  private var reportedHeight: CGFloat = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    clipsToBounds = false
    addSubview(bar)
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func layoutSubviews() {
    super.layoutSubviews()
    // Ask UIKit for its own height, including the home indicator and compact
    // landscape metrics, rather than forcing a cropped 76-point capsule.
    bar.frame = bounds
    bar.layoutIfNeeded()
    let height = bar.sizeThatFits(bounds.size).height
    bar.frame = CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
    if height > 0 && abs(height - reportedHeight) > 0.5 {
      reportedHeight = height
      heightChanged?(height)
    }
  }
  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    setNeedsLayout()
  }
}

final class DreamNativeTabs: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let root: DreamTabHost
  private var bar: UITabBar { root.bar }
  private let channel: FlutterMethodChannel
  private var configuration: [String: Any] = [:]
  private var labels: [String] = []
  private var lastOpaque: Bool?

  init(frame: CGRect, id: Int64, messenger: FlutterBinaryMessenger,
       configuration: [String: Any]) {
    root = DreamTabHost(frame: frame)
    channel = FlutterMethodChannel(name: "dreamspace/native-tabs/\(id)",
                                   binaryMessenger: messenger)
    super.init()
    root.heightChanged = { [weak self] height in
      self?.channel.invokeMethod("height", arguments: Double(height))
    }
    bar.delegate = self
    bar.isTranslucent = true
    bar.tintColor = .label
    bar.unselectedItemTintColor = .secondaryLabel
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "update", let config = call.arguments as? [String: Any] {
        self?.update(config)
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
    if lastOpaque != opaque {
      // Preserve UIKit's default iOS 26 appearance. Only override for accessibility.
      let appearance = UITabBarAppearance()
      if opaque { appearance.configureWithOpaqueBackground() }
      else { appearance.configureWithDefaultBackground() }
      bar.standardAppearance = appearance
      if #available(iOS 15.0, *) { bar.scrollEdgeAppearance = appearance }
      lastOpaque = opaque
    }
    let nextLabels = config["labels"] as? [String] ?? ["Home", "Journal", "Map", "Profile"]
    if labels != nextLabels {
      labels = nextLabels
      let symbols = ["house.fill", "book.closed.fill", "map.fill", "person.fill"]
      bar.setItems(labels.enumerated().map { index, title in
        UITabBarItem(title: title, image: UIImage(systemName: symbols[index]), tag: index)
      }, animated: false)
    }
    let index = config["index"] as? Int ?? 0
    if let items = bar.items, items.indices.contains(index) { bar.selectedItem = items[index] }
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    configuration["index"] = item.tag
    channel.invokeMethod("select", arguments: item.tag)
  }
  @objc private func accessibilityChanged() { update(configuration) }
  deinit {
    NotificationCenter.default.removeObserver(self)
    channel.setMethodCallHandler(nil)
  }
}

final class DreamGlassFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64,
              arguments args: Any?) -> FlutterPlatformView {
    DreamNativeGlass(frame: frame, id: viewId, messenger: messenger,
                     configuration: args as? [String: Any] ?? [:])
  }
}

/// System controls get iOS 26's glass interactions automatically. Older iOS uses
/// the corresponding native controls and system material, with no shader imitation.
final class DreamNativeGlass: NSObject, FlutterPlatformView {
  private let root: UIView
  private let channel: FlutterMethodChannel
  private let kind: String
  private let button = UIButton(type: .system)
  private let toggle = UISwitch()
  private let segments = UISegmentedControl()
  private let slider = UISlider()
  private let effect = UIVisualEffectView()
  private var configuration: [String: Any] = [:]
  private var segmentLabels: [String] = []
  private var lastMaterial: String?
  private let accent = UIColor(red: 0.40, green: 0.32, blue: 0.72, alpha: 1)

  init(frame: CGRect, id: Int64, messenger: FlutterBinaryMessenger,
       configuration: [String: Any]) {
    root = UIView(frame: frame)
    kind = configuration["kind"] as? String ?? "surface"
    channel = FlutterMethodChannel(name: "dreamspace/native-glass/\(id)",
                                   binaryMessenger: messenger)
    super.init()
    root.backgroundColor = .clear
    let content: UIView
    switch kind {
    case "button":
      content = button
      button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    case "switch":
      content = toggle
      toggle.onTintColor = accent
      toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
    case "segments":
      content = segments
      segments.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    case "slider":
      content = slider
      slider.minimumTrackTintColor = accent
      slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    default:
      content = effect
      root.isUserInteractionEnabled = false
      root.accessibilityElementsHidden = true
    }
    content.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(content)
    if kind == "switch" {
      NSLayoutConstraint.activate([
        content.centerXAnchor.constraint(equalTo: root.centerXAnchor),
        content.centerYAnchor.constraint(equalTo: root.centerYAnchor)
      ])
    } else {
      NSLayoutConstraint.activate([
        content.leadingAnchor.constraint(equalTo: root.leadingAnchor),
        content.trailingAnchor.constraint(equalTo: root.trailingAnchor),
        content.topAnchor.constraint(equalTo: root.topAnchor),
        content.bottomAnchor.constraint(equalTo: root.bottomAnchor)
      ])
    }
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "update", let config = call.arguments as? [String: Any] {
        self?.update(config)
        result(nil)
      } else { result(FlutterMethodNotImplemented) }
    }
    for name in [UIAccessibility.reduceTransparencyStatusDidChangeNotification,
                 UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
                 UIAccessibility.reduceMotionStatusDidChangeNotification] {
      NotificationCenter.default.addObserver(self, selector: #selector(accessibilityChanged),
                                             name: name, object: nil)
    }
    update(configuration)
  }

  func view() -> UIView { root }

  private func update(_ config: [String: Any]) {
    configuration = config
    root.overrideUserInterfaceStyle = (config["dark"] as? Bool ?? true) ? .dark : .light
    let opaque = (config["opaque"] as? Bool ?? false)
      || UIAccessibility.isReduceTransparencyEnabled || UIAccessibility.isDarkerSystemColorsEnabled
    let reduced = (config["reducedMotion"] as? Bool ?? false) || UIAccessibility.isReduceMotionEnabled
    let enabled = config["enabled"] as? Bool ?? true
    let label = config["label"] as? String ?? ""
    let scale = CGFloat((config["textScale"] as? NSNumber)?.doubleValue ?? 1)
    switch kind {
    case "button":
      let prominent = config["prominent"] as? Bool ?? false
      let selected = config["selected"] as? Bool ?? false
      if #available(iOS 15.0, *) {
        var appearance: UIButton.Configuration
        if !(config["glass"] as? Bool ?? true) {
          appearance = .plain()
        } else if #available(iOS 26.0, *), !opaque {
          appearance = prominent ? .prominentGlass() : .glass()
        } else {
          appearance = prominent ? .filled() : .gray()
        }
        appearance.cornerStyle = .capsule
        appearance.baseForegroundColor = prominent ? .white : .label
        if prominent { appearance.baseBackgroundColor = accent }
        let symbol = config["symbol"] as? String
        appearance.image = symbol.flatMap { UIImage(systemName: $0) }
          ?? (selected ? UIImage(systemName: "checkmark") : nil)
        appearance.imagePadding = 8
        appearance.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 19 * min(scale, 1.5), weight: .medium)
        appearance.title = symbol == nil || (config["showIconLabel"] as? Bool ?? false) ? label : nil
        appearance.showsActivityIndicator = config["busy"] as? Bool ?? false
        appearance.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
          var outgoing = incoming
          outgoing.font = UIFont.systemFont(ofSize: 14 * scale, weight: .semibold)
          return outgoing
        }
        appearance.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        button.configuration = appearance
      } else {
        if let symbol = config["symbol"] as? String {
          button.setImage(UIImage(systemName: symbol), for: .normal)
          button.setTitle(nil, for: .normal)
        } else { button.setTitle(label, for: .normal) }
        button.backgroundColor = prominent ? accent : .secondarySystemBackground
        button.layer.cornerRadius = 24
      }
      button.isEnabled = enabled
      button.isSelected = selected
      button.accessibilityLabel = label
      button.accessibilityTraits = selected ? [.button, .selected] : [.button]
    case "switch":
      toggle.isEnabled = enabled
      toggle.setOn(config["value"] as? Bool ?? false, animated: false)
      toggle.accessibilityLabel = label
    case "segments":
      let titles = config["labels"] as? [String] ?? []
      if segmentLabels != titles {
        segmentLabels = titles
        segments.removeAllSegments()
        for (index, title) in titles.enumerated() {
          segments.insertSegment(withTitle: title, at: index, animated: false)
        }
      }
      segments.selectedSegmentIndex = config["index"] as? Int ?? 0
      segments.isEnabled = enabled
      segments.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 14 * scale, weight: .medium)], for: .normal)
    case "slider":
      slider.minimumValue = 0
      slider.maximumValue = 100
      slider.value = (config["value"] as? NSNumber)?.floatValue ?? 0
      slider.isEnabled = enabled
      slider.accessibilityLabel = label
    default:
      let radius = CGFloat((config["radius"] as? NSNumber)?.doubleValue ?? 24)
      if #available(iOS 26.0, *) {
        effect.cornerConfiguration = .corners(radius: .fixed(Double(radius)))
      } else {
        effect.layer.cornerRadius = radius
        effect.layer.cornerCurve = .continuous
        effect.clipsToBounds = true
      }
      let material = "\(opaque)-\(reduced)"
      if lastMaterial != material {
        effect.backgroundColor = opaque ? .secondarySystemBackground : .clear
        if opaque { effect.effect = nil }
        else if #available(iOS 26.0, *) {
          let glass = UIGlassEffect(style: .regular)
          glass.isInteractive = false
          effect.effect = glass
        } else { effect.effect = UIBlurEffect(style: .systemMaterial) }
        lastMaterial = material
      }
    }
  }

  @objc private func buttonTapped() { channel.invokeMethod("change", arguments: true) }
  @objc private func toggleChanged() { channel.invokeMethod("change", arguments: toggle.isOn) }
  @objc private func segmentChanged() { channel.invokeMethod("change", arguments: segments.selectedSegmentIndex) }
  @objc private func sliderChanged() {
    let value = (slider.value / 5).rounded() * 5
    slider.value = value
    channel.invokeMethod("change", arguments: Int(value))
  }
  @objc private func accessibilityChanged() { update(configuration) }
  deinit {
    NotificationCenter.default.removeObserver(self)
    channel.setMethodCallHandler(nil)
  }
}

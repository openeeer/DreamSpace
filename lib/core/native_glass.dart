import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

bool get usesNativeGlass =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// UIKit draws and handles the control, including its interactive glass.
/// [sizingChild] only measures the Flutter layout; it never paints or handles taps.
class NativeGlassControl extends ConsumerStatefulWidget {
  const NativeGlassControl({
    super.key,
    required this.kind,
    required this.properties,
    required this.sizingChild,
    this.onChanged,
    this.interactive = true,
  });

  final String kind;
  final Map<String, Object> properties;
  final Widget sizingChild;
  final ValueChanged<Object?>? onChanged;
  final bool interactive;

  @override
  ConsumerState<NativeGlassControl> createState() => _NativeGlassControlState();
}

class _NativeGlassControlState extends ConsumerState<NativeGlassControl> {
  MethodChannel? channel;

  Map<String, Object> configuration(BuildContext context) => {
    ...widget.properties,
    'kind': widget.kind,
    'dark': Theme.of(context).brightness == Brightness.dark,
    'opaque':
        ref.read(settingsProvider)['opaque'] == 'true' ||
        MediaQuery.highContrastOf(context),
    'reducedMotion':
        MediaQuery.disableAnimationsOf(context) ||
        ref.read(settingsProvider)['animations'] == 'reduced',
    'textScale': MediaQuery.textScalerOf(context).scale(14) / 14,
  };

  @override
  void dispose() {
    channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(settingsProvider);
    final config = configuration(context);
    // Send after build, including inherited theme, locale and accessibility changes.
    final currentChannel = channel;
    if (currentChannel != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && channel == currentChannel) {
          currentChannel.invokeMethod<void>('update', config);
        }
      });
    }
    Widget platform = UiKitView(
      viewType: 'dreamspace/native-glass',
      creationParams: config,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: widget.interactive
          ? {Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)}
          : const {},
      onPlatformViewCreated: (id) {
        if (!mounted) return;
        channel = MethodChannel('dreamspace/native-glass/$id');
        channel!.setMethodCallHandler((call) async {
          if (mounted && call.method == 'change') {
            widget.onChanged?.call(call.arguments);
          }
        });
        // Creation may finish after a rebuild; update to the latest configuration.
        if (mounted) {
          channel!.invokeMethod<void>('update', configuration(context));
        }
      },
    );
    if (!widget.interactive) {
      platform = IgnorePointer(child: ExcludeSemantics(child: platform));
    }
    return Stack(
      fit: StackFit.passthrough,
      children: [
        ExcludeSemantics(
          child: IgnorePointer(
            child: Opacity(opacity: 0, child: widget.sizingChild),
          ),
        ),
        Positioned.fill(child: platform),
      ],
    );
  }
}

String? nativeSymbol(IconData? icon) => {
  CupertinoIcons.back: 'chevron.left',
  CupertinoIcons.chevron_left: 'chevron.left',
  CupertinoIcons.chevron_right: 'chevron.right',
  CupertinoIcons.heart: 'heart',
  CupertinoIcons.heart_fill: 'heart.fill',
  CupertinoIcons.pencil: 'pencil',
  CupertinoIcons.trash: 'trash',
  CupertinoIcons.ellipsis: 'ellipsis',
  CupertinoIcons.calendar: 'calendar',
  CupertinoIcons.add: 'plus',
  CupertinoIcons.gear: 'gearshape',
  CupertinoIcons.line_horizontal_3: 'line.3.horizontal',
  CupertinoIcons.arrow_up_left_arrow_down_right:
      'arrow.up.left.and.arrow.down.right',
  CupertinoIcons.xmark: 'xmark',
  CupertinoIcons.xmark_circle_fill: 'xmark.circle.fill',
  CupertinoIcons.slider_horizontal_3: 'slider.horizontal.3',
  CupertinoIcons.sparkles: 'sparkles',
  CupertinoIcons.moon_fill: 'moon.fill',
}[icon];

class NativeGlassButton extends StatelessWidget {
  const NativeGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.prominent = false,
    this.selected = false,
    this.busy = false,
    this.showIconLabel = false,
    this.glass = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool prominent, selected, busy, showIconLabel, glass;

  @override
  Widget build(BuildContext context) => NativeGlassControl(
    kind: 'button',
    properties: {
      'label': label,
      'symbol': ?nativeSymbol(icon),
      'enabled': onPressed != null,
      'prominent': prominent,
      'selected': selected,
      'busy': busy,
      'showIconLabel': showIconLabel,
      'glass': glass,
    },
    onChanged: (_) => onPressed?.call(),
    sizingChild: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      child: nativeSymbol(icon) == null || showIconLabel
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected || showIconLabel) ...[
                    Icon(icon ?? CupertinoIcons.check_mark, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(label, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            )
          : const SizedBox(width: 44, height: 44),
    ),
  );
}

/// A native material behind Flutter content, reserved for floating panels.
class NativeGlassBackdrop extends StatelessWidget {
  const NativeGlassBackdrop({super.key, required this.child, this.radius = 24});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: NativeGlassControl(
          kind: 'surface',
          properties: {'radius': radius},
          interactive: false,
          sizingChild: const SizedBox.expand(),
        ),
      ),
      child,
    ],
  );
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design.dart';
import 'native_glass.dart';

/// UIKit owns the material and controls on iOS; Flutter owns navigation state.
class DreamTabBar extends StatefulWidget {
  const DreamTabBar({
    super.key,
    required this.index,
    required this.labels,
    required this.onSelected,
    required this.opaque,
  });
  final int index;
  final List<String> labels;
  final ValueChanged<int> onSelected;
  final bool opaque;

  @override
  State<DreamTabBar> createState() => _DreamTabBarState();
}

class _DreamTabBarState extends State<DreamTabBar> {
  MethodChannel? channel;
  double? nativeHeight;

  Map<String, Object> get configuration => {
    'index': widget.index,
    'labels': widget.labels,
    'dark': Theme.of(context).brightness == Brightness.dark,
    'opaque': widget.opaque || MediaQuery.highContrastOf(context),
  };

  @override
  void didUpdateWidget(covariant DreamTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    channel?.invokeMethod<void>('update', configuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    channel?.invokeMethod<void>('update', configuration);
  }

  @override
  void dispose() {
    channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (usesNativeGlass) {
      return SizedBox(
        height: nativeHeight ?? 84 + MediaQuery.viewPaddingOf(context).bottom,
        child: UiKitView(
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
          },
          viewType: 'dreamspace/native-tabs',
          creationParams: configuration,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (id) {
            if (!mounted) return;
            channel = MethodChannel('dreamspace/native-tabs/$id');
            channel!.setMethodCallHandler((call) async {
              if (mounted && call.method == 'select' && call.arguments is int) {
                widget.onSelected(call.arguments as int);
              } else if (mounted &&
                  call.method == 'height' &&
                  call.arguments is num) {
                final height = (call.arguments as num).toDouble();
                if (height.isFinite &&
                    height >= 44 &&
                    height <= 180 &&
                    height != nativeHeight) {
                  setState(() => nativeHeight = height);
                }
              }
            });
            channel!.invokeMethod<void>('update', configuration);
          },
        ),
      );
    }
    const icons = [
      CupertinoIcons.house,
      CupertinoIcons.book,
      CupertinoIcons.map,
      CupertinoIcons.person,
    ];
    final light = Theme.of(context).brightness == Brightness.light;
    final accent = Theme.of(context).colorScheme.primary;
    final unselected = light
        ? const Color(0xff152a38).withValues(alpha: .45)
        : Palette.secondary;
    return DreamSurface(
      glass: true,
      radius: 30,
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < widget.labels.length; i++)
            Expanded(
              child: Semantics(
                selected: widget.index == i,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.onSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      // Selected tab: a bioluminescent well of jade light.
                      color: widget.index == i
                          ? (light
                                ? const Color(0xff2e7d64).withValues(alpha: .12)
                                : const Color(0xff9fe8c8).withValues(alpha: .12))
                          : null,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Filled symbol for the selected tab (HIG), tinted;
                        // unselected stay quiet and neutral.
                        AnimatedScale(
                          scale: widget.index == i ? 1.08 : 1,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            icons[i],
                            size: 24,
                            color: widget.index == i ? accent : unselected,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: widget.index == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: widget.index == i ? accent : unselected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

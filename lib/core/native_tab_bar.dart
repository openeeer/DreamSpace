import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design.dart';

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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        height: 62,
        child: UiKitView(
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
          },
          viewType: 'dreamspace/native-tabs',
          creationParams: configuration,
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (id) {
            channel = MethodChannel('dreamspace/native-tabs/$id');
            channel!.setMethodCallHandler((call) async {
              if (mounted && call.method == 'select' && call.arguments is int) {
                widget.onSelected(call.arguments as int);
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
    return DreamSurface(
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
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: widget.index == i
                          ? Palette.lavender.withValues(alpha: .16)
                          : null,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[i],
                          size: 21,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface,
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

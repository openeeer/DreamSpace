import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import 'design.dart';

abstract final class InternalStyle {
  static const gutter = 22.0, radius = 28.0, maxWidth = 620.0;
  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Palette.secondary
      : const Color(0xff595573);
  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Palette.lavender
      : const Color(0xff6652b8);
}

void dreamSelection(WidgetRef ref) {
  if (ref.read(settingsProvider)['haptics'] != 'false') {
    HapticFeedback.selectionClick();
  }
}

enum DreamGlass { panel, control, navigation, modal, selected }

class DreamGlassSurface extends ConsumerWidget {
  const DreamGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = InternalStyle.radius,
    this.preset = DreamGlass.panel,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final DreamGlass preset;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = Theme.of(context).brightness == Brightness.light;
    final opaque =
        ref.watch(settingsProvider)['opaque'] == 'true' ||
        MediaQuery.highContrastOf(context);
    final selected = preset == DreamGlass.selected;
    final border = BorderRadius.circular(radius);
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? [
                  Colors.white.withValues(alpha: opaque ? 1 : .88),
                  const Color(0xffe6e1f5).withValues(alpha: opaque ? 1 : .83),
                ]
              : [
                  (selected ? const Color(0xff6952b1) : Palette.raised)
                      .withValues(
                        alpha: opaque
                            ? 1
                            : selected
                            ? .68
                            : .48,
                      ),
                  Palette.surface.withValues(alpha: opaque ? 1 : .38),
                ],
        ),
        border: Border.all(
          color: InternalStyle.accent(context).withValues(
            alpha: opaque
                ? .65
                : selected
                ? .75
                : .32,
          ),
          width: .8,
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
    // One blur per panel; bubbles and switches only tint their existing surface.
    if (!opaque) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: content,
      );
    }
    content = ClipRRect(borderRadius: border, child: content);
    if (onTap != null) {
      content = CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          dreamSelection(ref);
          onTap!();
        },
        child: content,
      );
    }
    return DefaultTextStyle.merge(
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'Inter',
      ),
      child: content,
    );
  }
}

class DreamGlassAction extends ConsumerWidget {
  const DreamGlassAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.prominent = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool prominent;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Tooltip(
    message: label,
    child: Opacity(
      opacity: onPressed == null ? .45 : 1,
      child: DreamGlassSurface(
        padding: EdgeInsets.zero,
        radius: 25,
        preset: prominent ? DreamGlass.selected : DreamGlass.control,
        child: CupertinoButton(
          padding: icon == null
              ? const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
              : EdgeInsets.zero,
          minimumSize: const Size(48, 48),
          onPressed: onPressed == null
              ? null
              : () {
                  dreamSelection(ref);
                  onPressed!();
                },
          child: icon == null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : Icon(
                  icon,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
        ),
      ),
    ),
  );
}

class DreamInternalHeader extends StatelessWidget {
  const DreamInternalHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBack,
    this.backLabel,
    this.compact = false,
  });
  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final String? backLabel;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: InternalStyle.gutter,
      vertical: 12,
    ),
    child: LayoutBuilder(
      builder: (context, c) {
        final back = DreamGlassAction(
          label:
              backLabel ?? MaterialLocalizations.of(context).backButtonTooltip,
          icon: CupertinoIcons.back,
          onPressed:
              onBack ??
              () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
        );
        final large = MediaQuery.textScalerOf(context).scale(16) > 22;
        final titleWidget = Text(
          title,
          textAlign: TextAlign.center,
          style: display(
            compact || actions.isNotEmpty
                ? 25
                : c.maxWidth < 340
                ? 32
                : 40,
          ),
        );
        if (large || actions.length > 1) {
          return Column(
            children: [
              Row(
                children: [
                  back,
                  const Spacer(),
                  for (final action in actions) Flexible(child: action),
                ],
              ),
              const SizedBox(height: 12),
              titleWidget,
            ],
          );
        }
        final side = actions.isEmpty ? 52.0 : actions.length * 52.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: side + 6),
              child: titleWidget,
            ),
            Align(alignment: Alignment.centerLeft, child: back),
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ],
        );
      },
    ),
  );
}

class DreamInternalPage extends StatelessWidget {
  const DreamInternalPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.backLabel,
    this.compact = false,
    this.hero,
  });
  final String title;
  final String? subtitle, backLabel;
  final List<Widget> children, actions;
  final VoidCallback? onBack;
  final bool compact;
  final Widget? hero;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Palette.night.withValues(alpha: .12),
                      Colors.transparent,
                      Palette.night.withValues(alpha: .08),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 260,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white],
                  ).createShader(r),
                  child: Opacity(
                    opacity: Theme.of(context).brightness == Brightness.dark
                        ? .4
                        : .12,
                    child: Image.asset(
                      'assets/profile/profile_landscape.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      cacheWidth: 1000,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: InternalStyle.maxWidth,
                    ),
                    child: DreamInternalHeader(
                      title: title,
                      actions: actions,
                      onBack: onBack,
                      backLabel: backLabel,
                      compact: compact,
                    ),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    key: PageStorageKey('internal-$title'),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      if (hero != null) SliverToBoxAdapter(child: hero),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          InternalStyle.gutter,
                          16,
                          InternalStyle.gutter,
                          MediaQuery.paddingOf(context).bottom + 36,
                        ),
                        sliver: SliverList.list(
                          children: [
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Text(
                                  subtitle!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: InternalStyle.muted(context),
                                  ),
                                ),
                              ),
                            for (final child in children)
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: InternalStyle.maxWidth - 44,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: child,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class DreamIconBubble extends StatelessWidget {
  const DreamIconBubble(this.icon, {super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [
          InternalStyle.accent(context).withValues(alpha: .18),
          InternalStyle.accent(context).withValues(alpha: .05),
        ],
      ),
      border: Border.all(
        color: InternalStyle.accent(context).withValues(alpha: .3),
        width: .8,
      ),
    ),
    child: Icon(icon, size: 24, color: InternalStyle.accent(context)),
  );
}

class DreamSettingsRow extends ConsumerWidget {
  const DreamSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.child,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing, child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DreamIconBubble(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.3,
                        fontFamily: 'Inter',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontFamily: 'Inter',
                          color: InternalStyle.muted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null &&
                  MediaQuery.textScalerOf(context).scale(16) <= 22) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          if (trailing != null &&
              MediaQuery.textScalerOf(context).scale(16) > 22)
            Align(alignment: Alignment.centerRight, child: trailing!),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
    return onTap == null
        ? content
        : CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              dreamSelection(ref);
              onTap!();
            },
            child: content,
          );
  }
}

class DreamSettingsSection extends StatelessWidget {
  const DreamSettingsSection({
    super.key,
    this.title,
    this.icon,
    required this.children,
  });
  final String? title;
  final IconData? icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 27, color: InternalStyle.accent(context)),
                const SizedBox(width: 12),
              ],
              Expanded(child: Text(title!, style: display(28))),
            ],
          ),
        ),
      DreamGlassSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: .7,
                  indent: 78,
                  endIndent: 18,
                  color: InternalStyle.accent(context).withValues(alpha: .2),
                ),
              children[i],
            ],
          ],
        ),
      ),
    ],
  );
}

class DreamGlassSwitch extends ConsumerWidget {
  const DreamGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced =
        ref.watch(settingsProvider)['animations'] == 'reduced' ||
        MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: label,
      toggled: value,
      enabled: onChanged != null,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 5),
        minimumSize: const Size(58, 44),
        onPressed: onChanged == null
            ? null
            : () {
                dreamSelection(ref);
                onChanged!(!value);
              },
        child: AnimatedContainer(
          duration: Duration(milliseconds: reduced ? 0 : 210),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 34,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: value ? const Color(0xff9c83ef) : const Color(0xff484965),
            border: Border.all(
              color: InternalStyle.accent(
                context,
              ).withValues(alpha: value ? .75 : .25),
            ),
          ),
          child: AnimatedAlign(
            duration: Duration(milliseconds: reduced ? 0 : 210),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xffece8fa)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DreamSegmentedControl<T> extends ConsumerWidget {
  const DreamSegmentedControl({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final T value;
  final Map<T, String> options;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in options.entries)
        Semantics(
          selected: entry.key == value,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onChanged == null
                ? null
                : () {
                    dreamSelection(ref);
                    onChanged!(entry.key);
                  },
            child: AnimatedContainer(
              duration: Duration(
                milliseconds:
                    MediaQuery.disableAnimationsOf(context) ||
                        ref.watch(settingsProvider)['animations'] == 'reduced'
                    ? 0
                    : 200,
              ),
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: InternalStyle.accent(
                  context,
                ).withValues(alpha: entry.key == value ? .28 : .05),
                border: Border.all(
                  color: InternalStyle.accent(
                    context,
                  ).withValues(alpha: entry.key == value ? .85 : .25),
                ),
                boxShadow: entry.key == value
                    ? [
                        BoxShadow(
                          color: InternalStyle.accent(
                            context,
                          ).withValues(alpha: .13),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

Future<void> dreamNotice(BuildContext context, String title, String message) =>
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );

Future<DateTime?> dreamDatePicker(
  BuildContext context, {
  required DateTime initial,
  required bool en,
  CupertinoDatePickerMode mode = CupertinoDatePickerMode.dateAndTime,
  DateTime? maximumDate,
}) async {
  var selected = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => DreamGlassSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr(en, 'Отмена', 'Cancel')),
              ),
              CupertinoButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: Text(tr(en, 'Готово', 'Done')),
              ),
            ],
          ),
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              initialDateTime: initial,
              minimumDate: mode == CupertinoDatePickerMode.time
                  ? null
                  : DateTime(1900),
              maximumDate: maximumDate,
              mode: mode,
              use24hFormat: true,
              onDateTimeChanged: (v) => selected = v,
            ),
          ),
        ],
      ),
    ),
  );
}

class DreamGlassSheet extends StatelessWidget {
  const DreamGlassSheet({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DreamGlassSurface(
        preset: DreamGlass.modal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        radius: 30,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: InternalStyle.muted(context).withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

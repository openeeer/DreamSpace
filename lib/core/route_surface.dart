import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import 'design.dart';

/// Every route owns an opaque backdrop, including during interactive back swipes.
class DreamRoutePage extends Page<void> {
  const DreamRoutePage({required super.key, required this.child});
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => CupertinoPageRoute<void>(
    settings: this,
    builder: (_) => CosmicBackground(child: child),
  );
}

Page<void> dreamRoute(BuildContext context, GoRouterState state, Widget child) {
  final reduced =
      MediaQuery.disableAnimationsOf(context) ||
      ProviderScope.containerOf(context).read(settingsProvider)['animations'] ==
          'reduced';
  return reduced
      ? NoTransitionPage<void>(
          key: state.pageKey,
          child: CosmicBackground(child: child),
        )
      : DreamRoutePage(key: state.pageKey, child: child);
}

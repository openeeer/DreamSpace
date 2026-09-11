import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/providers.dart';
import 'design.dart';

/// CupertinoPage reads current Page settings on every router update.
/// Closing a route builder over an old Page freezes shell branch updates.
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
      : CupertinoPage<void>(
          key: state.pageKey,
          child: CosmicBackground(child: child),
        );
}

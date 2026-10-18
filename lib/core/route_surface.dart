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
  // Keep decorative layers and live UIKit glass within their own page while
  // both routes are visible during an interactive iOS back swipe.
  final surface = ClipRect(
    child: RepaintBoundary(child: CosmicBackground(child: child)),
  );
  return reduced
      ? NoTransitionPage<void>(key: state.pageKey, child: surface)
      : CupertinoPage<void>(
          key: state.pageKey,
          allowSnapshotting: false,
          child: surface,
        );
}

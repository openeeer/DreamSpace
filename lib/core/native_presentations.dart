import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native_glass.dart';

const nativePresentations = MethodChannel('dreamspace/presentation');

Map<String, Object> presentationStyle(BuildContext context) => {
  'dark': Theme.of(context).brightness == Brightness.dark,
  'language': Localizations.localeOf(context).languageCode,
};

/// The native alert/action sheet is presented above the Flutter view controller.
Future<String?> dreamActionSheet(
  BuildContext context, {
  required String title,
  required List<(String, String)> actions,
  required String cancelLabel,
  Set<String> destructive = const {},
}) async {
  if (usesNativeGlass) {
    return nativePresentations.invokeMethod<String>('actions', {
      ...presentationStyle(context),
      'title': title,
      'cancel': cancelLabel,
      'actions': [
        for (final (id, label) in actions)
          {'id': id, 'label': label, 'destructive': destructive.contains(id)},
      ],
    });
  }
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final (id, label) in actions)
          CupertinoActionSheetAction(
            isDestructiveAction: destructive.contains(id),
            onPressed: () => Navigator.pop(ctx, id),
            child: Text(label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: Text(cancelLabel),
      ),
    ),
  );
}

Future<void> dreamAlert(
  BuildContext context, {
  required String title,
  required String message,
  required String closeLabel,
}) async {
  if (usesNativeGlass) {
    await nativePresentations.invokeMethod<void>('alert', {
      ...presentationStyle(context),
      'title': title,
      'message': message,
      'close': closeLabel,
    });
    return;
  }
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(closeLabel),
        ),
      ],
    ),
  );
}

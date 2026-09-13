import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../core/notifications.dart';
import '../../data/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool working = false;
  Future<void> run(Future<void> Function() action) async {
    if (working) return;
    setState(() => working = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        await dreamNotice(
          context,
          'DreamSpace',
          tr(
            ref.read(englishProvider),
            'Не удалось выполнить действие. Попробуй ещё раз.',
            'Could not complete the action. Please retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider),
        settings = ref.watch(settingsProvider),
        controller = ref.read(settingsProvider.notifier);
    final hour = int.tryParse(settings['hour'] ?? '8') ?? 8,
        minute = int.tryParse(settings['minute'] ?? '0') ?? 0;
    Widget toggle(
      IconData icon,
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> changed,
    ) => DreamSettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: DreamGlassSwitch(
        label: title,
        value: value,
        onChanged: working ? null : changed,
      ),
    );
    return DreamInternalPage(
      title: tr(en, 'Настройки', 'Settings'),
      children: [
        Stack(
          children: [
            Positioned(
              right: -12,
              top: 0,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: .6,
                    child: Image.asset(
                      'assets/profile/dream_sphere.png',
                      width: 90,
                      height: 90,
                      cacheWidth: 240,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 65, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(en, 'Твой DreamSpace', 'Your DreamSpace'),
                    style: display(30),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      en,
                      'Настрой пространство под себя',
                      'Make this space your own',
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: InternalStyle.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!en)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Image.asset(
              'assets/profile/settings_handwritten_ru.png',
              height: 94,
              fit: BoxFit.contain,
              semanticLabel: 'Маленькие настройки — большие сны',
            ),
          ),
        DreamSettingsSection(
          children: [
            DreamSettingsRow(
              icon: CupertinoIcons.globe,
              title: tr(en, 'Язык приложения', 'App language'),
              subtitle: tr(
                en,
                'Выбери удобный язык',
                'Choose your preferred language',
              ),
              child: DreamSegmentedControl<String>(
                value: en ? 'en' : 'ru',
                options: const {'ru': 'Русский', 'en': 'English'},
                onChanged: working
                    ? null
                    : (v) => run(() async {
                        await controller.set('language', v);
                        if (settings['reminder'] == 'true') {
                          await reminders.schedule(
                            hour,
                            minute,
                            en: v == 'en',
                            request: false,
                          );
                        }
                      }),
              ),
            ),
            DreamSettingsRow(
              icon: CupertinoIcons.wand_stars,
              title: tr(en, 'Оформление', 'Appearance'),
              subtitle: tr(
                en,
                'Выбери атмосферу приложения',
                'Choose the atmosphere of your app',
              ),
              child: DreamSegmentedControl<String>(
                value: settings['theme'] ?? 'dark',
                options: {
                  'dark': tr(en, 'Полночь', 'Midnight'),
                  'light': tr(en, 'Туман', 'Mist'),
                  'system': tr(en, 'Системное', 'System'),
                },
                onChanged: working
                    ? null
                    : (v) => run(() => controller.set('theme', v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        DreamSettingsSection(
          title: tr(en, 'Утренний ритуал', 'Morning ritual'),
          icon: CupertinoIcons.sunrise,
          children: [
            toggle(
              CupertinoIcons.bell,
              tr(en, 'Напомнить записать сон', 'Morning reminder'),
              tr(
                en,
                'Мягкое напоминание после пробуждения',
                'A gentle nudge after waking',
              ),
              settings['reminder'] == 'true',
              (v) => run(() async {
                if (v) {
                  final ok = await reminders.schedule(hour, minute, en: en);
                  if (!ok) {
                    if (context.mounted) {
                      await dreamNotice(
                        context,
                        tr(en, 'Уведомления', 'Notifications'),
                        tr(
                          en,
                          'Разреши уведомления DreamSpace в настройках устройства, чтобы получать напоминания.',
                          'Allow DreamSpace notifications in device settings to receive reminders.',
                        ),
                      );
                    }
                    return;
                  }
                } else {
                  await reminders.cancel();
                }
                await controller.set('reminder', '$v');
              }),
            ),
            DreamSettingsRow(
              icon: CupertinoIcons.clock,
              title: tr(en, 'Время', 'Time'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: InternalStyle.accent(context),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right, size: 17),
                ],
              ),
              onTap: working
                  ? null
                  : () async {
                      final time = await dreamDatePicker(
                        context,
                        initial: DateTime(2026, 1, 1, hour, minute),
                        en: en,
                        mode: CupertinoDatePickerMode.time,
                      );
                      if (time == null || !mounted) return;
                      await run(() async {
                        if (settings['reminder'] == 'true') {
                          final ok = await reminders.schedule(
                            time.hour,
                            time.minute,
                            en: en,
                            request: false,
                          );
                          if (!ok) {
                            throw StateError(
                              'Notification permission unavailable',
                            );
                          }
                        }
                        await controller.set('hour', '${time.hour}');
                        await controller.set('minute', '${time.minute}');
                      });
                    },
            ),
          ],
        ),
        const SizedBox(height: 32),
        DreamSettingsSection(
          title: tr(en, 'Ощущения', 'Experience'),
          icon: CupertinoIcons.sparkles,
          children: [
            toggle(
              CupertinoIcons.sparkles,
              tr(en, 'Анимации', 'Animations'),
              tr(
                en,
                'Учитывает системное уменьшение движения',
                'Respects system Reduce Motion',
              ),
              settings['animations'] != 'reduced',
              (v) => run(
                () => controller.set('animations', v ? 'full' : 'reduced'),
              ),
            ),
            toggle(
              CupertinoIcons.layers,
              tr(en, 'Плотные поверхности', 'Reduce transparency'),
              tr(
                en,
                'Более выраженные карточки и элементы',
                'More defined cards and controls',
              ),
              settings['opaque'] == 'true',
              (v) => run(() => controller.set('opaque', '$v')),
            ),
            toggle(
              CupertinoIcons.hand_draw,
              tr(en, 'Тактильный отклик', 'Haptics'),
              tr(
                en,
                'Лёгкая вибрация при взаимодействии',
                'Gentle feedback as you interact',
              ),
              settings['haptics'] != 'false',
              (v) => run(() => controller.set('haptics', '$v')),
            ),
          ],
        ),
        const SizedBox(height: 32),
        DreamSettingsSection(
          title: tr(en, 'Данные', 'Your data'),
          icon: CupertinoIcons.archivebox,
          children: [
            DreamSettingsRow(
              icon: CupertinoIcons.square_arrow_up,
              title: tr(en, 'Экспортировать JSON', 'Export JSON'),
              onTap: working ? null : () => export(false),
            ),
            DreamSettingsRow(
              icon: CupertinoIcons.doc_text,
              title: tr(en, 'Экспортировать Markdown', 'Export Markdown'),
              onTap: working ? null : () => export(true),
            ),
            DreamSettingsRow(
              icon: CupertinoIcons.moon,
              title: tr(en, 'Удалить примеры снов', 'Remove sample dreams'),
              onTap: working ? null : () => clear(true),
            ),
            DreamSettingsRow(
              icon: CupertinoIcons.trash,
              title: tr(en, 'Удалить все сны', 'Delete all dreams'),
              onTap: working ? null : () => clear(false),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Center(child: Text('DreamSpace · 1.0.0', style: display(22))),
        const SizedBox(height: 8),
        Text(
          tr(
            en,
            'Маленькая вселенная внутри тебя',
            'A little universe within you',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(color: InternalStyle.muted(context), fontSize: 13),
        ),
        CupertinoButton(
          onPressed: () => Navigator.of(context).push(
            CupertinoPageRoute<void>(builder: (_) => const DreamLicensesPage()),
          ),
          child: Text(tr(en, 'Лицензии', 'Licenses')),
        ),
        if (working) const Center(child: CupertinoActivityIndicator()),
      ],
    );
  }

  Future<void> clear(bool demoOnly) async {
    final en = ref.read(englishProvider);
    if (!await confirm(
      context,
      en,
      demoOnly
          ? tr(en, 'Удалить примеры?', 'Remove sample dreams?')
          : tr(en, 'Удалить все сны?', 'Delete all dreams?'),
      demoOnly
          ? tr(
              en,
              'Твои собственные записи останутся.',
              'Your personal entries will remain.',
            )
          : tr(
              en,
              'Все записи, связи и черновик будут удалены с устройства.',
              'All dreams, connections and the draft will be removed from this device.',
            ),
    )) {
      return;
    }
    await run(() => ref.read(repositoryProvider).clear(demoOnly: demoOnly));
  }

  Future<void> export(bool markdown) => run(() async {
    final dreams = await ref.read(repositoryProvider).all();
    final content = markdown
        ? '# DreamSpace\n\n${dreams.map((d) => '## ${d.title}\n${d.toJson()['date']}\n\n${d.description}\n\n${d.elements.map((e) => e.name).join(', ')}\n').join('\n---\n\n')}'
        : const JsonEncoder.withIndent('  ').convert({
            'formatVersion': 1,
            'exportedAt': DateTime.now().toUtc().toIso8601String(),
            'dreams': dreams.map((d) => d.toJson()).toList(),
          });
    final dir = await getTemporaryDirectory(),
        fileName = 'dreamspace_export.${markdown ? 'md' : 'json'}';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        title: 'DreamSpace',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  });
}

class DreamLicensesPage extends StatefulWidget {
  const DreamLicensesPage({super.key});
  @override
  State<DreamLicensesPage> createState() => _DreamLicensesPageState();
}

class _DreamLicensesPageState extends State<DreamLicensesPage> {
  late final licenses = LicenseRegistry.licenses.toList();
  @override
  Widget build(BuildContext context) => CosmicBackground(
    child: DreamInternalPage(
      title: Localizations.localeOf(context).languageCode == 'ru'
          ? 'Лицензии'
          : 'Licenses',
      children: [
        FutureBuilder<List<LicenseEntry>>(
          future: licenses,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in snapshot.data!) ...[
                  Text(entry.packages.join(', '), style: display(22)),
                  const SizedBox(height: 12),
                  SelectableText(
                    entry.paragraphs.map((p) => p.text).join('\n\n'),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                ],
              ],
            );
          },
        ),
      ],
    ),
  );
}

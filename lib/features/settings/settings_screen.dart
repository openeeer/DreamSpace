import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design.dart';
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
    setState(() => working = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                ref.read(englishProvider),
                'Не удалось выполнить действие. Попробуй ещё раз.',
                'Could not complete the action. Please retry.',
              ),
            ),
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
    return DreamPage(
      title: tr(en, 'Настройки', 'Settings'),
      back: true,
      children: [
        SectionTitle(tr(en, 'Твой DreamSpace', 'Your DreamSpace')),
        DreamSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(en, 'Язык приложения', 'App language')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: [
                  DreamChip(
                    'Русский',
                    selected: !en,
                    onTap: () => run(() async {
                      await controller.set('language', 'ru');
                      if (settings['reminder'] == 'true') {
                        await reminders.schedule(
                          hour,
                          minute,
                          en: false,
                          request: false,
                        );
                      }
                    }),
                  ),
                  DreamChip(
                    'English',
                    selected: en,
                    onTap: () => run(() async {
                      await controller.set('language', 'en');
                      if (settings['reminder'] == 'true') {
                        await reminders.schedule(
                          hour,
                          minute,
                          en: true,
                          request: false,
                        );
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(tr(en, 'Оформление', 'Appearance')),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in ['dark', 'light', 'system'])
                    DreamChip(
                      switch (mode) {
                        'dark' => tr(en, 'Полночь', 'Midnight'),
                        'light' => tr(en, 'Туман', 'Mist'),
                        _ => tr(en, 'Системное', 'System'),
                      },
                      selected: (settings['theme'] ?? 'dark') == mode,
                      onTap: () => run(() => controller.set('theme', mode)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(tr(en, 'Утренний ритуал', 'Morning ritual')),
        DreamSurface(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                title: Text(
                  tr(en, 'Напомнить записать сон', 'Morning reminder'),
                ),
                subtitle: Text(
                  tr(
                    en,
                    'Мягкое напоминание после пробуждения',
                    'A gentle nudge after waking',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: settings['reminder'] == 'true',
                onChanged: working
                    ? null
                    : (value) => run(() async {
                        if (value) {
                          final ok = await reminders.schedule(
                            hour,
                            minute,
                            en: en,
                          );
                          if (!ok) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    tr(
                                      en,
                                      'Разреши уведомления в настройках устройства.',
                                      'Allow notifications in device settings.',
                                    ),
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                        } else {
                          await reminders.cancel();
                        }
                        await controller.set('reminder', '$value');
                      }),
              ),
              ListTile(
                title: Text(tr(en, 'Время', 'Time')),
                trailing: Text(
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                ),
                onTap: working
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: hour, minute: minute),
                        );
                        if (time == null) return;
                        await run(() async {
                          if (settings['reminder'] == 'true') {
                            await reminders.schedule(
                              time.hour,
                              time.minute,
                              en: en,
                              request: false,
                            );
                          }
                          await controller.set('hour', '${time.hour}');
                          await controller.set('minute', '${time.minute}');
                        });
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(tr(en, 'Ощущения', 'Experience')),
        DreamSurface(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                title: Text(tr(en, 'Анимации', 'Animations')),
                subtitle: Text(
                  tr(
                    en,
                    'Учитывает системное уменьшение движения',
                    'Respects system Reduce Motion',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                value: settings['animations'] != 'reduced',
                onChanged: (v) => run(
                  () => controller.set('animations', v ? 'full' : 'reduced'),
                ),
              ),
              SwitchListTile.adaptive(
                title: Text(
                  tr(en, 'Плотные поверхности', 'Reduce transparency'),
                ),
                value: settings['opaque'] == 'true',
                onChanged: (v) => run(() => controller.set('opaque', '$v')),
              ),
              SwitchListTile.adaptive(
                title: Text(tr(en, 'Тактильный отклик', 'Haptics')),
                value: settings['haptics'] != 'false',
                onChanged: (v) => run(() => controller.set('haptics', '$v')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(tr(en, 'Данные', 'Your data')),
        DreamSurface(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(CupertinoIcons.square_arrow_up),
                title: Text(tr(en, 'Экспортировать JSON', 'Export JSON')),
                onTap: working ? null : () => export(false),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.doc_text),
                title: Text(
                  tr(en, 'Экспортировать Markdown', 'Export Markdown'),
                ),
                onTap: working ? null : () => export(true),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.moon),
                title: Text(
                  tr(en, 'Удалить примеры снов', 'Remove sample dreams'),
                ),
                onTap: working ? null : () => clear(true),
              ),
              ListTile(
                leading: const Icon(
                  CupertinoIcons.trash,
                  color: Color(0xfff29ba9),
                ),
                title: Text(
                  tr(en, 'Удалить все сны', 'Delete all dreams'),
                  style: const TextStyle(color: Color(0xfff29ba9)),
                ),
                onTap: working ? null : () => clear(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Center(child: Text('DreamSpace · 1.0.0', style: display(20))),
        const SizedBox(height: 8),
        Center(
          child: Text(
            tr(
              en,
              'Маленькая вселенная внутри тебя',
              'A little universe within you',
            ),
            style: const TextStyle(color: Palette.secondary, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'DreamSpace',
            applicationVersion: '1.0.0',
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
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/dreamspace_export.${markdown ? 'md' : 'json'}',
    );
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

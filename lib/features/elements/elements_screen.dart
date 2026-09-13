import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';
import '../insights/analytics.dart';

class ElementsScreen extends StatefulWidget {
  const ElementsScreen({super.key});
  @override
  State<ElementsScreen> createState() => _ElementsScreenState();
}

class _ElementsScreenState extends State<ElementsScreen> {
  ElementKind kind = ElementKind.symbol;
  String query = '';
  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (dreams, en) {
      final items = DreamStats(dreams)
          .elements(kind)
          .where((e) => normalize(e.key.name).contains(normalize(query)))
          .toList();
      return DreamInternalPage(
        title: tr(en, 'Образы снов', 'Dream Elements'),
        subtitle: tr(
          en,
          'Символы, места и люди, которые возвращаются в твоих снах',
          'Symbols, places and people that return in your dreams',
        ),
        children: [
          DreamGlassSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                hintText: tr(en, 'Найти образ', 'Find an element'),
                prefixIcon: const Icon(CupertinoIcons.search),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DreamSegmentedControl(
            value: kind,
            options: {
              ElementKind.symbol: tr(en, 'Символы', 'Symbols'),
              ElementKind.place: tr(en, 'Места', 'Places'),
              ElementKind.character: tr(en, 'Люди', 'People'),
            },
            onChanged: (v) => setState(() => kind = v),
          ),
          const SizedBox(height: 22),
          if (items.isEmpty)
            Text(
              tr(
                en,
                'Добавляй образы при записи сна — здесь появится коллекция.',
                'Add elements to your dreams to build your collection.',
              ),
            ),
          LayoutBuilder(
            builder: (context, c) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in items)
                  SizedBox(
                    width: c.maxWidth < 350
                        ? c.maxWidth
                        : (c.maxWidth - 12) / 2,
                    child: DreamGlassSurface(
                      onTap: () => context.push(
                        '/elements/${Uri.encodeComponent(item.key.id)}',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Palette.lavender.withValues(alpha: .13),
                            ),
                            child: Icon(
                              kind == ElementKind.symbol
                                  ? CupertinoIcons.sparkles
                                  : kind == ElementKind.place
                                  ? CupertinoIcons.location
                                  : CupertinoIcons.person,
                              color: Palette.lavender,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(item.key.name, style: display(23)),
                          const SizedBox(height: 9),
                          Text(
                            '${item.value} ${tr(en, 'снов', 'dreams')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Palette.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            dreams
                                .where(
                                  (d) => d.elements.any(
                                    (e) => e.id == item.key.id,
                                  ),
                                )
                                .expand((d) => d.elements)
                                .where((e) => e.id != item.key.id)
                                .map((e) => e.name)
                                .toSet()
                                .take(3)
                                .join(' · '),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: InternalStyle.muted(context),
                            ),
                          ),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Icon(CupertinoIcons.chevron_right, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class ElementDetailScreen extends ConsumerWidget {
  const ElementDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DreamsBuilder(
    builder: (all, en) {
      final dreams = all
          .where((d) => d.elements.any((e) => e.id == id))
          .toList();
      final element = dreams
          .expand((d) => d.elements)
          .where((e) => e.id == id)
          .firstOrNull;
      if (element == null) {
        return DreamInternalPage(
          title: tr(en, 'Образ не найден', 'Element not found'),
          children: const [],
        );
      }
      final dates = dreams.map((d) => d.date).toList()..sort();
      final moods = DreamStats(dreams).moods.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final related = dreams
          .expand((d) => d.elements)
          .where((e) => e.id != id)
          .map((e) => e.name)
          .toSet();
      return DreamInternalPage(
        title: element.name,
        actions: [
          DreamGlassAction(
            label: tr(en, 'Переименовать', 'Rename'),
            icon: CupertinoIcons.pencil,
            onPressed: () async {
              final controller = TextEditingController(text: element.name);
              final name = await showCupertinoDialog<String>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: Text(tr(en, 'Название образа', 'Element name')),
                  content: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CupertinoTextField(
                      controller: controller,
                      autofocus: true,
                    ),
                  ),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(tr(en, 'Отмена', 'Cancel')),
                    ),
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(ctx, controller.text),
                      child: Text(tr(en, 'Сохранить', 'Save')),
                    ),
                  ],
                ),
              );
              if (name == null || name.trim().isEmpty) return;
              try {
                await ref.read(repositoryProvider).renameElement(element, name);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr(
                          en,
                          'Такое имя уже существует. Выбери другое.',
                          'This name already exists. Choose another.',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Palette.lavender.withValues(alpha: .4),
                    Palette.surface,
                  ],
                ),
              ),
              child: const Icon(
                CupertinoIcons.sparkles,
                size: 44,
                color: Palette.lavender,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${dreams.length} ${tr(en, 'снов с этим образом', 'dreams with this element')}',
              style: display(24),
            ),
          ),
          const SizedBox(height: 24),
          DreamGlassSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(en, 'Впервые', 'First appeared')}: ${formatDate(dates.first, en)}',
                ),
                const SizedBox(height: 12),
                if (moods.isNotEmpty)
                  Text(
                    '${tr(en, 'Частое настроение', 'Common mood')}: ${moods.first.key.label(en)}',
                  ),
                const SizedBox(height: 18),
                Text(
                  tr(en, 'Связанные образы', 'Related elements'),
                  style: const TextStyle(
                    color: Palette.secondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in related.take(12)) DreamChip(name),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionTitle(tr(en, 'Сновидения', 'Dreams')),
          for (final d in dreams) DreamCard(d, en: en),
        ],
      );
    },
  );
}

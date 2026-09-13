import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';
import 'journal_components.dart';

String journalCount(int count, bool en) {
  if (en) return '$count ${count == 1 ? 'entry' : 'entries'}';
  final last = count % 10, teen = count % 100;
  return '$count ${teen >= 11 && teen <= 14
      ? 'записей'
      : last == 1
      ? 'запись'
      : last >= 2 && last <= 4
      ? 'записи'
      : 'записей'}';
}

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key, this.mood});
  final String? mood;
  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final search = TextEditingController();
  String query = '';
  int filter = 0;
  bool oldest = false;
  String? mood;
  final collapsed = <String>{};
  @override
  void initState() {
    super.initState();
    mood = widget.mood;
  }

  @override
  void didUpdateWidget(covariant JournalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood != oldWidget.mood) mood = widget.mood;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void haptic() {
    if (ref.read(settingsProvider)['haptics'] != 'false') {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> options(bool en) async {
    FocusScope.of(context).unfocus();
    var selectedMood = mood, selectedFilter = filter;
    var ascending = oldest;
    final apply = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, update) => CupertinoActionSheet(
          title: Text(tr(en, 'Параметры дневника', 'Journal options')),
          message: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(tr(en, 'Порядок записей', 'Sort by date')),
              const SizedBox(height: 8),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: ascending,
                children: {
                  false: Text(tr(en, 'Сначала новые', 'Newest first')),
                  true: Text(tr(en, 'Сначала старые', 'Oldest first')),
                },
                onValueChanged: (value) =>
                    update(() => ascending = value ?? false),
              ),
              const SizedBox(height: 20),
              Text(tr(en, 'Настроение', 'Mood')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  JournalFilter(
                    label: tr(en, 'Любое', 'Any'),
                    selected: selectedMood == null,
                    onTap: () => update(() => selectedMood = null),
                  ),
                  for (final m in Mood.values)
                    JournalFilter(
                      label: m.label(en),
                      selected: selectedMood == m.name,
                      onTap: () => update(() => selectedMood = m.name),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(tr(en, 'Категория', 'Category')),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < 5; i++)
                    JournalFilter(
                      label: labels(en)[i],
                      selected: selectedFilter == i,
                      onTap: () => update(() => selectedFilter = i),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(en, 'Применить', 'Apply')),
            ),
            CupertinoActionSheetAction(
              onPressed: () => update(() {
                selectedMood = null;
                selectedFilter = 0;
                ascending = false;
              }),
              child: Text(tr(en, 'Сбросить фильтры', 'Reset filters')),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(en, 'Отмена', 'Cancel')),
          ),
        ),
      ),
    );
    if (mounted && apply == true) {
      setState(() {
        mood = selectedMood;
        filter = selectedFilter;
        oldest = ascending;
      });
    }
  }

  List<String> labels(bool en) => en
      ? ['All', 'Lucid', 'Nightmares', 'Recurring', 'Favorites']
      : ['Все', 'Осознанные', 'Кошмары', 'Повторяющиеся', 'Избранные'];

  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (dreams, en) {
      final visible =
          dreams
              .where(
                (d) =>
                    normalize(
                      '${dreamTitle(d, en)} ${d.description} ${d.elements.map((e) => e.name).join(' ')}',
                    ).contains(normalize(query)) &&
                    (mood == null || d.mood?.name == mood) &&
                    switch (filter) {
                      1 => d.type == DreamType.lucid,
                      2 => d.type == DreamType.nightmare,
                      3 => d.recurring,
                      4 => d.favorite,
                      _ => true,
                    },
              )
              .toList()
            ..sort(
              (a, b) =>
                  oldest ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
            );
      final months = <String, List<Dream>>{};
      for (final d in visible) {
        (months['${d.date.year}-${d.date.month}'] ??= []).add(d);
      }
      final light = Theme.of(context).brightness == Brightness.light;
      return Scaffold(
        body: Stack(
          children: [
            if (!light)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xff080c24).withValues(alpha: .4),
                          Colors.transparent,
                        ],
                        stops: const [0, .5, 1],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: MediaQuery.paddingOf(context).top - 8,
              right: 45,
              width: 200,
              height: 120,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: light ? .2 : .55,
                    child: Stack(
                      children: [
                        const Positioned(
                          top: 8,
                          left: 34,
                          child: Icon(
                            CupertinoIcons.moon_fill,
                            size: 62,
                            color: Palette.lavender,
                          ),
                        ),
                        Positioned.fill(
                          child: Image.asset(
                            'assets/backgrounds/nebula_foreground.webp',
                            fit: BoxFit.cover,
                            cacheWidth: 500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            CustomScrollView(
              key: const PageStorageKey('journal-scroll'),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + 22,
                    20,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr(en, 'Дневник', 'Journal'),
                              style: display(
                                MediaQuery.sizeOf(context).width < 360
                                    ? 33
                                    : 39,
                              ).copyWith(height: 1.05),
                            ),
                          ),
                          JournalGlass(
                            radius: 27,
                            child: JournalIconButton(
                              label: tr(en, 'Календарь', 'Calendar'),
                              icon: CupertinoIcons.calendar,
                              onPressed: () {
                                haptic();
                                context.push('/calendar');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.lavender.withValues(
                                    alpha: .24,
                                  ),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: JournalGlass(
                              radius: 27,
                              accent: true,
                              child: JournalIconButton(
                                label: tr(en, 'Записать сон', 'Record Dream'),
                                icon: CupertinoIcons.plus,
                                onPressed: () {
                                  haptic();
                                  context.push('/record');
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr(
                          en,
                          'Воспоминания с другой стороны ночи',
                          'Memories from the other side of night',
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Palette.secondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      JournalGlass(
                        radius: 26,
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14, right: 10),
                              child: Icon(
                                CupertinoIcons.search,
                                size: 20,
                                color: Palette.secondary,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: search,
                                style: const TextStyle(fontSize: 13),
                                keyboardAppearance: Theme.of(
                                  context,
                                ).brightness,
                                textInputAction: TextInputAction.search,
                                onTapOutside: (_) =>
                                    FocusScope.of(context).unfocus(),
                                onSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
                                onChanged: (s) => setState(() => query = s),
                                decoration: InputDecoration(
                                  hintText: tr(
                                    en,
                                    'Поиск снов, мест, символов...',
                                    'Search dreams, places, symbols...',
                                  ),
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Palette.secondary,
                                  ),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                            if (query.isNotEmpty)
                              JournalIconButton(
                                label: tr(en, 'Очистить поиск', 'Clear search'),
                                icon: CupertinoIcons.xmark_circle_fill,
                                onPressed: () {
                                  search.clear();
                                  setState(() => query = '');
                                },
                              ),
                            JournalIconButton(
                              label: tr(
                                en,
                                'Параметры дневника',
                                'Journal options',
                              ),
                              icon: CupertinoIcons.slider_horizontal_3,
                              onPressed: () => options(en),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: math.max(
                      44,
                      MediaQuery.textScalerOf(context).scale(14) + 24,
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 5,
                      separatorBuilder: (_, i) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => JournalFilter(
                        label: labels(en)[i],
                        selected: filter == i,
                        onTap: () => setState(() => filter = i),
                      ),
                    ),
                  ),
                ),
                if (mood != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => mood = null),
                          child: Text(
                            '${Mood.values.where((m) => m.name == mood).firstOrNull?.label(en) ?? mood} ×',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                if (visible.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyDreams(en: en, search: dreams.isNotEmpty),
                  ),
                for (final entry in months.entries) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Semantics(
                        expanded: !collapsed.contains(entry.key),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            haptic();
                            setState(
                              () => collapsed.contains(entry.key)
                                  ? collapsed.remove(entry.key)
                                  : collapsed.add(entry.key),
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _month(entry.value.first.date, en),
                                  style: display(24).copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                journalCount(entry.value.length, en),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Palette.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                collapsed.contains(entry.key)
                                    ? CupertinoIcons.chevron_down
                                    : CupertinoIcons.chevron_up,
                                size: 15,
                                color: Palette.secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!collapsed.contains(entry.key))
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: entry.value.length,
                        itemBuilder: (_, i) => DreamJournalCard(
                          key: ValueKey(entry.value[i].id),
                          dream: entry.value[i],
                          en: en,
                        ),
                      ),
                    ),
                ],
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.viewPaddingOf(context).bottom + 120,
                  ),
                ),
              ],
            ),
            if (!light)
              Positioned(
                left: -35,
                right: -35,
                bottom: -25,
                height: 110,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: .38,
                      child: Image.asset(
                        'assets/backgrounds/nebula_foreground.webp',
                        fit: BoxFit.cover,
                        cacheWidth: 1000,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );

  String _month(DateTime date, bool en) {
    final label = DateFormat('LLLL yyyy', en ? 'en' : 'ru').format(date);
    return '${label[0].toUpperCase()}${label.substring(1)}';
  }
}

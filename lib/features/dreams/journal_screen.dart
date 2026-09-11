import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/dream.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, this.mood});
  final String? mood;
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final search = TextEditingController();
  String query = '';
  int filter = 0;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (dreams, en) {
      final visible = dreams.where((d) {
        final matches = normalize(
          '${d.title} ${d.description} ${d.elements.map((e) => e.name).join(' ')}',
        ).contains(normalize(query));
        return matches &&
            (widget.mood == null || d.mood?.name == widget.mood) &&
            switch (filter) {
              1 => d.type == DreamType.lucid,
              2 => d.type == DreamType.nightmare,
              3 => d.recurring,
              4 => d.favorite,
              _ => true,
            };
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr(en, 'Дневник', 'Journal'),
                            style: display(27),
                          ),
                        ),
                        IconButton(
                          tooltip: tr(en, 'Календарь', 'Calendar'),
                          onPressed: () => context.push('/calendar'),
                          icon: const Icon(CupertinoIcons.calendar),
                        ),
                        IconButton(
                          tooltip: tr(en, 'Записать сон', 'Record Dream'),
                          onPressed: () => context.push('/record'),
                          icon: const Icon(CupertinoIcons.add_circled),
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
                    const SizedBox(height: 18),
                    TextField(
                      controller: search,
                      textInputAction: TextInputAction.search,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      onChanged: (s) => setState(() => query = s),
                      decoration: InputDecoration(
                        hintText: tr(
                          en,
                          'Поиск снов, мест, символов',
                          'Search dreams, places, symbols',
                        ),
                        prefixIcon: const Icon(CupertinoIcons.search, size: 19),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: tr(
                                  en,
                                  'Очистить поиск',
                                  'Clear search',
                                ),
                                icon: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  size: 18,
                                ),
                                onPressed: () {
                                  search.clear();
                                  setState(() => query = '');
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: math.max(
                        44,
                        MediaQuery.textScalerOf(context).scale(15) + 20,
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var i = 0; i < 5; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: DreamChip(
                                (en
                                    ? [
                                        'All',
                                        'Lucid',
                                        'Nightmares',
                                        'Recurring',
                                        'Favorites',
                                      ]
                                    : [
                                        'Все',
                                        'Осознанные',
                                        'Кошмары',
                                        'Повторяющиеся',
                                        'Избранное',
                                      ])[i],
                                selected: filter == i,
                                onTap: () => setState(() => filter = i),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.mood != null)
                      TextButton(
                        onPressed: () => context.go('/journal'),
                        child: Text(
                          '${Mood.values.byName(widget.mood!).label(en)} ×',
                        ),
                      ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              if (visible.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EmptyDreams(en: en, search: dreams.isNotEmpty),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, i) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i == 0 ||
                            visible[i].date.month !=
                                visible[i - 1].date.month ||
                            visible[i].date.year != visible[i - 1].date.year)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14, top: 10),
                            child: Text(
                              formatDate(
                                visible[i].date,
                                en,
                              ).replaceFirst(RegExp(r'^\d+ '), ''),
                              style: const TextStyle(
                                fontSize: 13,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        DreamCard(visible[i], en: en, large: i % 3 == 0),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
        ),
      );
    },
  );
}

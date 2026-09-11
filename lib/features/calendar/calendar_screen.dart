import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/design.dart';
import '../../models/dream.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month),
      selected = DateTime.now();
  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (dreams, en) {
      final offset = month.weekday - 1,
          days = DateTime(month.year, month.month + 1, 0).day;
      final entries = dreams
          .where((d) => dateKey(d.date) == dateKey(selected))
          .toList();
      return DreamPage(
        title: tr(en, 'Календарь', 'Calendar'),
        back: true,
        children: [
          DreamSurface(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: tr(en, 'Предыдущий месяц', 'Previous month'),
                      onPressed: () => setState(
                        () => month = DateTime(month.year, month.month - 1),
                      ),
                      icon: const Icon(CupertinoIcons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMM(en ? 'en' : 'ru').format(month),
                        textAlign: TextAlign.center,
                        style: display(22),
                      ),
                    ),
                    IconButton(
                      tooltip: tr(en, 'Следующий месяц', 'Next month'),
                      onPressed: () => setState(
                        () => month = DateTime(month.year, month.month + 1),
                      ),
                      icon: const Icon(CupertinoIcons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final d
                        in en
                            ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                            : ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'])
                      Expanded(
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Palette.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ((days + offset) / 7).ceil() * 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisExtent: 53,
                  ),
                  itemBuilder: (context, i) {
                    final day = i - offset + 1;
                    if (day < 1 || day > days) return const SizedBox.shrink();
                    final date = DateTime(month.year, month.month, day),
                        items = dreams
                            .where(
                              (d) =>
                                  dateKey(d.date) ==
                                  dateKey(
                                    DateTime(month.year, month.month, day),
                                  ),
                            )
                            .toList();
                    return Semantics(
                      button: true,
                      label: '${formatDate(date, en)}, ${items.length}',
                      selected: dateKey(date) == dateKey(selected),
                      child: GestureDetector(
                        onTap: () => setState(() => selected = date),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: dateKey(date) == dateKey(selected)
                                ? Palette.lavender.withValues(alpha: .23)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('$day'),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final d in items.take(3))
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: moodColor(d.mood),
                                      ),
                                    ),
                                  if (items.length > 3)
                                    const Text(
                                      '+',
                                      style: TextStyle(fontSize: 8),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                TextButton(
                  onPressed: () => setState(() {
                    selected = DateTime.now();
                    month = DateTime(selected.year, selected.month);
                  }),
                  child: Text(tr(en, 'Сегодня', 'Today')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SectionTitle(formatDate(selected, en)),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                tr(
                  en,
                  'В эту ночь ещё нет записей.',
                  'No dreams recorded for this night.',
                ),
              ),
            ),
          for (final d in entries) DreamCard(d, en: en),
          if (!selected.isAfter(DateTime.now()))
            DreamButton(
              label: tr(en, 'Добавить сон', 'Add Dream'),
              onPressed: () =>
                  context.push('/record?date=${dateKey(selected)}'),
            ),
        ],
      );
    },
  );
}

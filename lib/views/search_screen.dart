import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:komnotmorng2/core/task_colors.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

// filter key -> label shown on the chip (the keys are also the task states)
const _filters = {
  'all': 'All',
  'done': 'Completed',
  'doing': 'In progress',
  'todo': 'To do',
  'missed': 'Missed',
};

/// Animation length that becomes 0 when the phone's "reduce motion" is on.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

/// One search result: the task and its state ('done', 'doing', 'todo', 'missed').
class _Result {
  const _Result(this.schedule, this.state);
  final Schedule schedule;
  final String state;
}

// ============================================================
// Screen
// ============================================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final selectSche = Get.find<SelectScheduleVM>();
  final controller = TextEditingController();
  final query = ''.obs;
  final filter = 'all'.obs;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // ---------- Data ----------

  // The API labels wall-clock times as "Z", so read them as local time
  DateTime wallClock(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute);

  // Same rules as the home screen
  String stateOf(Schedule s, DateTime now) {
    if (s.status == 'completed') return 'done';
    if (now.isBefore(wallClock(s.startAt))) return 'todo';
    if (now.isBefore(wallClock(s.endAt))) return 'doing';
    return 'missed';
  }

  /// Tasks that match the typed text AND the chosen filter, newest first.
  List<_Result> results() {
    final q = query.value.trim().toLowerCase();
    final f = filter.value;
    if (q.isEmpty && f == 'all') return const []; // nothing to search yet

    final now = DateTime.now();
    final list = <_Result>[];
    for (final s in selectSche.schedules) {
      if (s.status == 'cancelled') continue;

      final textOk =
          q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.categoryName.toLowerCase().contains(q);
      if (!textOk) continue;

      final state = stateOf(s, now);
      if (f != 'all' && state != f) continue;
      list.add(_Result(s, state));
    }
    list.sort((a, b) => b.schedule.startAt.compareTo(a.schedule.startAt));
    return list;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Back button + search box
              Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => query.value = v,
                      decoration: InputDecoration(
                        hintText: 'Search tasks',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Obx(
                          () => query.value.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    controller.clear();
                                    query.value = '';
                                  },
                                ),
                        ),
                        filled: true,
                        fillColor: scheme.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: scheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Obx(
                  () => Row(
                    children: [
                      for (final e in _filters.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(e.value),
                            selected: filter.value == e.key,
                            onSelected: (_) => filter.value = e.key,
                            selectedColor: scheme.primary,
                            checkmarkColor: scheme.onPrimary,
                            labelStyle: TextStyle(
                              color: filter.value == e.key
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results (hint / nothing found / list, swapped with a fade)
              Expanded(
                child: Obx(() {
                  final list = results();
                  final searching =
                      query.value.trim().isNotEmpty || filter.value != 'all';

                  final Widget content;
                  if (!searching) {
                    content = const _Message(
                      key: ValueKey('hint'),
                      icon: Icons.search,
                      title: 'Search your tasks',
                      body: 'Type a title or category, or pick a filter.',
                    );
                  } else if (list.isEmpty) {
                    content = const _Message(
                      key: ValueKey('none'),
                      icon: Icons.search_off,
                      title: 'No tasks found',
                      body: 'Try a different word or filter.',
                    );
                  } else {
                    content = ListView.builder(
                      key: const ValueKey('list'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: list.length,
                      // keeps each tile attached to its task while typing
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<int>) return null;
                        final i = list.indexWhere(
                          (r) => r.schedule.id == key.value,
                        );
                        return i < 0 ? null : i;
                      },
                      itemBuilder: (_, i) => _ResultTile(
                        key: ValueKey(list[i].schedule.id),
                        result: list[i],
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: _motion(context, 200),
                    child: content,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Small widgets
// ============================================================

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({super.key, required this.result});
  final _Result result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<TaskColors>()!;

    final s = result.schedule;
    final done = result.state == 'done';
    final barColor = switch (result.state) {
      'done' => colors.done,
      'doing' => colors.doing,
      _ => colors.todo, // todo and missed
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              // the bar color alone says nothing to a screen reader
              child: Semantics(
                label: 'Status: ${_filters[result.state]}',
                child: Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: barColor, width: 4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${s.categoryName} · '
                        '${DateFormat('d MMM, h:mm a').format(s.startAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PriorityPill(priority: s.priority),
            if (done)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ExcludeSemantics(
                  child: Icon(Icons.check_circle, color: scheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small label like "High".
class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});
  final String priority;

  @override
  Widget build(BuildContext context) {
    if (priority.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final p = priority.toLowerCase();
    final color = p == 'high'
        ? scheme.error
        : p == 'medium'
        ? scheme.tertiary
        : scheme.onSurfaceVariant;
    final label = priority[0].toUpperCase() + priority.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/core/task_colors.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Animation length that becomes 0 when the phone's "reduce motion" is on.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// The API labels wall-clock times as "Z", so read them as local time
DateTime _wallClock(DateTime d) =>
    DateTime(d.year, d.month, d.day, d.hour, d.minute);

String _tasks(int n) => '$n ${n == 1 ? 'task' : 'tasks'}';

// ============================================================
// Screen
// ============================================================

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final vm = Get.find<SelectScheduleVM>();

  // The month on screen (always the 1st) and the chosen day inside it
  final month = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final selected = _dayOnly(DateTime.now()).obs;

  // ---------- Data ----------

  /// Tasks of one month, by day number. A task that spans several days
  /// appears on each of them. Cancelled tasks are hidden.
  Map<int, List<Schedule>> tasksByDay(DateTime m) {
    final first = DateTime(m.year, m.month, 1);
    final last = DateTime(m.year, m.month + 1, 0);
    final map = <int, List<Schedule>>{};

    for (final s in vm.schedules) {
      if (s.status == 'cancelled') continue;
      var day = _dayOnly(s.startAt);
      final end = _dayOnly(s.endAt);
      if (day.isBefore(first)) day = first;
      final stop = end.isAfter(last) ? last : end;
      while (!day.isAfter(stop)) {
        (map[day.day] ??= []).add(s);
        day = DateTime(day.year, day.month, day.day + 1);
      }
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
    }
    return map;
  }

  // ---------- Actions ----------

  void changeMonth(int step) {
    final m = DateTime(month.value.year, month.value.month + step, 1);
    final today = _dayOnly(DateTime.now());
    month.value = m;
    // today if it is in this month, otherwise the 1st
    selected.value = (today.year == m.year && today.month == m.month)
        ? today
        : m;
  }

  void goToday() {
    final today = _dayOnly(DateTime.now());
    month.value = DateTime(today.year, today.month, 1);
    selected.value = today;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            onPressed: goToday,
            tooltip: 'Go to today',
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      body: Obx(() {
        final m = month.value;
        final sel = selected.value;
        final byDay = tasksByDay(m);
        final dayTasks = byDay[sel.day] ?? const <Schedule>[];
        final now = DateTime.now();

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(child: monthCard(m, byDay, sel)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          DateFormat('EEEE, d MMMM').format(sel),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Text(
                      _tasks(dayTasks.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (dayTasks.isEmpty)
              const SliverToBoxAdapter(child: _EmptyDay())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: dayTasks.length,
                  itemBuilder: (_, i) =>
                      _DayTaskTile(schedule: dayTasks[i], now: now),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
            ),
          ],
        );
      }),
    );
  }

  // Month header, weekday names and the grid of days
  Widget monthCard(DateTime m, Map<int, List<Schedule>> byDay, DateTime sel) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<TaskColors>()!;
    final today = _dayOnly(DateTime.now());

    final lead = DateTime(m.year, m.month, 1).weekday - 1; // Monday first
    final days = DateTime(m.year, m.month + 1, 0).day;
    final rows = ((lead + days) / 7).ceil();
    // taller cells when the phone's text size is large
    final scale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, 1.5)
        .toDouble();
    final cellHeight = 56 * scale;

    Widget cell(int n) {
      if (n < 1 || n > days) return SizedBox(height: cellHeight);
      final d = DateTime(m.year, m.month, n);
      final tasks = byDay[n] ?? const <Schedule>[];
      return _DayCell(
        day: d,
        height: cellHeight,
        count: tasks.length,
        // up to 3 dots: green = completed, blue = not completed yet
        dots: [
          for (final s in tasks.take(3))
            s.status == 'completed' ? colors.done : scheme.primary,
        ],
        selected: d == sel,
        isToday: d == today,
        onTap: () => selected.value = d,
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      // swipe left / right to change the month
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;
          if (v < -300) changeMonth(1);
          if (v > 300) changeMonth(-1);
        },
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => changeMonth(-1),
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      DateFormat('MMMM yyyy').format(m),
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => changeMonth(1),
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final w in _weekdays)
                    Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: _motion(context, 200),
              child: Column(
                key: ValueKey(m),
                children: [
                  for (var r = 0; r < rows; r++)
                    Row(
                      children: [
                        for (var c = 0; c < 7; c++)
                          Expanded(child: cell(r * 7 + c - lead + 1)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Small widgets
// ============================================================

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.height,
    required this.count,
    required this.dots,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });
  final DateTime day;
  final double height;
  final int count;
  final List<Color> dots;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: height,
      child: Semantics(
        button: true,
        selected: selected,
        excludeSemantics: true,
        label:
            '${DateFormat('EEEE d MMMM').format(day)}, '
            '${count == 0 ? 'no tasks' : _tasks(count)}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: _motion(context, 150),
                curve: Curves.easeOut,
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : Colors.transparent,
                  // today gets a ring when it is not the selected day
                  border: isToday && !selected
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: FittedBox(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in dots)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks on this day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _DayTaskTile extends StatelessWidget {
  const _DayTaskTile({required this.schedule, required this.now});
  final Schedule schedule;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<TaskColors>()!;

    final s = schedule;
    final done = s.status == 'completed';
    final started = !now.isBefore(_wallClock(s.startAt));
    final ended = !now.isBefore(_wallClock(s.endAt));

    // same rules as the home screen
    final Color bar;
    final String status;
    if (done) {
      bar = colors.done;
      status = 'Completed';
    } else if (!started) {
      bar = colors.todo;
      status = 'To do';
    } else if (!ended) {
      bar = colors.doing;
      status = 'In progress';
    } else {
      bar = colors.todo;
      status = 'Missed';
    }

    final fmt = DateFormat('h:mm a');
    final time = '${fmt.format(s.startAt)} – ${fmt.format(s.endAt)}';

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
                label: 'Status: $status',
                child: Container(
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: bar, width: 4)),
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
                        '${s.categoryName} · $time',
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
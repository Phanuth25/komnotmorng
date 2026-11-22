import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/core/task_colors.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

// ============================================================
// Data
// ============================================================

/// One day of the chart. A task belongs to the day it ends (like History).
class DayStat {
  const DayStat({
    required this.day,
    required this.completed,
    required this.missed,
    required this.total,
  });

  final DateTime day; // date only
  final int completed; // marked completed
  final int missed; // ended without being completed
  final int total; // completed + missed + still to come

  int get remaining => total - completed - missed;
}

/// The last 7 days (oldest -> today) built from the real schedules.
List<DayStat> weeklyStats(List<Schedule> schedules, DateTime now) {
  return List.generate(7, (i) {
    final day = DateTime(now.year, now.month, now.day - (6 - i));
    var completed = 0, missed = 0, total = 0;

    for (final s in schedules) {
      if (s.status == 'cancelled') continue;

      // The API labels wall-clock times as "Z", so read the fields as they
      // are (no toLocal), the same way the home screen does.
      final e = s.endAt;
      if (e.year != day.year || e.month != day.month || e.day != day.day) {
        continue;
      }

      total++;
      if (s.status == 'completed') {
        completed++;
      } else if (DateTime(e.year, e.month, e.day, e.hour, e.minute)
          .isBefore(now)) {
        missed++;
      }
    }
    return DayStat(
      day: day,
      completed: completed,
      missed: missed,
      total: total,
    );
  });
}

/// Days in a row with at least one completed task. A quiet "today" does not
/// break the streak, because the day is not over yet.
int currentStreak(List<DayStat> days) {
  var i = days.length - 1;
  if (days[i].completed == 0) i--;
  var count = 0;
  while (i >= 0 && days[i].completed > 0) {
    count++;
    i--;
  }
  return count;
}

/// Animation length that becomes 0 when "reduce motion" is on.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: ms);

// ============================================================
// Screen
// ============================================================

class WeeklyProgressScreen extends StatelessWidget {
  const WeeklyProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<SelectScheduleVM>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly progress'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        // Rebuilds by itself when the schedules change
        child: Obx(() {
          final days = weeklyStats(vm.schedules, DateTime.now());
          final total = days.fold(0, (sum, d) => sum + d.total);
          final completed = days.fold(0, (sum, d) => sum + d.completed);
          final missed = days.fold(0, (sum, d) => sum + d.missed);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(completed: completed, total: total),
              const SizedBox(height: 16),
              total == 0 ? const _EmptyCard() : _ChartCard(days: days),
              const SizedBox(height: 16),
              _HighlightsCard(days: days, missed: missed),
            ],
          );
        }),
      ),
    );
  }
}

// ============================================================
// Cards
// ============================================================

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final percent = total == 0 ? 0 : (completed / total * 100).round();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$percent%',
            style: text.displaySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '$completed of $total tasks completed',
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 40,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'No tasks this week yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Bar chart
// ============================================================

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.days});
  final List<DayStat> days;

  @override
  Widget build(BuildContext context) {
    final maxTotal = days.fold(0, (m, d) => math.max(m, d.total));
    final dayName = DateFormat('E');

    // What a screen reader says instead of the drawing
    final label = days
        .map(
          (d) => '${dayName.format(d.day)}: ${d.completed} completed, '
              '${d.missed} missed, ${d.remaining} remaining',
        )
        .join('. ');

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: label,
            child: ExcludeSemantics(
              child: SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      Expanded(
                        child: _Bar(
                          stat: days[i],
                          maxTotal: maxTotal,
                          isToday: i == days.length - 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _Legend(),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.stat,
    required this.maxTotal,
    required this.isToday,
  });
  final DayStat stat;
  final int maxTotal;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<TaskColors>()!;
    final ratio = maxTotal == 0 ? 0.0 : stat.total / maxTotal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // Number of completed tasks above the bar
          SizedBox(
            height: 16,
            child: stat.completed > 0
                ? FittedBox(
                    child: Text(
                      '${stat.completed}',
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: _motion(context, 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          width: 18,
                          height: math.max(6, box.maxHeight * value),
                          child: stat.total == 0
                              ? ColoredBox(color: colors.todo)
                              : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch, // new
                                  children: [
                                    _Segment(stat.remaining, colors.todo),
                                    _Segment(stat.missed, scheme.error),
                                    _Segment(stat.completed, colors.done),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              DateFormat('E').format(stat.day),
              style: text.labelMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One colored part of a bar, sized by its task count.
class _Segment extends StatelessWidget {
  const _Segment(this.count, this.color);
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Expanded(flex: count, child: ColoredBox(color: color));
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TaskColors>()!;
    final error = Theme.of(context).colorScheme.error;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: colors.done, label: 'Completed'),
        _LegendItem(color: error, label: 'Missed'),
        _LegendItem(color: colors.todo, label: 'Remaining'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

// ============================================================
// Highlights
// ============================================================

class _HighlightsCard extends StatelessWidget {
  const _HighlightsCard({required this.days, required this.missed});
  final List<DayStat> days;
  final int missed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<TaskColors>()!;

    // Day with the most completed tasks (the earlier day wins a tie)
    DayStat? best;
    for (final d in days) {
      if (d.completed > 0 && (best == null || d.completed > best.completed)) {
        best = d;
      }
    }
    final streak = currentStreak(days);

    return _Card(
      child: Column(
        children: [
          _Row(
            icon: Icons.emoji_events_rounded,
            color: colors.done,
            text: best == null
                ? 'Best day: none yet'
                : 'Best day: ${DateFormat('EEEE').format(best.day)}'
                    ' · ${best.completed} done',
          ),
          const SizedBox(height: 12),
          _Row(
            icon: Icons.event_busy_rounded,
            color: scheme.error,
            text: 'Missed this week: $missed',
          ),
          const SizedBox(height: 12),
          _Row(
            icon: Icons.local_fire_department_rounded,
            color: colors.doing,
            text: 'Current streak: $streak ${streak == 1 ? 'day' : 'days'}',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
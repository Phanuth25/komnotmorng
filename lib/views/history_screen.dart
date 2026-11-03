import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/core/task_colors.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/schedules/delete_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

/// Animation length that becomes 0 when the phone's "reduce motion" is on.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

/// One line of the list: either a day header or a task.
abstract class _Row {
  const _Row();
  Key get key;
}

class _HeaderRow extends _Row {
  const _HeaderRow(this.label);
  final String label;
  @override
  Key get key => ValueKey('day-$label');
}

class _TaskRow extends _Row {
  const _TaskRow(this.schedule);
  final Schedule schedule;
  @override
  Key get key => ValueKey(schedule.id);
}

// ============================================================
// Screen
// ============================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final vm = Get.find<SelectScheduleVM>();
  final deleteSche = Get.find<DeleteScheduleVM>();
  final removing = <int>{}.obs; // tasks fading out while being deleted

  // ---------- Data ----------

  // The day a schedule ended (time removed)
  DateTime endDay(Schedule s) =>
      DateTime(s.endAt.year, s.endAt.month, s.endAt.day);

  // History = tasks that ended before today, newest first, without cancelled
  List<Schedule> history() {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final list = [
      for (final s in vm.schedules)
        if (s.status != 'cancelled' && endDay(s).isBefore(today)) s,
    ];
    list.sort((a, b) => b.endAt.compareTo(a.endAt));
    return list;
  }

  // "Yesterday", "Friday, 23 October" or "23 October 2025"
  String dayLabel(DateTime day) {
    final n = DateTime.now();
    if (day == DateTime(n.year, n.month, n.day - 1)) return 'Yesterday';
    final format = day.year == n.year ? 'EEEE, d MMMM' : 'd MMMM yyyy';
    return DateFormat(format).format(day);
  }

  // A day header whenever the day changes, then the tasks of that day
  List<_Row> buildRows(List<Schedule> list) {
    final rows = <_Row>[];
    DateTime? lastDay;
    for (final s in list) {
      final day = endDay(s);
      if (day != lastDay) {
        rows.add(_HeaderRow(dayLabel(day)));
        lastDay = day;
      }
      rows.add(_TaskRow(s));
    }
    return rows;
  }

  // ---------- Actions ----------

  // Ask first, fade the task out, then delete it
  Future<void> deleteTask(Schedule s) async {
    final scheme = Theme.of(context).colorScheme;
    final yes = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this task?'),
        content: Text(s.title, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;

    removing.add(s.id); // starts the fade-out
    await Future.delayed(_motion(context, 200));

    final ok = await deleteSche.deleteSchedule(s.id);
    if (!ok) {
      removing.remove(s.id); // bring it back
      Get.snackbar('Delete failed', 'Please try again');
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        final list = history();
        final error = vm.errorMessage.value;

        final Widget content;
        if (list.isNotEmpty) {
          content = body(list);
        } else if (vm.isLoading.value) {
          content = const _Message(key: ValueKey('loading'), loading: true);
        } else if (error.isNotEmpty) {
          content = _Message(
            key: const ValueKey('error'),
            icon: Icons.cloud_off_outlined,
            title: error,
            onRetry: vm.fetchSchedules,
          );
        } else {
          content = const _Message(
            key: ValueKey('empty'),
            icon: Icons.history,
            title: 'No history yet',
            body: 'Tasks you finish or miss will show up here.',
          );
        }

        return AnimatedSwitcher(
          duration: _motion(context, 200),
          child: content,
        );
      }),
    );
  }

  Widget body(List<Schedule> list) {
    final rows = buildRows(list);
    final done = list.where((s) => s.status == 'completed').length;
    final bottom = MediaQuery.paddingOf(context).bottom + 24;

    // lets the list keep each row attached to its task when the list changes
    final indexOfKey = {for (var i = 0; i < rows.length; i++) rows[i].key: i};

    return CustomScrollView(
      key: const ValueKey('list'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(
                child: _SummaryCard(done: done, missed: list.length - done),
              ),
              SliverList.builder(
                itemCount: rows.length,
                findChildIndexCallback: (key) => indexOfKey[key],
                itemBuilder: (_, i) {
                  final row = rows[i];
                  if (row is _HeaderRow) {
                    return _DayHeader(key: row.key, label: row.label);
                  }
                  final s = (row as _TaskRow).schedule;
                  // its own Obx, because itemBuilder runs outside the parent Obx
                  return Obx(
                    () => _HistoryTile(
                      schedule: s,
                      removing: removing.contains(s.id),
                      onDelete: () => deleteTask(s),
                    ),
                    key: row.key,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Small widgets
// ============================================================

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    this.icon,
    this.title = '',
    this.body,
    this.loading = false,
    this.onRetry,
  });
  final IconData? icon;
  final String title;
  final String? body;
  final bool loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (loading) return const Center(child: CircularProgressIndicator());

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: text.titleMedium),
            if (body != null) ...[
              const SizedBox(height: 4),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.done, required this.missed});
  final int done;
  final int missed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<TaskColors>()!;

    final total = done + missed;
    final rate = total == 0 ? 0.0 : done / total;
    final percent = (rate * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Semantics(
        label: '$done completed, $missed missed, $percent percent completion',
        child: ExcludeSemantics(
          child: Row(
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: rate),
                          duration: _motion(context, 280),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 7,
                            color: colors.done,
                            backgroundColor: colors.todo,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: FittedBox(
                          child: Text(
                            '$percent%',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  count: done,
                  label: 'completed',
                  color: colors.done,
                ),
              ),
              Expanded(
                child: _Stat(count: missed, label: 'missed', color: colors.todo),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.count, required this.label, required this.color});
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$count',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.schedule,
    required this.removing,
    required this.onDelete,
  });
  final Schedule schedule;
  final bool removing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<TaskColors>()!;

    final s = schedule;
    final done = s.status == 'completed';
    final fmt = DateFormat('h:mm a');
    final time = '${fmt.format(s.startAt)} – ${fmt.format(s.endAt)}';

    final card = Container(
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
              label: 'Status: ${done ? 'Completed' : 'Missed'}',
              child: Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: done ? colors.done : colors.todo,
                      width: 4,
                    ),
                  ),
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
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete "${s.title}"',
            icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    // Removal: fade out and collapse
    return ClipRect(
      child: AnimatedSize(
        duration: _motion(context, 200),
        curve: Curves.easeOut,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: removing ? 0.0 : 1.0,
          child: AnimatedOpacity(
            duration: _motion(context, 200),
            opacity: removing ? 0 : 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: card,
            ),
          ),
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
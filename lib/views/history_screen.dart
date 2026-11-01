import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/schedules/delete_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

const _blue = Color(0xFF6C7CF0);
const _green = Color(0xFF9FE0B8);
const _grey = Color(0xFFE3E4EA);

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // ---------- Data ----------

  // The day a schedule ended (time removed)
  DateTime endDay(Schedule s) =>
      DateTime(s.endAt.year, s.endAt.month, s.endAt.day);

  // History = tasks that ended before today, newest first, without cancelled
  List<Schedule> history(SelectScheduleVM vm) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return vm.schedules
        .where((s) => s.status != 'cancelled' && endDay(s).isBefore(today))
        .toList()
      ..sort((a, b) => b.endAt.compareTo(a.endAt));
  }

  // "Yesterday", "Friday, 23 October" or "23 October 2025"
  String dayLabel(DateTime day) {
    final n = DateTime.now();
    if (day == DateTime(n.year, n.month, n.day - 1)) return 'Yesterday';
    final format = day.year == n.year ? 'EEEE, d MMMM' : 'd MMMM yyyy';
    return DateFormat(format).format(day);
  }

  Color priorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return Colors.red;
    if (p == 'medium') return Colors.orange;
    return Colors.blueGrey;
  }

  // ---------- Actions ----------

  Future<void> askToDelete(Schedule s) async {
    final delete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this task?'),
        content: Text(s.title),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (delete != true) return;

    final ok = await Get.find<DeleteScheduleVM>().deleteSchedule(s.id);
    if (!ok) Get.snackbar('Delete failed', 'Please try again');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<SelectScheduleVM>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        final list = history(vm);
        if (list.isEmpty) {
          return const Center(child: Text('No history yet'));
        }

        final done = list.where((s) => s.status == 'completed').length;
        final missed = list.length - done;
        final rate = (done / list.length * 100).round();

        // Date header whenever the day changes, then the task cards
        final items = <Widget>[];
        DateTime? lastDay;
        for (final s in list) {
          final day = endDay(s);
          if (day != lastDay) {
            items.add(dayHeader(dayLabel(day)));
            lastDay = day;
          }
          items.add(taskCard(s));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [summaryCard(done, missed, rate), ...items],
        );
      }),
    );
  }

  Widget summaryCard(int done, int missed, int rate) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        stat('$done', 'completed', _green),
        stat('$missed', 'missed', _grey),
        stat('$rate%', 'completion', _blue),
      ],
    ),
  );

  Widget stat(String value, String label, Color color) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ),
    ],
  );

  Widget dayHeader(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    ),
  );

  Widget taskCard(Schedule s) {
    final time =
        '${DateFormat('h:mm a').format(s.startAt)} – '
        '${DateFormat('h:mm a').format(s.endAt)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              color: s.status == 'completed' ? _green : _grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${s.categoryName} · $time',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
            priorityPill(s.priority),
            if (s.status == 'completed')
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: _blue),
              ),
            IconButton(
              onPressed: () => askToDelete(s),
              icon: const Icon(Icons.delete_outline, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }

  Widget priorityPill(String priority) {
    if (priority.isEmpty) return const SizedBox();
    final color = priorityColor(priority);
    final label = priority[0].toUpperCase() + priority.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
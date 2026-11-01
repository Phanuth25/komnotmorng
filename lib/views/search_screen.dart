import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

const _blue = Color(0xFF6C7CF0);
const _green = Color(0xFF9FE0B8);
const _grey = Color(0xFFE3E4EA);

// filter key -> label shown on the chip
const _filters = {
  'all': 'All',
  'done': 'Completed',
  'doing': 'In progress',
  'todo': 'To do',
  'missed': 'Missed',
};

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final selectSche = Get.find<SelectScheduleVM>();
  final query = ''.obs;
  final filter = 'all'.obs;

  // The API labels wall-clock times as "Z", so read them as local time
  DateTime wallClock(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute);

  // 'done', 'doing', 'todo' or 'missed' (same rules as the home screen)
  String stateOf(Schedule s) {
    final now = DateTime.now();
    if (s.status == 'completed') return 'done';
    if (now.isBefore(wallClock(s.startAt))) return 'todo';
    if (now.isBefore(wallClock(s.endAt))) return 'doing';
    return 'missed';
  }

  // Same bar colors as the home screen
  Color stateColor(String state) {
    if (state == 'done') return _green;
    if (state == 'doing') return _blue;
    return _grey;
  }

  Color priorityColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'high') return Colors.red;
    if (p == 'medium') return Colors.orange;
    return Colors.blueGrey; // low or anything else
  }

  // Small label like "High"
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

  // Tasks that match the typed text AND the chosen filter, newest first
  List<Schedule> get results {
    final q = query.value.trim().toLowerCase();
    final f = filter.value;
    if (q.isEmpty && f == 'all') return []; // nothing to search yet

    return selectSche.schedules.where((s) {
      final textOk =
          q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.categoryName.toLowerCase().contains(q);
      final stateOk = f == 'all' || stateOf(s) == f;
      return s.status != 'cancelled' && textOk && stateOk;
    }).toList()..sort((a, b) => b.startAt.compareTo(a.startAt));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
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
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => query.value = v,
                      decoration: InputDecoration(
                        hintText: 'Search tasks',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
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
                            selectedColor: _blue,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: filter.value == e.key
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results
              Expanded(
                child: Obx(() {
                  final list = results;

                  if (query.value.trim().isEmpty && filter.value == 'all') {
                    return const Center(
                      child: Text('Type to search your tasks'),
                    );
                  }
                  if (list.isEmpty) {
                    return const Center(child: Text('No tasks found'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return Container(
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
                              color: stateColor(stateOf(s)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${s.categoryName} · '
                                    '${DateFormat('d MMM, h:mm a').format(s.startAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            priorityPill(s.priority),
                            if (s.status == 'completed') ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle, color: _blue),
                            ],
                          ],
                        ),
                      );
                    },
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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/update_sche_vm.dart';

const blue = Color(0xFF6C7CF0);
const green = Color(0xFF9FE0B8);
const grey = Color(0xFFE3E4EA);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final selectSche = Get.find<SelectScheduleVM>();
  final updateSche = Get.find<UpdateScheduleVM>();

  final userName = ''.obs;
  final nowTime = DateTime.now().obs; // updates every minute
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      nowTime.value = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectSche.fetchSchedules();
    });
    LocalStorage.getName().then((n) => userName.value = n);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ---------- Data ----------

  // Today's schedules, without cancelled ones
  List<Schedule> get todays => selectSche.schedules
      .where((s) => isToday(s) && s.status != 'cancelled')
      .toList();

  // The API labels wall-clock times as "Z", so read them as local time
  DateTime wallClock(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute);

  bool isToday(Schedule s) {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final start = DateTime(s.startAt.year, s.startAt.month, s.startAt.day);
    final end = DateTime(s.endAt.year, s.endAt.month, s.endAt.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  // 'done', 'doing', 'todo' or 'missed'
  String stateOf(Schedule s) {
    final now = nowTime.value;
    if (s.status == 'completed') return 'done';
    if (now.isBefore(wallClock(s.startAt))) return 'todo';
    if (now.isBefore(wallClock(s.endAt))) return 'doing';
    return 'missed';
  }

  int count(String state) => todays.where((s) => stateOf(s) == state).length;

  Color colorOf(String state) {
    if (state == 'done') return green;
    if (state == 'doing') return blue;
    return grey;
  }

  String tasks(int n) => '$n ${n == 1 ? 'task' : 'tasks'}';

  // ---------- Actions ----------

  // Tap the check: ask first, save only if the user presses Save
  Future<void> askToSave(Schedule s) async {
    final isDone = s.status == 'completed';

    final save = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isDone ? 'Mark as not done?' : 'Mark as completed?'),
        content: Text(s.title),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save != true) return;

    final ok = await updateSche.updateStatus(
      s.id,
      isDone ? 'scheduled' : 'completed',
    );
    if (!ok) Get.snackbar('Save failed', 'Please try again');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      key: scaffoldKey,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('log out'),
              onTap: () => Get.find<LoginViewModel>().logout(),
            ),
          ],
        ),
      ),
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFFD9DEFF), Color(0xFFF7F8FC)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              // Search + avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.search, color: Colors.black87),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.brown,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date + greeting
              Text(
                'Today is $date',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  'Morning, ${userName.value} 👋',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => Text(
                  '${tasks(todays.length)} for today',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Stats card
              Obx(() {
                final total = todays.length;
                final done = count('done');
                final doing = count('doing');
                return card(
                  Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: total == 0 ? 0 : (done + doing) / total,
                              strokeWidth: 7,
                              color: blue,
                              backgroundColor: grey,
                            ),
                            CircularProgressIndicator(
                              value: total == 0 ? 0 : done / total,
                              strokeWidth: 7,
                              color: green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      stat(green, tasks(done), 'completed'),
                      const Spacer(),
                      stat(blue, tasks(doing), 'in progress'),
                      const Spacer(),
                      stat(grey, tasks(count('todo')), 'left to do'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Task list
              Obx(
                () => Column(
                  children: [
                    for (final s in todays)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card(
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 36,
                                color: colorOf(stateOf(s)),
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
                                      '${DateFormat('h:mm a').format(s.startAt)} – '
                                      '${DateFormat('h:mm a').format(s.endAt)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => askToSave(s),
                                icon: Icon(
                                  stateOf(s) == 'done'
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/ScheduleScreen'),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            nav(Icons.home_rounded, 'Home', true),
            nav(Icons.calendar_today_outlined, 'Calendar'),
            const SizedBox(width: 48),
            nav(Icons.auto_awesome_outlined, 'Assistant'),
            nav(Icons.bar_chart_rounded, 'Statistics'),
          ],
        ),
      ),
    );
  }

  Widget card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget stat(Color color, String count, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
    ],
  );

  Widget nav(IconData icon, String label, [bool active = false]) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: active ? blue : Colors.black45),
      Text(
        label,
        style: TextStyle(fontSize: 11, color: active ? blue : Colors.black45),
      ),
    ],
  );
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

const blue = Color(0xFF6C7CF0);
const green = Color(0xFF9FE0B8);
const grey = Color(0xFFE3E4EA);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final userName = ''.obs;
  final nowTime = DateTime.now().obs; // updates every minute
  Timer? _timer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SelectScheduleVM selectSche = Get.find<SelectScheduleVM>();

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    // Refresh the clock every minute so "in progress" stays correct
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      nowTime.value = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectSche.fetchSchedules();
    });
    LocalStorage.getName().then((n) => userName.value = n);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- Data helpers ----------

  // Today's schedules, without cancelled ones
  List<Schedule> get todays => selectSche.schedules
      .where((s) => isToday(s) && s.status != 'cancelled')
      .toList();

  // The API sends wall-clock times labeled "Z", so rebuild them as local times
  DateTime wallClock(DateTime d) =>
      DateTime(d.year, d.month, d.day, d.hour, d.minute);

  // Returns 'done', 'todo', 'doing' or 'missed'
  String stateOf(Schedule s) {
    if (s.status == 'completed') return 'done';
    final now = nowTime.value;
    if (now.isBefore(wallClock(s.startAt))) return 'todo'; // not started yet
    if (now.isBefore(wallClock(s.endAt))) return 'doing'; // happening now
    return 'missed'; // ended but never completed
  }

  Color stateColor(String state) {
    if (state == 'done') return green;
    if (state == 'doing') return blue;
    return grey; // 'todo' and 'missed'
  }

  String taskWord(int n) => '$n ${n == 1 ? 'task' : 'tasks'}';

  String timeRange(Schedule s) =>
      '${DateFormat('h:mm a').format(s.startAt)} – ${DateFormat('h:mm a').format(s.endAt)}';

  // True if today falls between the schedule start day and end day.
  // Uses startAt/endAt as-is: the API stores the times you typed (wall-clock)
  // but labels them "Z", so toLocal() would wrongly add +7 hours.
  bool isToday(Schedule s) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(s.startAt.year, s.startAt.month, s.startAt.day);
    final end = DateTime(s.endAt.year, s.endAt.month, s.endAt.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayNumber = DateFormat('d');
    final dayName = DateFormat('EEEE');
    final monthName = DateFormat('MMMM');
    final text =
        'Today is ${dayName.format(now)}, ${dayNumber.format(now)} ${monthName.format(now)}';
    final LoginViewModel loginViewModel = Get.find<LoginViewModel>();

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('log out'),
              onTap: () => loginViewModel.logout(),
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
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
                        onTap: openDrawer,
                        child: const Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.brown,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 4,
                                backgroundColor: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(text, style: const TextStyle(color: Colors.black54)),
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

                  // Header count
                  Obx(
                    () => Text(
                      '${taskWord(todays.length)} for today',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats card
                  Obx(() {
                    final list = todays;
                    final total = list.length;
                    final done = list.where((s) => stateOf(s) == 'done').length;
                    final doing =
                        list.where((s) => stateOf(s) == 'doing').length;
                    final left = list.where((s) => stateOf(s) == 'todo').length;

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
                                  value:
                                      total == 0 ? 0 : (done + doing) / total,
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
                          stat(green, taskWord(done), 'completed'),
                          const Spacer(),
                          stat(blue, taskWord(doing), 'in progress'),
                          const Spacer(),
                          stat(grey, taskWord(left), 'left to do'),
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
                                    color: stateColor(stateOf(s)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          timeRange(s),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    stateOf(s) == 'done'
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: blue,
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
        ),
      ),

      // Center "+" button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/ScheduleScreen'),
        backgroundColor: blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),

      // Bottom nav
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

  Widget stat(Color c, String a, String b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: c),
          const SizedBox(width: 4),
          Text(
            a,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      Text(b, style: const TextStyle(fontSize: 10, color: Colors.black45)),
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
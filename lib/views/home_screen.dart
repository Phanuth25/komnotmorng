import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';

const blue = Color(0xFF6C7CF0);
const green = Color(0xFF9FE0B8);
const grey = Color(0xFFE3E4EA);

class Task {
  final String title, time;
  final Color color;
  bool done;
  Task(this.title, this.time, this.color, [this.done = false]);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  final tabs = ['All Tasks', 'Personal', 'Work'];
  final tasks = [
    Task('Breakfast with Alice', '9:30–10:30 AM', green, true),
    Task('Prepare daily meeting notes', '11–11:30 AM', blue),
    Task('Prepare daily meeting notes', '1–2 PM', grey),
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SelectScheduleVM selectSche =
      Get.find<SelectScheduleVM>(); // Access the LoginViewModel instance
  void openDrawer() {
    // Implement your drawer opening logic here
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectSche.fetchSchedules();
  }

  @override
  Widget build(BuildContext context) {
    // final width = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final dayNumber = DateFormat('d'); // "12"
    final dayName = DateFormat('EEEE'); // "Tuesday"
    final monthName = DateFormat('MMMM'); // "June"
    final text =
        'Today is ${dayName.format(now)}, ${dayNumber.format(now)} ${monthName.format(now)}';
    final LoginViewModel loginViewModel =
        Get.find<LoginViewModel>(); // Access the LoginViewModel instance

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
              onTap: () {
                // Handle item 1 tap
                loginViewModel
                    .logout(); // Call the logout method from the ViewModel
              },
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
              constraints: BoxConstraints(maxWidth: double.infinity),
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
                        onTap: () =>
                            openDrawer(), // Call the openDrawer function when tapped
                        child: Stack(
                          children: [
                            const CircleAvatar(
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
                  Text(text, style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Obx(() {
                    // Use Obx to listen for changes in userName
                    final name = loginViewModel.userName.value;
                    return Text(
                      'Morning, $name 👋',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Tabs build it here
                  Obx(() {
                    if (selectSche.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (selectSche.errorMessage.value.isNotEmpty) {
                      return Column(
                        children: [
                          Text(
                            selectSche.errorMessage.value,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: selectSche.fetchSchedules,
                            child: const Text('Retry'),
                          ),
                        ],
                      );
                    }
                    // One "All tasks" chip first, then each category once.
                    final categories = selectSche.schedules
                        .map((s) => s.categoryName)
                        .toSet()
                        .toList();
                    return SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) return _chip('All tasks');
                          return _chip(categories[index - 1]);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text(
                    '6 tasks for today',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  // Stats card
                  card(
                    Row(
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: Stack(
                            fit: StackFit.expand,
                            children: const [
                              CircularProgressIndicator(
                                value: 4 / 6,
                                strokeWidth: 7,
                                color: blue,
                                backgroundColor: grey,
                              ),
                              CircularProgressIndicator(
                                value: 3 / 6,
                                strokeWidth: 7,
                                color: green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        stat(green, '3 tasks', 'completed'),
                        const Spacer(),
                        stat(blue, '1 task', 'in progress'),
                        const Spacer(),
                        stat(grey, '2 tasks', 'left to do'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Task list
                  for (final t in tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card(
                        Row(
                          children: [
                            Container(width: 4, height: 36, color: t.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    t.time,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => t.done = !t.done),
                              child: Icon(
                                t.done
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
          ),
        ),
      ),

      // Center "+" button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(
            '/ScheduleScreen',
          ); // Navigate to ScheduleScreen using GetX
        },
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

  // One rounded chip with centered text.
Widget _chip(String text) => Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: grey),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
}
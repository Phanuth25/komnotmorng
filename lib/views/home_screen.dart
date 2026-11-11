import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:komnotmorng2/core/task_colors.dart';
import 'package:komnotmorng2/core/theme_controller.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/models/schedules/schedules_model.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/delete_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/update_sche_vm.dart';
import 'package:komnotmorng2/views/calender_screen.dart';
import 'package:komnotmorng2/views/history_screen.dart';
import 'package:komnotmorng2/views/search_screen.dart';

// ============================================================
// Small helpers and data types
// ============================================================

/// Animation length that becomes 0 when the phone's "reduce motion" is on.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

String _tasks(int n) => '$n ${n == 1 ? 'task' : 'tasks'}';

String _greeting(int hour) {
  if (hour >= 5 && hour < 12) return 'Morning';
  if (hour >= 12 && hour < 17) return 'Afternoon';
  return 'Evening';
}

enum _State { done, doing, todo, missed }

class _Item {
  const _Item(this.schedule, this.state);
  final Schedule schedule;
  final _State state;
}

/// Today's tasks and the counts, calculated once per rebuild.
class _Summary {
  const _Summary(this.items, this.done, this.doing, this.todo);
  final List<_Item> items;
  final int done;
  final int doing;
  final int todo;
  int get total => items.length;
}

// ============================================================
// Screen
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final selectSche = Get.find<SelectScheduleVM>();
  final updateSche = Get.find<UpdateScheduleVM>();
  final deleteSche = Get.find<DeleteScheduleVM>();

  final userName = ''.obs;
  final nowTime = DateTime.now().obs; // updates every minute
  final removing = <int>{}.obs; // tasks fading out while being deleted
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      nowTime.value = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectSche.schedules.clear(); // forget a previous user's list
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

  _State stateOf(Schedule s, DateTime now) {
    if (s.status == 'completed') return _State.done;
    if (now.isBefore(wallClock(s.startAt))) return _State.todo;
    if (now.isBefore(wallClock(s.endAt))) return _State.doing;
    return _State.missed;
  }

  /// Today's tasks (cancelled hidden) with their state and the counts.
  _Summary summary() {
    final now = nowTime.value;
    final items = <_Item>[];
    for (final s in selectSche.schedules) {
      if (isToday(s) && s.status != 'cancelled') {
        items.add(_Item(s, stateOf(s, now)));
      }
    }
    int count(_State st) => items.where((i) => i.state == st).length;
    return _Summary(
      items,
      count(_State.done),
      count(_State.doing),
      count(_State.todo),
    );
  }

  // ---------- Actions ----------

  Future<bool> confirm({
    required String title,
    required String body,
    required String yes,
    bool danger = false,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: danger
                ? TextButton.styleFrom(foregroundColor: scheme.error)
                : null,
            child: Text(yes),
          ),
        ],
      ),
    );
    return result == true;
  }

  // Check icon: ask first, save only if the user presses Save
  Future<void> toggleDone(Schedule s) async {
    final isDone = s.status == 'completed';
    final yes = await confirm(
      title: isDone ? 'Mark as not done?' : 'Mark as completed?',
      body: s.title,
      yes: 'Save',
    );
    if (!yes) return;

    final ok = await updateSche.updateStatus(
      s.id,
      isDone ? 'scheduled' : 'completed',
    );
    if (!ok) Get.snackbar('Save failed', 'Please try again');
  }

  // Trash icon: ask first, fade the task out, then delete it
  Future<void> deleteTask(Schedule s) async {
    final yes = await confirm(
      title: 'Delete this task?',
      body: s.title,
      yes: 'Delete',
      danger: true,
    );
    if (!yes || !mounted) return;

    removing.add(s.id); // starts the fade-out
    await Future.delayed(_motion(context, 200));

    final ok = await deleteSche.deleteSchedule(s.id);
    if (!ok) {
      removing.remove(s.id); // bring it back
      Get.snackbar('Delete failed', 'Please try again');
    }
  }

  void closeDrawerThen(VoidCallback go) {
    scaffoldKey.currentState?.closeDrawer();
    go();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: scaffoldKey,
      extendBody: true,
      drawer: _HomeDrawer(
        userName: userName,
        summary: summary,
        onClose: () => scaffoldKey.currentState?.closeDrawer(),
        onSearch: () =>
            closeDrawerThen(() => Get.to(() => const SearchScreen())),
        onHistory: () =>
            closeDrawerThen(() => Get.to(() => const HistoryScreen())),
        onLogout: () => Get.find<LoginViewModel>().logout(),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [scheme.primaryContainer, scheme.surface],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    userName: userName,
                    nowTime: nowTime,
                    onSearch: () => Get.to(() => const SearchScreen()),
                    onMenu: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
              ),
              Obx(() => body(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create task',
        onPressed: () => Get.toNamed('/ScheduleScreen'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: _BottomNav(
        onCalendar: () => Get.to(() => const CalendarScreen()),
      ),
    );
  }

  // Everything below the header. Runs inside Obx, so it rebuilds when the
  // schedules, the loading state, or the minute clock change.
  Widget body(BuildContext context) {
    final data = summary();
    final hasItems = data.items.isNotEmpty;
    final error = selectSche.errorMessage.value;

    // loading / error / empty are swapped with a fade
    Widget placeholder = const SizedBox.shrink(key: ValueKey('content'));
    if (!hasItems) {
      if (selectSche.isLoading.value) {
        placeholder = const _LoadingView(key: ValueKey('loading'));
      } else if (error.isNotEmpty) {
        placeholder = _ErrorView(
          key: const ValueKey('error'),
          message: error,
          onRetry: selectSche.fetchSchedules,
        );
      } else {
        placeholder = const _EmptyView(key: ValueKey('empty'));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (hasItems)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_tasks(data.total)} for today',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _StatsCard(summary: data),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: _motion(context, 200),
              child: placeholder,
            ),
          ),
          SliverList.builder(
            itemCount: data.items.length,
            // keeps each tile attached to its task when the list changes
            findChildIndexCallback: (key) {
              if (key is! ValueKey<int>) return null;
              final i = data.items.indexWhere(
                (e) => e.schedule.id == key.value,
              );
              return i < 0 ? null : i;
            },
            itemBuilder: (_, i) {
              final item = data.items[i];
              final s = item.schedule;
              // its own Obx, because itemBuilder runs outside the parent Obx
              return Obx(
                () => _TaskTile(
                  item: item,
                  index: i,
                  removing: removing.contains(s.id),
                  onToggle: () => toggleDone(s),
                  onDelete: () => deleteTask(s),
                ),
                key: ValueKey(s.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Small widgets
// ============================================================

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

/// Search + menu buttons, date and greeting.
class _Header extends StatelessWidget {
  const _Header({
    required this.userName,
    required this.nowTime,
    required this.onSearch,
    required this.onMenu,
  });
  final RxString userName;
  final Rx<DateTime> nowTime;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              color: scheme.surfaceContainerLowest,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: onSearch,
                tooltip: 'Search',
                icon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onMenu,
              tooltip: 'Open menu',
              padding: EdgeInsets.zero,
              icon: CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                child: Icon(Icons.person, color: scheme.onSecondaryContainer),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Obx(() {
          final now = nowTime.value;
          final name = userName.value;
          final hello = _greeting(now.hour);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today is ${DateFormat('EEEE, d MMMM').format(now)}',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name.isEmpty ? '$hello 👋' : '$hello, $name 👋',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.summary});
  final _Summary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<TaskColors>()!;
    final total = summary.total;
    final doneShare = total == 0 ? 0.0 : summary.done / total;
    final activeShare = total == 0
        ? 0.0
        : (summary.done + summary.doing) / total;

    return _Card(
      child: Semantics(
        label:
            '${summary.done} completed, ${summary.doing} in progress, '
            '${summary.todo} left to do',
        child: ExcludeSemantics(
          child: Row(
            children: [
              RepaintBoundary(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Ring(
                        value: activeShare,
                        color: colors.doing,
                        track: colors.todo,
                      ),
                      _Ring(value: doneShare, color: colors.done),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  color: colors.done,
                  count: summary.done,
                  label: 'completed',
                ),
              ),
              Expanded(
                child: _Stat(
                  color: colors.doing,
                  count: summary.doing,
                  label: 'in progress',
                ),
              ),
              Expanded(
                child: _Stat(
                  color: colors.todo,
                  count: summary.todo,
                  label: 'left to do',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One ring of the donut. The value animates when it changes.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.color, this.track});
  final double value;
  final Color color;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: _motion(context, 280),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => CircularProgressIndicator(
        value: v,
        strokeWidth: 7,
        color: color,
        backgroundColor: track,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.color, required this.count, required this.label});
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _tasks(count),
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.item,
    required this.index,
    required this.removing,
    required this.onToggle,
    required this.onDelete,
  });
  final _Item item;
  final int index; // used for the small entrance stagger
  final bool removing;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).extension<TaskColors>()!;

    final s = item.schedule;
    final done = item.state == _State.done;
    final barColor = switch (item.state) {
      _State.done => colors.done,
      _State.doing => colors.doing,
      _ => colors.todo, // todo and missed
    };
    final fmt = DateFormat('h:mm a');
    final time = '${fmt.format(s.startAt)} – ${fmt.format(s.endAt)}';
    final quick = _motion(context, 150);

    final card = _Card(
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: quick,
              curve: Curves.easeOut,
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
                    time,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete "${s.title}"',
            icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
          ),
          IconButton(
            onPressed: onToggle,
            tooltip: done
                ? 'Mark "${s.title}" as not done'
                : 'Mark "${s.title}" as completed',
            icon: AnimatedSwitcher(
              duration: quick,
              child: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(done),
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );

    // Entrance: fade + slide up (later tiles take a little longer)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _motion(context, 200 + 40 * (index > 5 ? 5 : index)),
      curve: Curves.easeOut,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      // Removal: fade out and collapse
      child: ClipRect(
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
      ),
    );
  }
}

// ---------- Loading / empty / error ----------

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text('No tasks today', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Tap + to add one',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: scheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ============================================================
// Drawer and bottom bar
// ============================================================

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer({
    required this.userName,
    required this.summary,
    required this.onClose,
    required this.onSearch,
    required this.onHistory,
    required this.onLogout,
  });
  final RxString userName;
  final _Summary Function() summary;
  final VoidCallback onClose;
  final VoidCallback onSearch;
  final VoidCallback onHistory;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final themeCtrl = Get.find<ThemeController>();

    return Drawer(
      child: Column(
        children: [
          // Header: avatar, name and today's progress
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 24,
              20,
              24,
            ),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.onPrimary,
                  child: CircleAvatar(
                    radius: 29,
                    backgroundColor: scheme.secondaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Text(
                    userName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final s = summary();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.done} of ${s.total} tasks done today',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.total == 0 ? 0 : s.done / s.total,
                          minHeight: 6,
                          color: scheme.onPrimary,
                          backgroundColor: scheme.onPrimary.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                  onTap: onClose,
                ),
                _DrawerItem(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: onSearch,
                ),
                _DrawerItem(
                  icon: Icons.history,
                  label: 'History',
                  onTap: onHistory,
                ),
              ],
            ),
          ),

          // Light / dark / auto
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        tooltip: 'Follow the phone',
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        tooltip: 'Light',
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        tooltip: 'Dark',
                      ),
                    ],
                    selected: {themeCtrl.mode.value},
                    onSelectionChanged: (s) => themeCtrl.setMode(s.first),
                  ),
                ),
              ],
            ),
          ),

          // Log out at the bottom
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Log out', style: TextStyle(color: scheme.error)),
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selected: selected,
        selectedTileColor: scheme.primary.withValues(alpha: 0.12),
        selectedColor: scheme.primary,
        leading: Icon(icon),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onCalendar});
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _NavItem(Icons.home_rounded, 'Home', active: true),
          _NavItem(
            Icons.calendar_today_outlined,
            'Calendar',
            onTap: onCalendar,
          ),
          const SizedBox(width: 48), // space for the + button
          const _NavItem(Icons.auto_awesome_outlined, 'Assistant'),
          const _NavItem(Icons.bar_chart_rounded, 'Statistics'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(this.icon, this.label, {this.active = false, this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap; // null = not available yet

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = active ? scheme.primary : scheme.onSurfaceVariant;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
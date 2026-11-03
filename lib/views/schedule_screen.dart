import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/viewmodels/categories/select_cate_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/create_sche_vm.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Animation length that becomes 0 when the phone's "reduce motion" is on.
Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: ms);

// ============================================================
// Screen
// ============================================================

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final selectCateVm = Get.find<SelectCateVM>();
  final ScheduleVm scheduleVm = Get.isRegistered<ScheduleVm>()
      ? Get.find<ScheduleVm>()
      : Get.put(ScheduleVm());

  // Form values. Only the date strip needs to rebuild when the date changes,
  // so the rest of the screen never calls setState.
  final date = DateTime.now().obs;
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();
  final pickedTimes = <TextEditingController, TimeOfDay>{};
  int? categoryId;
  String? priority;
  bool remind = false;
  bool repeat = false;
  final priorities = const ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    if (selectCateVm.categories.isEmpty) selectCateVm.fetchCategories();
  }

  @override
  void dispose() {
    title.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
  }

  // ---------- Time helpers ----------

  int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  // HH:mm:ss from the picked TimeOfDay (the field text is localized, so
  // parsing it would break on 24h phones and other languages)
  String to24h(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String? notEmpty(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  String? endValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final s = pickedTimes[start];
    final e = pickedTimes[end];
    if (s != null && e != null && toMinutes(e) == toMinutes(s)) {
      return 'End time must be after start time';
    }
    return null;
  }

  // Opens the time dialog in keyboard-entry mode only (no clock dial)
  Future<void> pickTime(TextEditingController c) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );
    if (t != null && mounted) {
      pickedTimes[c] = t;
      c.text = t.format(context);
    }
  }

  // ---------- Create ----------

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    final startTod = pickedTimes[start];
    final endTod = pickedTimes[end];
    if (startTod == null || endTod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final day = date.value.toIso8601String().substring(0, 10);

    // Ask for confirmation if the task runs past midnight
    if (toMinutes(endTod) < toMinutes(startTod)) {
      final nextDate = date.value
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);

      final goOn = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('This task ends tomorrow'),
          content: Text(
            'It starts at ${start.text} and ends at ${end.text} on $nextDate.\n\n'
            'Is that correct? You may have forgotten to switch AM/PM.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Edit times'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (goOn != true || !mounted) return;
    }

    await scheduleVm.createTask(
      category_id: categoryId,
      title: title.text,
      date: day,
      start: to24h(startTod),
      end: to24h(endTod),
      priority: priority,
    );

    if (scheduleVm.errorMessage.isEmpty) {
      Get.snackbar('Success', scheduleVm.successMessage.value);
    } else {
      Get.snackbar('Error', scheduleVm.errorMessage.value);
    }
  }

  // ---------- UI ----------

  InputDecoration decoration({String? hint, Widget? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Create New Task',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _DateStrip(date: date),

                    _Labeled(
                      'TASK NAME',
                      child: TextFormField(
                        controller: title,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: decoration(hint: 'Mobile Design'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a task name';
                          }
                          if (v.trim().length < 3) {
                            return 'Use at least 3 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    _Labeled('CATEGORY', child: categoryField()),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Labeled(
                            'START TIME',
                            child: timeField(start, '12:30', notEmpty),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _Labeled(
                            'END TIME',
                            child: timeField(end, '03:00', endValidator),
                          ),
                        ),
                      ],
                    ),

                    _Labeled(
                      'PRIORITY',
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        hint: const Text('Select priority'),
                        decoration: decoration(),
                        items: [
                          for (final p in priorities)
                            DropdownMenuItem<String>(
                              value: p.toLowerCase(),
                              child: Text(p),
                            ),
                        ],
                        onChanged: (v) => priority = v,
                      ),
                    ),

                    _Labeled(
                      'NOTIFICATION',
                      child: _SwitchTile(
                        text: 'Remind me',
                        onChanged: (v) => remind = v,
                      ),
                    ),
                    _Labeled(
                      'REPEAT',
                      child: _SwitchTile(
                        text: 'Daily',
                        onChanged: (v) => repeat = v,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // The button stays visible, even with the keyboard open
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: Obx(() {
                  final loading = scheduleVm.isLoading.value;
                  return FilledButton(
                    // disabled while the request runs (no double taps)
                    onPressed: loading ? null : submit,
                    child: AnimatedSwitcher(
                      duration: _motion(context, 150),
                      child: loading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'CREATE TASK',
                              key: ValueKey('label'),
                              style: TextStyle(
                                letterSpacing: 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shows the category name, stores the id
  Widget categoryField() {
    return Obx(() {
      final loading = selectCateVm.isLoading.value;
      final failed =
          selectCateVm.errorMessage.value.isNotEmpty &&
          selectCateVm.categories.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            hint: Text(loading ? 'Loading categories…' : 'Select category'),
            decoration: decoration(),
            validator: (v) => v == null ? 'Please select a category' : null,
            items: [
              for (final c in selectCateVm.categories)
                DropdownMenuItem<int>(
                  value: c.id,
                  child: Text(c.name, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => categoryId = v,
          ),
          if (failed)
            TextButton.icon(
              onPressed: selectCateVm.fetchCategories,
              icon: const Icon(Icons.refresh),
              label: const Text("Couldn't load categories. Retry"),
            ),
        ],
      );
    });
  }

  // Read-only field: tapping it opens the time dialog
  Widget timeField(
    TextEditingController controller,
    String hint,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: true,
      onTap: () => pickTime(controller),
      decoration: decoration(
        hint: hint,
        suffix: const Icon(Icons.access_time, size: 18),
      ),
    );
  }
}

// ============================================================
// Small widgets
// ============================================================

/// Small uppercase title above a field.
class _Labeled extends StatelessWidget {
  const _Labeled(this.label, {required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              letterSpacing: 1,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Switch row that keeps its own on/off state, so toggling it
/// does not rebuild the whole form.
class _SwitchTile extends StatefulWidget {
  const _SwitchTile({required this.text, required this.onChanged});
  final String text;
  final ValueChanged<bool> onChanged;

  @override
  State<_SwitchTile> createState() => _SwitchTileState();
}

class _SwitchTileState extends State<_SwitchTile> {
  bool value = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 8),
        title: Text(widget.text),
        value: value,
        onChanged: (v) {
          setState(() => value = v);
          widget.onChanged(v);
        },
      ),
    );
  }
}

/// Month header with arrows and a scrollable row of every day in the month.
class _DateStrip extends StatefulWidget {
  const _DateStrip({required this.date});
  final Rx<DateTime> date;

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  static const dayWidth = 52.0;

  late final scroll = ScrollController(
    initialScrollOffset: (widget.date.value.day - 1) * dayWidth,
  );

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void changeMonth(int step) {
    final d = widget.date.value;
    widget.date.value = DateTime(d.year, d.month + step, 1);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // taller row when the phone's text size is large
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
        .clamp(1.0, 1.6)
        .toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(() {
        final date = widget.date.value;
        final daysInMonth = DateTime(date.year, date.month + 1, 0).day;

        return Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => changeMonth(-1),
                  tooltip: 'Previous month',
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${_months[date.month - 1]} ${date.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => changeMonth(1),
                  tooltip: 'Next month',
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            SizedBox(
              height: 72 * textScale,
              child: RepaintBoundary(
                // allow dragging with a mouse too (web/desktop block it)
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView.builder(
                    controller: scroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: daysInMonth,
                    itemExtent: dayWidth,
                    itemBuilder: (_, i) {
                      final d = DateTime(date.year, date.month, i + 1);
                      return _DayChip(
                        day: d,
                        selected: d.day == date.day,
                        onTap: () => widget.date.value = d,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekday = _weekdays[day.weekday - 1];

    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: '$weekday ${day.day}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Text(
              weekday,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: _motion(context, 150),
              curve: Curves.easeOut,
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : Colors.transparent,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
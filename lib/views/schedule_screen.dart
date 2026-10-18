import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/viewmodels/categories/select_cate_vm.dart';
import 'package:komnotmorng2/viewmodels/schedule_vm.dart';

const sky = Color(0xFF29ABE2);

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime date = DateTime.now();
  late final scroll = ScrollController(
    initialScrollOffset: (date.day - 1) * 52.0,
  );
  final SelectCateVM selectCateVm = Get.find<SelectCateVM>();
  final months = [
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

  int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String? endValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final s = pickedTimes[start];
    final e = pickedTimes[end];
    if (s != null && e != null && toMinutes(e) == toMinutes(s)) {
      return 'End time must be after start time';
    }
    return null;
  }

  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void changeMonth(int step) {
    setState(() => date = DateTime(date.year, date.month + step, 1));
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  // FIX 3: build HH:mm:ss from the picked TimeOfDay instead of parsing
  // the localized text (which breaks on 24h phones / non-English locales)
  String to24h(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  // Remembers the TimeOfDay picked for each time field
  final Map<TextEditingController, TimeOfDay> pickedTimes = {};

  bool remind = false, repeat = false;

  // Category: shows the name, uses the id (id -> name from the categories table)
  int? category_id;
  String? priority;
  final priorities = ['Low', 'Medium', 'High'];
  final categories = {
    1: 'Study',
    2: 'Work',
    3: 'Personal',
    4: 'Exercise',
    5: 'Health',
    6: 'Shopping',
    7: 'Family',
    8: 'Finance',
    9: 'Entertainment',
    10: 'Other',
  };

  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final start = TextEditingController();
  final end = TextEditingController();

  @override
  void dispose() {
    scroll.dispose();
    title.dispose();
    start.dispose();
    end.dispose();
    super.dispose();
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

  String? notEmpty(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  @override
  void initState() {
    selectCateVm.fetchCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // FIX 4: use the registered instance, or create one if none exists
    final ScheduleVm scheduleVm = Get.isRegistered<ScheduleVm>()
        ? Get.find<ScheduleVm>()
        : Get.put(ScheduleVm());
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Create New Task',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                dateStrip(),

                label('TASK NAME'),
                field(
                  'Mobile Design',
                  controller: title,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter a task name';
                    }
                    if (v.trim().length < 3) return 'Use at least 3 characters';
                    return null;
                  },
                ),

                label('CATEGORY'),
                Obx(
                  () => DropdownButtonFormField<int>(
                    hint: const Text(
                      'Select category',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                    validator: (v) =>
                        v == null ? 'Please select a category' : null,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: border,
                      focusedErrorBorder: border,
                    ),
                    // visible text = name, stored value = id
                    items: [
                      for (final c in selectCateVm.categories)
                        DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(
                            c.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => category_id = v),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('START TIME'),
                          field(
                            '12:30',
                            controller: start,
                            validator: notEmpty,
                            time: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('END TIME'),
                          field(
                            '03:00',
                            controller: end,
                            validator: endValidator,
                            time: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                label('PRIORITY'),
                DropdownButtonFormField<String>(
                  hint: const Text(
                    'Select priority',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                    errorBorder: border,
                    focusedErrorBorder: border,
                  ),
                  items: [
                    for (final p in priorities)
                      DropdownMenuItem<String>(
                        value: p.toLowerCase(),
                        child: Text(p, style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  onChanged: (v) => setState(() => priority = v),
                ),
                label('NOTIFICATION'),
                switchRow(
                  'Remind Me',
                  remind,
                  Colors.green,
                  (v) => setState(() => remind = v),
                ),

                label('REPEAT'),
                switchRow('Daily', repeat, Colors.green, (v) {
                  setState(() => repeat = v);
                }),

                const SizedBox(height: 24),

                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: Obx(
                    () => FilledButton(
                      // disabled while the request is running (no double taps)
                      onPressed: scheduleVm.isLoading.value
                          ? null
                          : () async {
                              // FIX 2: stop here if the form is invalid
                              if (!formKey.currentState!.validate()) return;

                              final startTod = pickedTimes[start];
                              final endTod = pickedTimes[end];
                              if (startTod == null || endTod == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill in all required fields',
                                    ),
                                  ),
                                );
                                return;
                              }
                              // Ask for confirmation if the task runs past midnight
                              if (toMinutes(endTod) < toMinutes(startTod)) {
                                final nextDate = date
                                    .add(const Duration(days: 1))
                                    .toIso8601String()
                                    .substring(0, 10);

                                final goOn = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text(
                                      'This task ends tomorrow',
                                    ),
                                    content: Text(
                                      'It starts at ${start.text} and ends at ${end.text} on $nextDate.\n\n'
                                      'Is that correct?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Edit times'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Continue'),
                                      ),
                                    ],
                                  ),
                                );

                                if (goOn != true || !mounted) return;
                              }
                              final startTime = to24h(startTod);
                              final endTime = to24h(endTod);
                              debugPrint(
                                'Creating task: ${title.text}, ${date.toIso8601String().substring(0, 10)}, $startTime, $endTime, $remind, $repeat',
                              );

                              // FIX 1: named arguments to match the view model
                              final ok = await scheduleVm.createTask(
                                category_id: category_id,
                                title: title.text,
                                date: date.toIso8601String().substring(0, 10),
                                start: startTime,
                                end: endTime,
                                priority: priority,
                              );

                              if (!mounted) return;
                              // FIX 2: message shown only after the server answers
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? scheduleVm.successMessage.value
                                        : scheduleVm.errorMessage.value,
                                  ),
                                ),
                              );
                            },
                      style: FilledButton.styleFrom(backgroundColor: sky),
                      child: scheduleVm.isLoading.value
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'CREATE TASK',
                              style: TextStyle(letterSpacing: 1, fontSize: 12),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Month header with arrows + scrollable row of every day in the month
  Widget dateStrip() => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${months[date.month - 1]} ${date.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        SizedBox(
          height: 70,
          // allow dragging with a mouse too (web/desktop block it by default)
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
            ),
            child: ListView.builder(
              controller: scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: DateTime(
                date.year,
                date.month + 1,
                0,
              ).day, // days in month
              itemBuilder: (_, i) {
                final d = DateTime(date.year, date.month, i + 1);
                final selected = d.day == date.day;
                return GestureDetector(
                  onTap: () => setState(() => date = d),
                  child: SizedBox(
                    width: 52,
                    child: Column(
                      children: [
                        Text(
                          weekdays[d.weekday - 1],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: selected ? sky : Colors.transparent,
                          child: Text(
                            '${d.day}',
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );

  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1,
        color: Colors.black87,
      ),
    ),
  );

  Widget field(
    String hint, {
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool time = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: time, // time fields open the time dialog instead of typing here
      onTap: time ? () => pickTime(controller) : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black45),
        suffixIcon: time ? const Icon(Icons.access_time, size: 18) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: border,
        focusedBorder: border,
        errorBorder: border,
        focusedErrorBorder: border,
      ),
    );
  }

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
  );

  Widget switchRow(
    String text,
    bool value,
    Color color,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black45),
          ),
          const Spacer(),
          Switch(value: value, activeThumbColor: color, onChanged: onChanged),
        ],
      ),
    );
  }
}

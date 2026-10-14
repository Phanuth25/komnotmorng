import 'package:flutter/foundation.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ScheduleVm extends GetxController {
  void createTask(
    String name,
    String date,
    String start,
    String end,
    bool remind,
    bool repeat,
  ) {
    debugPrint(
      '$name, $date, $start, $end, $remind, $repeat',
    ); // call your API here
  }
}

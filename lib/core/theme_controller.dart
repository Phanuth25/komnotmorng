import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/data/local_storage.dart';

/// Holds the chosen theme (auto / light / dark) and remembers it.
class ThemeController extends GetxController {
  ThemeController(ThemeMode initial) : mode = initial.obs;

  final Rx<ThemeMode> mode;

  /// Reads the saved choice. Falls back to "auto" (follow the phone).
  static Future<ThemeMode> load() async {
    final saved = await LocalStorage.getThemeMode();
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode m) async {
    mode.value = m;
    Get.changeThemeMode(m);
    await LocalStorage.saveThemeMode(m.name);
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/core/task_colors.dart';
import 'package:komnotmorng2/core/theme_controller.dart';
import 'package:komnotmorng2/features/splash/splash_screen.dart';
import 'package:komnotmorng2/viewmodels/categories/select_cate_vm.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/viewmodels/register_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/create_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/delete_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/update_sche_vm.dart';
import 'package:komnotmorng2/views/home_screen.dart';
import 'package:komnotmorng2/views/login_screen.dart';
import 'package:komnotmorng2/views/register_screen.dart';
import 'package:komnotmorng2/views/schedule_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the saved theme and register its controller
  final savedTheme = await ThemeController.load();
  Get.put(ThemeController(savedTheme));

  _initControllers();
  runApp(MyApp(themeMode: savedTheme));
}

void _initControllers() {
  Get.put(RegisterViewModel());
  Get.put(LoginViewModel());
  Get.put(ScheduleVm());
  Get.put(SelectCateVM());
  Get.put(SelectScheduleVM());
  Get.put(UpdateScheduleVM());
  Get.put(DeleteScheduleVM());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeMode});

  final ThemeMode themeMode;

  static const _seed = Color(0xFF6C7CF0);

  ThemeData _theme(Brightness brightness, TaskColors colors) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: brightness,
        ),
        extensions: [colors],
      );

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Komnotmorng',
      theme: _theme(Brightness.light, TaskColors.light),
      darkTheme: _theme(Brightness.dark, TaskColors.dark),
      themeMode: themeMode, // saved choice (auto / light / dark)
      defaultTransition: Transition.native,
      initialRoute: '/SplashScreen',
      getPages: [
        GetPage(name: '/SplashScreen', page: () => const SplashScreen()),
        GetPage(name: '/HomeScreen', page: () => const HomeScreen()),
        GetPage(name: '/LoginScreen', page: () => const LoginScreen()),
        GetPage(name: '/RegisterScreen', page: () => const RegisterScreen()),
        GetPage(name: '/ScheduleScreen', page: () => const ScheduleScreen()),
      ],
    );
  }
}
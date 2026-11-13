import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/core/task_colors.dart';
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
//test
//testagain

//testagain3
void main() {
  runApp(const MyApp());
  Get.put(
    RegisterViewModel(),
  ); // Register the RegisterViewModel for dependency injection
  Get.put(
    LoginViewModel(),
  ); // Register the LoginViewModel for dependency injection
  Get.put(ScheduleVm());
  Get.put(SelectCateVM());
  // Register the ScheduleVm for dependency injection
  Get.put(SelectScheduleVM());
  Get.put(UpdateScheduleVM());
  Get.put(DeleteScheduleVM());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const seed = Color(0xFF6C7CF0);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      // Light and dark themes, following the phone's setting
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        extensions: const [TaskColors.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        extensions: const [TaskColors.dark],
      ),
      themeMode: ThemeMode.system,
      // Use each platform's own page transition (Cupertino on iOS, Material on Android)
      defaultTransition: Transition.native,
      initialRoute: '/SplashScreen',
      getPages: [
        GetPage(name: '/SplashScreen', page: () => const SplashScreen()),
        GetPage(name: '/HomeScreen', page: () => const HomeScreen()),
        GetPage(name: '/LoginScreen', page: () => const LoginScreen()),
        GetPage(name: '/RegisterScreen', page: () => const RegisterScreen()),
        GetPage(name: '/ScheduleScreen', page: () => const ScheduleScreen()),
      ],
      home: const SplashScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:komnotmorng2/features/splash/splash_screen.dart';
import 'package:komnotmorng2/viewmodels/categories/select_cate_vm.dart';
import 'package:komnotmorng2/viewmodels/login_vm.dart';
import 'package:komnotmorng2/viewmodels/register_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/create_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/select_sche_vm.dart';
import 'package:komnotmorng2/viewmodels/schedules/update_sche_vm.dart';
import 'package:komnotmorng2/views/home_screen.dart';
import 'package:komnotmorng2/views/login_screen.dart';
import 'package:komnotmorng2/views/register_screen.dart';
import 'package:komnotmorng2/views/schedule_screen.dart';

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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
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

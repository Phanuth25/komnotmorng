import 'package:flutter/material.dart';
import 'package:komnotmorng2/data/local_storage.dart';
import 'package:komnotmorng2/views/home_screen.dart';
import 'package:komnotmorng2/views/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait 2 seconds before opening the next screen.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      LocalStorage.getEmail().then((email) {
        if (email.isNotEmpty) {
          // If email is found, navigate to the login screen.
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // If no email is found, navigate to the login screen.
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // Center logo with a fade-in animation.
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: const Image(
                image: AssetImage('1km.png'),
                width: 150,
                height: 150,
              ),
            ),
          ),

          // Small label at the bottom.
          const Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Text(
              'Komnot Morng',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF65676B),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

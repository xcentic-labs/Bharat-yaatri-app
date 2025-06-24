import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Delay navigation and check authentication status
    Future.delayed(const Duration(seconds: 3), () async {
      final FlutterSecureStorage secureStorage = FlutterSecureStorage();
      String? userId = await secureStorage.read(key: "userId"); // Check if user is logged in by checking secure storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;

      if (userId != null) {
        // If user ID exists, user is logged in, navigate to BottomNav (main page)
        Navigator.pushReplacementNamed(context, '/main');
      } else if (!hasSeenIntro) {
        // If user ID is not found and has not seen intro, navigate to IntroScreen
        Navigator.pushReplacementNamed(context, '/intro');
      } else {
        // If user ID is not found and has seen intro, navigate to LoginPage
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF002D4C),
      body: Center(
        child: SizedBox(
          width: 423,
          height: 423,
          child: Image.asset(
            'assets/finallogo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

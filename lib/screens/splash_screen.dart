import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    Future.delayed(const Duration(seconds: 2), () async {
      final FlutterSecureStorage secureStorage = FlutterSecureStorage();
      String? userId = await secureStorage.read(key: "userId"); // Check if user is logged in by checking secure storage

      if (userId != null) {
        // If user ID exists, user is logged in, navigate to BottomNav (main page)
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        // If user ID is not found, navigate to LoginPage
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      body: Center(
        child: Image.asset(
          'assets/logo.png', // Your GIF image
          fit: BoxFit.contain, // Ensures the GIF fits within the screen bounds
        ),
      ),
    );
  }
}

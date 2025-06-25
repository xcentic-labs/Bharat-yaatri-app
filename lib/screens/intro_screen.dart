import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Image section
          AspectRatio(
            aspectRatio: 440 / 661, // width / height of the image
            child: Image.asset(
              'assets/intropage.png',
              fit: BoxFit.contain, // Ensure it's not cut
            ),
          ),
          // Remaining content in an Expanded widget
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 0), // Removed top spacing for the text group to bring it closer to the image
                SizedBox(
                  width: 365,
                  height: 46,
                  child: const Text(
                    'Namaste, Driver Partner!',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
                const SizedBox(height: 0), // Removed spacing after title to bring button closer
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 50.0, right: 50.0), // Left 50px for button
                    child: GestureDetector(
                      onTap: () async {
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('hasSeenIntro', true);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Container(
                        width: 330,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFF002D4C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Continue with Phone Number',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Spacing after button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 19.0, right: 19.0), // Left 19px for disclaimer
                    child: SizedBox(
                      width: 369,
                      height: 34,
                      child: const Text(
                        'By continuing, you agree that you have read and accept our T&Cs and Privacy Policy',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6F6F70),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Bottom spacing
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
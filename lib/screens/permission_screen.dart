import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestLocationPermission(BuildContext context) async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      // Navigate to HomeScreen (assuming /main is the home screen)
      Navigator.pushReplacementNamed(context, '/main');
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied.')),
      );
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied. Please enable from settings.')),
      );
      openAppSettings(); // Open app settings for the user
    }
  }

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Allow Location Access',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Color(0xFF000000),
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () => _requestLocationPermission(context),
              child: Container(
                width: 330,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF002D4C),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Allow Access',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
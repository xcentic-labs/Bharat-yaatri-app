import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cabproject/bottom_nav.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Future<void> _requestPermissions() async {
    // Request Location permission
    var status = await Permission.location.request();

    if (status.isGranted) {
      // Permission granted, navigate to Home Screen (BottomNav)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav()),
      );
    } else if (status.isDenied || status.isPermanentlyDenied) {
      // Permission denied, show a message or direct to settings
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required for the app to function.')),
      );
      // Optionally open app settings
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/intropage.png', // Assuming permission.png is named intropage.png as per the project layout
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bharat Yaatri mein aapka Swagat hai',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Booking ko asaan banane ke liye yeh 2 permissions de dijiye.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                color: Color(0xFF6F6F70),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Location – Taaki aapke aaspaas ke available rides dikha sakein.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '2. Phone – Aapke number ko verify karke account secure banayein.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 330,
                height: 55,
                child: ElevatedButton(
                  onPressed: _requestPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D4C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
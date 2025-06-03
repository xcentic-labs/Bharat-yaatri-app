import 'dart:convert';
import 'package:cabproject/screens/selection_screen.dart';
import 'package:cabproject/screens/upload_photos.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_overlay_window/flutter_overlay_window.dart'; // Add this import

import '../bottom_nav.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;
  bool _isLoading = false;
  String _sessionId = "";

  final String baseUrl = "https://api.bharatyaatri.com";

  @override
  void initState() {
    super.initState();
    // Request overlay permission when the login page initializes
    _requestOverlayPermission();
  }

  // Add this function to request overlay permission
  Future<void> _requestOverlayPermission() async {
    bool? permission = await FlutterOverlayWindow.isPermissionGranted();
    if (permission != true) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50,),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 300,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/swagat.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE96E03),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isOtpSent ? _buildOtpInput() : _buildPhoneInput(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_isOtpSent) {
                          _verifyOtp();
                        } else {
                          _sendOtp();
                        }
                        FocusScope.of(context).unfocus();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE96E03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          _isOtpSent ? "Verify OTP" : "Send OTP",
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mobile Number",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE96E03)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Color(0xFFE96E03)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "+91",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black),
                maxLength: 10,
                decoration: InputDecoration(
                  counterText: "", // Hides the character counter
                  hintText: "Enter your mobile number",
                  hintStyle: const TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE96E03)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE96E03)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE96E03), width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateFcmToken(String userId, String fcmToken) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/api/user/updateuser/$userId"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmtoken': fcmToken}),
      );

      if (response.statusCode == 200) {
        print('FCM token updated successfully for user $userId');
      } else {
        print('Failed to update FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error updating FCM token.');
    }
  }

  Widget _buildOtpInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Enter OTP",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Color(0xFFE96E03)),
        ),
        const SizedBox(height: 10),
        TextField(
          style: TextStyle(color: Colors.black),
          controller: _otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Enter 4-digit OTP",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length<10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number!")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/user/getotp"),
        body: jsonEncode({"phoneNumber": phone}),
        headers: {"Content-Type": "application/json"},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _isOtpSent = true;
          _sessionId = responseData['SessionId'];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'])),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP.")),
      );
    }
  }

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();


  Future<void> _verifyOtp() async {
    String phone = _phoneController.text.trim();
    String otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid OTP.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/user/verifyotp"),
        body: jsonEncode({
          "phoneNumber": phone,
          "SessionId": _sessionId,
          "OTP": otp,
        }),
        headers: {"Content-Type": "application/json"},
      );

      final responseData = jsonDecode(response.body);
      await _secureStorage.write(key: "phone", value: phone);
      String? storedPhone = await _secureStorage.read(key: "phone");
      print("Stored phone number: $storedPhone");


      if (response.statusCode == 404) {
        if (responseData["error"] == "User Not Register") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SelectionScreen()),
          );
        }
      } else if (response.statusCode == 200) {
        String userId = responseData["id"];
        await _secureStorage.write(key: "userId", value: userId);
        print(phone);
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print("FCM Token: $fcmToken");

          await _updateFcmToken(userId, fcmToken);
        } else {
          print("Failed to get FCM token");
        }

        final String userDataUrl = 'https://api.bharatyaatri.com/api/user/getuser/$userId';
        final response = await http.get(Uri.parse(userDataUrl));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          print(data[0]);
          if (data[0]['profilePhoto'] == null || data[0]['NumberPlate'] == null || data[0]['aadhaarPhoto'] == null || data[0]['dlPhoto'] == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
            );
          }else{
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BottomNav()),
            );
          }
        }
      } else {
        print(responseData['error']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'])),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP verification failed.")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
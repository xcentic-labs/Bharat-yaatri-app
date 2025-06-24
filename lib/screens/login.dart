import 'dart:convert';
import 'package:cabproject/screens/selection_screen.dart';
import 'package:cabproject/screens/upload_photos.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_overlay_window/flutter_overlay_window.dart'; // Add this import
import 'package:cabproject/screens/account_setup_screen.dart';

import '../bottom_nav.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  // final TextEditingController _otpController = TextEditingController(); // This will be deprecated or repurposed
  bool _isOtpSent = false;
  bool _isLoading = false;
  String _sessionId = "";

  final String baseUrl = "https://api.bharatyaatri.com";

  // New controllers and focus nodes for OTP input
  late List<TextEditingController> _otpDigitControllers;
  late List<FocusNode> _otpDigitFocusNodes;

  @override
  void initState() {
    super.initState();
    // clearSecureStorage(); // Do not clear secure storage on every login page open
    // Request overlay permission when the login page initializes
    _requestOverlayPermission();

    _otpDigitControllers = List.generate(4, (_) => TextEditingController());
    _otpDigitFocusNodes = List.generate(4, (_) => FocusNode());

    // Add listeners to move focus
    for (int i = 0; i < 4; i++) {
      _otpDigitControllers[i].addListener(() {
        if (_otpDigitControllers[i].text.length == 1 && i < 3) {
          _otpDigitFocusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    // Dispose all OTP digit controllers and focus nodes
    for (var controller in _otpDigitControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpDigitFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
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
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (!_isOtpSent) ...[
            // Heading Text: "Enter Phone Number for Verification"
            Positioned(
              top: 127,
              left: 24,
              width: 392,
              height: 32,
              child: const Text(
                'Enter Phone Number for Verification',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.0, // 100%
                  letterSpacing: 0,
                  color: Color(0xFF002D4C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subtext: "This number will be used..."
            Positioned(
              top: 159,
              left: 24,
              width: 392,
              height: 93,
              child: const Text(
                'This number will be used for all ride-related communication. You shall receive an SMS with code for verification',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  height: 1.0, // 100%
                  letterSpacing: 0,
                  color: Color(0xFF6F6F70),
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Input field: Country picker and phone number TextField
            Positioned(
              top: 262,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  _buildPhoneInput(),
                  // Underline for the input field
                  Container(
                    height: 1,
                    width: screenWidth - 48,
                    color: const Color(0xFF000000),
                  ),
                ],
              ),
            ),
          ] else ...[
            // OTP Info Text and Input Fields
            Positioned(
              top: 127,
              left: 24,
              right: 24,
              child: _buildOtpInput(),
            ),
          ],

          // Verify Button - centered at bottom
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: SizedBox(
              width: screenWidth - 48,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isOtpSent) {
                      _verifyOtp();
                    } else {
                      _sendOtp();
                    }
                    FocusScope.of(context).unfocus();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF002D4C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      _isOtpSent ? 'Verify OTP' : 'Verify',
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Row(
      children: [
        // Country picker part
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/indian_flag.png',
                width: 24, // Adjust size as needed
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8), // Space between flag and +91
              const Text(
                "+91",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black), // Dropdown icon
            ],
          ),
        ),
        const SizedBox(width: 8), // Space between country picker and text field
        Expanded(
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: Colors.black, fontSize: 16),
            maxLength: 10,
            decoration: const InputDecoration(
              isDense: true, // Reduce vertical space
              contentPadding: EdgeInsets.symmetric(vertical: 0), // Adjust content padding
              counterText: "", // Hides the character counter
              hintText: "Your number",
              hintStyle: TextStyle(color: Color(0xFF6F6F70)),
              border: InputBorder.none, // Remove all borders
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
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
          "Please wait.\nWe will auto verify the OTP sent to +91 xxxxxxxx",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Space Grotesk',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF002D4C),
          ),
        ),
        const SizedBox(height: 30),

        // OTP input fields
        Center(
          child: SizedBox(
            width: 280,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _otpDigitControllers[index],
                    focusNode: _otpDigitFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      counterText: "",
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF000000), width: 1),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF002D4C), width: 2),
                      ),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF000000), width: 1),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 1) {
                        if (index < 3) {
                          _otpDigitFocusNodes[index + 1].requestFocus();
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
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

      // print("UserID: $responseData");

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
        const SnackBar(content: Text("Failed to send OTP.")),
      );
    }
  }

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Utility function to clear secure storage (for testing, call this before login if needed)
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
    print('[DEBUG] Secure storage cleared.');
  }

  Future<void> _verifyOtp() async {
    String phone = _phoneController.text.trim();
    String otp = _otpDigitControllers.map((controller) => controller.text).join();

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
        print('[DEBUG] Saved userId: $userId');
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _updateFcmToken(userId, fcmToken);
        }

        final String userDataUrl = 'https://api.bharatyaatri.com/api/user/getuser/$userId';
        final userResponse = await http.get(Uri.parse(userDataUrl));

        if (userResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(userResponse.body);
          print(data[0]);
          if (data[0]['profilePhoto'] == null ||
              data[0]['NumberPlate'] == null ||
              data[0]['aadhaarPhoto'] == null ||
              data[0]['dlPhoto'] == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
            );
          } else {
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
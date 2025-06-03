import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'upload_photos.dart';

class AddAgentAccountPage extends StatefulWidget {
  const AddAgentAccountPage({Key? key}) : super(key: key);

  @override
  State<AddAgentAccountPage> createState() => _AddAgentAccountPageState();
}

class _AddAgentAccountPageState extends State<AddAgentAccountPage> {
  final TextEditingController _agentNameController = TextEditingController();
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _aadhaarNumberController = TextEditingController();
  final TextEditingController _dlNumberController = TextEditingController();

  final String baseUrl = "https://api.bharatyaatri.com";

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
  }

  Future<void> _loadPhoneNumber() async {
    String? phoneNumber = await _secureStorage.read(key: "phone");

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      setState(() {
        _mobileController.text = phoneNumber;
      });
    }
  }
  Future<void> _saveAgentDetails() async {
    if (_areFieldsEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    try {

      if (_mobileController.text.length != 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number must be exactly 10 digits.")),
        );
        return;
      }

      if (_aadhaarNumberController.text.length != 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aadhaar number must be exactly 12 digits.")),
        );
        return;
      }

      if (_dlNumberController.text.length != 16) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Driving license number must be exactly 16 characters.")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/user/addagent"),
        body: jsonEncode({
          "name": _agentNameController.text.trim(),
          "agencyName": _agencyNameController.text.trim(),
          "phoneNumber": _mobileController.text.trim(),
          "email": _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : "abc@gmail.com",
          "address": _addressController.text.trim(),
          "city": _cityController.text.trim(),
          "state": _stateController.text.trim(),
          "pincode": _pincodeController.text.trim(),
          "aadhaarNumber": _aadhaarNumberController.text.trim(),
          "dlNumber": _dlNumberController.text.trim(),
        }),
        headers: {"Content-Type": "application/json"},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        String userId = responseData["id"];

        print("User ID: $userId");

        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          print("FCM Token: $fcmToken");

          await _updateFcmToken(userId, fcmToken);
        } else {
          print("Failed to get FCM token");
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${responseData['error']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add agent details.")),
      );
    }
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

  bool _areFieldsEmpty() {
    return _agentNameController.text.isEmpty ||
        _agencyNameController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _pincodeController.text.isEmpty ||
        _aadhaarNumberController.text.isEmpty ||
        _dlNumberController.text.isEmpty;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        centerTitle: true,
        title: const Text(
          "Add Agent Account",
          style: TextStyle(
              color: Color(0xFFE96E03), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE96E03)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildDetailContainer("Agent Name", _agentNameController),
              const SizedBox(height: 15),
              _buildDetailContainer("Travel Agency Name", _agencyNameController),
              const SizedBox(height: 15),
              _buildDetailContainer("Mobile Number", _mobileController),
              const SizedBox(height: 15),
              _buildDetailContainer("Email ID(Optional)", _emailController),
              const SizedBox(height: 15),
              _buildDetailContainer("Full Address", _addressController),
              const SizedBox(height: 15),
              _buildDetailContainer("City", _cityController),
              const SizedBox(height: 15),
              _buildDetailContainer("State", _stateController),
              const SizedBox(height: 15),
              _buildDetailContainer("Pincode", _pincodeController),
              const SizedBox(height: 15),
              _buildDetailContainer("Aadhaar Number", _aadhaarNumberController),
              const SizedBox(height: 15),
              _buildDetailContainer("Driving License Number", _dlNumberController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAgentDetails,
                child: const Text("Save Details", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFE96E03)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDetailContainer(String label, TextEditingController controller) {
    TextInputType keyboardType = TextInputType.text;
    int? maxLength;
    bool isNumberField = false;

    if (label == "Mobile Number") {
      keyboardType = TextInputType.number;
      maxLength = 10;
      isNumberField = true;
    } else if (label == "Aadhaar Number") {
      keyboardType = TextInputType.number;
      maxLength = 12;
      isNumberField = true;
    } else if (label == "Pincode") {
      keyboardType = TextInputType.number;
      maxLength = 6;
      isNumberField = true;
    } else if (label == "Email ID") {
      keyboardType = TextInputType.emailAddress;
    }

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE96E03)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              readOnly: label == "Mobile Number",
              inputFormatters: isNumberField
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter $label',
                counterText: "", // Hides the character counter
              ),
            ),
          ],
        ),
      ),
    );
  }

}

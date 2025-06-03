import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';

import 'upload_photos.dart';

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({Key? key}) : super(key: key);

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AddAccountPageState extends State<AddAccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final String baseUrl = "https://api.bharatyaatri.com";

  Future<void> _selectDate(BuildContext context) async {
    var pickedDate = await DatePicker.showSimpleDatePicker(
      context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      dateFormat: "dd-MMMM-yyyy",
      locale: DateTimePickerLocale.en_us,
      looping: true,
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

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
        _phoneController.text = phoneNumber;
      });
    }
  }


  Future<void> _saveDetails() async {
    if (_nameController.text.isEmpty ||
        _licenseController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _aadhaarController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be exactly 10 digits.")),
      );
      return;
    }else if (_aadhaarController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aadhaar number must be exactly 12 digits.")),
      );
      return;
    }else if (_licenseController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driving license number must be exactly 16 characters.")),
      );
      return;
    }else {
      try {
        final response = await http.post(
          Uri.parse("$baseUrl/api/user/addrider"),
          body: jsonEncode({
            "name": _nameController.text.trim(),
            "phoneNumber": _phoneController.text.trim(),
            "email": _emailController.text
                .trim()
                .isNotEmpty
                ? _emailController.text.trim()
                : "abc@gmail.com",
            "aadhaarNumber": _aadhaarController.text.trim(),
            "dlNumber": _licenseController.text.trim(),
            "dob": _dobController.text.trim(),
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
            MaterialPageRoute(
                builder: (context) => UploadPhotosPage(userId: userId)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${responseData['error']}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update details.")),
        );
      }
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        centerTitle: true,
        title: const Text(
          "Add Account",
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
              _buildDetailContainer("Name", _nameController),
              const SizedBox(height: 15),
              _buildDetailContainer("Email (Optional)", _emailController),
              const SizedBox(height: 15),
              _buildDetailContainer("Phone Number", _phoneController),
              const SizedBox(height: 15),
              _buildDetailContainer("Driving License", _licenseController),
              const SizedBox(height: 15),
              _buildDatePickerContainer("Date of Birth", _dobController),
              const SizedBox(height: 15),
              _buildDetailContainer("Aadhaar Number", _aadhaarController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveDetails,
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
    final isPhoneNumber = label == "Phone Number";
    final isAadhaar = label == "Aadhaar Number";

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
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE96E03)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: (isPhoneNumber || isAadhaar) ? TextInputType.number : TextInputType.text,
              maxLength: isPhoneNumber ? 10 : (isAadhaar ? 12 : null),
              readOnly: isPhoneNumber,  // Make phone number field uneditable
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter $label',
                counterText: '', // Hide the character counter below TextField
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDatePickerContainer(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Card(
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
                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE96E03)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Select $label',
                  suffixIcon: Icon(Icons.calendar_today, color: Color(0xFFE96E03)),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

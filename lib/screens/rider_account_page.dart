import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dlNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aadhaarNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditing = false;
  String? _phoneNumber;
  String _profileImageUrl = 'assets/rider.png';


  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) {
        throw Exception("User ID not found in secure storage");
      }

      final response = await http.get(
        Uri.parse('https://api.bharatyaatri.com/api/user/getuser/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)[0];

        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneNumber = data['phoneNumber'] ?? '';
          _emailController.text = data['email'] ?? '';
          _aadhaarNumberController.text = data['aadhaarNumber'] ?? '';
          _dlNumberController.text = data['dlNumber'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _profileImageUrl = data['profilePhoto']['imageUrl'] ?? 'assets/rider.png';
        });
      } else {
        throw Exception("Failed to fetch user data: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user data.")),
      );
    }
  }

  Future<void> _updateUserData() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) {
        throw Exception("User ID not found in secure storage");
      }

      final url = Uri.parse('https://api.bharatyaatri.com/api/user/updateuser/$userId');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'phoneNumber': _phoneNumber,
          'email': _emailController.text,
          'aadhaarNumber': _aadhaarNumberController.text,
          'dlNumber': _dlNumberController.text,
          'dob': _dobController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details updated successfully!")),
        );
      } else {
        throw Exception("Failed to update user data: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating user data.")),
      );
    }
  }

  Future<void> _saveDetails() async {
    if (_nameController.text.isEmpty ||
        _dlNumberController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _aadhaarNumberController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    if (_aadhaarNumberController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aadhaar number must be exactly 12 digits.")),
      );
      return;
    }else if (_dlNumberController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driving license number must be exactly 16 characters.")),
      );
      return;
    }
    else{
      setState(() {
        _isEditing = false;
      });

      // Update user data in the backend
      await _updateUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5EE),
        centerTitle: true,
        title: const Text(
          "My Account",
          style: TextStyle(
              color: Color(0xFFE96E03), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE96E03)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Color(0xFFE96E03)),
            onPressed: () {
              if (_isEditing) {
                _saveDetails();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                     CircleAvatar(
                      radius: 55,
                      backgroundImage: _profileImageUrl.startsWith('profile')
                          ? NetworkImage("https://api.bharatyaatri.com/"+_profileImageUrl)
                          : AssetImage(_profileImageUrl) as ImageProvider,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : "User Name",
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold,color: Color(0xFFE96E03)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _phoneNumber ?? "Phone Number Unavailable",
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailContainer("Name", _nameController),
              const SizedBox(height: 15),
              _buildDetailContainer("Email", _emailController),
              const SizedBox(height: 15),
              _buildDetailContainer("Driving License", _dlNumberController),
              const SizedBox(height: 15),
              _buildDetailContainer("Date of Birth", _dobController),
              const SizedBox(height: 15),
              _buildDetailContainer("Aadhaar Number", _aadhaarNumberController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContainer(String label, TextEditingController controller) {
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
            _isEditing
                ? TextField(
              controller: controller,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter $label',
              ),
            )
                : Text(
              controller.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

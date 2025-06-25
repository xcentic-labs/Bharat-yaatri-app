import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({Key? key}) : super(key: key);

  @override
  _MyAccountScreenState createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dlNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aadhaarNumberController = TextEditingController();
  String? _phoneNumber;
  String _profileImageUrl = 'assets/rider.png';

  bool _isLoading = true;
  bool _isEditing = false;
  bool _documentsComplete = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final String? userId = await _storage.read(key: 'userId');
      print('[DEBUG] Fetched userId from storage: $userId');
      if (userId == null) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        return;
      }
      final String url = 'https://api.bharatyaatri.com/api/user/getuser/$userId';
      print('[DEBUG] Fetching user data from: https://api.bharatyaatri.com/api/user/getuser/$userId');
      final response = await http.get(Uri.parse(url));
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _nameController.text = data[0]['name'] ?? '';
            _phoneNumber = data[0]['phoneNumber'] ?? '';
            _emailController.text = data[0]['email'] ?? '';
            _aadhaarNumberController.text = data[0]['aadhaarNumber'] ?? '';
            _dlNumberController.text = data[0]['dlNumber'] ?? '';
            _dobController.text = data[0]['dob'] ?? '';
            _profileImageUrl = data[0]['profilePhoto']?['imageUrl'] ?? 'assets/rider.png';
            _isLoading = false;
            _documentsComplete = data[0]['verificationStatus'] ?? false;
          });
        } else {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user data found for this user ID.')),
          );
        }
      } else {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user data. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching details: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) throw Exception('User ID not found');

      final response = await http.patch(
        Uri.parse('https://api.bharatyaatri.com/api/user/updateuser/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'dlNumber': _dlNumberController.text,
          'dob': _dobController.text,
          'aadhaarNumber': _aadhaarNumberController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        setState(() { _isEditing = false; });
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF002B4D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Account', style: TextStyle(color: Color(0xFF002B4D), fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Color(0xFF002B4D)),
            onPressed: () async {
              if (_isEditing) {
                await _updateProfile();
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_isLoading) ...[
            SafeArea(
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
                                ? NetworkImage("https://api.bharatyaatri.com/" + _profileImageUrl)
                                : AssetImage(_profileImageUrl) as ImageProvider,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : "User Name",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF002B4D)),
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
          ] else ...[
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailContainer(String label, TextEditingController controller) {
    final isEditable = _isEditing;
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002B4D)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              readOnly: !isEditable,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isEditable ? 'Enter $label' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dlNumberController.dispose();
    _dobController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }
} 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AgentAccountPage extends StatefulWidget {
  const AgentAccountPage({Key? key}) : super(key: key);

  @override
  State<AgentAccountPage> createState() => _AgentAccountPageState();
}

class _AgentAccountPageState extends State<AgentAccountPage> {
  final TextEditingController _agentNameController = TextEditingController();
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _aadhaarNumberController = TextEditingController();
  final TextEditingController _dlNumberController = TextEditingController();


  final _storage = const FlutterSecureStorage();
  String? _phoneNumber;
  String? _profileImageUrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchAgentData(); // Fetch agent data when the page loads
  }

  Future<void> _fetchAgentData() async {
    try {
      // Retrieve user ID from secure storage
      final String? userId = await _storage.read(key: 'userId');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User ID not found in secure storage")),
        );
        return;
      }

      final String apiUrl =
          "https://api.bharatyaatri.com/api/user/getuser/$userId";

      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> agentData = json.decode(response.body);

        if (agentData.isNotEmpty) {
          final Map<String, dynamic> agent = agentData[0];

          setState(() {
            _agentNameController.text = agent['name'] ?? '';
            _agencyNameController.text = agent['agencyName'] ?? '';
            _phoneNumber = agent['phoneNumber'] ?? '';
            _emailController.text = agent['email'] ?? '';
            _addressController.text = agent['address'] ?? '';
            _cityController.text = agent['city'] ?? '';
            _stateController.text = agent['state'] ?? '';
            _pincodeController.text = agent['pincode'] ?? '';
            _profileImageUrl = agent['profilePhoto']['imageUrl'] ?? 'assets/agent.png';
            _aadhaarNumberController.text = agent['aadhaarNumber'] ?? '';
            _dlNumberController.text = agent['dlNumber'] ?? '';

          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No agent data found!")),
          );
        }
      } else {
        throw Exception(
            "Failed to fetch agent data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data.")),
      );
    }
  }

  Future<void> _updateAgentData() async {
    try {
      final String? userId = await _storage.read(key: 'userId');
      if (userId == null) {
        throw Exception("User ID not found in secure storage");
      }

      final String apiUrl =
          "https://api.bharatyaatri.com/api/user/updateuser/$userId";

      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _agentNameController.text,
          'agencyName': _agencyNameController.text,
          'phoneNumber': _phoneNumber,
          'email': _emailController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'pincode': _pincodeController.text,
          'dlNumber' : _dlNumberController.text,
          'aadhaarNumber' : _aadhaarNumberController
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Details updated successfully!")),
        );
      } else {
        throw Exception(
            "Failed to update agent data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating data.")),
      );
    }
  }

  Future<void> _saveDetails() async {
    if (_agentNameController.text.isEmpty ||
        _agencyNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required.")),
      );
      return;
    }

    if (_aadhaarNumberController.text.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Aadhaar number must be exactly 12 digits.")),
      );
      return;
    } else if (_dlNumberController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            "Driving license number must be exactly 16 characters.")),
      );
      return;
    }
    else {
      setState(() {
        _isEditing = false;
      });

      // Update agent data in the backend
      await _updateAgentData();
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
          "Edit Agent Account",
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
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundImage: _profileImageUrl != null
                              ? (_profileImageUrl!.startsWith('profile')
                              ? NetworkImage("https://api.bharatyaatri.com/"+_profileImageUrl!)
                              : AssetImage('assets/agent.png'))
                              : const AssetImage('assets/agent.png'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _agentNameController.text.isNotEmpty
                          ? _agentNameController.text
                          : "Agent Name",
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
              _buildDetailContainer("Agent Name", _agentNameController),
              const SizedBox(height: 15),
              _buildDetailContainer("Travel Agency Name", _agencyNameController),
              const SizedBox(height: 15),
              _buildDetailContainer("Email ID", _emailController),
              const SizedBox(height: 15),
              _buildDetailContainer("Aadhar Number", _aadhaarNumberController),
              const SizedBox(height: 15),
              _buildDetailContainer("Driving Licence", _dlNumberController),
              const SizedBox(height: 15),
              _buildDetailContainer("Full Address", _addressController),
              const SizedBox(height: 15),
              _buildDetailContainer("City", _cityController),
              const SizedBox(height: 15),
              _buildDetailContainer("State", _stateController),
              const SizedBox(height: 15),
              _buildDetailContainer("Pincode", _pincodeController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveDetails();
                },
                child: const Text("Save Details",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE96E03)
                ),
              ),
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

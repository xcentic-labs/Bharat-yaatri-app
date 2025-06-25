import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({Key? key}) : super(key: key);

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  List<Map<String, dynamic>> drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(Uri.parse('https://api.bharatyaatri.com/api/user/getalldrivers'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          drivers = List<Map<String, dynamic>>.from(data is List ? data : (data['drivers'] ?? []));
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch drivers')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddDriverModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddDriverForm(onDriverAdded: (_) {
          _fetchDrivers();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        backgroundColor: const Color(0xFF002D4C),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : drivers.isEmpty
              ? const Center(child: Text('No drivers found'))
              : ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(driver['name'] ?? driver['fullName'] ?? ''),
                      subtitle: Text(driver['phoneNumber'] ?? driver['contact'] ?? ''),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF002D4C),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddDriverModal,
      ),
    );
  }
}

class AddDriverForm extends StatefulWidget {
  final Function(Map<String, String>) onDriverAdded;
  const AddDriverForm({Key? key, required this.onDriverAdded}) : super(key: key);

  @override
  State<AddDriverForm> createState() => _AddDriverFormState();
}

class _AddDriverFormState extends State<AddDriverForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  File? _frontImage;
  File? _backImage;
  bool _isLoading = false;

  Future<void> _pickImage(bool isFront) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(picked.path);
        } else {
          _backImage = File(picked.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_frontImage == null || _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload both license images.')));
      return;
    }
    setState(() { _isLoading = true; });
    // Backend logic (adapted from AddAccountPage)
    try {
      final response = await http.post(
        Uri.parse("https://api.bharatyaatri.com/api/user/addrider"),
        body: jsonEncode({
          "name": _nameController.text.trim(),
          "phoneNumber": _contactController.text.trim(),
          "dlNumber": _licenseController.text.trim(),
          "address1": _address1Controller.text.trim(),
          "address2": _address2Controller.text.trim(),
          "city": _cityController.text.trim(),
          // You may need to handle image upload separately if backend requires multipart
        }),
        headers: {"Content-Type": "application/json"},
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onDriverAdded({
          'name': _nameController.text,
          'contact': _contactController.text,
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData['message'] ?? 'Failed to add driver')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 16),
              _buildTextField(_nameController, 'Driver Full Name'),
              const SizedBox(height: 12),
              _buildTextField(_contactController, 'Contact Number', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _buildTextField(_licenseController, 'License Number'),
              const SizedBox(height: 12),
              _buildTextField(_address1Controller, 'Address Line 1'),
              const SizedBox(height: 12),
              _buildTextField(_address2Controller, 'Address Line 2'),
              const SizedBox(height: 12),
              _buildTextField(_cityController, 'City'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Upload Driver License Images', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(true),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _frontImage == null
                            ? const Center(child: Text('+ Front'))
                            : Image.file(_frontImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(false),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _backImage == null
                            ? const Center(child: Text('+ Back'))
                            : Image.file(_backImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB800),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('ADD', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
} 
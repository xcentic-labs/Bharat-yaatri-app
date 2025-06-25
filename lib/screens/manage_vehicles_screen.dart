import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ManageVehiclesScreen extends StatefulWidget {
  const ManageVehiclesScreen({Key? key}) : super(key: key);

  @override
  State<ManageVehiclesScreen> createState() => _ManageVehiclesScreenState();
}

class _ManageVehiclesScreenState extends State<ManageVehiclesScreen> {
  List<Map<String, dynamic>> vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() { _isLoading = true; });
    try {
      final response = await http.get(Uri.parse('https://api.bharatyaatri.com/api/user/getallvehicles'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vehicles = List<Map<String, dynamic>>.from(data is List ? data : (data['vehicles'] ?? []));
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch vehicles')),
        );
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddVehicleModal() {
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
        child: AddVehicleForm(onVehicleAdded: (_) {
          _fetchVehicles();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        backgroundColor: const Color(0xFF002D4C),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
              ? const Center(child: Text('No vehicles found'))
              : ListView.builder(
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.directions_car)),
                      title: Text(vehicle['type'] ?? vehicle['vehicleType'] ?? ''),
                      subtitle: Text(vehicle['registration'] ?? vehicle['registrationNumber'] ?? ''),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF002D4C),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _showAddVehicleModal,
      ),
    );
  }
}

class AddVehicleForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onVehicleAdded;
  const AddVehicleForm({Key? key, required this.onVehicleAdded}) : super(key: key);

  @override
  State<AddVehicleForm> createState() => _AddVehicleFormState();
}

class _AddVehicleFormState extends State<AddVehicleForm> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleType;
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  File? _insuranceImage;
  final TextEditingController _insuranceExpiryController = TextEditingController();
  File? _rcFront;
  File? _rcBack;
  List<File?> _vehicleImages = [null, null, null];
  bool _isLoading = false;

  final List<String> vehicleTypes = [
    'Hatchback', 'Sedan', 'Ertiga', 'SUV', 'INNOVA', 'INNOVA CRYSTA', 'FORCE Traveller', 'Bus'
  ];

  Future<void> _pickImage(Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      onPicked(File(picked.path));
    }
  }

  Future<void> _pickVehicleImage(int index) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _vehicleImages[index] = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_insuranceImage == null || _rcFront == null || _rcBack == null || _vehicleImages.any((img) => img == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload all required images.')));
      return;
    }
    setState(() { _isLoading = true; });
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://api.bharatyaatri.com/api/user/addvehicle'));
      request.fields['type'] = _vehicleType ?? '';
      request.fields['registration'] = _registrationController.text;
      request.fields['year'] = _yearController.text;
      request.fields['insuranceExpiry'] = _insuranceExpiryController.text;
      request.files.add(await http.MultipartFile.fromPath('insuranceImage', _insuranceImage!.path));
      request.files.add(await http.MultipartFile.fromPath('rcFront', _rcFront!.path));
      request.files.add(await http.MultipartFile.fromPath('rcBack', _rcBack!.path));
      for (int i = 0; i < _vehicleImages.length; i++) {
        request.files.add(await http.MultipartFile.fromPath('vehicleImage$i', _vehicleImages[i]!.path));
      }
      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle added successfully!')));
        widget.onVehicleAdded({
          'type': _vehicleType,
          'registration': _registrationController.text,
          'year': _yearController.text,
        });
        Navigator.pop(context);
      } else {
        final respStr = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add vehicle: $respStr')));
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Vehicle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF002D4C))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _vehicleType,
                decoration: _inputDecoration('Select Vehicle Type'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select Vehicle Type')),
                  ...vehicleTypes.map((type) => DropdownMenuItem(value: type, child: Text(type)))
                ],
                onChanged: (val) => setState(() => _vehicleType = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(_registrationController, 'Registration Number (No space)'),
              const SizedBox(height: 12),
              _buildTextField(_yearController, 'Year of Manufacture', keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              Text('Add Insurance Details', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Color(0xFF002D4C))),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickImage((file) => setState(() => _insuranceImage = file)),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _insuranceImage == null
                      ? const Center(child: Text('+ Upload Insurance Image'))
                      : Image.file(_insuranceImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(_insuranceExpiryController, 'Insurance Expiry Date',
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _insuranceExpiryController.text = picked.toString().split(' ')[0];
                    }
                  },
                  suffixIcon: const Icon(Icons.calendar_today)),
              const SizedBox(height: 20),
              Text('Upload RC Images', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Color(0xFF002D4C))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage((file) => setState(() => _rcFront = file)),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _rcFront == null
                            ? const Center(child: Text('+ RC Front'))
                            : Image.file(_rcFront!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage((file) => setState(() => _rcBack = file)),
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _rcBack == null
                            ? const Center(child: Text('+ RC Front'))
                            : Image.file(_rcBack!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Upload Vehicle Images', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Color(0xFF002D4C))),
              const SizedBox(height: 8),
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => _pickVehicleImage(i),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _vehicleImages[i] == null
                            ? const Icon(Icons.camera_alt, size: 32, color: Color(0xFF002D4C))
                            : Image.file(_vehicleImages[i]!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002D4C),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, bool readOnly = false, VoidCallback? onTap, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffixIcon,
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
} 
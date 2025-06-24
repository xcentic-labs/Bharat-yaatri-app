import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddRideScreen extends StatefulWidget {
  const AddRideScreen({Key? key}) : super(key: key);

  @override
  State<AddRideScreen> createState() => _AddRideScreenState();
}

class _AddRideScreenState extends State<AddRideScreen> {
  String? _selectedCarModel; // For dropdown selection
  late TextEditingController _fromController;
  late TextEditingController _toController;
  final TextEditingController _descriptionController = TextEditingController();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? _userId; // User ID will be fetched from secure storage
  String? _rideType; // To store the selected ride type
  String? _carrierType = "";

  final String _baseUrl = 'https://api.bharatyaatri.com';

  // Fetch the user ID from secure storage when the screen loads
  Future<void> _getUserId() async {
    try {
      final storedUserId = await _secureStorage.read(key: 'userId');
      setState(() {
        _userId = storedUserId;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching user ID: $e")),
      );
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    final apiKey = "AIzaSyAMLvN5EB6t3hSj3M-WVTyV-a_juuao2Zo";
    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&components=country:in";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'];
      return predictions
          .map<String>((p) => p['description'] as String)
          .toList();
    } else {
      print("Error: ${response.statusCode}");
      return [];
    }
  }

  Future<void> _submitRide() async {
    if (_selectedCarModel == null ||
        _fromController.text.isEmpty ||
        _toController.text.isEmpty ||
        _rideType == null ||
        _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields and ensure you're logged in")),
      );
      return;
    }

    final String createdAt = DateTime.now().toIso8601String();
    final newRide = {
      "carModel": _selectedCarModel, // Use selected car model
      "from": _fromController.text.trim(),
      "to": _toController.text.trim(),
      "description": _descriptionController.text.trim(),
      "rideType": _rideType, // Add ride type
      "createdBy": _userId,
      "createdAt": createdAt,
      "carrier": _carrierType
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ride/addride'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newRide),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride added successfully!")),
        );

        final createdRide = json.decode(response.body);
        Navigator.pop(context, createdRide);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add ride: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e")),
      );
    }
  }
  Widget _buildDetailContainer(String label, TextEditingController controller,
      {bool multiline = false}) {
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002D4C)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: multiline ? 3 : 1,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter $label',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarModelSelector() {
    final List<Map<String, String>> carModels = [
      {"name": "SUV", "image": "assets/suv.png"},
      {"name": "Sedan", "image": "assets/sedan.png"},
      {"name": "Mini", "image": "assets/mini.png"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Car Model *",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002D4C)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: carModels.map((car) {
            final bool isSelected = _selectedCarModel == car["name"];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCarModel = car["name"];
                });
              },
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.orange : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Image.asset(
                      car["image"]!,
                      height: 50,
                      width: 50,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      car["name"]!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.orange : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStyledCard(String label, Widget child) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF002D4C),
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }



  Widget _buildLeadTypeButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lead Type *",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002D4C)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLeadTypeButton("Exchange", Icons.swap_horiz, Colors.blue),
            _buildLeadTypeButton("Available", Icons.thumb_up, Colors.amber),
          ],
        ),
      ],
    );
  }


  Widget _buildCarrierTypeButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Carrier Type",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002D4C)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCarrierTypeButton("With Carrier", Icons.local_shipping, Colors.green),
            _buildCarrierTypeButton("Without Carrier", Icons.directions_car, Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildCarrierTypeButton(String type, IconData icon, Color color) {
    final isSelected = _carrierType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _carrierType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLeadTypeButton(String type, IconData icon, Color color) {
    final isSelected = _rideType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _rideType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getUserId(); // Fetch user ID from secure storage when the screen is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5EE),
        centerTitle: true,
        title: const Text(
          "Add Ride",
          style: TextStyle(color: Color(0xFF002D4C), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF002D4C)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildCarModelSelector(), // Replaced with dropdown
              const SizedBox(height: 15),
              _buildStyledCard(
                "From *",
                TypeAheadField<String>(
                  suggestionsCallback: (pattern) async {
                    return await getSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return Column(
                      children: [
                        ListTile(
                          leading:
                              Icon(Icons.location_on, color: Colors.orange),
                          title: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],
                    );
                  },
                  onSelected: (suggestion) {
                    _fromController.text = suggestion;
                    FocusScope.of(context)
                        .unfocus(); // Optional: close keyboard
                  },
                  builder: (context, controller, focusNode) {
                    _fromController = controller; // 🔥 This is the fix!

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Pickup Location",
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              _buildStyledCard(
                "To *",
                TypeAheadField<String>(
                  suggestionsCallback: (pattern) async {
                    return await getSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return Column(
                      children: [
                        ListTile(
                          leading:
                              Icon(Icons.location_on, color: Colors.orange),
                          title: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 1),
                      ],
                    );
                  },
                  onSelected: (suggestion) {
                    _toController.text = suggestion;
                    FocusScope.of(context)
                        .unfocus(); // Optional: close keyboard
                  },
                  builder: (context, controller, focusNode) {
                    _toController = controller; // Same as _fromController line

                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Drop Location",
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
              _buildDetailContainer("Description", _descriptionController, multiline: true),
              const SizedBox(height: 20),
              _buildCarrierTypeButtons(),
              const SizedBox(height: 20),
              _buildLeadTypeButtons(), // Add lead type selector
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002D4C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Submit Ride", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

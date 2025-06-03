import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddDutyScreen extends StatefulWidget {
  const AddDutyScreen({Key? key}) : super(key: key);

  @override
  State<AddDutyScreen> createState() => _AddDutyScreenState();
}

class _AddDutyScreenState extends State<AddDutyScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _selectedCarModel;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _rideType = "One Way";
  String? _carrierType = "";

  Future<String?> _getUserIdFromSecureStorage() async {
    return await _secureStorage.read(key: "userId");
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // Delay the unfocus to let the widget tree settle
      Future.delayed(Duration(milliseconds: 100), () {
        FocusScope.of(context).unfocus();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submitRide() async {
    // Validate form fields
    if (_selectedCarModel == null ||
        _fromController.text.isEmpty ||
        _toController.text.isEmpty ||
        _fareController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Fetch user ID from secure storage
    final userId = await _getUserIdFromSecureStorage();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    // Create the JSON payload
    final pickupDateTime =
        "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}, ${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}";
    final Map<String, dynamic> rideData = {
      "carModel": _selectedCarModel,
      "from": _fromController.text,
      "to": _toController.text,
      "description": _descriptionController.text,
      "PickupDateAndTime": pickupDateTime,
      "customerFare": _fareController.text,
      "commissionFee": _commissionController.text,
      "tripType": _rideType,
      "rideType": "Duty",
      "createdBy": userId,
      "carrier": _carrierType
    };

    const String url = "https://api.bharatyaatri.com/api/ride/addride";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(rideData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride submitted successfully")),
        );
        // Clear the form
        _fromController.clear();
        _toController.clear();
        _fareController.clear();
        _commissionController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCarModel = null;
          _selectedDate = null;
          _selectedTime = null;
          _rideType = "One-Way";
        });
        Navigator.pop(context, true);
        ;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit ride: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error occurred: $e")),
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
                color: Color(0xFFE96E03),
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCarrierTypeButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Carrier Type",
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE96E03)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCarrierTypeButton(
                "With Carrier", Icons.local_shipping, Colors.green),
            _buildCarrierTypeButton(
                "Without Carrier", Icons.directions_car, Colors.red),
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
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE96E03)),
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
                  color: isSelected
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5EE),
        centerTitle: true,
        title: const Text(
          "Add Duty",
          style: TextStyle(
            color: Color(0xFFE96E03),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFE96E03)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStyledCard(
                "Trip Type *",
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      children: [
                        Radio<String>(
                          value: "One-Way",
                          groupValue: _rideType,
                          onChanged: (value) {
                            setState(() {
                              _rideType = value;
                            });
                          },
                        ),
                        const Text("One-Way"),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: "Round-Trip",
                          groupValue: _rideType,
                          onChanged: (value) {
                            setState(() {
                              _rideType = value;
                            });
                          },
                        ),
                        const Text("Round-Trip"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildCarModelSelector(), // Replaced with dropdown
              const SizedBox(height: 15),
              _buildCarrierTypeButtons(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStyledCard(
                    "Pickup Date *",
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? "Select Date"
                              : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                        ),
                      ),
                    ),
                  ),
                  _buildStyledCard(
                    "Pickup Time *",
                    GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedTime == null
                              ? "Select Time"
                              : "${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildStyledCard(
                "Fare *",
                TextField(
                  controller: _fareController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Fare (e.g. ₹600)",
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildStyledCard(
                "Commission Fee",
                TextField(
                  controller: _commissionController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Commission Fee (e.g. ₹50)",
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _buildStyledCard(
                "Description",
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Ride Description",
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE96E03),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                ),
                child: const Text("Submit Ride",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

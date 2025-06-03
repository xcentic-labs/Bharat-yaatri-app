import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FilterModal extends StatefulWidget {
  const FilterModal({Key? key}) : super(key: key);

  @override
  _FilterModalState createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  String? selectedCarType;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController();
    _toController = TextEditingController();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<List<String>> getSuggestions(String query) async {
    const apiKey = "AIzaSyAMLvN5EB6t3hSj3M-WVTyV-a_juuao2Zo";
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

  Widget _buildLocationTypeAhead(
      TextEditingController controller, String hintText, IconData icon) {
    return TypeAheadField<String>(
      suggestionsCallback: (pattern) async {
        return await getSuggestions(pattern);
      },
      itemBuilder: (context, suggestion) {
        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.orange),
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
        controller.text = suggestion;
        FocusScope.of(context).unfocus();
      },
      builder: (context, typeAheadController, focusNode) {
        if (controller != typeAheadController) {
          typeAheadController.text = controller.text;
          typeAheadController.selection = controller.selection;
        }

        return TextField(
          controller: typeAheadController,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.black),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFE96E03)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE96E03)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE96E03), width: 2),
            ),
          ),
          onChanged: (value) {
            controller.text = value;
            controller.selection = typeAheadController.selection;
          },
        );
      },
    );
  }

  void _clearFiltersAndClose() {
    Navigator.pop(context, {
      'from': '',
      'to': '',
      'carType': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE96E03),
        elevation: 0,
        title: const Text(
          'Filters',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE96E03),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _clearFiltersAndClose,
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFFE96E03),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'From Location',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildLocationTypeAhead(
                _fromController,
                'Enter pickup location',
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),
              const Text(
                'To Location',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildLocationTypeAhead(
                _toController,
                'Enter drop location',
                Icons.flag_outlined,
              ),
              const SizedBox(height: 20),
              const Text(
                'Car Type',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCarType,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                items: ['SUV', 'Sedan', 'Mini' , 'Any']
                    .map((carType) => DropdownMenuItem(
                          value: carType,
                          child: Text(carType,
                              style: const TextStyle(color: Colors.black)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCarType = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Select car type',
                  prefixIcon: const Icon(Icons.directions_car_outlined,
                      color: Colors.black),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFE96E03)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE96E03)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE96E03), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final filters = {
                      'from': _fromController.text.trim(),
                      'to': _toController.text.trim(),
                      'carType': selectedCarType == 'Any' ? '' : selectedCarType ?? '',
                    };
                    Navigator.pop(context, filters);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE96E03),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

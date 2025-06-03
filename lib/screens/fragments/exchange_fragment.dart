import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../cards/ride_card.dart';

class ExchangeFragment extends StatefulWidget {
  const ExchangeFragment({Key? key}) : super(key: key);

  @override
  ExchangeFragmentState createState() => ExchangeFragmentState();
}

class ExchangeFragmentState extends State<ExchangeFragment> {
  List<Map<String, dynamic>> ridesData = [];
  Map<String, String> _filters = {};
  bool _isLoading = true; // Loading state for fetching data
  TextEditingController _searchController = TextEditingController();
  List<String> _suggestedCities = [];

  final String _baseUrl = 'https://api.bharatyaatri.com/api/ride/getallrides?status=Pending&page=1&limit=20&ridetype=Exchange';

  @override
  void initState() {
    super.initState();
    _fetchRidesData(); // Fetch rides data when the screen initializes
    _searchController.addListener(_onSearchChanged); // Listen for changes in the search bar
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filters['from'] = _searchController.text.toLowerCase();
      _updateCitySuggestions(_searchController.text);
    });
  }

  void _updateCitySuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestedCities = [];
      });
      return;
    }

    List<String> allCities = ridesData.map((ride) => ride['from']?.toString().toLowerCase() ?? '').toSet().toList();
    setState(() {
      _suggestedCities = allCities
          .where((city) => city.contains(query.toLowerCase()))
          .take(5)
          .toList();
    });
  }

  // Function to apply filters based on search
  void applyFilters(Map<String, String> filters) {
    setState(() {
      _filters = filters;
    });
  }

  // Filter rides based on the applied filters
  List<Map<String, dynamic>> getFilteredRides() {
    return ridesData.where((ride) {
      final fromMatches = _filters['from'] == null ||
          _filters['from']!.isEmpty ||
          (ride['from']?.toString().toLowerCase().contains(_filters['from']!.toLowerCase()) ?? false);

      final toMatches = _filters['to'] == null ||
          _filters['to']!.isEmpty ||
          (ride['to']?.toString().toLowerCase().contains(_filters['to']!.toLowerCase()) ?? false);

      final carTypeMatches = _filters['carType'] == null ||
          _filters['carType']!.isEmpty ||
          (ride['carModel']?.toString().toLowerCase().contains(_filters['carType']!.toLowerCase()) ?? false);

      return fromMatches && toMatches && carTypeMatches;
    }).toList();
  }

  // Handle search input chang

  // Fetch ride data from the backend
  Future<void> _fetchRidesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(_baseUrl));

      print(response.statusCode);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('rides')) {
          setState(() {
            ridesData = List<Map<String, dynamic>>.from(data['rides']);
          });
        } else {
          setState(() {
            ridesData = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid data received")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch rides data")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRides = getFilteredRides();

    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black),
                  cursorColor: Color(0xFFE96E03),
                  decoration: InputDecoration(
                    hintText: 'Search by "From" Location...',
                    hintStyle: const TextStyle(color: Colors.black),
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _filters['from'] = '';  // Clear the filter as well
                          _suggestedCities = [];  // Optionally clear the suggested cities
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Color(0xFFF5F5EE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFFE96E03), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFFE96E03)),
                    ),
                  ),
                ),
                if (_suggestedCities.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: _suggestedCities.map((city) => ListTile(
                        title: Text(city, style: TextStyle(color: Colors.black)),
                        onTap: () {
                          setState(() {
                            _searchController.text = city;
                            _filters['from'] = city;
                            _suggestedCities = [];
                          });
                          FocusScope.of(context).unfocus();
                        },
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filteredRides.isEmpty
                ? const Center(child: Text('No rides found!'))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80.0),
              itemCount: filteredRides.length,
              itemBuilder: (context, index) {
                final ride = filteredRides[index];
                return RideCard(
                  carModel: ride['carModel'] ?? 'Unknown Car Model',
                  createdAt: ride['createdAt'] ?? 'Not Specified',
                  from: ride['from'] ?? 'Unknown Location',
                  to: ride['to'] ?? 'Unknown Destination',
                  carrierType: ride['carrier'] ?? 'Without Carrier',
                  description: ride['description'] ?? 'No Description Available',
                  personName: ride['createdByDetails']?['name'] ?? 'Unknown Person',
                  role: ride['createdByDetails']?['userType'] ?? "User",
                  personPhoneNumber: ride['createdByDetails']?['phoneNumber'] ?? 'Unavailable',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

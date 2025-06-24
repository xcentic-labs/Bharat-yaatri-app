import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../cards/ride_card.dart';
import '../add_ride_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat_screen.dart';

class AvailableFragment extends StatefulWidget {
  const AvailableFragment({Key? key}) : super(key: key);

  @override
  AvailableFragmentState createState() => AvailableFragmentState();
}

class AvailableFragmentState extends State<AvailableFragment> {
  List<Map<String, dynamic>> ridesData = [];
  Map<String, String> _filters = {};
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<String> _suggestedCities = [];

  final String _baseUrl = 'https://api.bharatyaatri.com/api/ride/getallrides?status=Pending&page=1&limit=20&ridetype=Available';

  @override
  void initState() {
    super.initState();
    _fetchRidesData();
    _searchController.addListener(_onSearchChanged);
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

  void applyFilters(Map<String, String> filters) {
    setState(() {
      _filters = filters.map((key, value) => MapEntry(key, value.toLowerCase()));
    });
  }

  List<Map<String, dynamic>> getFilteredRides() {
    return ridesData.where((ride) {
      final fromMatches = _filters['from'] == null ||
          _filters['from']!.isEmpty ||
          (ride['from']?.toString().toLowerCase().contains(_filters['from']!) ?? false);

      final toMatches = _filters['to'] == null ||
          _filters['to']!.isEmpty ||
          (ride['to']?.toString().toLowerCase().contains(_filters['to']!) ?? false);

      final carTypeMatches = _filters['carType'] == null ||
          _filters['carType']!.isEmpty ||
          (ride['carModel']?.toString().toLowerCase().contains(_filters['carType']!) ?? false);

      return fromMatches && toMatches && carTypeMatches;
    }).toList();
  }

  Future<void> _fetchRidesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(_baseUrl));

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
          SnackBar(content: Text("Failed to fetch rides data: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: filteredRides.isEmpty
                ? const Center(child: Text('No free vehicles found!', style: TextStyle(color: Colors.black),))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80.0),
              itemCount: filteredRides.length,
              itemBuilder: (context, index) {
                final ride = filteredRides[index];
                if (ride['rideType'] == 'Available') {
                  final user = ride['createdByDetails'] ?? {};
                  return Padding(
                    padding: index == 0
                        ? const EdgeInsets.fromLTRB(16, 8, 16, 4)
                        : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: FreeVehicleCard(
                      name: user['name'] ?? 'Unknown',
                      rating: user['rating']?.toString() ?? '4.8',
                      carType: ride['carModel'] ?? 'Unknown',
                      avatarUrl: user['profilePhoto']?['imageUrl'],
                      onChat: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              userName: user['name'] ?? 'Unknown',
                              userId: user['_id']?.toString() ?? user['phoneNumber']?.toString() ?? 'Unknown',
                            ),
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FreeVehicleCard extends StatelessWidget {
  final String name;
  final String rating;
  final String carType;
  final String? avatarUrl;
  final VoidCallback onChat;
  const FreeVehicleCard({
    required this.name,
    required this.rating,
    required this.carType,
    this.avatarUrl,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: (avatarUrl == null || avatarUrl!.isEmpty)
                          ? Icon(Icons.person, size: 32, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF002D4C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 2),
                              Text(rating, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Car type: $carType',
                            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13, color: Colors.grey[700]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 120,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onChat,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
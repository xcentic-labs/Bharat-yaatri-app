import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../cards/new_duty_card.dart';
import '../cards/ride_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class DutyFragment extends StatefulWidget {
  const DutyFragment({Key? key}) : super(key: key);

  @override
  DutyFragmentState createState() => DutyFragmentState();
}

class DutyFragmentState extends State<DutyFragment> {
  List<Map<String, dynamic>> ridesData = [];
  Map<String, String> _filters = {};
  bool _isLoading = true; // Loading state for fetching data
  TextEditingController _searchController = TextEditingController();
  List<String> _suggestedCities = [];
  void fetchRidesData() {
    // Your logic to fetch and update rides data
    _fetchRidesData(); // Call your internal function
  }
// Controller for search bar

  final String _baseUrl = 'https://api.bharatyaatri.com/api/ride/getallrides?status=Pending&page=1&limit=100&ridetype=all';

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

  // Fetch ride data from the custom backend
  Future<void> _fetchRidesData() async {
    setState(() {
      _isLoading = true;
    });

    final String availableRidesUrl = 'https://api.bharatyaatri.com/api/ride/getallrides?status=Pending&page=1&limit=20&ridetype=Duty';
    try {
      final response = await http.get(Uri.parse(availableRidesUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data.containsKey('rides')) {
          setState(() {
            ridesData = List<Map<String, dynamic>>.from(data['rides']);
            _isLoading = false;
          });
        } else {
          setState(() {
            ridesData = [];
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid data received")),
          );
        }
      } else {
        setState(() {
          ridesData = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch rides data: \\${response.statusCode}")),
        );
      }
    } catch (e) {
      setState(() {
        ridesData = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: \\${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRides = getFilteredRides();

    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black),
                      cursorColor: Color(0xFF002D4C),
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
                                    _filters['from'] = '';
                                    _suggestedCities = [];
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Color(0xFFF5F5EE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF002D4C)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF002D4C)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF002D4C), width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF002D4C)),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF002D4C)),
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
                    // Show all rides as cards
                    if (filteredRides.isNotEmpty)
                      ...filteredRides.map((ride) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _LeadCard(ride: ride),
                      )).toList(),
                    if (!_isLoading && filteredRides.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Text('No rides found.', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// LEAD CARD WIDGET
class _LeadCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  const _LeadCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final driver = ride['createdByDetails'] ?? {};
    final carModel = ride['carModel'] ?? 'Sedan';
    final carImage = _getCarImage(carModel);
    final bookingId = ride['_id']?.toString().substring(0,8) ?? 'ID: Unknown';
    final status = ride['status'] ?? 'Open';
    final pickupTime = ride['PickupDateAndTime'] ?? 'Time N/A';
    final from = ride['from'] ?? 'Unknown';
    final to = ride['to'] ?? 'Unknown';
    final tripType = ride['tripType'] ?? 'One Way';
    final totalAmount = ride['customerFare'] ?? '₹0';
    final driverEarning = ride['driverEarning'] ?? '₹0';
    final commission = ride['commissionFee'] ?? '₹0';
    final driverName = driver['name'] ?? 'Unknown';
    final driverCompany = driver['agencyName'] ?? 'Company';
    final driverRating = driver['rating']?.toString() ?? '4.8';
    final driverAvatar = driver['profilePhoto']?['imageUrl'];
    final phone = driver['phoneNumber'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 8,
      shadowColor: Color(0xFFE0E0E0),
      color: Color(0xFFF6F6F6),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 0,
          maxWidth: MediaQuery.of(context).size.width,
          // Prevent overflow by limiting maxHeight, but allow scrolling if needed
          maxHeight: 260,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('ID: $bookingId ($status)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w400),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(pickupTime,
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(from, 
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF002D4C)),
                    Flexible(
                      child: Text(to, 
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(tripType, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey[800])),
                  ),
                ),
                const SizedBox(height: 8),
                // Vehicle Info
                Row(
                  children: [
                    Image.asset(carImage, width: 60, height: 40, fit: BoxFit.contain),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(carModel, style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Price Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(totalAmount, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Driver's Earning", style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(driverEarning, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Commission', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(commission, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Driver Info Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: driverAvatar != null ? NetworkImage(driverAvatar) : AssetImage('assets/driver.png') as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverName, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(driverCompany, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        Text(driverRating, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Call Button
                    InkWell(
                      onTap: () async {
                        if (phone.isNotEmpty) {
                          final Uri phoneUri = Uri(scheme: 'tel', path: phone);
                          if (await canLaunchUrl(phoneUri)) {
                            await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.call, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Chat Button
                    InkWell(
                      onTap: () {
                        // TODO: Navigate to chat screen with driver
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.chat, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCarImage(String model) {
    switch (model.toLowerCase()) {
      case 'suv':
        return 'assets/suv.png';
      case 'sedan':
        return 'assets/sedan.png';
      case 'mini':
        return 'assets/mini.png';
      default:
        return 'assets/sedan.png';
    }
  }
}

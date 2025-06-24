import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'fragments/available_fragment.dart';
import 'fragments/duty_fragment.dart';
import '../screens/upload_photos.dart';
import '../widgets/custom_app_bar.dart';
import 'my_account_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storage = const FlutterSecureStorage();
  bool _documentsComplete = false;
  bool _hideHomeInstruction = false;

  // Add for rides fetching
  List<Map<String, dynamic>> _homeRides = [];
  bool _isHomeRidesLoading = false;
  String? _userId;

  // Search logic for 'Where to?'
  final TextEditingController _searchController = TextEditingController();
  String _searchFrom = '';
  List<String> _suggestedCities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _initUserAndFetch();
  }

  void _onSearchChanged() {
    setState(() {
      _searchFrom = _searchController.text.toLowerCase();
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
    List<String> allCities = _homeRides.map((ride) => ride['from']?.toString().toLowerCase() ?? '').toSet().toList();
    setState(() {
      _suggestedCities = allCities
          .where((city) => city.contains(query.toLowerCase()))
          .take(5)
          .toList();
    });
  }

  List<Map<String, dynamic>> get _filteredHomeRides {
    if (_searchFrom.isEmpty) return _homeRides;
    return _homeRides.where((ride) {
      final from = ride['from']?.toString().toLowerCase() ?? '';
      return from.contains(_searchFrom);
    }).toList();
  }

  Future<void> _initUserAndFetch() async {
    _userId = await _storage.read(key: 'userId');
    _checkDocumentsStatus();
    _checkHideHomeInstruction();
    await _fetchHomeRides();
  }

  Future<void> _checkDocumentsStatus() async {
    final userId = await _storage.read(key: 'userId');
    if (userId == null) return;
    final response = await http.get(Uri.parse('https://api.bharatyaatri.com/api/user/getuser/$userId'));
    if (response.statusCode == 200) {
      final List<dynamic> dataList = jsonDecode(response.body);
      if (dataList.isNotEmpty) {
        final Map<String, dynamic> userData = dataList[0];
        bool profilePhoto = userData['profilePhoto']?['verificationStatus'] ?? false;
        bool numberPlate = userData['NumberPlate']?['verificationStatus'] ?? false;
        bool aadhar = userData['aadhaarPhoto']?['verificationStatus'] ?? false;
        bool dl = userData['dlPhoto']?['verificationStatus'] ?? false;
        setState(() {
          _documentsComplete = profilePhoto && numberPlate && aadhar && dl;
        });
      }
    }
  }

  Future<void> _checkHideHomeInstruction() async {
    final hide = await _storage.read(key: 'hideHomeInstruction');
    setState(() {
      _hideHomeInstruction = hide == 'true';
    });
  }

  Future<void> _fetchHomeRides() async {
    setState(() { _isHomeRidesLoading = true; });
    final String url = 'https://api.bharatyaatri.com/api/ride/getallrides?status=Pending&page=1&limit=20&ridetype=Duty';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final allRides = List<Map<String, dynamic>>.from(data['rides'] ?? []);
        setState(() {
          _homeRides = allRides.where((ride) {
            final createdBy = ride['createdByDetails'];
            if (createdBy == null || _userId == null) return true;
            return createdBy['_id'] != _userId;
          }).toList();
          _isHomeRidesLoading = false;
        });
      } else {
        setState(() { _homeRides = []; _isHomeRidesLoading = false; });
      }
    } catch (e) {
      setState(() { _homeRides = []; _isHomeRidesLoading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        onRightLogoTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Help/Support Tapped!')),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFFF6B00),
                labelColor: const Color(0xFF002D4C),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                labelPadding: EdgeInsets.symmetric(horizontal: 2),
                tabs: const [
                  Tab(text: 'BOOKINGS'),
                  Tab(text: 'DUTY'),
                  Tab(text: 'FREE VEHICLES'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // BOOKINGS TAB
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search Bar (always visible)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Where to?',
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.grey),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchFrom = '';
                                              _suggestedCities = [];
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Text("Now", style: TextStyle(color: Colors.black)),
                                    Icon(Icons.arrow_drop_down, color: Colors.black),
                                  ],
                                ),
                              ),
                            ],
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
                                    _searchFrom = city;
                                    _suggestedCities = [];
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                              )).toList(),
                            ),
                          ),
                        if (!_documentsComplete && !_hideHomeInstruction) ...[
                          // Banner
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/home1.png',
                                width: double.infinity,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                          // Instructional text and boxes
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(maxWidth: 350),
                                    child: Text(
                                      'Please complete your profile and add at-least one vehicle and one driver in order to take a booking.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        height: 1.2,
                                        letterSpacing: 0.01,
                                        color: Color(0xFF002D4C),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      _InstructionCard(
                                        title: "Personal Information",
                                        steps: [
                                          "Click Profile → Personal Information →",
                                          "Set Profile Pic → Update",
                                        ],
                                        onTap: () async {
                                          final userId = await _storage.read(key: 'userId');
                                          if (userId != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _InstructionCard(
                                        title: "Add Vehicle",
                                        steps: [
                                          "Click Profile → Manage Vehicle → Add Button →",
                                          "Add Details → Submit",
                                        ],
                                        onTap: () async {
                                          final userId = await _storage.read(key: 'userId');
                                          if (userId != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _InstructionCard(
                                        title: "Add Driver",
                                        steps: [
                                          "Click Profile → Manage Driver → Add Button →",
                                          "Add Details → Submit",
                                        ],
                                        onTap: () async {
                                          final userId = await _storage.read(key: 'userId');
                                          if (userId != null) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                        else ...[
                          if (_isHomeRidesLoading)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            )),
                          if (!_isHomeRidesLoading && _filteredHomeRides.isEmpty)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No rides found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            )),
                          if (!_isHomeRidesLoading && _filteredHomeRides.isNotEmpty)
                            ..._filteredHomeRides.map((ride) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: _LeadCard(ride: ride),
                            )).toList(),
                        ],
                      ],
                    ),
                  ),
                  // DUTY TAB
                  DutyFragment(),
                  // FREE VEHICLES TAB
                  AvailableFragment(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final String title;
  final List<String> steps;
  final VoidCallback onTap;
  const _InstructionCard({required this.title, required this.steps, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFFF6B00), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF002D4C)
                )
            ),
            const SizedBox(height: 8),
            ...steps.map((s) => Row(
              children: [
                const Icon(Icons.arrow_right, color: Color(0xFFFF6B00)),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(
                        s,
                        style: const TextStyle(fontSize: 14)
                    )
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

// LEAD CARD WIDGET (moved from DutyFragment)
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ID: $bookingId ( 0$status)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w400),
                ),
                Text(pickupTime,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(from, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF002D4C)),
                Text(to, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
                    Text(totalAmount, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Driver's Earning", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(driverEarning, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commission', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text(commission, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black)),
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
                      Text(driverName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
    );
  }
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

class _AlertsToggleBox extends StatefulWidget {
  @override
  State<_AlertsToggleBox> createState() => _AlertsToggleBoxState();
}

class _AlertsToggleBoxState extends State<_AlertsToggleBox> {
  bool _isAlertOn = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchAlertStatus();
  }

  Future<void> _fetchAlertStatus() async {
    try {
      final storage = FlutterSecureStorage();
      final String? userId = await storage.read(key: 'userId');
      if (userId != null) {
        final response = await http.get(Uri.parse('https://api.bharatyaatri.com/api/user/getuser/$userId'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            setState(() {
              _isAlertOn = data[0]['sentNotification'] ?? true;
            });
          }
        }
      }
    } catch (e) {
      // fallback: keep current state
    }
  }

  Future<void> _toggleAlertStatus() async {
    setState(() { _loading = true; });
    try {
      final storage = FlutterSecureStorage();
      final String? userId = await storage.read(key: 'userId');
      if (userId != null) {
        final response = await http.patch(
          Uri.parse('https://api.bharatyaatri.com/api/user/updateuser/$userId'),
          headers: { 'Content-Type': 'application/json' },
          body: json.encode({ 'sentNotification': !_isAlertOn }),
        );
        if (response.statusCode == 200) {
          setState(() { _isAlertOn = !_isAlertOn; });
        }
      }
    } catch (e) {
      // fallback: do not change state
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFF7D9CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ALERTS',
            style: TextStyle(
              fontFamily: 'Space Grotesk',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.0,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _loading ? null : _toggleAlertStatus,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isAlertOn ? Color(0xFF1A9F0B) : Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isAlertOn ? 'ON' : 'OFF',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                  height: 1.0,
                  letterSpacing: 0,
                  color: _isAlertOn ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
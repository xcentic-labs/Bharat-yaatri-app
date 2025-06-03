import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  LatLng _currentLocation = const LatLng(37.7749, -122.4194); // Default: San Francisco
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Determine User's Current Location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog("Location services are disabled. Please enable them.");
      return;
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showErrorDialog("Location permissions are denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isMapLoaded = true;
      });
    } catch (e) {
      _showErrorDialog("Failed to fetch location.");
    }
  }

  // Show an Error Dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF), // Light background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar and Time Button
                Row(
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
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Where to?",
                                  border: InputBorder.none,
                                ),
                              ),
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
                const SizedBox(height: 16),

                // Map Section with Real-Time Map
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _isMapLoaded
                            ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation,
                            zoom: 14.0,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        )
                            : const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      ..._buildCarIcons(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Last Rides Section
                const Text(
                  "Last rides",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRideItem("Canadian Society", "67, Nexa Rd, Ben, Canada"),
                _buildRideItem("Avenue Society", "173 U.S. 82, Alamogordo, New York"),
                _buildRideItem("Holley Rd", "Some other address here"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Location Button Widget
  Widget _buildLocationButton(String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black)),
    );
  }

  // Car Icons on the Map
  List<Widget> _buildCarIcons() {
    return [
      const Positioned(top: 60, left: 100, child: Icon(Icons.local_taxi, color: Colors.yellow, size: 30)),
      const Positioned(top: 120, right: 80, child: Icon(Icons.local_taxi, color: Colors.yellow, size: 30)),
      const Positioned(bottom: 50, left: 150, child: Icon(Icons.local_taxi, color: Colors.yellow, size: 30)),
      const Positioned(bottom: 80, right: 50, child: Icon(Icons.local_taxi, color: Colors.yellow, size: 30)),
    ];
  }

  // Last Ride Item
  Widget _buildRideItem(String title, String address) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            const Icon(Icons.location_pin, color: Colors.blue),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

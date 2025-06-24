import 'package:cabproject/screens/add_duty_screen.dart';
import 'package:cabproject/screens/add_ride_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyRidesPage extends StatefulWidget {
  const MyRidesPage({Key? key}) : super(key: key);

  @override
  State<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends State<MyRidesPage> {
  bool isLoading = true;
  List<dynamic> rides = [];
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchRides();
  }

  Future<void> _fetchRides() async {
    try {
      // Retrieve user ID from secure storage or another source
      final String? userId = await _secureStorage.read(key: 'userId'); // Replace with dynamic user ID

      final String apiUrl = "https://api.bharatyaatri.com/api/ride/getownrides/$userId";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          rides = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load rides");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching rides.")),
      );
    }
  }

  Widget _buildRideOption({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Color(0xFFF5F5F5),  // Ensure Material widget wraps the ListTile and gives it the black color
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: Color(0xFF002D4C),  // Ensuring the background color is black
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.black),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFFF5F5F5),
        title: const Text(
          'My Rides',
          style: TextStyle(fontWeight: FontWeight.bold,color: Color(0xFF002D4C), fontSize: 25),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFF002D4C),  // Change back arrow color
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: ListView.builder(
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return RideCard(
                          carModel: ride['carModel'] ?? 'Unknown',
                          createdAt: ride['createdAt'] ?? 'Unknown',
                          from: ride['from'] ?? 'Unknown',
                          to: ride['to'] ?? 'Unknown',
                          description: ride['description'] ?? 'No description',
                          status: ride['status'] ?? 'Unknown',
                          rideId: ride['_id'], // Assuming '_id' is the ride's unique identifier
                          onDelete: () => _fetchRides(), // Refresh list after deletion
                          onUpdate: () => _fetchRides(),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title for the modal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add Ride',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color:  Colors.black,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color:  Colors.black),
                            ),
                          ],
                        ),
                      ),
                      // List of options
                      _buildRideOption(
                        icon: Icons.person,
                        color: Colors.white,
                        title: 'Need Car/Driver?',
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to the respective page
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => AddDutyScreen()));
                        },
                      ),
                      _buildRideOption(
                        icon: Icons.person_search,
                        color: Colors.white,
                        title: 'Need Duty/Customers?',
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to the respective page
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => AddRideScreen()));
                        },
                      ),
                      _buildRideOption(
                        icon: Icons.swap_horiz,
                        color: Colors.white,
                        title: 'Exchange Duties',
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => AddRideScreen()));
                          // Navigate to the respective page
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        label: const Text(
          'Add Ride',
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF002D4C),
      ),
    );
  }
}

class RideCard extends StatelessWidget {
  final String carModel;
  final String createdAt;
  final String from;
  final String to;
  final String description;
  final String status;
  final String rideId;
  final Function onDelete;
  final Function onUpdate; // Callback to refresh UI after update

  const RideCard({
    Key? key,
    required this.carModel,
    required this.createdAt,
    required this.from,
    required this.to,
    required this.description,
    required this.status,
    required this.rideId,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  Future<void> _deleteRide(BuildContext context) async {
    final String apiUrl = "https://api.bharatyaatri.com/api/ride/deleteride/$rideId";

    try {
      final response = await http.delete(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride deleted successfully")),
        );
        onDelete(); // Refresh the rides list
      } else {
        throw Exception("Failed to delete ride");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error.")),
      );
    }
  }

  Future<void> _updateRideStatus(BuildContext context) async {
    final String apiUrl = "https://api.bharatyaatri.com/api/ride/updateride/$rideId";

    try {
      final response = await http.patch(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "Completed"}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride status updated to Completed")),
        );
        onUpdate(); // Refresh the rides list
      } else {
        throw Exception("Failed to update ride status");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 5,
          color: const Color(0xFFF5F5F5),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Model and Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          _getCarImage(carModel),
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carModel,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              createdAt,
                              style: const TextStyle(
                                color: Color(0xFF002D4C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRide(context),
                    ),
                  ],
                ),

                // Ride Details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location_outlined, size: 12, color: Color(0xFF002D4C)),
                              const SizedBox(width: 3),
                              const Text(
                                "From",
                                style: TextStyle(
                                  color: Color(0xFF002D4C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(from, style: const TextStyle(color: Colors.black, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.my_location_outlined, size: 12, color: Color(0xFF002D4C)),
                              const SizedBox(width: 3),
                              const Text(
                                "To",
                                style: TextStyle(
                                  color: Color(0xFF002D4C),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(to, style: const TextStyle(color: Colors.black, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Ride Details",
                      style: TextStyle(
                        color: Color(0xFF1D1A31),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Ride Status",
                      style: TextStyle(
                        color: Color(0xFF1D1A31),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: status == "Completed" ? Colors.green : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                if (status != "Completed")
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _updateRideStatus(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Mark as Completed", style: TextStyle(color: Colors.white)),
                    ),
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

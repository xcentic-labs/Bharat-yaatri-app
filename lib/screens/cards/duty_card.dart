import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cabproject/screens/subscription-page.dart';

class DutyCard extends StatefulWidget {
  final String carModel;
  final String createdAt;
  final String from;
  final String to;
  final String description;
  final String pickupDateAndTime;
  final String customerFare;
  final String commissionFee;
  final String tripType;
  final String rideType;
  final String personName;
  final String personPhoneNumber;
  final String role;
  final String carrierType;

  const DutyCard({
    Key? key,
    required this.carModel,
    required this.createdAt,
    required this.from,
    required this.to,
    required this.description,
    required this.pickupDateAndTime,
    required this.customerFare,
    required this.commissionFee,
    required this.tripType,
    required this.rideType,
    required this.personName,
    required this.personPhoneNumber,
    required this.role,
    required this.carrierType
  }) : super(key: key);

  @override
  _DutyCardState createState() => _DutyCardState();
}

class _DutyCardState extends State<DutyCard> {
  bool isSubscribed = false;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      String? userId = await _secureStorage.read(key: 'userId');
      if (userId != null) {
        final response = await http.get(Uri.parse('https://api.bharatyaatri.com/api/user/getuser/$userId'));
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);
          setState(() {
            isSubscribed = data[0]['isSubscribed'] ?? false;
          });
        } else {
          setState(() {
            isSubscribed = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching subscription status.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 20,
        shadowColor: Colors.black,
        color: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Car Model and Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    _getCarImage(widget.carModel),
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.carModel,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.createdAt,
                          style: const TextStyle(
                            color: Color(0xFFE96E03),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final String fromQuery = Uri.encodeComponent(widget.from);
                      final String toQuery = Uri.encodeComponent(widget.to);

                      final Uri googleMapsUrl = Uri.parse(
                        "https://www.google.com/maps/dir/?api=1&origin=$fromQuery&destination=$toQuery&travelmode=driving",
                      );

                      if (await canLaunchUrl(googleMapsUrl)) {
                        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open Google Maps')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(6),
                      backgroundColor: const Color(0xFFE96E03),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location_outlined,
                                size: 12, color: Color(0xFFE96E03)),
                            const SizedBox(width: 3),
                            Text(
                              "From",
                              style: TextStyle(
                                color: Color(0xFFE96E03),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.from,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.my_location_outlined,
                                size: 12, color: Color(0xFFE96E03)),
                            Text(
                              "To",
                              style: TextStyle(
                                color: Color(0xFFE96E03),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widget.to,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Ride Details Section
              const Text(
                "Ride Information",
                style: TextStyle(
                  color: Color(0xFF1D1A31),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today, "Pickup Date & Time", widget.pickupDateAndTime),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.currency_rupee, "Customer Fare", "₹${widget.customerFare}"),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.currency_rupee, "Commission Fee", "₹${widget.commissionFee}"),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.trip_origin, "Trip Type", widget.tripType),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoRow(Icons.luggage, "Carrier Type", widget.carrierType),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Call Button with Subscription Check
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage("assets/user2.png"),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.personName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.role,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (isSubscribed) {
                        final Uri phoneUri = Uri(scheme: 'tel', path: widget.personPhoneNumber);

                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri,mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch phone dialer')),
                          );
                        }

                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SubscriptionPage()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE96E03),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text(
                      "Call",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFE96E03), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
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

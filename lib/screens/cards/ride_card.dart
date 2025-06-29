import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cabproject/screens/subscription-page.dart';

class RideCard extends StatefulWidget {
  final String carModel;
  final String createdAt;
  final String from;
  final String to;
  final String description;
  final String personName;
  final String personPhoneNumber;
  final String role;
  final String carrierType; // <-- Add Carrier Type here

  const RideCard({
    Key? key,
    required this.carModel,
    required this.createdAt,
    required this.from,
    required this.to,
    required this.description,
    required this.personName,
    required this.personPhoneNumber,
    required this.role,
    required this.carrierType, // <-- Add Carrier Type here
  }) : super(key: key);

  @override
  _RideCardState createState() => _RideCardState();
}


class _RideCardState extends State<RideCard> {
  bool isSubscribed = false;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      // Fetch the userId from secure storage
      String? userId = await _secureStorage.read(key: 'userId');
      if (userId != null) {
        // Fetch user data from API
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
          side: BorderSide(
            color: Colors.white
          )
        ),
        elevation: 15,
        shadowColor: Colors.black,
        color: Color(0xFFF5F5F5),
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
                            color: Colors.black,
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
                      backgroundColor: Color(0xFFE96E03),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white),
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

              const SizedBox(height: 15),
              const Text(
                "Ride Details",
                style: TextStyle(
                  color: Color(0xFFE96E03),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),

// Carrier Type Section
              const SizedBox(height: 15),
              const Text(
                "Carrier Type",
                style: TextStyle(
                  color: Color(0xFFE96E03),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.carrierType,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),

              // Call Button with Subscription Check
              const SizedBox(height: 16),
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
                            color: Colors.black,
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
                          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open the dialer')),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class NewDutyCard extends StatelessWidget {
  final String rideId;
  final String status;
  final String dateTime;
  final String from;
  final String to;
  final String tripType;
  final String carModel;
  final String totalAmount;
  final String driverEarning;
  final String commission;
  final String driverName;
  final String driverAgency;
  final double driverRating;
  final String driverPhotoUrl;
  final VoidCallback onChat;
  final VoidCallback onCall;

  const NewDutyCard({
    Key? key,
    required this.rideId,
    required this.status,
    required this.dateTime,
    required this.from,
    required this.to,
    required this.tripType,
    required this.carModel,
    required this.totalAmount,
    required this.driverEarning,
    required this.commission,
    required this.driverName,
    required this.driverAgency,
    required this.driverRating,
    required this.driverPhotoUrl,
    required this.onChat,
    required this.onCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color.fromRGBO(128, 0, 128, 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: ID, Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: $rideId ($status)',
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  dateTime,
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Middle Section: Route and Car
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(from,
                    style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text('—$tripType—',
                    style: GoogleFonts.manrope(
                        fontSize: 12, color: Colors.grey[600])),
                Text(to,
                    style: GoogleFonts.manrope(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Image.asset('assets/sedan.png', height: 40),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    carModel,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Financial Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFinancialInfo('Total Amount', totalAmount),
                _buildFinancialInfo('Driver\'s Earning', driverEarning),
                _buildFinancialInfo('Commission', commission),
              ],
            ),
            const SizedBox(height: 16),

            // Driver Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(driverPhotoUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: GoogleFonts.manrope(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          driverAgency,
                          style: GoogleFonts.manrope(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        driverRating.toString(),
                        style: GoogleFonts.manrope(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.orange),
                    onPressed: onChat,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_outlined, color: Colors.orange),
                    onPressed: onCall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfo(String title, String amount) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          '₹$amount',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailContainer(String label, TextEditingController controller) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF002B4D)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              readOnly: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
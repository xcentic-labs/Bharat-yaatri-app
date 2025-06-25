import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // A more standard background color
      appBar: CustomAppBar(
        onRightLogoTap: () {
          // Handle the tap event, e.g., navigate to a help screen
          print("Right logo tapped on MyBookingScreen!");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Help/Support Tapped!')),
          );
        },
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFF6B00),
              labelColor: const Color(0xFF002D4C),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              tabs: const [
                Tab(text: 'BOOKING POSTED'),
                Tab(text: 'BOOKING RECEIVED'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                Center(
                  child: Text('Booking Posted Content'),
                ),
                Center(
                  child: Text('Booking Received Content'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
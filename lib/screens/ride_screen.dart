import 'package:cabproject/screens/add_duty_screen.dart';
import 'package:cabproject/screens/add_ride_screen.dart';
import 'package:cabproject/screens/fragments/available_fragment.dart';
import 'package:cabproject/screens/my_rides.dart';
import 'package:cabproject/screens/subscription-page.dart';
import 'package:flutter/material.dart';
import 'fragments/duty_fragment.dart';
import 'fragments/exchange_fragment.dart';
import 'filter_modal.dart';
import 'package:cabproject/screens/agent_account_page.dart';
import 'package:cabproject/screens/rider_account_page.dart';

class RideScreen extends StatefulWidget {
  final String name;
  final String currentCity;
  final String profileImageUrl;
  final String userType;
  final bool isAlertOn;

  const RideScreen({
    Key? key,
    required this.name,
    required this.currentCity,
    required this.profileImageUrl,
    required this.userType,
    required this.isAlertOn,
  }) : super(key: key);

  @override
  _RideScreenState createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  int _currentFragment = 0; // 0 for Rides, 1 for Agents
  final PageController _pageController = PageController();

  Map<String, String> _appliedFilters = {}; // Store applied filters
  final GlobalKey<DutyFragmentState> _dutyFragmentKey =
      GlobalKey<DutyFragmentState>();
  final GlobalKey<ExchangeFragmentState> _exchangeFragmentKey =
      GlobalKey<ExchangeFragmentState>();
  final GlobalKey<AvailableFragmentState> _availableFragmentKey =
      GlobalKey<AvailableFragmentState>(); // GlobalKey for AgentsFragment

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper function for navigation to account page (re-implemented from old BottomNav)
  void _navigateToAccountPage() {
    print(widget.userType);
    if (widget.userType == 'RIDER') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountPage()),
      );
    } else if (widget.userType == 'AGENT') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AgentAccountPage()),
      );
    } else if (widget.userType == 'ADMIN') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AgentAccountPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid user type')),
      );
    }
  }

  Widget _buildGradientButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Flexible(
      child: SizedBox(
        width: 150,
        height: 38,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5), // Shadow color
                      blurRadius: 3, // Spread of the shadow
                      offset: Offset(0, 2), // Position of the shadow
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(3),
          child: Material(
            color: const Color(0xFFE96E03), // Button background color
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onPressed,
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Flexible(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE96E03), width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFFE96E03), // Background color for the button
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
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
        color: Colors
            .black, // Ensure Material widget wraps the ListTile and gives it the black color
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor:
              Color(0xFFE96E03), // Ensuring the background color is black
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5EE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72), // Height for the custom AppBar
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Color(0xFFF5F5EE),
          flexibleSpace: Container(
            margin: const EdgeInsets.only(top: 35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            _navigateToAccountPage();
                          },
                          child: CircleAvatar(
                            radius: 24,
                            backgroundImage: widget.profileImageUrl.startsWith('assets/')
                                ? AssetImage(widget.profileImageUrl) as ImageProvider
                                : NetworkImage("https://api.bharatyaatri.com/" + widget.profileImageUrl),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Hey ${widget.name}!",
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                const Icon(Icons.circle,
                                    color: Color(0xFFE96E03), size: 10),
                                Flexible(
                                  child: Text(
                                    " ${widget.currentCity}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.isAlertOn
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: const Color(0xFFE96E03),
                        size: 30,
                      ),
                      // The actual switch is handled in BottomNav, this is just visual
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // My Leads and Location buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            color: Color(0xFFF5F5EE),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCustomButton(
                  text: "My Rides",
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => MyRidesPage()));
                  },
                ),
                const SizedBox(width: 8),
                _buildCustomButton(
                  text: "Location",
                  onPressed: () async {
                    final filters =
                        await showModalBottomSheet<Map<String, String>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (BuildContext context) {
                        return Container(
                          height: MediaQuery.of(context).size.height * 0.9,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: const FilterModal(),
                        );
                      },
                    );

                    if (filters != null) {
                      setState(() {
                        _appliedFilters = filters;
                      });
                      _dutyFragmentKey.currentState?.applyFilters(filters);
                      _exchangeFragmentKey.currentState?.applyFilters(filters);
                      _availableFragmentKey.currentState?.applyFilters(filters);
                    }
                  },
                ),
              ],
            ),
          ),
          // Start Membership container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
                color: Color(0xFFF5F5EE),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Color(0xFFE96E03))),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Start Membership",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE96E03),
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SubscriptionPage()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE96E03),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                        child: const Text(
                          "Join Now",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // PageView for fragments
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentFragment = index;
                });
              },
              children: <Widget>[
                DutyFragment(key: _dutyFragmentKey),
                ExchangeFragment(key: _exchangeFragmentKey),
                AvailableFragment(key: _availableFragmentKey), // AgentsFragment
              ],
            ),
          ),
          // Bottom navigation for fragments
          Container(
            color: Color(0xFFF5F5EE),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGradientButton(
                  text: "Rides",
                  isSelected: _currentFragment == 0,
                  onPressed: () {
                    _pageController.animateToPage(0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                ),
                _buildGradientButton(
                  text: "Exchange",
                  isSelected: _currentFragment == 1,
                  onPressed: () {
                    _pageController.animateToPage(1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                ),
                _buildGradientButton(
                  text: "Agents",
                  isSelected: _currentFragment == 2,
                  onPressed: () {
                    _pageController.animateToPage(2,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.ease);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 105,
        child: FloatingActionButton.extended(
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
                      color: Color(0xFFF5F5EE),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title for the modal
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Add Ride',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close,
                                    color: Colors.black),
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
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddDutyScreen()));
                          },
                        ),
                        _buildRideOption(
                          icon: Icons.person_search,
                          color: Colors.white,
                          title: 'Need Duty/Customers?',
                          onTap: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddRideScreen()),
                            );

                            if (result == true) {
                              // Call the refresh function of DutyFragment if result is true
                              _dutyFragmentKey.currentState?.fetchRidesData();
                            }
                          },
                        ),

                        _buildRideOption(
                          icon: Icons.swap_horiz,
                          color: Colors.white,
                          title: 'Exchange Duties',
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddRideScreen()));
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
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          icon: const Icon(
            Icons.add,
            color: Colors.white,
            size: 15,
          ),
          backgroundColor: const Color(0xFFE96E03),
        ),
      ),
    );
  }
}

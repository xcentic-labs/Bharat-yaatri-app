import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/agent_account_page.dart';
import 'screens/rider_account_page.dart';
import 'screens/ride_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/my_booking_screen.dart';
import 'screens/add_plus_button_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_duty_screen.dart';
import 'screens/add_ride_screen.dart';

class BottomNav extends StatefulWidget {
  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;
  bool _isAlertOn = true;
  String _currentCity = "Loading...";
  String _name = 'User';
  String _profileImageUrl = 'assets/agent.png';
  String _userType = 'none';

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _setupFirebaseMessaging();
    _initializeData();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _initializeScreens() {
    _screens = <Widget>[
      HomeScreen(),
      const MyBookingScreen(),
      ChatScreen(userName: 'Unknown', userId: 'Unknown'),
      ProfileScreen(),
    ];
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging.onTokenRefresh.listen((newToken) {
      _updateToken(newToken);
    });
  }

  void _initializeData() {
    Future.delayed(Duration.zero, () async {
      await _getCurrentCity();
      await _fetchUserData();
    });
  }

  void _updateScreens() {
    setState(() {
      _screens = <Widget>[
        HomeScreen(),
        const MyBookingScreen(),
        ChatScreen(userName: 'Unknown', userId: 'Unknown'),
        ProfileScreen(),
      ];
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      // Center '+' icon tapped: show Add Ride modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.40,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title and close button
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
                            color: Colors.black,
                            fontFamily: 'SpaceGrotesk',
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action Buttons
                  _buildAddRideOption(
                    icon: Icons.person,
                    title: 'Need Car/Driver?',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddDutyScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildAddRideOption(
                    icon: Icons.person_search,
                    title: 'Need Duty/Customers?',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddRideScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildAddRideOption(
                    icon: Icons.swap_horiz,
                    title: 'Exchange Duties',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddRideScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      setState(() {
        _selectedIndex = index < 2 ? index : index - 1;
      });
    }
  }

  Widget _buildAddRideOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFF002D4C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/home.png',
                height: 24,
                width: 24,
                color: _selectedIndex == 0 ? Color(0xFFFF6B00) : Colors.grey,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/bookingicon.png',
                height: 24,
                width: 24,
                color: _selectedIndex == 1 ? Color(0xFFFF6B00) : Colors.grey,
              ),
              label: 'My Booking',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF002D4C),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/plus.png',
                    height: 24,
                    width: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/chat.png',
                height: 24,
                width: 24,
                color: _selectedIndex == 2 ? Color(0xFFFF6B00) : Colors.grey,
              ),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
                color: _selectedIndex == 3 ? Color(0xFFFF6B00) : Colors.grey,
              ),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1,
          selectedItemColor: Color(0xFFFF6B00),
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFF002D4C),
          elevation: 0,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true; // Exit app
  }

  Future<void> _fetchUserData() async {
    try {
      final String? userId = await _storage.read(key: 'userId');
      if (userId != null) {
        // Fetch the FCM token
        final String? fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          final String url =
              'https://api.bharatyaatri.com/api/user/updateuser/$userId';
          final response = await http.patch(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'fcmtoken': fcmToken,
            }),
          );

          if (response.statusCode == 200) {
            print('FCM token updated successfully');
          } else {
            print('Failed to update FCM token: ${response.body}');
          }
        }

        // Fetch user data including notification status
        final String userDataUrl =
            'https://api.bharatyaatri.com/api/user/getuser/$userId';
        final response = await http.get(Uri.parse(userDataUrl));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            if (mounted) {
              setState(() {
                _name = (data[0]['name']?.split(' ')[0]) ?? 'User';
                _profileImageUrl =
                    data[0]['profilePhoto']['imageUrl'] ?? 'assets/rider.png';
                _userType = data[0]['userType'] ?? 'none';
                _isAlertOn = data[0]['sentNotification'] ?? true;

                // Update _screens list with fetched data
                _screens = <Widget>[
                  HomeScreen(),
                  const MyBookingScreen(),
                  ChatScreen(userName: 'Unknown', userId: 'Unknown'),
                  ProfileScreen(),
                ];
              });
            }
          }
        } else {
          // This part shows the snackbar. We will bypass it.
          // if (mounted) {
          //   setState(() {});
          // }
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Failed to fetch user data')),
          // );
        }
      }
    } catch (e) {
      print('Error fetching user data in bottom_nav: $e');
      // Also suppress snackbar on exception
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('An error occurred: $e')),
      // );
    }
  }

  Future<void> _updateToken(String newToken) async {
    final String? userId = await _storage.read(key: 'userId');
    if (userId != null) {
      try {
        final String url =
            'https://api.bharatyaatri.com/api/user/updateuser/$userId';
        final response = await http.patch(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'fcmtoken': newToken,
          }),
        );

        if (response.statusCode == 200) {
          print('FCM token updated successfully');
        } else {
          print('Failed to update FCM token: ${response.body}');
        }
      } catch (e) {
        print('Error updating FCM token.');
      }
    }
  }

  Future<void> _getCurrentCity() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentCity = "Location services are disabled. Please enable them.";
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentCity = "Location permission denied.";
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      String currentCity = place.locality ?? "City not found";

      if (mounted) {
        setState(() {
          _currentCity = currentCity;

          // Update _screens list with current city for RideScreen
          _screens = <Widget>[
            HomeScreen(),
            const MyBookingScreen(),
            ChatScreen(userName: 'Unknown', userId: 'Unknown'),
            ProfileScreen(),
          ];
        });
      }

      // Get userId from secure storage
      final String? userId = await _storage.read(key: 'userId');
      if (userId != null) {
        // Send the current city to your backend
        final url = 'https://api.bharatyaatri.com/api/user/updateuser/$userId';
        final response = await http.patch(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'userCurrentLocation': currentCity,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated successfully'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update location')),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _currentCity = "Error: ${e.toString()}";
        });
      }
    }
  }
}


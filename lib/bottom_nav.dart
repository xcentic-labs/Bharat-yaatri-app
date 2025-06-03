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

  static final List<Widget> _screens = <Widget>[
    RideScreen(),
    ProfileScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.directions_car),
      label: "Rides",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profile",
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Get an instance of FirebaseMessaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      _updateToken(newToken);
    });

    // Other initializations
    Future.delayed(Duration.zero, () {
      _getCurrentCity();
      _fetchUserData();
    });

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
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
                _userType = data[0]['userType'] ??
                    'none'; // Fetch userType from the response
                print(_userType);
                _isAlertOn = data[0]['sentNotification'] ?? true;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {});
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch user data')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data.')),
      );
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentCity = "Error: ${e.toString()}";
        });
      }
    }
  }

  Future<void> _updateToken(String newToken) async {
    final String? userId = await _storage.read(key: 'userId');
    if (userId != null) {
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
        print('FCM token refreshed and updated successfully');
      } else {
        print('Failed to update refreshed FCM token: ${response.body}');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  IconData _getSelectedIcon(int index) {
    switch (index) {
      case 0:
        return _selectedIndex == 0
            ? Icons.directions_car
            : Icons.directions_car_filled_outlined;
      case 1:
        return _selectedIndex == 1 ? Icons.person : Icons.person_outline;
      default:
        return Icons.home;
    }
  }

  void _navigateToAccountPage() {
    print(_userType);
    if (_userType == 'RIDER') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AccountPage()),
      );
    } else if (_userType == 'AGENT') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AgentAccountPage()),
      );
    } else if (_userType == 'ADMIN') {
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

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _selectedIndex == 1
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(72),
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
                                    backgroundImage: _profileImageUrl
                                            .startsWith('profile')
                                        ? NetworkImage(
                                            "https://api.bharatyaatri.com/" +
                                                _profileImageUrl)
                                        : AssetImage('assets/agent.png')
                                            as ImageProvider,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hey $_name!",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.circle,
                                            color: Color(0xFFE96E03), size: 10),
                                        Flexible(
                                          child: Text(
                                            " $_currentCity",
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
                                _isAlertOn
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color: const Color(0xFFE96E03),
                                size: 30,
                              ),
                              Switch(
                                value: _isAlertOn,
                                onChanged: (value) async {
                                  setState(() {
                                    _isAlertOn = value;
                                  });

                                  final String? userId =
                                      await _storage.read(key: 'userId');
                                  if (userId != null) {
                                    final String url =
                                        'https://api.bharatyaatri.com/api/user/updateuser/$userId';
                                    final response = await http.patch(
                                      Uri.parse(url),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: json.encode({
                                        'sentNotification': _isAlertOn,
                                      }),
                                    );

                                    if (response.statusCode == 200) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Notification preference updated'),
                                            duration: Duration(seconds: 1)),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed to update notification preference')),
                                      );
                                    }
                                  }
                                },
                                activeColor: const Color(0xFFE96E03),
                                inactiveTrackColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        body: _screens[_selectedIndex],
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: ClipRRect(
              child: BottomNavigationBar(
                items: _navItems.map((item) {
                  return BottomNavigationBarItem(
                    icon: Icon(
                      _getSelectedIcon(_navItems.indexOf(item)),
                      size: 22,
                    ),
                    label: item.label,
                  );
                }).toList(),
                currentIndex: _selectedIndex,
                selectedItemColor: const Color(0xFFE96E03),
                unselectedItemColor: const Color(0xFFE96E03),
                backgroundColor: Color(0xFFF5F5EE),
                type: BottomNavigationBarType.fixed,
                onTap: _onItemTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

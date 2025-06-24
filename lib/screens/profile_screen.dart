import 'dart:convert';
import 'package:cabproject/screens/my_rides.dart';
import 'package:cabproject/screens/rider_account_page.dart';
import 'package:cabproject/screens/subscription-page.dart';
import 'package:cabproject/screens/upload_photos.dart';
import 'package:cabproject/screens/my_account_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'agent_account_page.dart';
import 'login.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cabproject/screens/privacy_policy_screen.dart';
import 'manage_drivers_screen.dart';
import 'manage_vehicles_screen.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String _name = 'Guest';
  String? _profileImageUrl = 'assets/agent.png';
  String _userType = '';
  String _carType = 'Swift Dzire'; // Placeholder, replace with backend value if available
  double _rating = 4.8; // Placeholder, replace with backend value if available
  bool _isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    print('==== [DEBUG] ProfileScreen: _fetchUserData called ====' );
    try {
      final String? userId = await _secureStorage.read(key: 'userId');
      print('==== [DEBUG] userId from secure storage: $userId ====' );
      if (userId != null) {
        final String url = 'https://api.bharatyaatri.com/api/user/getuser/$userId';
        final response = await http.get(Uri.parse(url));
        print('==== [DEBUG] HTTP status: ${response.statusCode} ====' );
        print('==== [DEBUG] User data response: ${response.body} ====' );
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            if (mounted) {
              setState(() {
                _name = (data[0]['name'] != null && data[0]['name'].toString().trim().isNotEmpty)
                    ? data[0]['name']
                    : 'User';
                _profileImageUrl = (data[0]['profilePhoto'] != null && data[0]['profilePhoto']['imageUrl'] != null && data[0]['profilePhoto']['imageUrl'].toString().trim().isNotEmpty)
                    ? data[0]['profilePhoto']['imageUrl']
                    : 'assets/agent.png';
                _userType = data[0]['userType'] ?? '';
                _carType = (data[0]['carType'] != null && data[0]['carType'].toString().trim().isNotEmpty)
                    ? data[0]['carType']
                    : 'Swift Dzire';
                _rating = (data[0]['rating'] != null && data[0]['rating'].toString().trim().isNotEmpty)
                    ? double.tryParse(data[0]['rating'].toString()) ?? 4.8
                    : 4.8;
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _name = 'No Data Found';
                _profileImageUrl = 'assets/user2.png';
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch user data')),
          );
        }
      }
    } catch (e) {
      print('==== [DEBUG] Exception in _fetchUserData: $e ====' );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching details')),
      );
    }
  }

  Future<void> _logout() async {
    final bool? confirmLogout = await _showLogoutConfirmationDialog();
    if (confirmLogout == true) {
      await _secureStorage.delete(key: "userId");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  Future<bool?> _showLogoutConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
            TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
            ),
            TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _navigateToDummyScreen(String title) {
    Navigator.push(
              context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text('$title screen coming soon!')),
        ),
      ),
    );
  }

  void _navigateToAboutUs() {
    _navigateToDummyScreen('About Us');
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
    );
  }

  void _navigateToPersonalInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyAccountScreen()),
    );
  }

  void _navigateToManageDrivers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageDriversScreen()),
    );
  }

  void _navigateToManageVehicles() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManageVehiclesScreen()),
    );
  }

  void _navigateToPaymentMethods() {
    _navigateToDummyScreen('Payment Methods');
  }

  void _navigateToSubscriptions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubscriptionPage()),
    );
  }

  void _navigateToDocuments() async {
  final String? userId = await _secureStorage.read(key: 'userId');
  if (userId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
    );
  } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID not found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF002B4D),
                                  ),
                                ),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                          Icons.star,
                                          color: index < _rating.round()
                                              ? Colors.amber
                                              : Colors.grey.shade300,
                                          size: 16,
                                        )),
                                    SizedBox(width: 4),
                                    Text(
                                      _rating.toStringAsFixed(1),
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Car type: $_carType',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: (_profileImageUrl != null && _profileImageUrl!.startsWith('profile'))
                                ? NetworkImage("https://api.bharatyaatri.com/" + _profileImageUrl!)
                                : AssetImage(_profileImageUrl ?? 'assets/agent.png') as ImageProvider,
                            backgroundColor: const Color(0xFF002B4D),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ProfileActionButton(
                            assetIcon: 'assets/help.png',
                            label: 'Help',
                            onTap: () => _navigateToDummyScreen('Help'),
                            compact: true,
                            assetWidth: 35,
                            assetHeight: 35,
                          ),
                          _ProfileActionButton(
                            assetIcon: 'assets/pastactivity.png',
                            label: 'Past Activity',
                            onTap: () => _navigateToDummyScreen('Past Activity'),
                            compact: true,
                            assetWidth: 35,
                            assetHeight: 28,
                          ),
                          _ProfileActionButton(
                            assetIcon: 'assets/Rupees.png',
                            label: 'Transactions',
                            onTap: () => _navigateToDummyScreen('Transactions'),
                            compact: true,
                            assetWidth: 45,
                            assetHeight: 45,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Account',
                        style: GoogleFonts.manrope(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF002B4D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ProfileListTile(
                        label: 'Personal Information',
                        onTap: _navigateToPersonalInfo,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Documents',
                        onTap: _navigateToDocuments,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Manage Drivers',
                        onTap: _navigateToManageDrivers,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Manage Vehicles',
                        onTap: _navigateToManageVehicles,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Payment Methods',
                        onTap: _navigateToPaymentMethods,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Subscriptions',
                        onTap: _navigateToSubscriptions,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        height: 2,
                        color: Color(0xFFD9D9D9),
                      ),
                      Text(
                        'General',
                        style: GoogleFonts.manrope(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Color(0xFF002B4D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ProfileListTile(
                        label: 'About us',
                        onTap: _navigateToAboutUs,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Privacy Policy',
                        onTap: _navigateToPrivacyPolicy,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      _ProfileListTile(
                        label: 'Logout',
                        onTap: _logout,
                        color: Colors.redAccent,
                        textStyle: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                          letterSpacing: 0,
                          color: const Color(0xFF6F6F70),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final String? assetIcon;
  final double? assetWidth;
  final double? assetHeight;
  const _ProfileActionButton({this.icon, required this.label, required this.onTap, this.compact = false, this.assetIcon, this.assetWidth, this.assetHeight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 125,
          height: 100,
          margin: EdgeInsets.symmetric(horizontal: 2),
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (assetIcon != null)
                SizedBox(
                  height: 45,
                  child: Center(
                    child: Image.asset(assetIcon!, width: assetWidth, height: assetHeight),
                  ),
                )
              else if (icon != null)
                Icon(icon, color: Color(0xFF002B4D), size: compact ? 22 : 28),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: 0.16,
                  color: const Color(0xFF002B4D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final TextStyle? textStyle;
  const _ProfileListTile({required this.label, required this.onTap, this.color, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      dense: true,
      minVerticalPadding: 0,
        title: Text(
        label,
        style: textStyle ?? GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: color ?? Color(0xFF002B4D),
        ),
      ),
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
    );
  }
}

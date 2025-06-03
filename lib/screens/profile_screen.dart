import 'dart:convert';
import 'package:cabproject/screens/my_rides.dart';
import 'package:cabproject/screens/rider_account_page.dart';
import 'package:cabproject/screens/subscription-page.dart';
import 'package:cabproject/screens/upload_photos.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'agent_account_page.dart';
import 'login.dart';
import 'package:url_launcher/url_launcher.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String _name = 'Guest'; // Default name for guest users
  String? _profileImageUrl = 'assets/agent.png'; // Default image for guest users
  String _userType = ''; // Default userType
  bool _isLoading = true; // Loading state for user data
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final String? userId = await _secureStorage.read(key: 'userId');
      if (userId != null) {
        final String url = 'https://api.bharatyaatri.com/api/user/getuser/$userId';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          if (data.isNotEmpty) {
            if (mounted) {
              setState(() {
                _name = (data[0]['name']) ?? 'User';
                _profileImageUrl = data[0]['profilePhoto']['imageUrl'] ?? 'assets/agent.png';
                _userType = data[0]['userType'] ?? ''; // Fetch userType from the response
                _isLoading = false; // Stop loading once data is fetched
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
              _isLoading = false; // Stop loading on failure
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch user data')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading on error
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching details')),
      );
    }
  }

  // Logout function to remove userId from secure storage and navigate to login screen
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
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF5F5F5),
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: const Text('Logout', style: TextStyle(color: Color(0xFFE96E03))),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/banner.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 55,
                      backgroundImage: _profileImageUrl != null
                          ? (_profileImageUrl!.startsWith('profile')
                          ? NetworkImage("https://api.bharatyaatri.com/"+_profileImageUrl!)
                          : AssetImage('assets/agent.png'))
                          : const AssetImage('assets/agent.png'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            _isLoading
                ? const CircularProgressIndicator() // Show loading indicator while fetching data
                : Text(
              _name,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold,color: Color(0xFFE96E03)),
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              context,
              Icons.person,
              'My Account',
              _navigateToAccountPage,
            ),
            _buildMenuItem(
              context,
              Icons.description,
              'Documents',
              _navigateToDocumentPage,
            ),
            _buildMenuItem(
              context,
              Icons.directions_car,
              'My Rides',
              _navigateToRidesPage,
            ),
            _buildMenuItem(
              context,
              Icons.attach_money,
              'Subscription',
              _navigateToSubscriptionPage,
            ),
            _buildMenuItem(
              context,
              Icons.call,
              'SOS',
              _openDialer,
            ),
            _buildMenuItem(
              context,
              Icons.logout,
              'Logout',
              _logout,
              trailing: Icon(null), // Hide the default arrow icon for logout
            ),
          ],
        ),
      ),
    );
  }

  // Function to navigate to the appropriate account page based on userType
  void _navigateToAccountPage() {
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
    }
    else if (_userType == 'ADMIN') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AgentAccountPage()),
      );
    }
     else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid user type')),
      );
    }
  }

  void _navigateToSubscriptionPage(){
    Navigator.push(context,
      MaterialPageRoute(builder: (context) => SubscriptionPage()),
    );
  }

  void _openDialer() async {
  const phoneNumber = 'tel:9599232228';
  if (await canLaunchUrl(Uri.parse(phoneNumber))) {
    await launchUrl(Uri.parse(phoneNumber));
  } else {
    throw 'Could not launch $phoneNumber';
  }
}

  void _navigateToDocumentPage() async {
  final String? userId = await _secureStorage.read(key: 'userId');
  if (userId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadPhotosPage(userId: userId)),
    );
  } else {
    print('User ID not found');
  }
}


  void _navigateToRidesPage(){
    Navigator.push(context,
      MaterialPageRoute(builder: (context) => MyRidesPage()),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Color(0xFFE96E03))
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFE96E03)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,color: Colors.black),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFFE96E03)),
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        onTap: onTap,
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cabproject/screens/permissions_screen.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({Key? key}) : super(key: key);

  @override
  _AccountSetupScreenState createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _cityNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _registerAccount() {
    if (_formKey.currentState!.validate()) {
      // Validate fields locally. No backend logic changes as per instructions.
      // Navigate to the PermissionsScreen after successful validation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF002D4C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set up your Bharat Yaatri account',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF002D4C),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your name helps customers identify you.\nAn email address lets us share trip receipts.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6F6F70),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cityNameController,
                decoration: const InputDecoration(
                  labelText: 'City Name',
                  labelStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Email (Optional)',
                  labelStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: SizedBox(
                  width: 330,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _registerAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002D4C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
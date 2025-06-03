import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int? _selectedPlanIndex;
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _plans = [];
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchSubscriptionPlans();
  }

  Future<void> _fetchSubscriptionPlans() async {
    final url = 'https://api.bharatyaatri.com/api/subscription/getsubscription';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _plans = data.map((plan) {
          List<String> benefitsList = [];

          // Safely parse benefits array
          if (plan["benefits"] is List && plan["benefits"].isNotEmpty) {
            try {
              benefitsList = List<String>.from(json.decode(plan["benefits"][0]));
            } catch (e) {
              print("Error parsing benefits for plan ${plan["_id"]}.");
            }
          }

          return {
            "id": plan["_id"].toString(),
            "title": plan["subscriptionType"],
            "price": "₹${plan["price"]}",
            "amount": double.tryParse(plan["price"])?.toInt() ?? 0,
            "benefits": benefitsList,
            "timePeriod": plan["timePeriod"],
          };
        }).toList();
      });

      // Highlight the user's active subscription plan after fetching plans
      _highlightUserSubscription();
    } else {
      print("Failed to fetch subscription plans: ${response.body}");
    }
  }

  Future<void> _fetchUserData() async {
    final String? userId = await _secureStorage.read(key: 'userId');
    if (userId == null) return;

    final url = 'https://api.bharatyaatri.com/api/user/getuser/$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _userData = json.decode(response.body)[0];
      });

      _highlightUserSubscription();
    } else {
      print("Failed to fetch user data: ${response.body}");
    }
  }

  void _highlightUserSubscription() {
    if (_userData == null || _plans.isEmpty) return;

    final userSubscriptionData = _userData?['suscriptionType'];

    // Safely check if suscriptionType is an object and contains _id
    if (userSubscriptionData == null || userSubscriptionData is! Map) {
      print("User subscriptionType is null or invalid");
      return;
    }

    final String? userSubscriptionId = userSubscriptionData['_id']?.toString();

    if (userSubscriptionId == null) {
      print("User subscription ID is null");
      return;
    }

    // Find the index based on the subscription _id
    final int index = _plans.indexWhere((plan) => plan['id'] == userSubscriptionId);

    if (index != -1) {
      setState(() {
        _selectedPlanIndex = index;
      });
      print("Matched Plan Index: $index");
      print("Plan Title: ${_plans[index]['title']}");
    } else {
      print("No matching subscription plan found for ID: $userSubscriptionId");
    }
  }



  Future<void> _updateSubscriptionStatus(String planTitle, int timePeriod, String planId) async {
    final String? userId = await _secureStorage.read(key: 'userId');
    if (userId == null) return;

    final url = 'https://api.bharatyaatri.com/api/user/updateuser/$userId';
    final body = json.encode({
      'isSubscribed': true,
      'suscriptionType': planId,
      'freeTrailEliglibity': planTitle == "Trial" ? false : _userData!['freeTrailEliglibity'],
    });

    final response = await http.patch(Uri.parse(url), body: body, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      print("Subscription Updated Successfully");
      await _fetchUserData();
    } else {
      print("Failed to update subscription: ${response.body}");
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isTrialEligible = _userData?['freeTrailEliglibity'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE96E03)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
            child: Column(
                    children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_plans.length, (index) {
                    final plan = _plans[index];
                    final bool isSelected = _selectedPlanIndex == index;
                    final bool isTrialPlan = plan['title'] == 'Trial';

                    return Opacity(
                      opacity: isTrialPlan && !isTrialEligible ? 0.5 : 1.0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE96E03) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    plan["title"],
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    plan["price"],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Benefits",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: plan["benefits"].map<Widget>((benefit) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text("• $benefit"),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              if (plan['title'] != 'None')
                                ElevatedButton(
                                  onPressed: (isTrialPlan && !isTrialEligible)
                                      ? null
                                      : () {
                                    _updateSubscriptionStatus(
                                      plan['title'],
                                      plan['timePeriod'],
                                      plan['id'],
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text("Subscribe"),
                                ),

                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
                    ],
                  ),
          ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class CarAlertOverlay extends StatelessWidget {
  final String carModel;
  final String from;
  final String to;
  final String description;

  const CarAlertOverlay({
    Key? key,
    required this.carModel,
    required this.from,
    required this.to,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 50),
          width: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFF5F5EE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/sedan.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              Text(
                carModel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  decoration: TextDecoration.none
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'From: $from',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                          decoration: TextDecoration.none
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To: $to',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                          decoration: TextDecoration.none
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                    decoration: TextDecoration.none
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FlutterOverlayWindow.closeOverlay();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        shadowColor: Colors.red.withOpacity(0.3),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
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
}

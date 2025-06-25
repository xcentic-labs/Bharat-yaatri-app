import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String userName;
  final String userId;
  const ChatScreen({Key? key, required this.userName, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Chat with $userName\n(User ID: $userId)',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 
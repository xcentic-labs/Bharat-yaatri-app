class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? rideId; // Optional: to link messages to specific rides

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.rideId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      rideId: json['rideId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'rideId': rideId,
    };
  }
} 
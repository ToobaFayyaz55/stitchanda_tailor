import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String type; // text, image, etc.
  final DateTime timestamp;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.readBy,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String id) {
    return ChatMessage(
      id: id,
      senderId: json['sender_id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: (json['read_by'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'text': text,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'read_by': readBy,
    };
  }
}


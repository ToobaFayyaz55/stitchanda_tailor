import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final List<String> participants; // user ids
  final String? lastMessage;
  final DateTime lastUpdated;

  Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastUpdated,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String id) {

    return Conversation(
      id: id,
      participants: (json['participants'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      lastMessage: json['last_message'] as String?,
      lastUpdated: (json['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'last_message': lastMessage,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }
}


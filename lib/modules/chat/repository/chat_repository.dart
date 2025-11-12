import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/modules/chat/models/chat_message.dart';
import 'package:stichanda_tailor/modules/chat/models/conversation.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections structure:
  // conversations (doc id) { participants: [uid1, uid2], last_message, last_updated }
  // conversations/{conversationId}/messages/{messageId}

  Future<Conversation> createOrGetConversation(String userA, String userB) async {
    // conversation id deterministic: sorted uids joined
    final List<String> parts = [userA, userB]..sort();
    final convId = parts.join('_');
    final docRef = _firestore.collection('conversations').doc(convId);
    final snap = await docRef.get();
    if (snap.exists) {
      return Conversation.fromJson(snap.data() as Map<String, dynamic>, convId);
    }
    final now = DateTime.now();
    await docRef.set({
      'participants': [userA, userB],
      'last_message': null,
      'last_updated': FieldValue.serverTimestamp(),
    });
    return Conversation(id: convId, participants: [userA, userB], lastMessage: null, lastUpdated: now);
  }

  Stream<List<Conversation>> conversationStream(String uid) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('last_updated', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Conversation.fromJson(d.data(), d.id)).toList());

  }

  Stream<List<ChatMessage>> messageStream(String conversationId, {int limit = 50}) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromJson(d.data(), d.id)).toList());
  }

  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    final messagesRef = _firestore.collection('conversations').doc(conversationId).collection('messages');
    final newDoc = messagesRef.doc();
    await newDoc.set(message.toJson());
    await _firestore.collection('conversations').doc(conversationId).update({
      'last_message': message.type == 'text' ? message.text : '[${message.type}]',
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessageRead(String conversationId, String messageId, String uid) async {
    final msgRef = _firestore.collection('conversations').doc(conversationId).collection('messages').doc(messageId);
    await msgRef.update({
      'read_by': FieldValue.arrayUnion([uid]),
    });
  }
}


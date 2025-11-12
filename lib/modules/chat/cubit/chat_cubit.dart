import 'dart:async';
import 'package:bloc/bloc.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stichanda_tailor/modules/chat/models/chat_message.dart';
import 'package:stichanda_tailor/modules/chat/models/conversation.dart';
import 'package:stichanda_tailor/modules/chat/repository/chat_repository.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<List<Conversation>>? _convSub;
  StreamSubscription<List<ChatMessage>>? _msgSub;

  ChatCubit(this._repo) : super(ChatInitial());

  void loadConversations(String uid) {
    emit(ConversationsLoading());
    _convSub?.cancel();
    _convSub = _repo.conversationStream(uid).listen((list) {


      emit(ConversationsLoaded(list));
    }, onError: (e) {

      emit(ChatError(e.toString()));
    });
  }

  Future<Conversation> startConversation(String me, String other) async {
    final conv = await _repo.createOrGetConversation(me, other);
    return conv;
  }

  void subscribeMessages(String conversationId) {
    emit(MessagesLoading());
    _msgSub?.cancel();
    _msgSub = _repo.messageStream(conversationId).listen((messages) {
      emit(MessagesLoaded(messages));
    }, onError: (e) {
      emit(ChatError(e.toString()));
    });
  }

  Future<void> sendMessage(String conversationId, ChatMessage message) async {
    try {
      await _repo.sendMessage(conversationId, message);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> markRead(String conversationId, String messageId, String uid) async {
    try {
      await _repo.markMessageRead(conversationId, messageId, uid);
    } catch (e) {
      // ignore
    }
  }

  Future<void> loadPeer(String otherUid) async {
    try {
      final user = await _getUserById(otherUid);
      if (user != null) {
        emit(ChatPeerLoaded(uid: otherUid, name: user['name'] ?? 'User', imageUrl: user['imageUrl']));
      }
    } catch (e) {
      // ignore soft failures
    }
  }

  Future<Map<String,String?>?> _getUserById(String uid) async {
    // driver
    final d = await _firestore.collection('driver').doc(uid).get();
    if (d.exists) {
      final data = d.data() as Map<String, dynamic>;
      final p = (data['profile_image_path']?.toString() ?? '').trim();
      return {
        'name': (data['name']?.toString()),
        'imageUrl': p.isNotEmpty ? p : null,
      };
    }
    // customer
    final c = await _firestore.collection('customer').doc(uid).get();
    if (c.exists) {
      final data = c.data() as Map<String, dynamic>;
      final p = (data['profile_image_path']?.toString() ?? '').trim();
      return {
        'name': (data['name']?.toString() ),
        'imageUrl': p.isNotEmpty ? p : null,
      };
    }
    // tailor
    final t = await _firestore.collection('tailor').doc(uid).get();
    if (t.exists) {
      final data = t.data() as Map<String, dynamic>;
      final p = (data['profile_image_path']?.toString() ?? '').trim();
      return {
        'name': (data['name']?.toString()),
        'imageUrl': p.isNotEmpty ? p : null,
      };
    }
    return null;
  }

  @override
  Future<void> close() {
    _convSub?.cancel();
    _msgSub?.cancel();
    return super.close();
  }
}

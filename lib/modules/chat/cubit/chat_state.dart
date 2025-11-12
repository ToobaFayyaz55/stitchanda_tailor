part of 'chat_cubit.dart';

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ConversationsLoading extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  ConversationsLoaded(this.conversations);
}

class MessagesLoading extends ChatState {}

class MessagesLoaded extends ChatState {
  final List<ChatMessage> messages;
  MessagesLoaded(this.messages);
}

class ChatPeerLoaded extends ChatState {
  final String uid;
  final String name;
  final String? imageUrl;
  ChatPeerLoaded({required this.uid, required this.name, this.imageUrl});
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

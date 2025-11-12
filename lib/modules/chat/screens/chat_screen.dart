import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stichanda_tailor/modules/chat/cubit/chat_cubit.dart';
import 'package:stichanda_tailor/modules/chat/models/chat_message.dart';
import 'package:stichanda_tailor/modules/chat/models/conversation.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final String otherUid;
  String? otherName;
  String? otherImage;

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().subscribeMessages(widget.conversation.id);
    otherUid = widget.conversation.participants.firstWhere((e) => e != uid, orElse: () => '');
    if (otherUid.isNotEmpty) {
      context.read<ChatCubit>().loadPeer(otherUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: (otherImage != null && otherImage!.isNotEmpty) ? NetworkImage(otherImage!) : null,
              child: (otherImage == null || otherImage!.isEmpty) ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                otherName ?? 'Chat',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: BlocListener<ChatCubit, ChatState>(
        listenWhen: (p, n) => n is ChatPeerLoaded && n.uid == otherUid,
        listener: (context, state) {
          if (state is ChatPeerLoaded) {
            setState(() {
              otherName = state.name;
              otherImage = state.imageUrl;
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                buildWhen: (previous, current) =>
                    current is MessagesLoading ||
                    current is MessagesLoaded ||
                    current is ChatError,
                builder: (context, state) {
                  if (state is MessagesLoading) return Center(child: CircularProgressIndicator());
                  if (state is MessagesLoaded) {
                    final messages = state.messages;
                    if (messages.isEmpty) return Center(child: Text('No messages yet'));
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final ChatMessage msg = messages[index];
                        final isMe = msg.senderId == uid;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blueAccent : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                          ),
                        );
                      },
                    );
                  }
                  if (state is ChatError) return Center(child: Text('Error: ${state.message}'));
                  // Preserve current list when other unrelated chat states are emitted
                  return SizedBox.shrink();
                },
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(hintText: 'Type a message'),
                      ),
                    ),
                  ),
                  IconButton(
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        final msg = ChatMessage(
                          id: '',
                          senderId: uid,
                          text: text,
                          type: 'text',
                          timestamp: DateTime.now(),
                          readBy: [],
                        );
                        await context.read<ChatCubit>().sendMessage(widget.conversation.id, msg);
                        _controller.clear();
                      },
                      icon: Icon(Icons.send)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

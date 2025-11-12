import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stichanda_tailor/modules/chat/cubit/chat_cubit.dart';
import 'package:stichanda_tailor/modules/chat/models/conversation.dart';
import 'chat_screen.dart';
import 'package:stichanda_tailor/controller/auth_cubit.dart';
import 'package:stichanda_tailor/theme/theme.dart';
import 'package:stichanda_tailor/view/base/custom_bottom_nav_bar.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  String? _currentUid;
  bool _initialLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.watch<AuthCubit>().state;
    if (authState is AuthSuccess) {
      final uid = authState.tailor.tailor_id;
      if (uid.isNotEmpty && uid != _currentUid) {
        _currentUid = uid;
        context.read<ChatCubit>().loadConversations(uid);
        _initialLoaded = true;
      }
    }
  }

  Future<void> _refresh() async {
    if (_currentUid != null) {
      context.read<ChatCubit>().loadConversations(_currentUid!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final bool loggedIn = authState is AuthSuccess;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations', style: TextStyle(color: AppColors.textBlack)),
        backgroundColor: AppColors.caramel,
        automaticallyImplyLeading: false,
      ),
      body: !loggedIn
          ? const Center(child: Text('Please login to view conversations'))
          : BlocBuilder<ChatCubit, ChatState>(
              buildWhen: (previous, current) =>
                  current is ConversationsLoading ||
                  current is ConversationsLoaded ||
                  current is ChatError,
              builder: (context, state) {
                if ((state is ConversationsLoading) && !_initialLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatError) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Failed to load conversations',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final list = state is ConversationsLoaded ? state.conversations : <Conversation>[];
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 72, color: AppColors.iconGrey),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No conversations yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'When customers contact you, chats will appear here.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conv = list[index];
                      final other = conv.participants.firstWhere((e) => e != _currentUid, orElse: () => '');
                      return _ConversationTile(conversation: conv, otherUid: other);
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: const CustomBottomNavBar(activeIndex: 0),
    );
  }
}

class _ConversationTile extends StatefulWidget {
  final Conversation conversation;
  final String otherUid;
  const _ConversationTile({required this.conversation, required this.otherUid});

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  String? name;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadPeer(widget.otherUid);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (p, n) => n is ChatPeerLoaded && n.uid == widget.otherUid,
      listener: (context, state) {
        if (state is ChatPeerLoaded) {
          setState(() {
            name = state.name;
            imageUrl = state.imageUrl;
          });
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(name ?? 'User'),
        subtitle: Text(widget.conversation.lastMessage ?? ''),
        trailing: Text(_formatTime(widget.conversation.lastUpdated), style: Theme.of(context).textTheme.bodySmall),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(conversation: widget.conversation)));
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}

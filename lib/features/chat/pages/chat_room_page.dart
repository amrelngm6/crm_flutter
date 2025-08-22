import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/models/chat.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatRoom room;

  const ChatRoomPage({super.key, required this.room});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.setCurrentRoom(widget.room);

      // Scroll to bottom when messages are loaded
      _scrollToBottom();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more messages when scrolling to top
    if (_scrollController.position.pixels <= 100) {
      context.read<ChatProvider>().loadNextMessages();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B4D3E),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          _buildRoomAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${widget.room.participantsCount} participants',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (widget.room.hasVideoMeeting)
          IconButton(
            onPressed: () {
              // TODO: Implement video call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video call feature coming soon'),
                  backgroundColor: Color(0xFF52D681),
                ),
              );
            },
            icon: const Icon(Icons.videocam, color: Colors.white),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'participants':
                _showParticipants();
                break;
              case 'info':
                _showRoomInfo();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'participants',
              child: Row(
                children: [
                  Icon(Icons.people, size: 20),
                  SizedBox(width: 12),
                  Text('Participants'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 12),
                  Text('Room Info'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF52D681),
            Color(0xFF1B4D3E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          _getRoomInitials(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getRoomInitials() {
    final words = widget.room.name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words[0].isNotEmpty) {
      return words[0].substring(0, 2).toUpperCase();
    }
    return 'CR';
  }

  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingMessages && provider.messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
            ),
          );
        }

        if (provider.messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF52D681).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 40,
                    color: Color(0xFF52D681),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4D3E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation by sending a message',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount:
              provider.messages.length + (provider.hasMoreMessages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0 && provider.hasMoreMessages) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: provider.isLoadingMessages
                    ? const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF52D681)),
                      )
                    : TextButton(
                        onPressed: () => provider.loadNextMessages(),
                        child: const Text(
                          'Load more messages',
                          style: TextStyle(color: Color(0xFF52D681)),
                        ),
                      ),
              );
            }

            final messageIndex = provider.hasMoreMessages ? index - 1 : index;
            final message = provider.messages[messageIndex];
            final isLastMessage = messageIndex == provider.messages.length - 1;

            return MessageBubble(
              message: message,
              isLastMessage: isLastMessage,
              showSender: _shouldShowSender(messageIndex, provider.messages),
            );
          },
        );
      },
    );
  }

  bool _shouldShowSender(int index, List<Message> messages) {
    if (index == 0) return true;

    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    return currentMessage.userId != previousMessage.userId ||
        currentMessage.userType != previousMessage.userType;
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: MessageInput(
        controller: _messageController,
        onSend: (message) => _sendMessage(message),
        isLoading: context.watch<ChatProvider>().isSendingMessage,
      ),
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final provider = context.read<ChatProvider>();
    final success = await provider.sendMessage(widget.room.id, message);

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _showParticipants() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Participants',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: widget.room.participants.length,
                    itemBuilder: (context, index) {
                      final participant = widget.room.participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF52D681),
                          child: Text(
                            participant.user?.initials ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          participant.user?.name ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(participant.user?.email ?? ''),
                        trailing: participant.isModerator
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF52D681)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Moderator',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF52D681),
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Room Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4D3E),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', widget.room.name),
            _buildInfoRow('Participants', '${widget.room.participantsCount}'),
            _buildInfoRow('Video Meeting',
                widget.room.hasVideoMeeting ? 'Enabled' : 'Disabled'),
            _buildInfoRow('Created', _formatDate(widget.room.createdAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF52D681)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B4D3E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

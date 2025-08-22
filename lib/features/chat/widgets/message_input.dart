import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isLoading;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSendButton);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSendButton);
    super.dispose();
  }

  void _updateSendButton() {
    final canSend =
        widget.controller.text.trim().isNotEmpty && !widget.isLoading;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  void _handleSend() {
    if (_canSend) {
      widget.onSend(widget.controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF52D681).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _handleAttachment,
                  icon: const Icon(
                    Icons.attach_file,
                    color: Color(0xFF52D681),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                IconButton(
                  onPressed: _handleEmoji,
                  icon: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Color(0xFF52D681),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildSendButton(),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _canSend
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF52D681),
                  Color(0xFF1B4D3E),
                ],
              )
            : null,
        color: _canSend ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _canSend ? _handleSend : null,
          child: Container(
            width: 48,
            height: 48,
            child: widget.isLoading
                ? Container(
                    padding: const EdgeInsets.all(12),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color: _canSend ? Colors.white : Colors.grey[500],
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  void _handleAttachment() {
    // TODO: Implement file attachment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment feature coming soon'),
        backgroundColor: Color(0xFF52D681),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleEmoji() {
    // TODO: Implement emoji picker functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emoji picker feature coming soon'),
        backgroundColor: Color(0xFF52D681),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../config/Session.dart';
import '../service/ConversationService.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String username;
  final String? avatarUrl;
  final int otherUserId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.username,
    required this.otherUserId,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final msgs = await ConversationService.getMessages(widget.conversationId);
      final sorted = msgs.reversed.toList();
      setState(() {
        _messages = sorted;
        _isLoading = false;
      });
      if (mounted) {
        await ConversationService.markAsRead(widget.conversationId);
      }
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pollMessages() async {
    try {
      final msgs = await ConversationService.getMessages(widget.conversationId);
      if (!mounted) return;
      final sorted = msgs.reversed.toList();
      setState(() => _messages = sorted);
      await ConversationService.markAsRead(widget.conversationId);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.hasContentDimensions) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      await ConversationService.sendMessage(
          recipientId: widget.otherUserId, content: text);
      await _pollMessages();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  void _showFullImage() {
    if (widget.avatarUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: InteractiveViewer(
              child: Image.network(
                widget.avatarUrl!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = Session().userId;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgAppBar,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 30,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showFullImage,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.gold,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? Text(
                        widget.username.isNotEmpty
                            ? widget.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: AppColors.textOnGold,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                widget.username,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Messages List ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet. Say hi! 👋',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final senderId =
                              msg['sender']?['id'] ?? msg['senderId'];
                          final isMine = senderId == myId;
                          final content = msg['content'] ?? msg['text'] ?? '';
                          final time =
                              _formatTime(msg['createdAt'] ?? msg['sentAt']);
                          final isRead = msg['read'] ?? false;

                          return _ChatBubble(
                            content: content,
                            time: time,
                            isMine: isMine,
                            isRead: isRead,
                          );
                        },
                      ),
          ),

          // ── Input Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: AppColors.bgAppBar,
            child: Row(
              children: [
                // Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send,
                        color: AppColors.textOnGold, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String content;
  final String time;
  final bool isMine;
  final bool isRead;

  const _ChatBubble({
    required this.content,
    required this.time,
    required this.isMine,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          left: isMine ? 60 : 0,
          right: isMine ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.gold.withValues(alpha: 0.16)
              : AppColors.bgSurface,
          border: Border.all(
            color: isMine
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 0),
            bottomRight: Radius.circular(isMine ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
                if (isMine) ...[
                  const SizedBox(width: 3),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? AppColors.gold : AppColors.textTertiary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

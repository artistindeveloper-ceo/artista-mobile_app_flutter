import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/Session.dart';
import '../../service/ConversationService.dart';
import '../../service/PresenceService.dart';
import '../../theme/app_theme.dart';
import '../profile/ProfileScreen.dart';

class ChatScreen extends StatefulWidget {
  // Nullable ab: naya chat start hone par conversation abhi bani hi nahi hai.
  // Pehla message bhejte hi backend lazily conversation create karega aur
  // response me asli conversationId milegi.
  final int? conversationId;
  final String username; // display name (dikhane ke liye)
  final String? profileUsername; // asli @username (profile lookup ke liye)
  final String? avatarUrl;
  final int otherUserId;

  const ChatScreen({
    super.key,
    this.conversationId,
    required this.username,
    required this.otherUserId,
    this.profileUsername,
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

  // conversationId ab state me rakhte hain kyunki pehle message ke baad
  // widget.conversationId se alag ho sakti hai (lazily create hone ke baad).
  int? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;

    if (_conversationId != null) {
      // Existing conversation: normal load + polling.
      _loadMessages();
      _startPolling();
    } else {
      // Naya chat: koi API call nahi, seedha empty state dikhao.
      _isLoading = false;
    }

    // Presence: REST se turant status laao (WebSocket event abhi tak nahi
    // aaya ho sakta), aur live updates ke liye listener lagao.
    PresenceService.instance.fetchInitialStatus(widget.otherUserId);
    PresenceService.instance.addListener(_onPresenceChanged);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    PresenceService.instance.removeListener(_onPresenceChanged);
    super.dispose();
  }

  void _onPresenceChanged() {
    if (mounted) setState(() {}); // avatar dot repaint
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollMessages();
    });
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;
    setState(() => _isLoading = true);
    try {
      final msgs = await ConversationService.getMessages(_conversationId!);
      final sorted = msgs.reversed.toList();
      setState(() {
        _messages = sorted;
        _isLoading = false;
      });
      if (mounted) {
        await ConversationService.markAsRead(_conversationId!);
      }
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pollMessages() async {
    if (_conversationId == null) return;
    try {
      final msgs = await ConversationService.getMessages(_conversationId!);
      if (!mounted) return;
      final sorted = msgs.reversed.toList();
      setState(() => _messages = sorted);
      await ConversationService.markAsRead(_conversationId!);
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

  // Backend response se conversation id nikaalne ki koshish karta hai.
  // Response ka exact shape ConversationService.sendMessage() par depend
  // karta hai — dono common key names (`id`, `conversationId`) try kiye hain.
  int? _extractConversationId(dynamic response) {
    if (response == null) return null;
    if (response is int) return response;
    if (response is Map) {
      final raw = response['conversationId'] ??
          response['conversation_id'] ??
          response['id'];
      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw);
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    try {
      final response = await ConversationService.sendMessage(
          recipientId: widget.otherUserId, content: text);
      if (_conversationId == null) {
        final newId = _extractConversationId(response);
        if (newId != null) {
          setState(() => _conversationId = newId);
          _startPolling();
        }
      }

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

  // ⬅️ NAYA METHOD: tap karne par profile screen khulegi
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(username: widget.profileUsername ?? widget.username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = Session().userId;
    final isOnline = PresenceService.instance.isOnline(widget.otherUserId);

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
          onTap: _openProfile, // ⬅️ ab profile khulegi
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
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
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.bgAppBar, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.username,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  if (isOnline)
                    const Text(
                      'Online',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                ],
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

import 'package:flutter/material.dart';

import '../../../../config/ApiConfig.dart';
import '../../../../service/CommentService.dart';
import '../../../../theme/app_theme.dart';

class CommentsSheet extends StatefulWidget {
  final int postId;
  final VoidCallback? onCommentAdded;

  const CommentsSheet({super.key, required this.postId, this.onCommentAdded});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await CommentService.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    try {
      await CommentService.addComment(widget.postId, text);
      _loadComments();
      widget.onCommentAdded?.call();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(color: AppColors.divider),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : _comments.isEmpty
                    ? const Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) {
                          final c = _comments[i];
                          final author = c['author'] as Map<String, dynamic>?;
                          final username =
                              author?['username'] ?? c['username'] ?? 'unknown';
                          final avatarPath =
                              author?['profilePhotoUrl'] ?? c['userAvatarUrl'];
                          final avatarUrl = (avatarPath != null &&
                                  avatarPath.toString().isNotEmpty)
                              ? (avatarPath.toString().startsWith('http')
                                  ? avatarPath.toString()
                                  : '${ApiConfig.baseUrl}${avatarPath.toString().startsWith('/') ? '' : '/'}$avatarPath')
                              : null;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.bgSurfaceElevated,
                              backgroundImage: avatarUrl != null
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: avatarUrl == null
                                  ? Text(
                                      username.isNotEmpty
                                          ? username[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary),
                                    )
                                  : null,
                            ),
                            title: Text(username,
                                style: const TextStyle(
                                    color: AppColors.textPrimary)),
                            subtitle: Text(
                              c['content'] ?? c['text'] ?? '',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          );
                        },
                      ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.gold),
                  onPressed: _postComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

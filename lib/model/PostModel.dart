import '../config/ApiConfig.dart';

class PostModel {
  final int id;
  final String username;
  final String? userAvatarUrl;
  final String? imageUrl;
  final String? caption;
  final String? timeAgo;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final int authorId;
  PostModel({
    required this.id,
    required this.username,
    this.userAvatarUrl,
    this.imageUrl,
    this.caption,
    this.timeAgo,
    required this.likesCount,
    required this.commentsCount,
    required this.likedByMe,
    required this.authorId,
  });

  // ── Relative path ko full URL banata hai ──
  static String? _buildUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/$clean';
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return PostModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      authorId: author?['id'] is int
          ? author!['id']
          : int.tryParse('${author?['id']}') ?? 0,
      username: author?['username'] ?? json['username'] ?? 'unknown',
      userAvatarUrl: _buildUrl(
        author?['profilePhotoUrl'] ?? json['userAvatarUrl'],
      ),
      imageUrl: _buildUrl(
        json['mediaUrl'] ?? json['imageUrl'] ?? json['image'],
      ),
      caption: json['caption'] ?? json['content'],
      timeAgo: json['timeAgo'] ?? json['createdAt'],
      likesCount: json['likeCount'] ?? json['likesCount'] ?? json['likes'] ?? 0,
      commentsCount: json['commentCount'] ??
          json['commentsCount'] ??
          json['comments'] ??
          0,
      likedByMe:
          json['likedByViewer'] ?? json['likedByMe'] ?? json['liked'] ?? false,
    );
  }
}

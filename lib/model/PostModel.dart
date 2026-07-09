import '../config/ApiConfig.dart';

class PostModel {
  final int id;
  final String username;
  final String? userAvatarUrl;
  final String? imageUrl;
  final bool isVideo;
  final String? caption;
  final String? timeAgo;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;
  final int authorId;
  final int viewsCount;

  PostModel({
    required this.id,
    required this.username,
    this.userAvatarUrl,
    this.imageUrl,
    this.isVideo = false, // ← NEW
    this.caption,
    this.timeAgo,
    this.viewsCount = 0,
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

  // ── URL extension se video detect karta hai (backend fallback) ──
  static bool _detectIsVideo(String? mediaType, String? url) {
    if (mediaType != null) {
      return mediaType.toUpperCase() == 'VIDEO';
    }
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v');
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final rawMediaUrl = json['mediaUrl'] ?? json['imageUrl'] ?? json['image'];

    return PostModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      authorId: author?['id'] is int
          ? author!['id']
          : int.tryParse('${author?['id']}') ?? 0,
      username: author?['username'] ?? json['username'] ?? 'unknown',
      userAvatarUrl: _buildUrl(
        author?['profilePhotoUrl'] ?? json['userAvatarUrl'],
      ),
      imageUrl: _buildUrl(rawMediaUrl),
      isVideo: _detectIsVideo(
        json['mediaType'] as String?,
        rawMediaUrl as String?,
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
      viewsCount: json['viewsCount'] ?? json['views'] ?? json['viewCount'] ?? 0,
    );
  }
}

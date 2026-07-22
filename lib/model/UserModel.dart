import '../config/ApiConfig.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? createdAt;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? username;
  final String? bio;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final bool isFollowing;
  final bool isPrivate;
  final bool hasPendingFollowRequest;
  final String? profilePhotoUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.createdAt,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.username,
    this.bio,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.isFollowing = false,
    this.isPrivate = false,
    this.hasPendingFollowRequest = false,
    this.profilePhotoUrl,
  });

  UserModel copyWith({
    bool? isFollowing,
    String? profilePhotoUrl,
    bool? isPrivate,
    bool? hasPendingFollowRequest,
  }) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      createdAt: createdAt,
      avatarUrl: avatarUrl,
      coverPhotoUrl: coverPhotoUrl,
      username: username,
      bio: bio,
      followersCount: followersCount,
      followingCount: followingCount,
      postsCount: postsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isPrivate: isPrivate ?? this.isPrivate,
      hasPendingFollowRequest:
          hasPendingFollowRequest ?? this.hasPendingFollowRequest,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  static String? _buildUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/$clean';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['displayName'] ?? json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      createdAt: json['createdAt'],
      avatarUrl: _buildUrl(
        json['profilePhotoUrl'] ??
            json['avatarUrl'] ??
            json['profileImage'] ??
            json['profilePhoto'],
      ),
      coverPhotoUrl: _buildUrl(
        json['coverPhotoUrl'] ?? json['coverPhoto'],
      ),
      username: json['username'],
      bio: json['bio'],
      followersCount: json['followerCount'] ??
          json['followersCount'] ??
          json['followers'] ??
          0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postCount'] ?? json['postsCount'] ?? json['posts'] ?? 0,
      isFollowing: json['following'] ??
          json['isFollowedByViewer'] ??
          json['isFollowing'] ??
          false,
      isPrivate: json['isPrivate'] ?? false,
      hasPendingFollowRequest: json['hasPendingFollowRequest'] ?? false,
      profilePhotoUrl: json['profilePhotoUrl'] ??
          json['avatarUrl'] ??
          json['profile_photo_url'],
    );
  }
}

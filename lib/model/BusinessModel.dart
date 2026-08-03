class BusinessModel {
  final int id;
  final String businessType;
  final String name;
  final String? description;
  final int? cityId;
  final String? cityName;
  final String? countryName; // NAYA
  final String? contactEmail;
  final String? contactPhone;
  final String? profilePhotoUrl;
  final String? coverPhotoUrl;
  final bool isVerified;
  final double? avgRating;
  final int? ratingCount;
  final Map<String, dynamic>? details;
  final int followerCount;
  final int followingCount;
  final bool isFollowedByViewer;

  BusinessModel({
    required this.id,
    required this.businessType,
    required this.name,
    this.description,
    this.cityId,
    this.cityName,
    this.countryName, // NAYA
    this.contactEmail,
    this.contactPhone,
    this.profilePhotoUrl,
    this.coverPhotoUrl,
    this.isVerified = false,
    this.avgRating,
    this.ratingCount,
    this.details,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowedByViewer = false,
  });

  BusinessModel copyWith({
    int? followerCount,
    int? followingCount,
    bool? isFollowedByViewer,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
  }) {
    return BusinessModel(
      id: id,
      businessType: businessType,
      name: name,
      description: description,
      cityId: cityId,
      cityName: cityName,
      countryName: countryName,
      // NAYA
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      isVerified: isVerified,
      avgRating: avgRating,
      ratingCount: ratingCount,
      details: details,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowedByViewer: isFollowedByViewer ?? this.isFollowedByViewer,
    );
  }

  // ✅ FIXED: backend Jackson boolean serialization "is" prefix hata deta hai,
  // isliye JSON me keys "verified" aur "followedByViewer" aati hain,
  // "isVerified"/"isFollowedByViewer" nahi.
  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      businessType: json['businessType'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      cityId: json['cityId'],
      cityName: json['cityName'],
      countryName: json['countryName'],
      // NAYA
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      profilePhotoUrl: json['profilePhotoUrl'],
      coverPhotoUrl: json['coverPhotoUrl'],
      isVerified: json['verified'] ?? false,
      // ← FIX
      avgRating: json['avgRating'] == null
          ? null
          : (json['avgRating'] as num).toDouble(),
      ratingCount: json['ratingCount'],
      details: json['details'] is Map<String, dynamic> ? json['details'] : null,
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isFollowedByViewer: json['followedByViewer'] ?? false, // ← FIX
    );
  }
}

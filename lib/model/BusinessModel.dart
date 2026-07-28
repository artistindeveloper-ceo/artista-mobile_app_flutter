class BusinessModel {
  final int id;
  final String businessType; // SHOP, ACADEMY, SCHOOL, INSTITUTE
  final String name;
  final String? description;
  final String? cityName;
  final String? contactEmail;
  final String? contactPhone;
  final String? coverPhotoUrl;
  final bool isVerified;
  final double? avgRating;
  final int? ratingCount;
  final Map<String, dynamic>? details;
  final int followerCount;
  final bool isFollowedByViewer;

  BusinessModel({
    required this.id,
    required this.businessType,
    required this.name,
    this.description,
    this.cityName,
    this.contactEmail,
    this.contactPhone,
    this.coverPhotoUrl,
    this.isVerified = false,
    this.avgRating,
    this.ratingCount,
    this.details,
    this.followerCount = 0,
    this.isFollowedByViewer = false,
  });

  BusinessModel copyWith({
    int? followerCount,
    bool? isFollowedByViewer,
  }) {
    return BusinessModel(
      id: id,
      businessType: businessType,
      name: name,
      description: description,
      cityName: cityName,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      coverPhotoUrl: coverPhotoUrl,
      isVerified: isVerified,
      avgRating: avgRating,
      ratingCount: ratingCount,
      details: details,
      followerCount: followerCount ?? this.followerCount,
      isFollowedByViewer: isFollowedByViewer ?? this.isFollowedByViewer,
    );
  }

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      businessType: json['businessType'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      cityName: json['cityName'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      coverPhotoUrl: json['coverPhotoUrl'],
      isVerified: json['isVerified'] ?? false,
      avgRating: json['avgRating'] == null ? null : (json['avgRating'] as num)
          .toDouble(),
      ratingCount: json['ratingCount'],
      details: json['details'] is Map<String, dynamic> ? json['details'] : null,
      followerCount: json['followerCount'] ?? 0,
      isFollowedByViewer: json['isFollowedByViewer'] ?? false,
    );
  }
}
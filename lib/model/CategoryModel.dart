// lib/model/CategoryModel.dart
//
// CategoryController ke /profile-categories aur /business-categories
// dono endpoints yahi shape return karte hain.

class CategoryModel {
  final int id;
  final String
      code; // MUSICIAN, SHOP, etc. — register() call me isko hi bhejna hai
  final String displayName; // dropdown me dikhane wala naam
  final String? description;
  final String? iconUrl;

  CategoryModel({
    required this.id,
    required this.code,
    required this.displayName,
    this.description,
    this.iconUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      code: json['code'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
    );
  }
}

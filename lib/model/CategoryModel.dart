class CategoryModel {
  final int id;
  final String name;
  final String? description;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
    );
  }
}
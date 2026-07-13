class InstrumentTypeModel {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final int categoryId;

  InstrumentTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.categoryId,
  });

  factory InstrumentTypeModel.fromJson(Map<String, dynamic> json) {
    return InstrumentTypeModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      categoryId: json['categoryId'],
    );
  }
}
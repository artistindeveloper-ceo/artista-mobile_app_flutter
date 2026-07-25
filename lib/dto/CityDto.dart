class CityDto {
  final int id;
  final String name;
  final int stateId;
  final String stateName;
  final int countryId;
  final String countryName;

  CityDto({
    required this.id,
    required this.name,
    required this.stateId,
    required this.stateName,
    required this.countryId,
    required this.countryName,
  });

  factory CityDto.fromJson(Map<String, dynamic> json) {
    return CityDto(
      id: json['id'] as int,
      name: json['name'] as String,
      stateId: json['stateId'] as int? ?? 0,
      stateName: json['stateName'] as String? ?? '',
      countryId: json['countryId'] as int? ?? 0,
      countryName: json['countryName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'stateId': stateId,
      'stateName': stateName,
      'countryId': countryId,
      'countryName': countryName,
    };
  }

  /// Dropdown/search field me dikhane wala text
  String get displayLabel => '$name, $stateName';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CityDto && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

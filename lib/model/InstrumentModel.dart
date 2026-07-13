/// Mirrors backend InstrumentResponseDTO.BrandDTO
class BrandDTO {
  final int id;
  final String name;
  final String? logoUrl;
  final String? country;

  BrandDTO({required this.id, required this.name, this.logoUrl, this.country});

  factory BrandDTO.fromJson(Map<String, dynamic> json) => BrandDTO(
    id: json['id'],
    name: json['name'] ?? '',
    logoUrl: json['logoUrl'],
    country: json['country'],
  );
}

/// Mirrors backend InstrumentResponseDTO.InstrumentTypeDTO (e.g. "Octapad")
class InstrumentTypeDTO {
  final int id;
  final String name;
  final String? icon;

  InstrumentTypeDTO({required this.id, required this.name, this.icon});

  factory InstrumentTypeDTO.fromJson(Map<String, dynamic> json) =>
      InstrumentTypeDTO(
        id: json['id'],
        name: json['name'] ?? '',
        icon: json['icon'],
      );
}

/// Mirrors backend InstrumentResponseDTO.CategoryDTO (e.g. "Percussion")
class CategoryDTO {
  final int id;
  final String name;
  final String? icon;

  CategoryDTO({required this.id, required this.name, this.icon});

  factory CategoryDTO.fromJson(Map<String, dynamic> json) => CategoryDTO(
    id: json['id'],
    name: json['name'] ?? '',
    icon: json['icon'],
  );
}

/// Mirrors backend InstrumentResponseDTO.MediaDTO
class MediaDTO {
  final int id;
  final String url;
  final String? mediaType;
  final bool isPrimary;
  final String? caption;

  MediaDTO({
    required this.id,
    required this.url,
    this.mediaType,
    this.isPrimary = false,
    this.caption,
  });

  factory MediaDTO.fromJson(Map<String, dynamic> json) => MediaDTO(
    id: json['id'],
    url: json['url'] ?? '',
    mediaType: json['mediaType'],
    isPrimary: json['isPrimary'] ?? false,
    caption: json['caption'],
  );
}

/// Mirrors backend InstrumentResponseDTO.UserInstrumentDTO — present only
/// when this instrument belongs to a user (isUserInstrument == true)
class UserInstrumentDetailsDTO {
  final int id;
  final bool isPrimary;
  final String? proficiencyLevel;
  final double? yearsExperience;
  final String? purchaseDate;

  UserInstrumentDetailsDTO({
    required this.id,
    required this.isPrimary,
    this.proficiencyLevel,
    this.yearsExperience,
    this.purchaseDate,
  });

  factory UserInstrumentDetailsDTO.fromJson(Map<String, dynamic> json) =>
      UserInstrumentDetailsDTO(
        id: json['id'] ?? 0,
        isPrimary: json['isPrimary'] ?? false,
        proficiencyLevel: json['proficiencyLevel'],
        yearsExperience: (json['yearsExperience'] as num?)?.toDouble(),
        purchaseDate: json['purchaseDate'],
      );
}

/// Mirrors backend InstrumentResponseDTO.
/// This represents ONE specific instrument model (e.g. Roland SPD-20),
/// with brand + type + category nested inside. When fetched via
/// GET /api/instruments/user/{userId}, [isUserInstrument] is true and
/// [userInstrumentDetails] tells you whether it's the user's primary or
/// secondary instrument.
class InstrumentModel {
  final int id;
  final String model; // e.g. "SPD-20"
  final int? modelYear;
  final String? description;
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? price;
  final String? currency;
  final BrandDTO? brand;
  final InstrumentTypeDTO? instrumentType;
  final CategoryDTO? category;
  final List<MediaDTO> media;
  final double? avgRating;
  final int? totalReviews;
  final bool isUserInstrument;
  final UserInstrumentDetailsDTO? userInstrumentDetails;

  InstrumentModel({
    required this.id,
    required this.model,
    this.modelYear,
    this.description,
    this.imageUrl,
    this.thumbnailUrl,
    this.price,
    this.currency,
    this.brand,
    this.instrumentType,
    this.category,
    this.media = const [],
    this.avgRating,
    this.totalReviews,
    this.isUserInstrument = false,
    this.userInstrumentDetails,
  });

  factory InstrumentModel.fromJson(Map<String, dynamic> json) {
    return InstrumentModel(
      id: json['id'],
      model: json['model'] ?? '',
      modelYear: json['modelYear'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'],
      brand: json['brand'] != null
          ? BrandDTO.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
      instrumentType: json['instrumentType'] != null
          ? InstrumentTypeDTO.fromJson(
          json['instrumentType'] as Map<String, dynamic>)
          : null,
      category: json['category'] != null
          ? CategoryDTO.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      media: (json['media'] as List<dynamic>? ?? [])
          .map((e) => MediaDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'],
      isUserInstrument: json['isUserInstrument'] ?? false,
      userInstrumentDetails: json['userInstrumentDetails'] != null
          ? UserInstrumentDetailsDTO.fromJson(
          json['userInstrumentDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  /// "Roland SPD-20" style display (brand + model)
  String get displayName {
    final b = brand?.name;
    if (b != null && b.isNotEmpty) return '$b $model';
    return model;
  }

  /// e.g. "Octapad"
  String get typeName => instrumentType?.name ?? category?.name ?? '';

  String? get displayImageUrl => thumbnailUrl ?? imageUrl;

  bool get isPrimary => userInstrumentDetails?.isPrimary ?? false;
}
/// Represents a country with its name and ISO code.
class Country {
  /// Common name of the country (e.g. "Germany").
  final String name;

  /// ISO 3166-1 alpha-2 code (e.g. "DE").
  final String code;

  const Country({required this.name, required this.code});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name']['common'] as String,
      code: json['cca2'] as String,
    );
  }

  /// URL for the flag image from flagcdn.com.
  String get flagUrl => 'https://flagcdn.com/w320/${code.toLowerCase()}.png';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Country(name: $name, code: $code)';
}

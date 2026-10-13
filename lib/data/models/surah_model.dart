class SurahModel {
  final int number;
  final String name; // Arabic Name (e.g. الفاتحة)
  final String englishName; // e.g. Al-Faatiha
  final String englishNameTranslation; // e.g. The Opening
  final int numberOfAyahs;
  final String revelationType; // Meccan or Medinan

  SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'numberOfAyahs': numberOfAyahs,
      'revelationType': revelationType,
    };
  }

  factory SurahModel.fromMap(Map<String, dynamic> map) {
    return SurahModel(
      number: map['number'] as int,
      name: map['name'] as String,
      englishName: map['englishName'] as String,
      englishNameTranslation: map['englishNameTranslation'] as String,
      numberOfAyahs: map['numberOfAyahs'] as int,
      revelationType: map['revelationType'] as String,
    );
  }
}

class AyahModel {
  final int number; // Global Ayah number (1 to 6236)
  final int numberInSurah; // 1 to n
  final int surahNumber;
  final String text; // Arabic
  final String translation; // English/Urdu
  final String audioUrl;
  final int juz;
  final int page;
  bool isBookmarked;

  AyahModel({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.text,
    required this.translation,
    required this.audioUrl,
    required this.juz,
    required this.page,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'numberInSurah': numberInSurah,
      'surahNumber': surahNumber,
      'text': text,
      'translation': translation,
      'audioUrl': audioUrl,
      'juz': juz,
      'page': page,
      'isBookmarked': isBookmarked ? 1 : 0,
    };
  }

  factory AyahModel.fromMap(Map<String, dynamic> map) {
    return AyahModel(
      number: map['number'] as int,
      numberInSurah: map['numberInSurah'] as int,
      surahNumber: map['surahNumber'] as int,
      text: map['text'] as String,
      translation: map['translation'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      juz: map['juz'] as int? ?? 1,
      page: map['page'] as int? ?? 1,
      isBookmarked: (map['isBookmarked'] as int? ?? 0) == 1,
    );
  }
}

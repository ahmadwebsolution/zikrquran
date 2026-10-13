class JuzModel {
  final int number; // 1 to 30
  final String name; // Transliterated name (e.g. Alif-Laam-Meem)
  final String arabicName; // Arabic name (e.g. الم)
  final int startSurahNumber;
  final String startSurahName;
  final int startAyahNumber;
  final int endSurahNumber;
  final String endSurahName;
  final int endAyahNumber;

  const JuzModel({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.startSurahNumber,
    required this.startSurahName,
    required this.startAyahNumber,
    required this.endSurahNumber,
    required this.endSurahName,
    required this.endAyahNumber,
  });
}

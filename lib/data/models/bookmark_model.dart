class BookmarkModel {
  final int? id;
  final int surahNumber;
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final String translation;
  final String createdAt;

  BookmarkModel({
    this.id,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    required this.translation,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'ayahText': ayahText,
      'translation': translation,
      'createdAt': createdAt,
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as int?,
      surahNumber: map['surahNumber'] as int,
      surahName: map['surahName'] as String,
      ayahNumber: map['ayahNumber'] as int,
      ayahText: map['ayahText'] as String,
      translation: map['translation'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}

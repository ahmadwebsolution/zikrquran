import 'package:flutter/material.dart';
import '../data/models/surah_model.dart';
import '../data/models/ayah_model.dart';
import '../data/models/bookmark_model.dart';
import '../data/models/juz_model.dart';
import '../data/repositories/quran_repository.dart';

class QuranViewModel extends ChangeNotifier {
  final QuranRepository _quranRepository;

  List<SurahModel> _surahs = [];
  List<SurahModel> _filteredSurahs = [];
  List<JuzModel> _paras = [];
  List<JuzModel> _filteredParas = [];
  List<AyahModel> _currentAyahs = [];
  List<BookmarkModel> _bookmarks = [];
  Map<String, dynamic>? _lastRead;
  bool _isLoading = false;
  String _searchQuery = '';

  QuranViewModel({QuranRepository? quranRepository})
      : _quranRepository = quranRepository ?? QuranRepository() {
    loadSurahs();
    loadParas();
    loadBookmarks();
    loadLastRead();
  }

  List<SurahModel> get surahs => _filteredSurahs;
  List<JuzModel> get paras => _filteredParas;
  List<AyahModel> get currentAyahs => _currentAyahs;
  List<BookmarkModel> get bookmarks => _bookmarks;
  Map<String, dynamic>? get lastRead => _lastRead;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Fetch all 114 Surahs
  Future<void> loadSurahs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _surahs = await _quranRepository.getSurahs();
      _filteredSurahs = _surahs;
    } catch (e) {
      debugPrint('Error loading surahs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all 30 Paras (Juz)
  void loadParas() {
    _paras = _quranRepository.getParas();
    _filteredParas = _paras;
    notifyListeners();
  }

  // Search Surahs or Paras by Name or Number
  void filterSurahs(String query) {
    _searchQuery = query;
    if (query.trim().isEmpty) {
      _filteredSurahs = _surahs;
      _filteredParas = _paras;
    } else {
      final q = query.toLowerCase().trim();

      String normalize(String text) {
        return text
            .toLowerCase()
            .replaceAll('-', '')
            .replaceAll("'", '')
            .replaceAll('`', '')
            .replaceAll('aa', 'a')
            .replaceAll('ee', 'i')
            .replaceAll('oo', 'u');
      }

      final normQ = normalize(q);

      _filteredSurahs = _surahs.where((s) {
        final normEnglish = normalize(s.englishName);
        return s.englishName.toLowerCase().contains(q) ||
            normEnglish.contains(normQ) ||
            s.name.contains(q) ||
            s.number.toString() == q ||
            s.englishNameTranslation.toLowerCase().contains(q);
      }).toList();

      _filteredParas = _paras.where((p) {
        final normPara = normalize(p.name);
        return p.name.toLowerCase().contains(q) ||
            normPara.contains(normQ) ||
            p.arabicName.contains(q) ||
            p.number.toString() == q ||
            p.startSurahName.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  // Load Ayahs for selected Surah (cached or via API)
  Future<void> loadAyahsForSurah(int surahNumber) async {
    _isLoading = true;
    _currentAyahs = [];
    notifyListeners();

    try {
      _currentAyahs = await _quranRepository.getAyahsForSurah(surahNumber);
    } catch (e) {
      debugPrint('Error loading ayahs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Bookmark
  Future<void> toggleBookmark(AyahModel ayah, String surahName) async {
    if (ayah.isBookmarked) {
      await _quranRepository.removeBookmark(ayah.surahNumber, ayah.numberInSurah);
      ayah.isBookmarked = false;
    } else {
      final bookmark = BookmarkModel(
        surahNumber: ayah.surahNumber,
        surahName: surahName,
        ayahNumber: ayah.numberInSurah,
        ayahText: ayah.text,
        translation: ayah.translation,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _quranRepository.addBookmark(bookmark);
      ayah.isBookmarked = true;
    }
    await loadBookmarks();
    notifyListeners();
  }

  // Remove Bookmark directly by surah & ayah numbers
  Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    await _quranRepository.removeBookmark(surahNumber, ayahNumber);
    for (var a in _currentAyahs) {
      if (a.surahNumber == surahNumber && a.numberInSurah == ayahNumber) {
        a.isBookmarked = false;
      }
    }
    await loadBookmarks();
    notifyListeners();
  }

  // Load Bookmarks
  Future<void> loadBookmarks() async {
    _bookmarks = await _quranRepository.getBookmarks();
    notifyListeners();
  }

  // Save Last Read
  Future<void> saveLastRead(int surahNumber, String surahName, int ayahNumber) async {
    await _quranRepository.saveLastRead(surahNumber, surahName, ayahNumber);
    await loadLastRead();
  }

  // Load Last Read
  Future<void> loadLastRead() async {
    _lastRead = await _quranRepository.getLastRead();
    notifyListeners();
  }
}

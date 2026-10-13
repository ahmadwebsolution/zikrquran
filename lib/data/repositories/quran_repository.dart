import '../datasources/local/db_helper.dart';
import '../datasources/local/quran_data.dart';
import '../datasources/remote/quran_api_service.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import '../models/bookmark_model.dart';
import '../models/juz_model.dart';

class QuranRepository {
  final DatabaseHelper _dbHelper;
  final QuranApiService _apiService;

  QuranRepository({
    DatabaseHelper? dbHelper,
    QuranApiService? apiService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _apiService = apiService ?? QuranApiService();

  Future<List<SurahModel>> getSurahs() {
    return _dbHelper.getAllSurahs();
  }

  List<JuzModel> getParas() {
    return QuranData.allParas;
  }

  Future<List<AyahModel>> getAyahsForSurah(int surahNumber) async {
    // 1. Try local SQLite database first
    final localAyahs = await _dbHelper.getAyahsForSurah(surahNumber);
    if (localAyahs.isNotEmpty) {
      return localAyahs;
    }

    // 2. Fetch from Quran API if not in local database
    final remoteAyahs = await _apiService.fetchAyahsForSurah(surahNumber);
    if (remoteAyahs.isNotEmpty) {
      await _dbHelper.saveAyahs(remoteAyahs);
      return _dbHelper.getAyahsForSurah(surahNumber);
    }

    return [];
  }

  Future<int> addBookmark(BookmarkModel bookmark) {
    return _dbHelper.insertBookmark(bookmark);
  }

  Future<int> removeBookmark(int surahNumber, int ayahNumber) {
    return _dbHelper.deleteBookmark(surahNumber, ayahNumber);
  }

  Future<List<BookmarkModel>> getBookmarks() {
    return _dbHelper.getAllBookmarks();
  }

  Future<void> saveLastRead(int surahNumber, String surahName, int ayahNumber) {
    return _dbHelper.saveLastRead(surahNumber, surahName, ayahNumber);
  }

  Future<Map<String, dynamic>?> getLastRead() {
    return _dbHelper.getLastRead();
  }
}

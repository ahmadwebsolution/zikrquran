import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/surah_model.dart';
import '../../models/ayah_model.dart';
import '../../models/bookmark_model.dart';
import 'quran_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('zikr_quran.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // Ensure all 114 Surahs and pre-seeded Ayahs are populated
    await _ensureDataSeeded(db);
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    // Surahs Table
    await db.execute('''
      CREATE TABLE surahs (
        number INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        englishName TEXT NOT NULL,
        englishNameTranslation TEXT NOT NULL,
        numberOfAyahs INTEGER NOT NULL,
        revelationType TEXT NOT NULL
      )
    ''');

    // Ayahs Table
    await db.execute('''
      CREATE TABLE ayahs (
        number INTEGER PRIMARY KEY,
        numberInSurah INTEGER NOT NULL,
        surahNumber INTEGER NOT NULL,
        text TEXT NOT NULL,
        translation TEXT NOT NULL,
        audioUrl TEXT NOT NULL,
        juz INTEGER NOT NULL,
        page INTEGER NOT NULL,
        FOREIGN KEY (surahNumber) REFERENCES surahs (number)
      )
    ''');

    // Bookmarks Table
    await db.execute('''
      CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surahNumber INTEGER NOT NULL,
        surahName TEXT NOT NULL,
        ayahNumber INTEGER NOT NULL,
        ayahText TEXT NOT NULL,
        translation TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Last Read Table
    await db.execute('''
      CREATE TABLE last_read (
        id INTEGER PRIMARY KEY,
        surahNumber INTEGER NOT NULL,
        surahName TEXT NOT NULL,
        ayahNumber INTEGER NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();

    // Seed all 114 Surahs
    for (var s in QuranData.allSurahs) {
      batch.insert('surahs', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Seed pre-seeded Ayahs
    for (var a in QuranData.preSeededAyahs) {
      batch.insert('ayahs', a.toMap()..remove('isBookmarked'), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _ensureDataSeeded(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM surahs')) ?? 0;
    if (count < 114) {
      await _seedInitialData(db);
    }
  }

  // Save dynamically fetched Ayahs
  Future<void> saveAyahs(List<AyahModel> ayahs) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var a in ayahs) {
      batch.insert('ayahs', a.toMap()..remove('isBookmarked'), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // --- Surah Queries ---
  Future<List<SurahModel>> getAllSurahs() async {
    final db = await instance.database;
    final maps = await db.query('surahs', orderBy: 'number ASC');
    if (maps.length < 114) {
      return QuranData.allSurahs;
    }
    return maps.map((e) => SurahModel.fromMap(e)).toList();
  }

  Future<List<AyahModel>> getAyahsForSurah(int surahNumber) async {
    final db = await instance.database;
    final maps = await db.query(
      'ayahs',
      where: 'surahNumber = ?',
      whereArgs: [surahNumber],
      orderBy: 'numberInSurah ASC',
    );

    // Also check which ayahs are bookmarked
    final bookmarkedMap = await getBookmarkedAyahNumbers(surahNumber);

    return maps.map((e) {
      final ayah = AyahModel.fromMap(e);
      ayah.isBookmarked = bookmarkedMap.contains(ayah.numberInSurah);
      return ayah;
    }).toList();
  }

  // --- Bookmark Queries ---
  Future<int> insertBookmark(BookmarkModel bookmark) async {
    final db = await instance.database;
    return await db.insert('bookmarks', bookmark.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteBookmark(int surahNumber, int ayahNumber) async {
    final db = await instance.database;
    return await db.delete(
      'bookmarks',
      where: 'surahNumber = ? AND ayahNumber = ?',
      whereArgs: [surahNumber, ayahNumber],
    );
  }

  Future<List<BookmarkModel>> getAllBookmarks() async {
    final db = await instance.database;
    final maps = await db.query('bookmarks', orderBy: 'id DESC');
    return maps.map((e) => BookmarkModel.fromMap(e)).toList();
  }

  Future<Set<int>> getBookmarkedAyahNumbers(int surahNumber) async {
    final db = await instance.database;
    final maps = await db.query(
      'bookmarks',
      columns: ['ayahNumber'],
      where: 'surahNumber = ?',
      whereArgs: [surahNumber],
    );
    return maps.map((e) => e['ayahNumber'] as int).toSet();
  }

  // --- Last Read Queries ---
  Future<void> saveLastRead(int surahNumber, String surahName, int ayahNumber) async {
    final db = await instance.database;
    await db.insert(
      'last_read',
      {
        'id': 1,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLastRead() async {
    final db = await instance.database;
    final maps = await db.query('last_read', where: 'id = 1');
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}

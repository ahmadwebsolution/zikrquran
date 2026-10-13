import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/ayah_model.dart';

class QuranApiService {
  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  Future<List<AyahModel>> fetchAyahsForSurah(int surahNumber) async {
    try {
      final uri = Uri.parse(
        'https://api.alquran.cloud/v1/surah/$surahNumber/editions/quran-uthmani,en.sahih',
      );
      final request = await _client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>;

        final arabicData = data[0]['ayahs'] as List<dynamic>;
        final englishData = data[1]['ayahs'] as List<dynamic>;

        final List<AyahModel> ayahs = [];
        for (int i = 0; i < arabicData.length; i++) {
          final ar = arabicData[i] as Map<String, dynamic>;
          final en = englishData[i] as Map<String, dynamic>;
          final globalNumber = ar['number'] as int;
          final numberInSurah = ar['numberInSurah'] as int;

          ayahs.add(
            AyahModel(
              number: globalNumber,
              numberInSurah: numberInSurah,
              surahNumber: surahNumber,
              text: ar['text'] as String,
              translation: en['text'] as String,
              audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalNumber.mp3',
              juz: ar['juz'] as int? ?? 1,
              page: ar['page'] as int? ?? 1,
            ),
          );
        }
        return ayahs;
      }
    } catch (e) {
      debugPrint('Error fetching Ayahs from Quran API for Surah $surahNumber: $e');
    }
    return [];
  }
}

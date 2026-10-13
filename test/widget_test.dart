import 'package:flutter_test/flutter_test.dart';
import 'package:zikrquran/core/utils/validators.dart';
import 'package:zikrquran/data/datasources/local/quran_data.dart';
import 'package:zikrquran/data/models/ayah_model.dart';
import 'package:zikrquran/data/models/surah_model.dart';

void main() {
  group('Quran Data Verification', () {
    test('All 114 Surahs are present and valid', () {
      expect(QuranData.allSurahs.length, equals(114));
      expect(QuranData.allSurahs.first.englishName, equals('Al-Faatiha'));
      expect(QuranData.allSurahs.first.numberOfAyahs, equals(7));
      expect(QuranData.allSurahs.last.englishName, equals('An-Naas'));
      expect(QuranData.allSurahs.last.numberOfAyahs, equals(6));
    });

    test('All 30 Paras (Juz) are present', () {
      expect(QuranData.allParas.length, equals(30));
      expect(QuranData.allParas.first.number, equals(1));
      expect(QuranData.allParas.first.startSurahNumber, equals(1));
      expect(QuranData.allParas.last.number, equals(30));
      expect(QuranData.allParas.last.endSurahNumber, equals(114));
    });

    test('Pre-seeded offline Ayahs are properly structured', () {
      expect(QuranData.preSeededAyahs.isNotEmpty, isTrue);

      // Verify Surah Al-Fatiha
      final fatihaAyahs = QuranData.preSeededAyahs.where((a) => a.surahNumber == 1).toList();
      expect(fatihaAyahs.length, equals(7));
      expect(fatihaAyahs.first.numberInSurah, equals(1));
      expect(fatihaAyahs.first.text, contains('بِسْمِ'));
      expect(fatihaAyahs.first.audioUrl, contains('cdn.islamic.network'));

      // Verify Surah Al-Ikhlas
      final ikhlasAyahs = QuranData.preSeededAyahs.where((a) => a.surahNumber == 112).toList();
      expect(ikhlasAyahs.length, equals(4));
    });
  });

  group('Validation Rules', () {
    test('Email validator handles valid and invalid emails', () {
      expect(Validators.validateEmail('user@test.com'), isNull);
      expect(Validators.validateEmail('invalid-email'), isNotNull);
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
    });

    test('Password validator requires minimum 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
    });

    test('Phone validator checks minimum length and formats', () {
      expect(Validators.validatePhone('+919876543210'), isNull);
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('123'), isNotNull);
      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone(null), isNotNull);
    });
  });

  group('Data Models Serialization', () {
    test('SurahModel toMap and fromMap work correctly', () {
      final surah = SurahModel(
        number: 1,
        name: 'الفَاتِحَة',
        englishName: 'Al-Faatiha',
        englishNameTranslation: 'The Opening',
        numberOfAyahs: 7,
        revelationType: 'Meccan',
      );

      final map = surah.toMap();
      final fromMap = SurahModel.fromMap(map);

      expect(fromMap.number, equals(surah.number));
      expect(fromMap.name, equals(surah.name));
      expect(fromMap.englishName, equals(surah.englishName));
      expect(fromMap.numberOfAyahs, equals(surah.numberOfAyahs));
    });

    test('AyahModel toMap and fromMap work correctly', () {
      final ayah = AyahModel(
        number: 1,
        numberInSurah: 1,
        surahNumber: 1,
        text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        translation: 'In the name of Allah',
        audioUrl: 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/1.mp3',
        juz: 1,
        page: 1,
        isBookmarked: true,
      );

      final map = ayah.toMap();
      final fromMap = AyahModel.fromMap(map);

      expect(fromMap.number, equals(ayah.number));
      expect(fromMap.text, equals(ayah.text));
      expect(fromMap.audioUrl, equals(ayah.audioUrl));
      expect(fromMap.isBookmarked, equals(ayah.isBookmarked));
    });
  });

  group('Flexible Search Filtering', () {
    test('Normalized matching finds Surahs regardless of double vowels or hyphens', () {
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

      // Check 'Ikhlas' against 'Al-Ikhlaas'
      final q1 = normalize('Ikhlas');
      final name1 = normalize('Al-Ikhlaas');
      expect(name1.contains(q1), isTrue);

      // Check 'Fatiha' against 'Al-Faatiha'
      final q2 = normalize('Fatiha');
      final name2 = normalize('Al-Faatiha');
      expect(name2.contains(q2), isTrue);

      // Check 'Yasin' against 'Yaseen'
      final q3 = normalize('Yasin');
      final name3 = normalize('Yaseen');
      expect(name3.contains(q3), isTrue);
    });
  });
}

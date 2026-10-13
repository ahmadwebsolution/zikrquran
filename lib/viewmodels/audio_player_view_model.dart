import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/ayah_model.dart';

class AudioPlayerViewModel extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  AyahModel? _currentAyah;
  String? _currentSurahName;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  List<AyahModel> _playlist = [];
  int _currentIndex = 0;
  ConcatenatingAudioSource? _playlistSource;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _currentIndexSub;

  AudioPlayerViewModel() {
    _initAudioListeners();
  }

  AyahModel? get currentAyah => _currentAyah;
  String? get currentSurahName => _currentSurahName;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  bool get hasNext => _currentIndex + 1 < _playlist.length;
  bool get hasPrevious => _currentIndex > 0;

  // Format valid audio URL
  static String resolveAudioUrl(AyahModel ayah) {
    if (ayah.audioUrl.isNotEmpty && ayah.audioUrl.startsWith('http')) {
      return ayah.audioUrl;
    }
    return 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3';
  }

  void _initAudioListeners() {
    // 1. Listen to playback & buffering state
    _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final buffering = playerState.processingState == ProcessingState.buffering ||
          playerState.processingState == ProcessingState.loading;
      final completed = playerState.processingState == ProcessingState.completed;

      bool shouldNotify = false;

      if (_isPlaying != playing) {
        _isPlaying = playing;
        shouldNotify = true;
      }

      if (_isBuffering != buffering) {
        _isBuffering = buffering;
        shouldNotify = true;
      }

      if (completed) {
        _isPlaying = false;
        _isBuffering = false;
        shouldNotify = true;
      }

      if (shouldNotify) {
        notifyListeners();
      }
    });

    // 2. Track duration updates
    _durationSub = _audioPlayer.durationStream.listen((duration) {
      if (duration != null && duration != _totalDuration) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // 3. Track position without triggering heavy UI rebuilds
    _positionSub = _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
    });

    // 4. Native sequence index changes (1 -> 2 -> 3 -> 4)
    // ExoPlayer handles playlist transitions natively with ZERO gaps and NO skips!
    _currentIndexSub = _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        if (_currentIndex != index || _currentAyah?.number != _playlist[index].number) {
          _currentIndex = index;
          _currentAyah = _playlist[index];
          notifyListeners();
        }
      }
    });
  }

  // Helper to create cached or streaming audio source
  AudioSource _createAudioSource(AyahModel ayah) {
    final url = resolveAudioUrl(ayah);
    try {
      // ignore: experimental_member_use
      return LockCachingAudioSource(Uri.parse(url), tag: ayah);
    } catch (_) {
      return AudioSource.uri(Uri.parse(url), tag: ayah);
    }
  }

  // Play playlist sequentially starting at startIndex
  Future<void> playPlaylist(List<AyahModel> ayahs, String surahName, [int startIndex = 0]) async {
    if (ayahs.isEmpty) return;

    final targetIndex = (startIndex >= 0 && startIndex < ayahs.length) ? startIndex : 0;

    // If already playing this Surah playlist
    final isSameSurah = _currentSurahName == surahName && _playlist.length == ayahs.length;
    if (isSameSurah && _playlistSource != null) {
      if (_currentIndex == targetIndex) {
        // Toggle play/pause if tapped the current playing Ayah
        togglePlayPause();
        return;
      } else {
        // Jump directly to tapped Ayah in existing native playlist
        _currentIndex = targetIndex;
        _currentAyah = _playlist[targetIndex];
        _isBuffering = true;
        notifyListeners();

        try {
          await _audioPlayer.seek(Duration.zero, index: targetIndex);
          await _audioPlayer.play();
        } catch (e) {
          debugPrint('Error seeking in playlist: $e');
        }
        return;
      }
    }

    // Set new playlist
    try {
      _playlist = List.from(ayahs);
      _currentSurahName = surahName;
      _currentIndex = targetIndex;
      _currentAyah = _playlist[targetIndex];
      _isBuffering = true;
      notifyListeners();

      final sources = <AudioSource>[];
      for (final ayah in ayahs) {
        sources.add(_createAudioSource(ayah));
      }

      _playlistSource = ConcatenatingAudioSource(
        useLazyPreparation: true,
        children: sources,
      );

      await _audioPlayer.setAudioSource(
        _playlistSource!,
        initialIndex: targetIndex,
        initialPosition: Duration.zero,
      );

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error starting playlist with cache, attempting direct stream fallback: $e');
      try {
        final fallbackSources = ayahs
            .map((a) => AudioSource.uri(Uri.parse(resolveAudioUrl(a)), tag: a))
            .toList();
        _playlistSource = ConcatenatingAudioSource(
          useLazyPreparation: true,
          children: fallbackSources,
        );
        await _audioPlayer.setAudioSource(
          _playlistSource!,
          initialIndex: targetIndex,
          initialPosition: Duration.zero,
        );
        await _audioPlayer.play();
      } catch (fallbackError) {
        debugPrint('Direct stream fallback also failed: $fallbackError');
        _isBuffering = false;
        _isPlaying = false;
        notifyListeners();
      }
    }
  }

  // Play single Ayah
  Future<void> playAyah(AyahModel ayah, String surahName) async {
    await playPlaylist([ayah], surahName, 0);
  }

  // Next Ayah
  Future<void> playNext() async {
    if (hasNext) {
      try {
        await _audioPlayer.seekToNext();
      } catch (e) {
        debugPrint('Error playing next: $e');
      }
    }
  }

  // Previous Ayah
  Future<void> playPrevious() async {
    if (hasPrevious) {
      try {
        await _audioPlayer.seekToPrevious();
      } catch (e) {
        debugPrint('Error playing previous: $e');
      }
    }
  }

  // Toggle Play / Pause
  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  // Seek within current track
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  // Stop & clear
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping: $e');
    }
    _currentAyah = null;
    _currentSurahName = null;
    _isPlaying = false;
    _isBuffering = false;
    _currentPosition = Duration.zero;
    _playlist = [];
    _currentIndex = 0;
    _playlistSource = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _currentIndexSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

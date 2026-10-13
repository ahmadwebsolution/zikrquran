import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/surah_model.dart';
import '../../viewmodels/audio_player_view_model.dart';
import '../../viewmodels/quran_view_model.dart';
import '../audio/mini_audio_player.dart';

class SurahDetailView extends StatefulWidget {
  final SurahModel surah;

  const SurahDetailView({super.key, required this.surah});

  @override
  State<SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<SurahDetailView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final quranVm = Provider.of<QuranViewModel>(context, listen: false);
      quranVm.loadAyahsForSurah(widget.surah.number);
      // Save last read
      quranVm.saveLastRead(widget.surah.number, widget.surah.englishName, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quranVm = context.watch<QuranViewModel>();
    final audioVm = context.watch<AudioPlayerViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.surah.englishName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${widget.surah.revelationType} • ${widget.surah.numberOfAyahs} Ayahs',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (quranVm.currentAyahs.isNotEmpty)
            IconButton(
              icon: Icon(
                (audioVm.currentSurahName == widget.surah.englishName && audioVm.isPlaying)
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: AppColors.accent,
                size: 28,
              ),
              tooltip: (audioVm.currentSurahName == widget.surah.englishName && audioVm.isPlaying)
                  ? 'Pause'
                  : 'Play Surah',
              onPressed: () {
                if (audioVm.currentSurahName == widget.surah.englishName && audioVm.isPlaying) {
                  audioVm.togglePlayPause();
                } else {
                  audioVm.playPlaylist(quranVm.currentAyahs, widget.surah.englishName, 0);
                }
              },
            ),
        ],
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const MiniAudioPlayer(),
      body: quranVm.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading Ayahs & Audio recitation...',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Bismillah Header (Except Surah At-Tawbah #9)
                if (widget.surah.number != 9)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      AppStrings.bismillah,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Ayahs List
                Expanded(
                  child: quranVm.currentAyahs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              const Text(
                                'Ayahs not cached yet. Connect to internet to load.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Load Ayahs'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  quranVm.loadAyahsForSurah(widget.surah.number);
                                },
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: quranVm.currentAyahs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ayah = quranVm.currentAyahs[index];
                            final isThisAyahPlaying = audioVm.currentAyah?.number == ayah.number && audioVm.isPlaying;

                            return Card(
                              elevation: 1,
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isThisAyahPlaying ? AppColors.accent : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Header: Ayah Number & Actions
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${ayah.numberInSurah}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Play Audio Button
                                        IconButton(
                                          icon: Icon(
                                            isThisAyahPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                            color: AppColors.primary,
                                            size: 26,
                                          ),
                                          onPressed: () {
                                            if (isThisAyahPlaying) {
                                              audioVm.togglePlayPause();
                                            } else {
                                              audioVm.playPlaylist(quranVm.currentAyahs, widget.surah.englishName, index);
                                            }
                                          },
                                        ),
                                        // Bookmark Button
                                        IconButton(
                                          icon: Icon(
                                            ayah.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                            color: ayah.isBookmarked ? AppColors.accent : AppColors.textSecondary,
                                          ),
                                          onPressed: () {
                                            quranVm.toggleBookmark(ayah, widget.surah.englishName);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Arabic Text
                                    Text(
                                      ayah.text,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textArabic,
                                        height: 1.8,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Translation
                                    Text(
                                      ayah.translation,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

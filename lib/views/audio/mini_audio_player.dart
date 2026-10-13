import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/audio_player_view_model.dart';

class MiniAudioPlayer extends StatelessWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioVm = context.watch<AudioPlayerViewModel>();

    if (audioVm.currentAyah == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear progress indicator
            StreamBuilder<Duration>(
              stream: audioVm.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? audioVm.currentPosition;
                final total = audioVm.totalDuration;
                final progress = total.inMilliseconds > 0
                    ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
                    : 0.0;
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 2,
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.audiotrack_rounded, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audioVm.currentSurahName ?? 'Quran Recitation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Ayah ${audioVm.currentAyah!.numberInSurah}',
                        style: const TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 24),
                  onPressed: audioVm.hasPrevious ? () => audioVm.playPrevious() : null,
                ),
                if (audioVm.isBuffering)
                  const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      audioVm.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: AppColors.accent,
                      size: 36,
                    ),
                    onPressed: () => audioVm.togglePlayPause(),
                  ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 24),
                  onPressed: audioVm.hasNext ? () => audioVm.playNext() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => audioVm.stop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

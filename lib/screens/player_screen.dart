import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/player_provider.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final track = playerProvider.currentTrack;
    final libraryService = LibraryService();

    if (track == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: Text('Ничего не играет',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: const [
            Text('Воспроизводится из',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Медиатека',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Обложка трека
            Expanded(
              child: FutureBuilder(
                future: libraryService.fetchArtwork(track.id),
                builder: (context, snapshot) {
                  final artwork = snapshot.data;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: artwork != null
                        ? Image.memory(artwork, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF2A2A2A),
                            child: const Icon(Icons.music_note,
                                size: 96, color: Colors.white24),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Название и исполнитель
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                track.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                track.artist,
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Прогресс-бар
            StreamBuilder<Duration>(
              stream: playerProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = playerProvider.duration;
                return Column(
                  children: [
                    Slider(
                      value: position.inMilliseconds
                          .toDouble()
                          .clamp(0, duration.inMilliseconds.toDouble() + 1),
                      max: duration.inMilliseconds.toDouble() + 1,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        playerProvider
                            .seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position),
                            style:
                                const TextStyle(color: Colors.white54)),
                        Text(_formatDuration(duration),
                            style:
                                const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle,
                      color: playerProvider.isShuffle
                          ? Colors.white
                          : Colors.white38),
                  onPressed: playerProvider.toggleShuffle,
                ),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  onPressed: playerProvider.previous,
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 36,
                    icon: Icon(
                      playerProvider.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.black,
                    ),
                    onPressed: playerProvider.togglePlayPause,
                  ),
                ),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: playerProvider.next,
                ),
                IconButton(
                  icon: Icon(Icons.repeat,
                      color: playerProvider.isRepeat
                          ? Colors.white
                          : Colors.white38),
                  onPressed: playerProvider.toggleRepeat,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Избранное
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    playerProvider.isFavorite(track.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: playerProvider.isFavorite(track.id)
                        ? Colors.pinkAccent
                        : Colors.white54,
                  ),
                  onPressed: () => playerProvider.toggleFavorite(track.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import 'audio_handler.dart';

/// Обёртка над AudioHandler — хранит очередь, избранное, отдаёт удобные
/// геттеры для UI. Сам плейбек и фоновая работа делегированы audio_service,
/// что обязательно для корректной работы на iOS (lock screen, Control Center,
/// продолжение игры при свёрнутом приложении).
class PlayerProvider extends ChangeNotifier {
  final LaneAudioHandler audioHandler;

  List<Track> _queue = [];
  final Set<int> _favoriteIds = {};

  PlayerProvider(this.audioHandler) {
    _loadFavorites();
    audioHandler.playbackState.listen((_) => notifyListeners());
    audioHandler.mediaItem.listen((_) => notifyListeners());
  }

  // ---------- Геттеры для UI ----------

  Track? get currentTrack {
    final item = audioHandler.mediaItem.value;
    if (item == null) return null;
    return _queue.firstWhere(
      (t) => t.data == item.id,
      orElse: () => _queue.isNotEmpty ? _queue.first : _emptyTrack(),
    );
  }

  Track _emptyTrack() => Track(
      id: -1, title: '', artist: '', data: '', duration: 0);

  bool get isPlaying => audioHandler.playbackState.value.playing;

  bool get isShuffle =>
      audioHandler.playbackState.value.shuffleMode !=
      AudioServiceShuffleMode.none;

  bool get isRepeat =>
      audioHandler.playbackState.value.repeatMode == AudioServiceRepeatMode.one;

  Duration get position => audioHandler.playbackState.value.updatePosition;

  Duration get duration => audioHandler.mediaItem.value?.duration ?? Duration.zero;

  Stream<Duration> get positionStream => AudioService.position;

  bool isFavorite(int trackId) => _favoriteIds.contains(trackId);

  List<Track> get favoriteTracks =>
      _queue.where((t) => _favoriteIds.contains(t.id)).toList();

  // ---------- Управление очередью и воспроизведением ----------

  Future<void> playQueue(List<Track> tracks, int startIndex) async {
    _queue = tracks;
    await audioHandler.loadQueue(tracks, startIndex);
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (audioHandler.playbackState.value.playing) {
      await audioHandler.pause();
    } else {
      await audioHandler.play();
    }
  }

  Future<void> next() => audioHandler.skipToNext();

  Future<void> previous() async {
    if (position.inSeconds > 3) {
      await audioHandler.seek(Duration.zero);
      return;
    }
    await audioHandler.skipToPrevious();
  }

  void toggleShuffle() {
    final enabled = !isShuffle;
    audioHandler.setShuffleMode(
      enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  void toggleRepeat() {
    final enabled = !isRepeat;
    audioHandler.setRepeatMode(
      enabled ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none,
    );
  }

  Future<void> seek(Duration position) => audioHandler.seek(position);

  // ---------- Избранное (хранится локально, без сервера) ----------

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favorite_ids') ?? [];
    _favoriteIds.addAll(saved.map(int.parse));
    notifyListeners();
  }

  Future<void> toggleFavorite(int trackId) async {
    if (_favoriteIds.contains(trackId)) {
      _favoriteIds.remove(trackId);
    } else {
      _favoriteIds.add(trackId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorite_ids',
      _favoriteIds.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }
}

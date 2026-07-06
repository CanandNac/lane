import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

/// Обработчик аудио для audio_service.
/// Отвечает за то, что происходит на экране блокировки, в шторке уведомлений
/// (Android) и в Control Center / lock screen на iOS, а также за корректную
/// работу плеера, когда приложение свёрнуто.
class LaneAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  List<Track> _tracks = [];

  AudioPlayer get player => _player;

  LaneAudioHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenForDurationChanges();
    _listenForCurrentSongIndexChanges();
    _listenForSequenceStateChanges();
  }

  /// Загружает очередь треков в плеер и в системный UI (lock screen / шторка).
  Future<void> loadQueue(List<Track> tracks, int startIndex) async {
    _tracks = tracks;

    queue.add(tracks
        .map((t) => MediaItem(
              id: t.data,
              title: t.title,
              artist: t.artist,
              album: t.album,
              duration: Duration(milliseconds: t.duration),
            ))
        .toList());

    final audioSource = ConcatenatingAudioSource(
      children: tracks.map((t) => AudioSource.uri(Uri.file(t.data))).toList(),
    );

    await _player.setAudioSource(audioSource, initialIndex: startIndex);
    play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
      default:
        await _player.setLoopMode(LoopMode.off);
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  /// Пробрасывает состояние just_audio в системный UI (play/pause/буферизация).
  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  void _listenForDurationChanges() {
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      if (index == null || queue.value.isEmpty) return;
      final newQueue = List<MediaItem>.from(queue.value);
      if (index < newQueue.length) {
        newQueue[index] = newQueue[index].copyWith(duration: duration);
        queue.add(newQueue);
      }
    });
  }

  void _listenForCurrentSongIndexChanges() {
    _player.currentIndexStream.listen((index) {
      if (index == null || queue.value.isEmpty) return;
      if (index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  void _listenForSequenceStateChanges() {
    _player.sequenceStateStream.listen((sequenceState) {
      final sequence = sequenceState?.effectiveSequence;
      if (sequence == null || sequence.isEmpty) return;
    });
  }
}

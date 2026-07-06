import 'dart:typed_data';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track.dart';

/// Сервис отвечает за доступ к музыкальным файлам, хранящимся на устройстве.
class LibraryService {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Запрашивает разрешение на доступ к медиафайлам.
  /// На Android — READ_MEDIA_AUDIO / READ_EXTERNAL_STORAGE,
  /// на iOS — доступ к медиатеке (Info.plist: NSAppleMusicUsageDescription).
  Future<bool> requestPermission() async {
    final status = await Permission.audio.request();
    if (status.isGranted) return true;

    // fallback для старых версий Android
    final storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Возвращает список всех треков, найденных на устройстве.
  Future<List<Track>> fetchAllTracks() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
    );

    return songs
        .where((song) => song.isMusic ?? true)
        .map((song) => Track(
              id: song.id,
              title: song.title,
              artist: song.artist ?? 'Неизвестный исполнитель',
              album: song.album,
              data: song.data,
              duration: song.duration ?? 0,
            ))
        .toList();
  }

  /// Получить обложку трека (если есть).
  Future<Uint8List?> fetchArtwork(int trackId) async {
    return _audioQuery.queryArtwork(
      trackId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 300,
    );
  }

  /// Список исполнителей на устройстве.
  Future<List<ArtistModel>> fetchArtists() {
    return _audioQuery.queryArtists();
  }

  /// Список альбомов на устройстве.
  Future<List<AlbumModel>> fetchAlbums() {
    return _audioQuery.queryAlbums();
  }
}

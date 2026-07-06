import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class Playlist {
  final int id;
  final String name;
  Playlist({required this.id, required this.name});
}

/// Локальное хранилище плейлистов (без сервера).
/// Таблицы:
///  - playlists(id, name)
///  - playlist_tracks(playlist_id, track_id) — связывает плейлист
///    с id трека из on_audio_query (медиатека устройства).
class PlaylistService {
  static Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'lane_playlists.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE playlists(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_tracks(
            playlist_id INTEGER NOT NULL,
            track_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<Playlist>> fetchPlaylists() async {
    final db = await _database;
    final rows = await db.query('playlists', orderBy: 'id DESC');
    return rows.map((r) => Playlist(id: r['id'] as int, name: r['name'] as String)).toList();
  }

  Future<int> createPlaylist(String name) async {
    final db = await _database;
    return db.insert('playlists', {'name': name});
  }

  Future<void> deletePlaylist(int playlistId) async {
    final db = await _database;
    await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
    await db.delete('playlists', where: 'id = ?', whereArgs: [playlistId]);
  }

  Future<void> addTrackToPlaylist(int playlistId, int trackId) async {
    final db = await _database;
    final existing = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) as maxPos FROM playlist_tracks WHERE playlist_id = ?',
      [playlistId],
    );
    final nextPos = (existing.first['maxPos'] as int) + 1;
    await db.insert('playlist_tracks', {
      'playlist_id': playlistId,
      'track_id': trackId,
      'position': nextPos,
    });
  }

  Future<void> removeTrackFromPlaylist(int playlistId, int trackId) async {
    final db = await _database;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  /// Возвращает список track_id треков, состоящих в плейлисте, по порядку.
  Future<List<int>> fetchTrackIdsForPlaylist(int playlistId) async {
    final db = await _database;
    final rows = await db.query(
      'playlist_tracks',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );
    return rows.map((r) => r['track_id'] as int).toList();
  }
}

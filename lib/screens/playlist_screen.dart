import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';
import '../services/player_provider.dart';
import 'player_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final playlists = await _playlistService.fetchPlaylists();
    setState(() => _playlists = playlists);
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Новый плейлист', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Название плейлиста'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _playlistService.createPlaylist(name);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
        title: const Text('Плейлисты', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createPlaylist),
        ],
      ),
      body: _playlists.isEmpty
          ? const Center(
              child: Text('Плейлистов пока нет.\nНажми + чтобы создать.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            )
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: const Icon(Icons.queue_music, color: Colors.white70),
                  title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlist: playlist),
                    ),
                  ).then((_) => _load()),
                  onLongPress: () async {
                    await _playlistService.deletePlaylist(playlist.id);
                    _load();
                  },
                );
              },
            ),
    );
  }
}

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final PlaylistService _playlistService = PlaylistService();
  final LibraryService _libraryService = LibraryService();
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final trackIds = await _playlistService.fetchTrackIdsForPlaylist(widget.playlist.id);
    final allTracks = await _libraryService.fetchAllTracks();
    setState(() {
      _tracks = trackIds
          .map((id) => allTracks.where((t) => t.id == id).firstOrNull)
          .whereType<Track>()
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
        title: Text(widget.playlist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(
                  child: Text('В плейлисте пока нет треков',
                      style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note, color: Colors.white38),
                      title: Text(track.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(track.artist, style: const TextStyle(color: Colors.white54)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
                        onPressed: () async {
                          await _playlistService.removeTrackFromPlaylist(
                              widget.playlist.id, track.id);
                          _load();
                        },
                      ),
                      onTap: () async {
                        await playerProvider.playQueue(_tracks, index);
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlayerScreen()),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

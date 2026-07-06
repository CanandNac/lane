import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/library_service.dart';
import '../services/playlist_service.dart';
import '../services/player_provider.dart';
import 'player_screen.dart';
import 'playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  final PlaylistService _playlistService = PlaylistService();
  List<Track> _tracks = [];
  bool _isLoading = true;
  String _selectedTab = 'Все';

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    final hasPermission = await _libraryService.requestPermission();
    if (!hasPermission) {
      setState(() => _isLoading = false);
      return;
    }
    final tracks = await _libraryService.fetchAllTracks();
    setState(() {
      _tracks = tracks;
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
        title: const Text('Медиатека',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabs(),
                Expanded(
                  child: _selectedTab == 'Плейлисты'
                      ? const PlaylistsScreen()
                      : _tracks.isEmpty
                          ? const Center(
                              child: Text(
                                'Треки не найдены.\nДобавьте музыку на устройство.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : _buildTrackList(playerProvider),
                ),
              ],
            ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Все', 'Плейлисты', 'Исполнители', 'Альбомы'];
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: tabs.map((tab) {
          final isSelected = tab == _selectedTab;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(tab),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedTab = tab),
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFF1E1E1E),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrackList(PlayerProvider playerProvider) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return ListTile(
          leading: FutureBuilder(
            future: _libraryService.fetchArtwork(track.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(snapshot.data!,
                      width: 48, height: 48, fit: BoxFit.cover),
                );
              }
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.white38),
              );
            },
          ),
          title: Text(track.title,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(track.artist,
              style: const TextStyle(color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          onTap: () async {
            await playerProvider.playQueue(_tracks, index);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            }
          },
          onLongPress: () => _showAddToPlaylistSheet(track),
        );
      },
    );
  }

  Future<void> _showAddToPlaylistSheet(Track track) async {
    final playlists = await _playlistService.fetchPlaylists();
    if (!mounted) return;
    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала создай плейлист во вкладке "Плейлисты"')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: playlists
            .map((p) => ListTile(
                  leading: const Icon(Icons.queue_music, color: Colors.white70),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  onTap: () async {
                    await _playlistService.addTrackToPlaylist(p.id, track.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }
}

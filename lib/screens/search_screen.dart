import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/track.dart';
import '../services/library_service.dart';
import '../services/player_provider.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final LibraryService _libraryService = LibraryService();

  List<String> _recentSearches = [];
  List<Track> _allTracks = [];
  List<Track> _results = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    _allTracks = await _libraryService.fetchAllTracks();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  Future<void> _removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {});
  }

  void _onSearchChanged(String query) {
    setState(() {
      _results = _allTracks
          .where((t) =>
              t.title.toLowerCase().contains(query.toLowerCase()) ||
              t.artist.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final showResults = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E0E0E),
        elevation: 0,
        title: const Text('Поиск',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              onSubmitted: _saveSearch,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Поиск людей, треков и альбомов',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: showResults ? _buildResults(playerProvider) : _buildRecent(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecent() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text('Нет недавних запросов',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Недавно искали',
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
        ..._recentSearches.map((query) => ListTile(
              title:
                  Text(query, style: const TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.close, color: Colors.white38),
                onPressed: () => _removeSearch(query),
              ),
              onTap: () {
                _controller.text = query;
                _onSearchChanged(query);
              },
            )),
      ],
    );
  }

  Widget _buildResults(PlayerProvider playerProvider) {
    if (_results.isEmpty) {
      return const Center(
        child: Text('Ничего не найдено', style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final track = _results[index];
        return ListTile(
          leading: const Icon(Icons.music_note, color: Colors.white38),
          title: Text(track.title, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(track.artist, style: const TextStyle(color: Colors.white54)),
          onTap: () async {
            await _saveSearch(_controller.text);
            await playerProvider.playQueue(_results, index);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            }
          },
        );
      },
    );
  }
}

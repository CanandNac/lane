import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'services/audio_handler.dart';
import 'services/player_provider.dart';
import 'screens/library_screen.dart';
import 'screens/search_screen.dart';

late LaneAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация audio_service — обязательна для фонового воспроизведения
  // и управления с экрана блокировки / Control Center на iOS.
  audioHandler = await AudioService.init(
    builder: () => LaneAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.laneapp.audio',
      androidNotificationChannelName: 'Воспроизведение музыки',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const LaneApp());
}

class LaneApp extends StatelessWidget {
  const LaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlayerProvider(audioHandler),
      child: MaterialApp(
        title: 'Music Player',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0E0E0E),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
          ),
        ),
        home: const RootScreen(),
      ),
    );
  }
}

/// Корневой экран с нижней навигацией: Медиатека / Поиск.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _currentIndex = 0;

  final _screens = const [
    LibraryScreen(),
    SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0E0E0E),
        currentIndex: _currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white38,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Медиатека'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
        ],
      ),
    );
  }
}

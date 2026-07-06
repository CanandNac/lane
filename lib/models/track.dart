import 'dart:typed_data';

class Track {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final String data; // путь к файлу на устройстве
  final int duration; // в миллисекундах
  final Uint8List? artwork;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.data,
    required this.duration,
    this.album,
    this.artwork,
  });

  String get durationFormatted {
    final d = Duration(milliseconds: duration);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

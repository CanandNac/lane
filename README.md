# Music Player (Flutter, iOS + Android)

Полнофункциональный локальный музыкальный плеер: тёмная тема, медиатека,
поиск, плейлисты, полноэкранный плеер, фоновое воспроизведение с
управлением с экрана блокировки (и на iOS, и на Android). Без бэкенда,
без соцфункций — вся музыка берётся с устройства.

## Быстрый старт

```bash
# 1. Установи Flutter: https://docs.flutter.dev/get-started/install

# 2. В этой папке сгенерируй нативные обёртки iOS/Android
#    (папки lib/ и pubspec.yaml уже готовы — flutter create их не тронет,
#    только добавит недостающие ios/, android/, etc.)
flutter create .

# 3. Поставь зависимости
flutter pub get

# 4. Настрой Android-права (см. ниже) и/или запусти скрипт для iOS:
chmod +x setup_ios.sh
./setup_ios.sh          # актуально только на macOS, до pod install

# 5. Запусти
flutter run
```

## Android — права доступа

В `android/app/src/main/AndroidManifest.xml`, перед тегом `<application>`:
```xml
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
```

Также добавь `audio_service` receiver — обычно подхватывается автоматически
при `flutter pub get` благодаря манифесту пакета, но если после сборки не
появляется уведомление о воспроизведении — проверь `android/app/build.gradle`:
`minSdkVersion` должен быть не ниже 21.

## iOS — сборка (нужен Mac или облачный CI)

`setup_ios.sh` сам добавит в `Info.plist`:
- `NSAppleMusicUsageDescription` — разрешение на доступ к медиатеке
- `UIBackgroundModes: audio` — чтобы звук не останавливался при сворачивании

После этого на Mac:
```bash
cd ios
pod install
cd ..
flutter run
```

### Если Mac нет под рукой
- **Codemagic** (codemagic.io) — бесплатный тир, собирает .ipa в облаке,
  можно закинуть сразу в TestFlight. Просто подключи git-репозиторий
  с этим проектом.
- **GitHub Actions** с `macos-latest` раннером — тоже бесплатно в лимитах,
  но конфиг придётся написать самому (workflow с flutter build ios).
- **MacInCloud** — аренда виртуального Mac, если нужен полноценный Xcode
  для отладки, а не только автосборка.

## Структура проекта

```
lib/
  main.dart                    — точка входа, инициализация audio_service, навигация
  models/
    track.dart                  — модель трека
  services/
    library_service.dart        — сканирование медиатеки устройства
    playlist_service.dart       — плейлисты на SQLite (создание, треки)
    audio_handler.dart          — AudioHandler для audio_service (фон, lock screen)
    player_provider.dart        — состояние плеера для UI (обёртка над audio_handler)
  screens/
    library_screen.dart         — вкладки Все/Плейлисты/Исполнители/Альбомы
    playlist_screen.dart        — список плейлистов + треки внутри
    search_screen.dart          — поиск + история запросов
    player_screen.dart          — полноэкранный плеер
setup_ios.sh                    — автонастройка Info.plist для iOS
```

## Что уже работает
- Сканирование локальной музыки с устройства
- Полноэкранный плеер: play/pause/next/prev, shuffle, repeat, seek
- Избранное (сердечко), хранится локально
- Создание своих плейлистов, добавление треков в них (долгий тап на трек)
- Поиск по названию/исполнителю + история запросов
- Фоновое воспроизведение + управление с lock screen / Control Center (iOS)
  и шторки уведомлений (Android)

## Что можно добавить дальше
- Экраны "Исполнители" и "Альбомы" (сейчас видны в списке медиатеки,
  но у них ещё нет отдельного детального экрана — легко добавить по
  аналогии с playlist_screen.dart, используя `fetchArtists`/`fetchAlbums`
  из library_service.dart)
- Эквалайзер, кроссфейд между треками
- Импорт из Spotify/SoundCloud — потребует их API и OAuth, серьёзно
  расширит проект, если понадобится — можно обсудить отдельно

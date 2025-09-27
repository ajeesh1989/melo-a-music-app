import 'dart:async';
import 'dart:io';
import 'dart:developer'; // Already imported for log()
import 'dart:math' show Random;
import 'dart:typed_data';
// <--- NEW: Import for Random class

import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:retrowave/model/song_data_model.dart';

// --- Global Constant for Logging ---
const String _logTag = 'RETROWAVE_LOG';

class MusicProvider extends ChangeNotifier {
  // <--- NEW: Random instance for reliable shuffling --->
  final Random _random = Random();

  final AudioPlayer _player = AudioPlayer();
  List<File> _playlist = [];
  int _currentIndex = 0;

  bool _isShuffling = false;
  bool _isRepeating = false;
  bool _loading = true;

  Uint8List? _albumArtBytes;
  ImageProvider? _albumArtImageProvider;
  ImageProvider? get albumArtImageProvider => _albumArtImageProvider;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  String _searchQuery = '';

  static const String _cacheKey = "cached_song_paths";
  static const String _favoritesCacheKey = "cached_favorites";
  static const String _shuffleKey = "shuffle_enabled";
  static const String _currentIndexKey = "current_song_index";

  Set<String> _favorites = {};

  // -========== Sleep Timer Variables and Getters
  Timer? _sleepTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  Duration get remainingTime => _remaining;

  // New getter to check if timer is running
  bool get isTimerActive => _remaining > Duration.zero;

  bool get isSleepTimerActive => _sleepTimer?.isActive ?? false;

  void startSleepTimer(Duration duration) {
    log('[$_logTag] Starting sleep timer for: $duration');
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();

    _remaining = duration;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        _remaining = Duration.zero; // Ensure remaining is zero at end
        log('[$_logTag] Sleep countdown complete.');
        notifyListeners();
      } else {
        _remaining -= const Duration(seconds: 1);
        notifyListeners();
      }
    });

    _sleepTimer = Timer(duration, () {
      log('[$_logTag] Sleep timer finished. Quitting app.');
      quitApp();
    });
  }

  void cancelSleepTimer() {
    log('[$_logTag] Sleep timer cancelled.');
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    _remaining = Duration.zero;
    notifyListeners();
  }

  void quitApp() {
    exit(0);
  }
  // -========== End Sleep Timer

  final Map<String, SongMetadata> _metadataMap = {};

  Future<SongMetadata?> _extractMetadata(String filePath) async {
    try {
      final session = await FFmpegKit.execute('-i "$filePath" -f ffmetadata -');
      final output = await session.getAllLogs();
      final logString = output.map((e) => e.getMessage()).join('\n');

      final genreMatch = RegExp(r'genre\s*=\s*(.*)').firstMatch(logString);
      final artistMatch = RegExp(r'artist\s*=\s*(.*)').firstMatch(logString);
      final languageMatch = RegExp(
        r'language\s*=\s*(.*)',
      ).firstMatch(logString);

      final genre = genreMatch?.group(1)?.trim();
      final artist = artistMatch?.group(1)?.trim();
      final language = languageMatch?.group(1)?.trim();
      final folder = File(filePath).parent.path.split('/').last;

      return SongMetadata(
        genre: genre,
        artist: artist,
        language: language,
        folder: folder,
      );
    } catch (e) {
      log('[$_logTag] Metadata extract error: $e');
      return null;
    }
  }

  Future<void> loadMetadataForPlaylist() async {
    _metadataMap.clear();
    for (var file in _playlist) {
      final meta = await _extractMetadata(file.path);
      if (meta != null) {
        _metadataMap[file.path] = meta;
      }
    }
    notifyListeners();
  }

  // --- Getters remain the same ---

  Map<String, List<File>> get genreMap {
    final map = <String, List<File>>{};
    for (var file in _playlist) {
      final meta = _metadataMap[file.path];
      final key = (meta?.genre?.isNotEmpty == true) ? meta!.genre! : 'Unknown';
      map.putIfAbsent(key, () => []).add(file);
    }
    return map;
  }

  Map<String, List<File>> get artistMap {
    final map = <String, List<File>>{};
    for (var file in _playlist) {
      final meta = _metadataMap[file.path];
      final key =
          (meta?.artist?.isNotEmpty == true) ? meta!.artist! : 'Unknown';
      map.putIfAbsent(key, () => []).add(file);
    }
    return map;
  }

  Map<String, List<File>> get languageMap {
    final map = <String, List<File>>{};
    for (var file in _playlist) {
      final meta = _metadataMap[file.path];
      final key =
          (meta?.language?.isNotEmpty == true) ? meta!.language! : 'Unknown';
      map.putIfAbsent(key, () => []).add(file);
    }
    return map;
  }

  Map<String, List<File>> get folderMap {
    final map = <String, List<File>>{};
    for (var file in _playlist) {
      final meta = _metadataMap[file.path];
      final key = meta?.folder ?? 'Unknown';
      map.putIfAbsent(key, () => []).add(file);
    }
    return map;
  }

  List<File> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  bool get isShuffling => _isShuffling;
  bool get isRepeating => _isRepeating;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<File> get filteredPlaylist =>
      _searchQuery.isEmpty
          ? _playlist
          : _playlist
              .where(
                (file) => file.path.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
  AudioPlayer get player => _player;

  late Box _box;

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {
    log('[$_logTag] MusicProvider initializing...');
    // Open Hive box (must be called once)
    _box = await Hive.openBox('musicBox');

    final granted = await _requestPermissions();
    if (!granted) {
      log('[$_logTag] Permissions not granted. Loading complete.');
      _loading = false;
      notifyListeners();
      return;
    }

    _isShuffling = _box.get(_shuffleKey, defaultValue: false) as bool;
    log('[$_logTag] Initial Shuffle state loaded: $_isShuffling');

    await _initializePlayer();

    _player.playerStateStream.listen((state) {
      if (state.playing) _scrollToCurrentSong();
      if (state.processingState == ProcessingState.completed) {
        log('[$_logTag] Player state completed. Handling song finish.');
        _handleSongComplete();
      }
    });
    player.playingStream.listen((isPlaying) {
      notifyListeners();
    });

    // --- NEW: Listen to loop/shuffle status from just_audio ---
    // This is less critical since you manually set the mode on play,
    // but good for completeness.
    player.loopModeStream.listen((mode) {
      log('[$_logTag] Player Loop Mode: $mode');
      _isRepeating = (mode == LoopMode.one);
      notifyListeners();
    });
  }

  Future<bool> _requestPermissions() async {
    // ... permission logic remains the same
    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdkInt >= 33) {
        final audioStatus = await Permission.audio.request();
        log(
          '[$_logTag] Android 13+ (SDK $sdkInt) Audio permission: ${audioStatus.isGranted}',
        );
        return audioStatus.isGranted;
      } else if (sdkInt >= 30) {
        final manageStatus = await Permission.manageExternalStorage.request();
        log(
          '[$_logTag] Android 11/12 (SDK $sdkInt) Manage Storage permission: ${manageStatus.isGranted}',
        );
        return manageStatus.isGranted;
      } else {
        final storageStatus = await Permission.storage.request();
        log(
          '[$_logTag] Android <11 (SDK $sdkInt) Storage permission: ${storageStatus.isGranted}',
        );
        return storageStatus.isGranted;
      }
    }
    return true;
  }

  Future<void> _initializePlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final cachedFavorites = _box.get(_favoritesCacheKey);
    if (cachedFavorites != null) {
      _favorites = Set<String>.from(cachedFavorites);
    }

    final cachedPaths = _box.get(_cacheKey);
    if (cachedPaths != null && cachedPaths.isNotEmpty) {
      _playlist = (cachedPaths as List).map((path) => File(path)).toList();
      log('[$_logTag] Loaded ${_playlist.length} songs from cache.');
    } else {
      await _scanAndCacheSongs();
    }

    // Check again in case scanning failed or found no songs
    if (_playlist.isNotEmpty) {
      int initialIndex;
      if (_isShuffling) {
        // <--- FIX 1: Use Random instance for initial shuffle index --->
        initialIndex = _random.nextInt(_playlist.length);
        log(
          '[$_logTag] Shuffle is ON. Starting at random index: $initialIndex',
        );
      } else {
        final savedIndex = _box.get(_currentIndexKey, defaultValue: 0) as int;
        initialIndex = savedIndex.clamp(0, _playlist.length - 1);
        log(
          '[$_logTag] Shuffle is OFF. Starting at saved index: $initialIndex',
        );
      }

      setCurrentIndex(initialIndex);
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> setCurrentIndex(int index) async {
    if (index < 0 || index >= _playlist.length) {
      log('[$_logTag] Error: Attempted to set invalid index: $index');
      return;
    }

    _currentIndex = index;
    await _box.put(_currentIndexKey, index);
    log(
      '[$_logTag] Current Index set to: $index. Song: ${_playlist[index].path.split('/').last}',
    );

    // We do not await this, as fetching album art is slow
    fetchAlbumArtForCurrent(_playlist[index].path);
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;

    try {
      final currentSongPath = _playlist[_currentIndex].path;
      log('[$_logTag] Starting playback for: $currentSongPath');

      await _player.setFilePath(currentSongPath);
      await _player.seek(Duration.zero);

      // Set the loop mode based on the current state
      await _player.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);

      await _player.play();
      _scrollToCurrentSong();
      notifyListeners();
    } catch (e) {
      log('[$_logTag] Playback error: $e. Skipping to next.');
      // Important: if a song fails to play, skip it
      next();
    }
  }

  Future<void> fetchAlbumArtForCurrent(String path) async {
    _albumArtBytes = await _extractAlbumArtBytes(path);
    _albumArtImageProvider =
        _albumArtBytes != null ? MemoryImage(_albumArtBytes!) : null;
    notifyListeners();
  }

  Future<Uint8List?> _extractAlbumArtBytes(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final coverPath = '${tempDir.path}/cover.jpg';
      final coverFile = File(coverPath);
      if (await coverFile.exists()) await coverFile.delete();

      final session = await FFmpegKit.execute(
        '-i "$path" -an -vcodec copy "$coverPath"',
      );
      final returnCode = await session.getReturnCode();

      if (returnCode?.isValueSuccess() == true && await coverFile.exists()) {
        log('[$_logTag] Album art extracted successfully.');
        return await coverFile.readAsBytes();
      } else {
        log('[$_logTag] FFmpeg failed to extract album art. Code: $returnCode');
      }
    } catch (e) {
      log('[$_logTag] FFmpeg album art error: $e');
    }
    return null;
  }

  void _handleSongComplete() {
    if (_isRepeating) {
      _player.seek(Duration.zero);
      _player.play();
      log('[$_logTag] Song complete. Repeating current track.');
    } else {
      log('[$_logTag] Song complete. Moving to next track.');
      next();
    }
  }

  void _scrollToCurrentSong() {
    // ... scroll logic remains the same
    final index = filteredPlaylist.indexWhere(
      (f) => f.path == _playlist[_currentIndex].path,
    );
    if (index != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController.animateTo(
          index * 72.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void next() {
    if (_playlist.isEmpty) return;

    final int nextIndex;

    if (_isShuffling) {
      // <--- FIX 2: Use Random instance for next track index (NON-REPEATING SHUFFLE REQUIRES just_audio PLAYLIST) --->
      nextIndex = _random.nextInt(_playlist.length);
      log('[$_logTag] NEXT (Shuffle): New index determined: $nextIndex');
    } else {
      // Normal sequential playback
      nextIndex = (_currentIndex + 1) % _playlist.length;
      log('[$_logTag] NEXT (Sequential): New index determined: $nextIndex');
    }

    setCurrentIndex(nextIndex);
  }

  void previous() {
    if (_playlist.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    log('[$_logTag] PREVIOUS: New index determined: $prevIndex');
    setCurrentIndex(prevIndex);
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    // Ensure the hardware player's loop mode is updated
    _player.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
    log('[$_logTag] Toggled Repeat to: $_isRepeating');
    notifyListeners();
  }

  void toggleShuffle() async {
    _isShuffling = !_isShuffling;
    await _box.put(_shuffleKey, _isShuffling);
    log('[$_logTag] Toggled Shuffle to: $_isShuffling');
    notifyListeners();
  }

  Future<void> _scanAndCacheSongs() async {
    // ... scanning logic remains the same but with added logs
    _loading = true;
    notifyListeners();
    log('[$_logTag] Starting song scan and cache...');

    final List<File> foundSongs = [];
    const searchDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Audio',
    ];

    for (final path in searchDirs) {
      final dir = Directory(path);
      if (await dir.exists()) {
        foundSongs.addAll(await _getFilesRecursive(dir));
      }
    }

    final uniquePaths = <String>{};
    final filtered = foundSongs.where((f) => uniquePaths.add(f.path)).toList();
    filtered.sort((a, b) => a.path.compareTo(b.path));

    await _box.put(_cacheKey, filtered.map((f) => f.path).toList());

    _playlist = filtered;
    _loading = false;
    log(
      '[$_logTag] Scan complete. Found and cached ${_playlist.length} unique songs.',
    );
    notifyListeners();
  }

  Future<List<File>> _getFilesRecursive(Directory dir) async {
    final List<File> files = [];
    try {
      await for (var entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          files.add(entity);
        }
      }
    } catch (e) {
      log('[$_logTag] Directory scan error in ${dir.path}: $e');
    }
    return files;
  }

  Future<void> refreshSongs() async {
    log('[$_logTag] Refreshing song list.');
    await _scanAndCacheSongs();
    if (_playlist.isNotEmpty) {
      setCurrentIndex(0);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSearching(bool searching) {
    if (!searching) _searchQuery = '';
    notifyListeners();
  }

  bool isFavorite(String path) => _favorites.contains(path);

  void toggleFavorite(String path) {
    if (_favorites.contains(path)) {
      _favorites.remove(path);
    } else {
      _favorites.add(path);
    }
    saveFavorites();
    notifyListeners();
  }

  Future<void> saveFavorites() async {
    log('[$_logTag] Saving ${_favorites.length} favorites.');
    await _box.put(_favoritesCacheKey, _favorites.toList());
  }

  String formatDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}';
  }

  Future<void> stop() async {
    log('[$_logTag] Player stopping.');
    await _player.stop();
    await _player.seek(Duration.zero);
    notifyListeners();
  }

  @override
  void dispose() {
    log('[$_logTag] Disposing MusicProvider.');
    _player.dispose();
    scrollController.dispose();
    searchController.dispose();
    _sleepTimer?.cancel();
    _countdownTimer?.cancel();
    // Do not close the box here if other parts of the app rely on it being open.
    // _box.close();
    super.dispose();
  }
}

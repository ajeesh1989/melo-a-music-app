import 'dart:io';
import 'dart:developer';
import 'dart:convert'; // for base64Encode
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  List<File> _playlist = [];
  int _currentIndex = 0;

  bool _isShuffling = false;
  bool _isRepeating = false;
  bool _loading = true;
  Uint8List? _albumArtBytes;
  ImageProvider? _albumArtImageProvider;

  ImageProvider? get albumArtImageProvider => _albumArtImageProvider;

  // Updated fetchAlbumArtForCurrent to store bytes & create MemoryImage:

  Future<void> fetchAlbumArtForCurrent(String path) async {
    _albumArtBytes = await _extractAlbumArtBytes(path);
    if (_albumArtBytes != null) {
      _albumArtImageProvider = MemoryImage(_albumArtBytes!);
    } else {
      _albumArtImageProvider = null;
    }
    notifyListeners();
  }

  // New method to extract bytes from FFmpeg output:
  Future<Uint8List?> _extractAlbumArtBytes(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final coverPath = '${tempDir.path}/cover.jpg';

      final coverFile = File(coverPath);
      if (await coverFile.exists()) {
        await coverFile.delete();
      }

      final command = '-i "$path" -an -vcodec copy "$coverPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (returnCode!.isValueSuccess() && await coverFile.exists()) {
        return await coverFile.readAsBytes();
      } else {
        // log("FFmpeg failed with code: $returnCode");
      }
    } catch (e) {
      // log("FFmpeg album art extract error: $e");
    }
    return null;
  }

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  static const String _cacheKey = "cached_song_paths";
  static const String _favoritesCacheKey = "cached_favorites";

  Set<String> _favorites = {};

  List<File> get playlist => List.unmodifiable(_playlist);
  int get currentIndex => _currentIndex;
  bool get isShuffling => _isShuffling;
  bool get isRepeating => _isRepeating;
  bool get loading => _loading;
  String get searchQuery => _searchQuery;
  Set<String> get favorites => Set.unmodifiable(_favorites);

  List<File> get filteredPlaylist {
    if (_searchQuery.isEmpty) {
      return _playlist;
    }
    return _playlist.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  AudioPlayer get player => _player;

  MusicProvider() {
    _init();
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      fetchAlbumArtForCurrent(_playlist[index].path);
      _playCurrent();
      notifyListeners();
    }
  }

  Future<void> _init() async {
    final granted = await _requestPermissions();
    if (granted) {
      await _initializePlayer();
    } else {
      _loading = false;
      notifyListeners();
    }

    _player.playerStateStream.listen((state) {
      if (state.playing) {
        _scrollToCurrentSong();
      }

      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
    });
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      if (sdkInt >= 33) {
        var audioStatus = await Permission.audio.status;
        if (!audioStatus.isGranted) {
          audioStatus = await Permission.audio.request();
        }
        if (audioStatus.isGranted) return true;
      } else if (sdkInt >= 30) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        if (manageStatus.isGranted) return true;
      } else {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        if (storageStatus.isGranted) return true;
      }

      if (await Permission.storage.isPermanentlyDenied ||
          await Permission.manageExternalStorage.isPermanentlyDenied ||
          await Permission.audio.isPermanentlyDenied) {
        openAppSettings();
      }
    }
    return false;
  }

  Future<void> _initializePlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final prefs = await SharedPreferences.getInstance();

    final cachedFavorites = prefs.getStringList(_favoritesCacheKey);
    if (cachedFavorites != null) {
      _favorites = cachedFavorites.toSet();
    }

    final cachedPaths = prefs.getStringList(_cacheKey);
    if (cachedPaths != null && cachedPaths.isNotEmpty) {
      _playlist = cachedPaths.map((path) => File(path)).toList();
      _loading = false;
      notifyListeners();

      if (await _requestPermissions()) {
        if (_playlist.isNotEmpty) {
          setCurrentIndex(0); // triggers play and fetch album art
        }
      } else {
        _showPermissionDenied();
      }
    } else {
      if (await _requestPermissions()) {
        await _scanAndCacheSongs();
        if (_playlist.isNotEmpty) {
          setCurrentIndex(0); // triggers play and fetch album art
        }
      } else {
        _showPermissionDenied();
      }
    }
  }

  void _showPermissionDenied() {
    _loading = false;
    notifyListeners();
  }

  Future<void> _scanAndCacheSongs() async {
    _loading = true;
    notifyListeners();

    List<File> foundSongs = [];

    List<String> searchDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Audio',
    ];

    for (String path in searchDirs) {
      final dir = Directory(path);
      if (await dir.exists()) {
        final files = await _getFilesRecursive(dir);
        foundSongs.addAll(files);
      }
    }

    final uniquePaths = <String>{};
    foundSongs = foundSongs.where((f) => uniquePaths.add(f.path)).toList();
    foundSongs.sort((a, b) => a.path.compareTo(b.path));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cacheKey,
      foundSongs.map((f) => f.path).toList(),
    );

    _playlist = foundSongs;
    _loading = false;
    notifyListeners();

    log("Found ${_playlist.length} songs.");
  }

  Future<List<File>> _getFilesRecursive(Directory dir) async {
    List<File> files = [];
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          files.add(entity);
        }
      }
    } catch (e) {
      log("Error scanning ${dir.path}: $e");
    }
    return files;
  }

  void _handleSongComplete() {
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      setCurrentIndex(_currentIndex);
    }
  }

  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;

    try {
      await _player.setFilePath(_playlist[_currentIndex].path);
      await _player.seek(Duration.zero);
      await _player.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
      await _player.play();
      notifyListeners();
      _scrollToCurrentSong();
    } catch (e) {
      log("Playback error: $e");
      next();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
    notifyListeners();
  }

  void _scrollToCurrentSong() {
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
    if (_isShuffling) {
      _currentIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    setCurrentIndex(_currentIndex);
  }

  void previous() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    setCurrentIndex(_currentIndex);
  }

  void toggleRepeat() {
    _isRepeating = !_isRepeating;
    _player.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    notifyListeners();
  }

  Future<void> refreshSongs() async {
    await _scanAndCacheSongs();
    if (_playlist.isNotEmpty) {
      setCurrentIndex(0);
    }
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesCacheKey, _favorites.toList());
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleSearching(bool searching) {
    _isSearching = searching;
    if (!searching) {
      _searchQuery = '';
    }
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

  // Fetch album art using metadata_god package
  Future<String?> fetchAlbumArtUrlFor(String path) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final coverPath = '${tempDir.path}/cover.jpg';

      // Remove if already exists
      final coverFile = File(coverPath);
      if (await coverFile.exists()) {
        await coverFile.delete();
      }

      final command = "-i \"$path\" -an -vcodec copy \"$coverPath\"";

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (returnCode!.isValueSuccess()) {
        final bytes = await coverFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        return 'data:image/jpeg;base64,$base64Image';
      } else {
        log("FFmpeg failed with code: $returnCode");
      }
    } catch (e) {
      log("FFmpeg album art extract error: $e");
    }
    return null;
  }

  @override
  void dispose() {
    _player.dispose();
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
}

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:retrowave/sreens/favourites.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const RetrowaveApp());

class RetrowaveApp extends StatelessWidget {
  const RetrowaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retrowave',
      theme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const MusicHomePage(),
    );
  }
}

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final AudioPlayer _player = AudioPlayer();
  List<File> _playlist = [];
  int _currentIndex = 0;

  bool _isShuffling = false;
  bool _isRepeating = false;
  bool _loading = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  static const String _cacheKey = "cached_song_paths";
  static const String _favoritesCacheKey = "cached_favorites";

  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _initializePlayer();

    _player.playerStateStream.listen((state) {
      if (state.playing) {
        _scrollToCurrentSong();
      }

      // Check if the playback has completed
      if (state.processingState == ProcessingState.completed) {
        _handleSongComplete();
      }
    });
  }

  List<File> get _filteredPlaylist {
    if (_searchQuery.isEmpty) {
      return _playlist;
    }
    return _playlist.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _initializePlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final prefs = await SharedPreferences.getInstance();

    // Load favorites
    final cachedFavorites = prefs.getStringList(_favoritesCacheKey);
    if (cachedFavorites != null) {
      _favorites = cachedFavorites.toSet();
    }

    // Load cached playlist
    final cachedPaths = prefs.getStringList(_cacheKey);
    if (cachedPaths != null && cachedPaths.isNotEmpty) {
      setState(() {
        _playlist = cachedPaths.map((path) => File(path)).toList();
        _loading = false;
      });

      if (await _requestPermissions()) {
        if (_playlist.isNotEmpty) {
          await _playCurrent();
        }
      } else {
        _showPermissionDenied();
      }
    } else {
      // No cached playlist: scan device
      if (await _requestPermissions()) {
        await _scanAndCacheSongs();
        if (_playlist.isNotEmpty) {
          await _playCurrent();
        }
      } else {
        _showPermissionDenied();
      }
    }
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

  void _showPermissionDenied() {
    setState(() {
      _loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permission denied. Please grant permissions to access music files.',
        ),
      ),
    );
  }

  Future<void> _scanAndCacheSongs() async {
    setState(() => _loading = true);
    List<File> foundSongs = [];

    // Directories to search for mp3 files
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

    // Remove duplicates & sort
    final uniquePaths = <String>{};
    foundSongs = foundSongs.where((f) => uniquePaths.add(f.path)).toList();
    foundSongs.sort((a, b) => a.path.compareTo(b.path));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cacheKey,
      foundSongs.map((f) => f.path).toList(),
    );

    setState(() {
      _playlist = foundSongs;
      _loading = false;
    });

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
    // Advance current index, loop if at the end
    if (_playlist.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
      _playCurrent();
    }
  }

  Future<void> _playCurrent() async {
    if (_playlist.isEmpty) return;

    try {
      await _player.setFilePath(_playlist[_currentIndex].path);
      await _player.seek(Duration.zero);
      await _player.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
      await _player.play();
      setState(() {});
      _scrollToCurrentSong();
    } catch (e) {
      log("Playback error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
      _next();
    }
  }

  Future<void> _stop() async {
    await _player.stop(); // Stops the player
    await _player.seek(Duration.zero); // Resets to the beginning
    await _player.play(); // Automatically starts playing again
    setState(() {});
  }

  void _scrollToCurrentSong() {
    if (!_scrollController.hasClients || _playlist.isEmpty) return;
    final offset = _currentIndex * 72.0; // Approximate tile height
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_playlist.isEmpty) return;
    if (_isShuffling) {
      _currentIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
    } else {
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    _playCurrent();
  }

  void _previous() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _playCurrent();
  }

  void _toggleRepeat() {
    _isRepeating = !_isRepeating;
    _player.setLoopMode(_isRepeating ? LoopMode.one : LoopMode.off);
    setState(() {});
  }

  void _toggleShuffle() {
    _isShuffling = !_isShuffling;
    setState(() {});
  }

  Future<void> _refreshSongs() async {
    await _scanAndCacheSongs();
    if (_playlist.isNotEmpty) {
      _currentIndex = 0;
      await _playCurrent();
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesCacheKey, _favorites.toList());
  }

  String _formatDuration(Duration duration) {
    twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildBottomControls() {
    final currentSongName =
        _playlist.isNotEmpty
            ? _playlist[_currentIndex].path.split('/').last
            : 'No song playing';

    return Container(
      // margin: const EdgeInsets.all(3), // optional: add spacing around container
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15), // 🔹 Rounded corners
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          SizedBox(
            height: 24, // Adjust height based on your layout
            child: Marquee(
              text: currentSongName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.start,
              blankSpace: 50.0,
              velocity: 30.0,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),

          const SizedBox(height: 8),
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;

              return Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight:
                            2, // Increase track height (default is 2-4)
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ), // Larger thumb radius
                        overlayShape: RoundSliderOverlayShape(
                          overlayRadius: 20,
                        ), // Touch area size
                      ),
                      child: Slider(
                        value:
                            position.inMilliseconds
                                .clamp(0, duration.inMilliseconds)
                                .toDouble(),
                        max: duration.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          _player.seek(Duration(milliseconds: value.toInt()));
                        },
                        activeColor: Colors.cyan,
                        inactiveColor: Colors.cyan.withOpacity(0.3),
                      ),
                    ),
                  ),

                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 28,
                color: _isShuffling ? Colors.cyan : Colors.white,
                icon: const Icon(Icons.shuffle),
                onPressed: _toggleShuffle,
                tooltip: 'Shuffle',
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_previous),
                onPressed: _previous,
                tooltip: 'Previous',
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final playing = playerState?.playing ?? false;
                  final processingState = playerState?.processingState;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 64.0,
                      height: 64.0,
                      child: const CircularProgressIndicator(),
                    );
                  } else if (playing) {
                    return IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.pause_circle),
                      onPressed: _player.pause,
                      tooltip: 'Pause',
                    );
                  } else {
                    return IconButton(
                      iconSize: 64,
                      icon: const Icon(Icons.play_circle),
                      onPressed: _player.play,
                      tooltip: 'Play',
                    );
                  }
                },
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.stop_circle),
                onPressed: _stop,
                tooltip: 'Stop',
              ),
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.skip_next),
                onPressed: _next,
                tooltip: 'Next',
              ),
              IconButton(
                iconSize: 28,
                color: _isRepeating ? Colors.cyan : Colors.white,
                icon: const Icon(Icons.repeat),
                onPressed: _toggleRepeat,
                tooltip: 'Repeat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(int index, File file) {
    final isCurrent = _playlist[_currentIndex].path == file.path;
    final fileName = file.path.split('/').last;
    final isFavorite = _favorites.contains(file.path);

    return ListTile(
      selected: isCurrent,
      // ignore: deprecated_member_use
      selectedTileColor: Colors.cyan.withOpacity(0.3),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${index + 1}. ',
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.cyan, // index always in cyan
              ),
            ),
            TextSpan(
              text: fileName,
              style: TextStyle(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.cyan : Colors.grey,
        ),
        onPressed: () async {
          setState(() {
            if (isFavorite) {
              _favorites.remove(file.path);
            } else {
              _favorites.add(file.path);
            }
          });
          await _saveFavorites();
        },
        tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
      ),
      onTap: () {
        final originalIndex = _playlist.indexWhere((f) => f.path == file.path);
        if (originalIndex != -1) {
          setState(() {
            _currentIndex = originalIndex;
          });
          _playCurrent();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSong =
        (_playlist.isNotEmpty && _currentIndex < _playlist.length)
            ? _playlist[_currentIndex]
            : null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:
            !_isSearching
                ? const Text('m e l o', style: TextStyle(color: Colors.cyan))
                : TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
        actions: [
          !_isSearching
              ? IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              )
              : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSongs,
            tooltip: 'Refresh Library',
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.cyan),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => FavoritesPage(
                        favorites: _favorites,
                        allSongs: _playlist,
                        onToggleFavorite: (String path) {
                          setState(() {
                            if (_favorites.contains(path)) {
                              _favorites.remove(path);
                            } else {
                              _favorites.add(path);
                            }
                            _saveFavorites();
                          });
                        },
                        onPlaySong: (String path) {
                          final index = _playlist.indexWhere(
                            (f) => f.path == path,
                          );
                          if (index != -1) {
                            setState(() {
                              _currentIndex = index;
                            });
                            _playCurrent();
                          }
                        },
                      ),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.grey.shade900,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.music_note, size: 48, color: Colors.cyan),
                  SizedBox(height: 8),
                  Text(
                    'Melo',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'by aj_labs',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.cyan),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.cyan),
              title: const Text(
                'Favorites',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => FavoritesPage(
                          favorites: _favorites,
                          allSongs: _playlist,
                          onToggleFavorite: (String path) {
                            setState(() {
                              if (_favorites.contains(path)) {
                                _favorites.remove(path);
                              } else {
                                _favorites.add(path);
                              }
                              _saveFavorites();
                            });
                          },
                          onPlaySong: (String path) {
                            final index = _playlist.indexWhere(
                              (f) => f.path == path,
                            );
                            if (index != -1) {
                              setState(() {
                                _currentIndex = index;
                              });
                              _playCurrent();
                            }
                          },
                        ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.cyan),
              title: const Text(
                'About & Help',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationIcon: const Icon(
                    Icons.music_note,
                    size: 40,
                    color: Colors.cyan,
                  ),
                  applicationName: 'Melo',
                  applicationVersion: 'v1.0.0',
                  applicationLegalese: '© 2025 aj_labs',
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        '🎵 Melo is a modern offline music player designed for simplicity, elegance, and performance.\n\n'
                        'Developed by aj_labs with love and passion for music.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '🛠️ How to Use:\n'
                        '• 🔍 Search: Use the search icon to find songs by title.\n'
                        '• 🔄 Refresh: Tap the refresh button to reload your music library.\n'
                        '• ❤️ Favorite: Tap the heart icon to mark/unmark songs as favorites.\n'
                        '• 🎶 Favorites Page: View all your favorite songs in one place.\n'
                        '• ▶️ Player: Control playback with shuffle, repeat, previous, next, play, pause, and stop.\n'
                        '• 📰 Long Titles: Marquee scrolling shows full song names.\n',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Thank you for using Melo 🎧\n- aj_labs',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPlaylist.isEmpty
              ? const Center(child: Text("No songs found."))
              : RefreshIndicator(
                onRefresh: _refreshSongs,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _filteredPlaylist.length,
                  itemBuilder:
                      (context, index) =>
                          _buildSongTile(index, _filteredPlaylist[index]),
                ),
              ),

      bottomNavigationBar: currentSong == null ? null : _buildBottomControls(),
    );
  }
}

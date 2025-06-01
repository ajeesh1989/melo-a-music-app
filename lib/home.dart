// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:retrowave/controller/music_controller.dart';
import 'package:retrowave/neos/neo_box.dart';
import 'package:retrowave/neos/song_page.dart';
import 'package:retrowave/sreens/favourites.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  bool _showSearch = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isPlayerExpanded = false;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final music = Provider.of<MusicProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[300],
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Text(
                'M e l o 🎵',
                style: TextStyle(color: Colors.black, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.white),
              title: const Text(
                'Favorites',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => FavoritesPage(
                          favorites: music.favorites,
                          allSongs: music.filteredPlaylist,
                          onToggleFavorite: music.toggleFavorite,
                          onPlaySong: (path) {
                            final idx = music.playlist.indexWhere(
                              (f) => f.path == path,
                            );
                            if (idx != -1) {
                              music.setCurrentIndex(idx);
                              music.player.play();
                            }
                          },
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu button
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black26),
                        tooltip: "Open Menu",
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ),
                  ),

                  // App title or song count
                  Expanded(
                    child: Center(
                      child:
                          _showSearch || music.searchQuery.isNotEmpty
                              ? Text(
                                'Songs: ${music.filteredPlaylist.length}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : const Text(
                                'M  E  L  O',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                    ),
                  ),

                  // Refresh button
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black26),
                        tooltip: "Rescan Songs",
                        onPressed: music.refreshSongs,
                      ),
                    ),
                  ),

                  // Toggle search
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: IconButton(
                        icon: Icon(
                          _showSearch ? Icons.close : Icons.search,
                          color: Colors.black,
                        ),
                        tooltip: "Toggle Search",
                        onPressed: () {
                          setState(() {
                            if (_showSearch) {
                              music.searchController.clear();
                              music.updateSearchQuery('');
                            }
                            _showSearch = !_showSearch;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: music.searchController,
                    onChanged: music.updateSearchQuery,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: const TextStyle(color: Colors.black45),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black45,
                      ),
                      suffixIcon:
                          music.searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  music.searchController.clear();
                                  music.updateSearchQuery('');
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      fillColor: Colors.grey[300],
                      filled: true,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // Song list
              Expanded(
                child:
                    music.loading
                        ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.black),
                              SizedBox(height: 15),
                              Text(
                                'Searching for songs!!!',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : music.filteredPlaylist.isEmpty
                        ? const Center(child: Text("No songs found"))
                        : ListView.builder(
                          controller: music.scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: music.filteredPlaylist.length,
                          itemBuilder: (context, index) {
                            final file = music.filteredPlaylist[index];
                            final isCurrent =
                                music.playlist.isNotEmpty &&
                                music.currentIndex >= 0 &&
                                music.currentIndex < music.playlist.length &&
                                file.path ==
                                    music.playlist[music.currentIndex].path;

                            return NeuBox(
                              child: ListTile(
                                leading: Icon(
                                  Icons.music_note,
                                  color:
                                      isCurrent
                                          ? Colors.black
                                          : Colors.grey[600],
                                  size: 28,
                                ),
                                title: Text(
                                  file.path.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight:
                                        isCurrent
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                    color:
                                        isCurrent
                                            ? const Color.fromARGB(
                                              255,
                                              7,
                                              131,
                                              9,
                                            )
                                            : Colors.grey[800],
                                    fontStyle:
                                        isCurrent
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                    decoration:
                                        isCurrent
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                  ),
                                ),

                                onTap: () {
                                  final indexInPlaylist = music.playlist
                                      .indexWhere((f) => f.path == file.path);
                                  if (indexInPlaylist != -1) {
                                    music.setCurrentIndex(indexInPlaylist);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                SongPage(songPath: file.path),
                                      ),
                                    );
                                  }
                                },
                                trailing: IconButton(
                                  icon: Icon(
                                    music.isFavorite(file.path)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        music.isFavorite(file.path)
                                            ? Colors.grey
                                            : Colors.grey[700],
                                  ),
                                  onPressed:
                                      () => music.toggleFavorite(file.path),
                                ),
                              ),
                            );
                          },
                        ),
              ),

              // Mini Player
              // Mini Player with expand/collapse
              // Inside the build method where you render the mini player...
              if (music.playlist.isNotEmpty &&
                  music.currentIndex >= 0 &&
                  music.currentIndex < music.playlist.length)
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.delta.dy < -10) {
                      setState(() {
                        _isPlayerExpanded = true;
                      });
                    } else if (details.delta.dy > 10) {
                      setState(() {
                        _isPlayerExpanded = false;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(top: 8, bottom: 15),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade500,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    height: _isPlayerExpanded ? 120 : 60,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Use Flexible instead of Expanded here to avoid forcing fill height
                          Row(
                            children: [
                              // Collapse/Expand Button
                              SizedBox(
                                width: 30,
                                child: IconButton(
                                  icon: Icon(
                                    _isPlayerExpanded
                                        ? Icons.expand_more
                                        : Icons.expand_less,
                                    size: 24,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPlayerExpanded = !_isPlayerExpanded;
                                    });
                                  },
                                ),
                              ),

                              // Previous Button
                              SizedBox(
                                width: 35,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    size: 24,
                                    color: Colors.black,
                                  ),
                                  onPressed: music.previous,
                                ),
                              ),

                              // Play/Pause Button
                              SizedBox(
                                width: 35,
                                child: Consumer<MusicProvider>(
                                  builder: (context, music, child) {
                                    return IconButton(
                                      icon: Icon(
                                        music.player.playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 28,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        if (music.player.playing) {
                                          music.player.pause();
                                        } else {
                                          music.player.play();
                                        }
                                        music.notifyListeners();
                                      },
                                    );
                                  },
                                ),
                              ),

                              // Next Button
                              SizedBox(
                                width: 35,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    size: 24,
                                    color: Colors.black,
                                  ),
                                  onPressed: music.next,
                                ),
                              ),

                              // Song title with marquee and open icon
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => SongPage(
                                              songPath:
                                                  music
                                                      .playlist[music
                                                          .currentIndex]
                                                      .path,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 20,
                                          child: Marquee(
                                            text:
                                                music
                                                    .playlist[music
                                                        .currentIndex]
                                                    .path
                                                    .split('/')
                                                    .last,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            scrollAxis: Axis.horizontal,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            blankSpace: 30.0,
                                            velocity: 30.0,
                                            pauseAfterRound: const Duration(
                                              seconds: 1,
                                            ),
                                            accelerationDuration:
                                                const Duration(seconds: 1),
                                            accelerationCurve: Curves.linear,
                                            decelerationDuration:
                                                const Duration(
                                                  milliseconds: 500,
                                                ),
                                            decelerationCurve: Curves.easeOut,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.open_in_new,
                                        size: 18,
                                        color: Colors.green.shade800,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_isPlayerExpanded)
                            Consumer<MusicProvider>(
                              builder: (context, music, child) {
                                final player = music.player;
                                final duration =
                                    player.duration ?? Duration(seconds: 1);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      StreamBuilder<Duration>(
                                        stream: player.positionStream,
                                        builder: (context, snapshot) {
                                          final currentPos =
                                              snapshot.data ?? Duration.zero;
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _formatDuration(
                                                  player.position,
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Slider(
                                                min: 0,
                                                max:
                                                    duration.inMilliseconds
                                                        .toDouble(),
                                                value:
                                                    currentPos.inMilliseconds
                                                        .clamp(
                                                          0,
                                                          duration
                                                              .inMilliseconds,
                                                        )
                                                        .toDouble(),
                                                activeColor:
                                                    const Color.fromARGB(
                                                      255,
                                                      59,
                                                      147,
                                                      61,
                                                    ),
                                                inactiveColor: Colors.grey[400],
                                                onChanged: (value) {
                                                  player.seek(
                                                    Duration(
                                                      milliseconds:
                                                          value.toInt(),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Text(
                                                _formatDuration(duration),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

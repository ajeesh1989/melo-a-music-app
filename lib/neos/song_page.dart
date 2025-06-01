import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:retrowave/controller/music_controller.dart';
import 'package:retrowave/neos/neo_box.dart';
import 'package:retrowave/sreens/favourites.dart';

class SongPage extends StatelessWidget {
  final String songPath;

  const SongPage({super.key, required this.songPath});

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  Widget fallbackImage() {
    return Image.asset(
      'assets/images/album.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: 330,
    );
  }

  void showActionPopup(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final opacity = ValueNotifier<double>(0.0);

    overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            bottom: 150,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Material(
              color: Colors.transparent,
              child: ValueListenableBuilder<double>(
                valueListenable: opacity,
                builder: (context, value, _) {
                  return AnimatedOpacity(
                    opacity: value,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 50), () {
      opacity.value = 1.0;
    });

    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () async {
      opacity.value = 0.0;
      await Future.delayed(const Duration(milliseconds: 400));
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final music = Provider.of<MusicProvider>(context, listen: false);
    final index = music.playlist.indexWhere((f) => f.path == songPath);

    if (index != -1 && music.currentIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        music.setCurrentIndex(index);
        music.player.play();
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FavoritesPage(
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
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Consumer<MusicProvider>(
            builder: (context, music, _) {
              final player = music.player;
              final currentSongPath =
                  music.playlist.isNotEmpty
                      ? music.playlist[music.currentIndex].path
                      : '';
              final fileName = currentSongPath.split('/').last;
              final albumArtImageProvider = music.albumArtImageProvider;

              Widget buildAlbumArt() {
                if (albumArtImageProvider != null) {
                  return Image(
                    image: albumArtImageProvider,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: 330,
                    errorBuilder:
                        (context, error, stackTrace) => fallbackImage(),
                  );
                } else {
                  return fallbackImage();
                }
              }

              return StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final currentPos = snapshot.data ?? Duration.zero;
                  final totalDuration =
                      player.duration ?? const Duration(seconds: 1);

                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: NeuBox(
                              child: GestureDetector(
                                onTap:
                                    () => Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst),
                                child: const Icon(
                                  Icons.expand_more,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'P L A Y L I S T',
                            style: TextStyle(color: Colors.black),
                          ),
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: NeuBox(
                              child: Builder(
                                builder:
                                    (context) => IconButton(
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.black26,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => FavoritesPage(
                                                  favorites: music.favorites,
                                                  allSongs:
                                                      music.filteredPlaylist,
                                                  onToggleFavorite:
                                                      music.toggleFavorite,
                                                  onPlaySong: (path) {
                                                    final idx = music.playlist
                                                        .indexWhere(
                                                          (f) => f.path == path,
                                                        );
                                                    if (idx != -1) {
                                                      music.setCurrentIndex(
                                                        idx,
                                                      );
                                                      music.player.play();
                                                    }
                                                  },
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      NeuBox(
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: buildAlbumArt(),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Now Playing 🎵',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: Color.fromARGB(
                                              255,
                                              136,
                                              126,
                                              126,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 24,
                                          child: Marquee(
                                            text: fileName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 18,
                                            ),
                                            blankSpace: 50,
                                            velocity: 30.0,
                                            pauseAfterRound: const Duration(
                                              seconds: 1,
                                            ),
                                            startPadding: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  NeuBox(
                                    child: IconButton(
                                      icon: Icon(
                                        music.isFavorite(currentSongPath)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            music.isFavorite(currentSongPath)
                                                ? Colors.grey
                                                : Colors.black26,
                                        size: 25,
                                      ),
                                      onPressed: () {
                                        music.toggleFavorite(currentSongPath);
                                        showActionPopup(
                                          context,
                                          music.isFavorite(currentSongPath)
                                              ? "Added to Favorites"
                                              : "Removed from Favorites",
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            formatDuration(currentPos),
                            style: const TextStyle(color: Colors.black),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.shuffle,
                              color: music.isShuffling ? Colors.black : null,
                            ),
                            tooltip: "Shuffle",
                            onPressed: () {
                              music.toggleShuffle();
                              showActionPopup(
                                context,
                                music.isShuffling
                                    ? "Shuffle On"
                                    : "Shuffle Off",
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              music.isRepeating
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              color: music.isRepeating ? Colors.black : null,
                            ),
                            onPressed: () {
                              music.toggleRepeat();
                              showActionPopup(
                                context,
                                music.isRepeating ? "Repeat On" : "Repeat Off",
                              );
                            },
                          ),
                          Text(
                            formatDuration(totalDuration),
                            style: const TextStyle(color: Colors.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      NeuBox(
                        child: Slider(
                          min: 0,
                          max: totalDuration.inMilliseconds.toDouble(),
                          value:
                              currentPos.inMilliseconds
                                  .clamp(0, totalDuration.inMilliseconds)
                                  .toDouble(),
                          activeColor: const Color.fromARGB(255, 59, 147, 61),
                          inactiveColor: Colors.grey[400],
                          onChanged: (value) {
                            player.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 75,
                        child: Row(
                          children: [
                            Expanded(
                              child: NeuBox(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.skip_previous,
                                    color: Colors.black54,
                                    size: 30,
                                  ),
                                  onPressed: music.previous,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: NeuBox(
                                child: IconButton(
                                  icon: Icon(
                                    player.playing
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.black54,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    if (player.playing) {
                                      player.pause();
                                    } else {
                                      player.play();
                                    }
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: NeuBox(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    size: 30,
                                    color: Colors.black54,
                                  ),
                                  onPressed: music.next,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

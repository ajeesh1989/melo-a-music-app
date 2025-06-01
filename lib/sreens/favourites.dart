import 'dart:io';

import 'package:flutter/material.dart';
import 'package:retrowave/neos/neo_box.dart';
import 'package:retrowave/neos/song_page.dart';

class FavoritesPage extends StatefulWidget {
  final Set<String> favorites;
  final List<File> allSongs;
  final Function(String) onToggleFavorite;
  final Function(String) onPlaySong;

  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.allSongs,
    required this.onToggleFavorite,
    required this.onPlaySong,
  });

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late List<File> favoriteSongs;

  @override
  void initState() {
    super.initState();
    favoriteSongs =
        widget.allSongs
            .where((f) => widget.favorites.contains(f.path))
            .toList();
  }

  void _removeFromFavorites(String path) {
    setState(() {
      widget.onToggleFavorite(path);
      favoriteSongs.removeWhere((file) => file.path == path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 25.0,
          ), // same as SongPage
          child: Column(
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
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black26,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'F A V O U R I T E S',
                    style: TextStyle(color: Colors.black),
                  ),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black26),
                        onPressed: () {
                          // Optional: open a drawer or menu
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child:
                    favoriteSongs.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'No favorites yet.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: favoriteSongs.length,
                          itemBuilder: (context, index) {
                            final file = favoriteSongs[index];
                            final fileName = file.path.split('/').last;

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: NeuBox(
                                child: ListTile(
                                  title: Text(
                                    '${index + 1}. $fileName',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.favorite,
                                      color: Colors.grey,
                                    ),
                                    onPressed:
                                        () => _removeFromFavorites(file.path),
                                  ),
                                  onTap: () {
                                    widget.onPlaySong(file.path);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                SongPage(songPath: file.path),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

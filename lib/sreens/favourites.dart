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
  late List<File> filteredSongs;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    favoriteSongs =
        widget.allSongs
            .where((f) => widget.favorites.contains(f.path))
            .toList();
    filteredSongs = List.from(favoriteSongs);

    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        filteredSongs =
            favoriteSongs
                .where((song) => song.path.toLowerCase().contains(query))
                .toList();
      });
    });
  }

  void _removeFromFavorites(String path) {
    setState(() {
      widget.onToggleFavorite(path);
      favoriteSongs.removeWhere((file) => file.path == path);
      filteredSongs.removeWhere((file) => file.path == path);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white54 : Colors.black26;
    final fadedText = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                        child: Icon(Icons.arrow_back, color: iconColor),
                      ),
                    ),
                  ),
                  Expanded(
                    // wrap text / textfield inside Expanded so it takes available space proportionally
                    child:
                        _isSearching
                            ? SizedBox(
                              height: 45,
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: textColor),
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search favorites...',
                                  hintStyle: TextStyle(color: fadedText),
                                  filled: true,
                                  fillColor:
                                      isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  // suffixIcon: IconButton(
                                  //   icon: Icon(Icons.clear, color: iconColor),
                                  //   onPressed: () {
                                  //     setState(() {
                                  //       _searchController.clear();
                                  //       _isSearching = false;
                                  //       filteredSongs = List.from(
                                  //         favoriteSongs,
                                  //       );
                                  //     });
                                  //   },
                                  // ),
                                ),
                              ),
                            )
                            : Text(
                              'F A V O U R I T E',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                  ),
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: iconColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchController.clear();
                              filteredSongs = List.from(favoriteSongs);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              Expanded(
                child:
                    filteredSongs.isEmpty
                        ? Center(
                          child: Text(
                            'No favorites found.',
                            style: TextStyle(fontSize: 16, color: fadedText),
                          ),
                        )
                        : ListView.builder(
                          itemCount: filteredSongs.length,
                          itemBuilder: (context, index) {
                            final file = filteredSongs[index];
                            final fileName = file.path.split('/').last;

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: NeuBox(
                                child: ListTile(
                                  title: Text(
                                    '${index + 1}. $fileName',
                                    style: TextStyle(color: textColor),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color:
                                          isDark
                                              ? Colors.white54
                                              : Colors.grey[700],
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

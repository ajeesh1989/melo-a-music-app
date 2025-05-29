import 'dart:io';

import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Favorites')),
      body:
          favoriteSongs.isEmpty
              ? const Center(child: Text('No favorites yet.'))
              : ListView.builder(
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final file = favoriteSongs[index];
                  final fileName = file.path.split('/').last;

                  return ListTile(
                    title: Text('${index + 1}. $fileName'),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.cyan),
                      onPressed: () {
                        _removeFromFavorites(file.path);
                      },
                      tooltip: 'Remove from favorites',
                    ),
                    onTap: () {
                      widget.onPlaySong(file.path);
                      Navigator.of(context).pop(); // Close favorites screen
                    },
                  );
                },
              ),
    );
  }
}

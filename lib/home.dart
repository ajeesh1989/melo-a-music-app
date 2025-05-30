import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retrowave/controller/music_controller.dart';
import 'package:retrowave/neos/neo_box.dart';
import 'package:retrowave/neos/song_page.dart';

class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  State<MusicHomePage> createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Light background for neumorphic look
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Consumer<MusicProvider>(
          builder:
              (context, music, _) =>
                  music.searchQuery.isEmpty && !_showSearch
                      ? const Text(
                        "M  E  L  O",
                        style: TextStyle(color: Colors.black),
                      )
                      : Text(
                        "Songs: ${music.filteredPlaylist.length}",
                        style: TextStyle(color: Colors.black),
                      ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Colors.black, // <-- set icon color here
            ),
            onPressed: () {
              final music = Provider.of<MusicProvider>(context, listen: false);
              setState(() {
                if (_showSearch) {
                  music.searchController.clear();
                  music.updateSearchQuery('');
                }
                _showSearch = !_showSearch;
              });
            },
          ),

          Consumer<MusicProvider>(
            builder:
                (context, music, _) => IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  tooltip: "Rescan Songs",
                  onPressed: music.refreshSongs,
                ),
          ),
          SizedBox(width: 10),
        ],
        bottom:
            _showSearch
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Consumer<MusicProvider>(
                    builder: (context, music, _) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: TextField(
                          controller: music.searchController,
                          onChanged: music.updateSearchQuery,
                          style: const TextStyle(
                            color: Colors.black,
                          ), // <-- Add this line
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(color: Colors.black),
                            hintText: "Search songs...",
                            hintStyle: const TextStyle(color: Colors.black),
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
                      );
                    },
                  ),
                )
                : null,
      ),
      body: Consumer<MusicProvider>(
        builder: (context, music, _) {
          if (music.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  SizedBox(height: 15),
                  Text(
                    'Searching for songs!!!',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (music.filteredPlaylist.isEmpty) {
            return const Center(child: Text("No songs found"));
          }

          return ListView.builder(
            controller: music.scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            itemCount: music.filteredPlaylist.length,
            itemBuilder: (context, index) {
              final file = music.filteredPlaylist[index];
              final isCurrent =
                  music.playlist.isNotEmpty &&
                  file.path == music.playlist[music.currentIndex].path;

              return NeuBox(
                child: ListTile(
                  leading: Icon(
                    Icons.music_note,
                    color: isCurrent ? Colors.blueAccent : Colors.grey[700],
                    size: 28,
                  ),
                  title: Text(
                    file.path.split('/').last,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: Colors.grey[800],
                    ),
                  ),
                  onTap: () {
                    final indexInPlaylist = music.playlist.indexWhere(
                      (f) => f.path == file.path,
                    );
                    if (indexInPlaylist != -1) {
                      music.setCurrentIndex(indexInPlaylist);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongPage(songPath: file.path),
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
                              ? Colors.red
                              : Colors.grey[700],
                    ),
                    onPressed: () => music.toggleFavorite(file.path),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

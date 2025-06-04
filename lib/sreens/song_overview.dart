import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retrowave/controller/music_controller.dart';
import 'package:retrowave/neos/song_page.dart';

class CategoriesOverviewPage extends StatefulWidget {
  const CategoriesOverviewPage({super.key});

  @override
  State<CategoriesOverviewPage> createState() => _CategoriesOverviewPageState();
}

class _CategoriesOverviewPageState extends State<CategoriesOverviewPage> {
  late Future<void> _loadingFuture;

  @override
  void initState() {
    super.initState();
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    _loadingFuture = musicProvider.loadMetadataForPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Music Categories")),
      body: FutureBuilder(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategorySection(
                  context,
                  "Artists",
                  musicProvider.artistMap,
                ),
                _buildCategorySection(
                  context,
                  "Genres",
                  musicProvider.genreMap,
                ),
                _buildCategorySection(
                  context,
                  "Languages",
                  musicProvider.languageMap,
                ),
                _buildCategorySection(
                  context,
                  "Folders",
                  musicProvider.folderMap,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    Map<String, List<File>> map,
  ) {
    final itemCount = map.length;

    if (itemCount == 0) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text("No $title found.", style: const TextStyle(fontSize: 16)),
      );
    }

    final keys = map.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "$title: $itemCount ${itemCount == 1 ? 'item' : 'items'} found",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3 / 2,
          ),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final key = keys[index];
            final songCount = map[key]?.length ?? 0;

            return Card(
              child: InkWell(
                onTap: () {
                  final files = map[key] ?? [];
                  if (files.isNotEmpty) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SongPage(songPath: title),
                      ),
                    );
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          key,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$songCount song${songCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

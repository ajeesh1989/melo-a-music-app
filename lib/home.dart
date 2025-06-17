// ignore_for_file: invalid_use_of_protected_member, deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:retrowave/about.dart';
import 'package:retrowave/controller/music_controller.dart';
import 'package:retrowave/controller/theme_provider.dart';
import 'package:retrowave/neos/neo_box.dart';
import 'package:retrowave/neos/song_page.dart';
import 'package:retrowave/sreens/favourites.dart';
import 'package:retrowave/sreens/song_overview.dart';

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

  Widget _buildMinimalItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        icon,
        size: 20,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
    );
  }

  void _showCustomSleepTimerPicker(
    BuildContext context,
    MusicProvider provider,
  ) {
    int selectedMinutes = 10;

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Duration (minutes)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: 9, // Index 9 => 10 min default
                  ),
                  itemExtent: 32.0,
                  onSelectedItemChanged: (int index) {
                    selectedMinutes = index + 1;
                  },
                  backgroundColor: theme.dialogBackgroundColor,
                  children: List<Widget>.generate(180, (index) {
                    return Center(
                      child: Text(
                        '${index + 1} min',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                ),
                child: Text(
                  "Set Timer",
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  provider.startSleepTimer(Duration(minutes: selectedMinutes));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Sleep timer set for $selectedMinutes minutes",
                        style: TextStyle(
                          color:
                              theme.snackBarTheme.contentTextStyle?.color ??
                              Colors.white,
                        ),
                      ),
                      backgroundColor:
                          theme.snackBarTheme.backgroundColor ??
                          theme.primaryColor,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Set Sleep Timer"),
          children: [
            SimpleDialogOption(
              child: const Text("15 minutes"),
              onPressed: () {
                provider.startSleepTimer(const Duration(minutes: 15));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sleep timer set for 15 minutes"),
                  ),
                );
              },
            ),
            SimpleDialogOption(
              child: const Text("30 minutes"),
              onPressed: () {
                provider.startSleepTimer(const Duration(minutes: 30));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sleep timer set for 30 minutes"),
                  ),
                );
              },
            ),
            SimpleDialogOption(
              child: const Text("60 minutes"),
              onPressed: () {
                provider.startSleepTimer(const Duration(hours: 1));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sleep timer set for 1 hour")),
                );
              },
            ),
            SimpleDialogOption(
              child: const Text("Custom Time"),
              onPressed: () {
                Navigator.pop(context);
                _showCustomSleepTimerPicker(context, provider);
              },
            ),
            SimpleDialogOption(
              child: const Text("Cancel Timer"),
              onPressed: () {
                provider.cancelSleepTimer();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sleep timer canceled")),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final music = Provider.of<MusicProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? Colors.grey[300]
              : Colors.grey[900],

      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // App title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'M E L O',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 6,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Drawer Items
                _buildMinimalItem(
                  context,
                  icon: Icons.arrow_back_ios_outlined,
                  label: 'Back to melo',
                  onTap: () => Navigator.pop(context),
                ),
                SizedBox(height: 15),

                _buildMinimalItem(
                  context,
                  icon: Icons.favorite_border,
                  label: 'Favorites',
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
                SizedBox(height: 15),

                _buildMinimalItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'Artist',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoriesOverviewPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: 15),

                _buildMinimalItem(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Sleep Timer',
                  onTap: () {
                    Navigator.pop(context);
                    _showSleepTimerDialog(context);
                  },
                ),
                SizedBox(height: 15),
                _buildMinimalItem(
                  context,
                  icon: Icons.info_outline,
                  label: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    );
                  },
                ),

                // Theme Toggle
                Consumer<ThemeProvider>(
                  builder:
                      (context, themeProvider, _) => Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  themeProvider.isDark
                                      ? Icons.dark_mode
                                      : Icons.light_mode,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).iconTheme.color?.withOpacity(0.8),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  themeProvider.isDark
                                      ? 'Light Mode'
                                      : 'Dark Mode',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: themeProvider.isDark,
                              onChanged: (value) {
                                themeProvider.toggleTheme();
                              },
                              activeColor:
                                  Colors.grey, // Neutral tone for both themes
                            ),
                          ],
                        ),
                      ),
                ),
                Spacer(),
                // Footer
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12.0,
                    left: 10,
                    right: 10,
                    top: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '          v1.0.0      © 2025 MELO     Made by aj_labs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.6),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
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
                        icon: Icon(
                          Icons.menu,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black26
                                  : Colors.white54,
                        ),
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
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : Consumer<MusicProvider>(
                                builder: (context, provider, _) {
                                  final textColor =
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white;

                                  final isTimerActive =
                                      provider.remainingTime > Duration.zero;
                                  // Or if you added isTimerActive getter:
                                  // final isTimerActive = provider.isTimerActive;

                                  if (isTimerActive) {
                                    final minutes = provider
                                        .remainingTime
                                        .inMinutes
                                        .remainder(60)
                                        .toString()
                                        .padLeft(2, '0');
                                    final seconds = provider
                                        .remainingTime
                                        .inSeconds
                                        .remainder(60)
                                        .toString()
                                        .padLeft(2, '0');

                                    return Text(
                                      '$minutes:$seconds',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    );
                                  } else {
                                    return Text(
                                      'M  E  L  O',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    );
                                  }
                                },
                              ),
                    ),
                  ),

                  // Refresh button
                  SizedBox(
                    height: 60,
                    width: 60,
                    child: NeuBox(
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black26
                                  : Colors.white54,
                        ),
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
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black26
                                  : Colors.white54,
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
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.black
                              : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black45
                                : Colors.white54,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color:
                            Theme.of(context).brightness == Brightness.light
                                ? Colors.black45
                                : Colors.white54,
                      ),
                      suffixIcon:
                          music.searchQuery.isNotEmpty
                              ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                ),
                                onPressed: () {
                                  music.searchController.clear();
                                  music.updateSearchQuery('');
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      fillColor:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[300]
                              : Colors.grey[800],
                      filled: true,
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // Song list
              Expanded(
                child:
                    music.loading
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/lottie/loading.json',
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                              Text(
                                'Searching for songs!!!',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : music.filteredPlaylist.isEmpty
                        ? Center(
                          child: Text(
                            "No songs found",
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black54
                                      : Colors.white70,
                            ),
                          ),
                        )
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
                                          ? (Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.black
                                              : Colors.cyan)
                                          : (Theme.of(context).brightness ==
                                                  Brightness.light
                                              ? Colors.grey[600]
                                              : Colors.grey[400]),
                                  size: 28,
                                ),
                                title:
                                    isCurrent
                                        ? SizedBox(
                                          height:
                                              20, // Adjust height to fit your design
                                          child: Marquee(
                                            text: file.path.split('/').last,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic,
                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.light
                                                      ? const Color.fromARGB(
                                                        255,
                                                        27,
                                                        28,
                                                        27,
                                                      )
                                                      : Colors.cyan,
                                            ),
                                            scrollAxis: Axis.horizontal,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            blankSpace: 30.0,
                                            velocity: 25.0,
                                            pauseAfterRound: Duration(
                                              seconds: 1,
                                            ),
                                            startPadding: 10.0,
                                            accelerationDuration: Duration(
                                              seconds: 1,
                                            ),
                                            accelerationCurve: Curves.linear,
                                            decelerationDuration: Duration(
                                              milliseconds: 500,
                                            ),
                                            decelerationCurve: Curves.easeOut,
                                          ),
                                        )
                                        : Text(
                                          file.path.split('/').last,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontStyle: FontStyle.normal,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.grey[700]
                                                    : Colors.grey[300],
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
                                            ? (Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.grey[500]
                                                : Colors.grey[300])
                                            : (Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.grey
                                                : Colors.grey[400]),
                                  ),
                                  onPressed:
                                      () => music.toggleFavorite(file.path),
                                ),
                              ),
                            );
                          },
                        ),
              ),

              // Mini Player with expand/collapse
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
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey[300]
                              : Colors.grey[850],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.3),
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
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.purple.shade100
                                            : Colors.purple.shade800,
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
                                  icon: Icon(
                                    Icons.skip_previous,
                                    size: 24,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey
                                            : Colors.grey.shade800,
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
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.grey
                                                : Colors.grey.shade800,
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
                                  icon: Icon(
                                    Icons.skip_next,
                                    size: 24,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey
                                            : Colors.grey.shade800,
                                  ),
                                  onPressed: music.next,
                                ),
                              ),

                              // Song Title with Marquee & Open Icon
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
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,

                                              color:
                                                  Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.light
                                                      ? Colors.grey.shade800
                                                      : Colors.cyan,
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
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
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
                                    player.duration ??
                                    const Duration(seconds: 1);

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
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withOpacity(0.7),
                                                ),
                                              ),
                                              Expanded(
                                                child: Slider(
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
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.light
                                                          ? const Color.fromARGB(
                                                            255,
                                                            59,
                                                            147,
                                                            61,
                                                          )
                                                          : Colors
                                                              .cyan
                                                              .shade800,
                                                  inactiveColor:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.light
                                                          ? Colors.grey[400]
                                                          : Colors.grey[900],
                                                  onChanged: (value) {
                                                    player.seek(
                                                      Duration(
                                                        milliseconds:
                                                            value.toInt(),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),

                                              Text(
                                                _formatDuration(duration),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withOpacity(0.7),
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

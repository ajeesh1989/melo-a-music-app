// import 'dart:io';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';

// class NowPlayingScreen extends StatelessWidget {
//   final AudioPlayer player;
//   final File currentSong;
//   final Uint8List? albumArt;

//   const NowPlayingScreen({
//     super.key,
//     required this.player,
//     required this.currentSong,
//     required this.albumArt,
//   });

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$minutes:$seconds';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text("Now Playing"),
//         backgroundColor: Colors.black,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             if (albumArt != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Image.memory(albumArt!, height: 250),
//               )
//             else
//               Container(
//                 height: 250,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[800],
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Icon(
//                   Icons.music_note,
//                   size: 100,
//                   color: Colors.white70,
//                 ),
//               ),
//             const SizedBox(height: 20),
//             Text(
//               currentSong.path.split('/').last,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             StreamBuilder<Duration?>(
//               stream: player.durationStream,
//               builder: (context, snapshotDuration) {
//                 final duration = snapshotDuration.data ?? Duration.zero;

//                 return StreamBuilder<Duration>(
//                   stream: player.positionStream,
//                   builder: (context, snapshotPosition) {
//                     final position = snapshotPosition.data ?? Duration.zero;

//                     return Column(
//                       children: [
//                         Slider(
//                           min: 0,
//                           max: duration.inMilliseconds.toDouble(),
//                           value:
//                               position.inMilliseconds
//                                   .clamp(0, duration.inMilliseconds)
//                                   .toDouble(),
//                           onChanged: (value) {
//                             player.seek(Duration(milliseconds: value.toInt()));
//                           },
//                           activeColor: Colors.pinkAccent,
//                           inactiveColor: Colors.grey,
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _formatDuration(position),
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                             Text(
//                               _formatDuration(duration),
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 30),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.skip_previous),
//                               onPressed: () => player.seekToPrevious(),
//                               iconSize: 40,
//                               color: Colors.white,
//                             ),
//                             StreamBuilder<PlayerState>(
//                               stream: player.playerStateStream,
//                               builder: (context, snapshot) {
//                                 final playing = snapshot.data?.playing ?? false;
//                                 return IconButton(
//                                   icon: Icon(
//                                     playing
//                                         ? Icons.pause_circle
//                                         : Icons.play_circle,
//                                     color: Colors.pinkAccent,
//                                   ),
//                                   iconSize: 60,
//                                   onPressed: () {
//                                     if (player.playing) {
//                                       player.pause();
//                                     } else {
//                                       player.play();
//                                     }
//                                   },
//                                 );
//                               },
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.skip_next),
//                               onPressed: () => player.seekToNext(),
//                               iconSize: 40,
//                               color: Colors.white,
//                             ),
//                           ],
//                         ),
//                       ],
//                     );
//                   },
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

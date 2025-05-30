import 'package:flutter/material.dart';
import 'package:retrowave/controller/music_controller.dart';
import 'package:retrowave/home.dart';

// main.dart
import 'package:provider/provider.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // await MetadataGod.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => MusicProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'm e l o',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: MusicHomePage(),
    );
  }
}

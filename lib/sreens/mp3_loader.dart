// lib/screens/mp3_loader.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class Mp3Loader extends StatefulWidget {
  const Mp3Loader({super.key});

  @override
  _Mp3LoaderState createState() => _Mp3LoaderState();
}

class _Mp3LoaderState extends State<Mp3Loader> {
  List<FileSystemEntity> mp3Files = [];

  @override
  void initState() {
    super.initState();
    requestPermissionAndLoadFiles();
  }

  Future<void> requestPermissionAndLoadFiles() async {
    PermissionStatus status = await Permission.audio.request();

    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      loadMp3Files();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Permission denied')));
    }
  }

  Future<void> loadMp3Files() async {
    List<FileSystemEntity> allFiles = [];

    Directory? musicDir = await getExternalStorageDirectory();
    if (musicDir != null) {
      final musicFolder = Directory(musicDir.path);
      allFiles =
          musicFolder
              .listSync(recursive: true, followLinks: false)
              .where((item) => item.path.toLowerCase().endsWith('.mp3'))
              .toList();
    }

    if (allFiles.isEmpty) {
      final fallbackDir = Directory('/storage/emulated/0/Music');
      if (await fallbackDir.exists()) {
        allFiles =
            fallbackDir
                .listSync(recursive: true, followLinks: false)
                .where((item) => item.path.toLowerCase().endsWith('.mp3'))
                .toList();
      }
    }

    setState(() {
      mp3Files = allFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MP3 Files")),
      body:
          mp3Files.isEmpty
              ? Center(child: Text("No MP3 files found"))
              : ListView.builder(
                itemCount: mp3Files.length,
                itemBuilder: (context, index) {
                  final file = mp3Files[index];
                  return ListTile(title: Text(file.path.split('/').last));
                },
              ),
    );
  }
}

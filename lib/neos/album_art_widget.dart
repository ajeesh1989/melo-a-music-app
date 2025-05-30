import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:retrowave/controller/music_controller.dart';

class AlbumArtWidget extends StatelessWidget {
  final double width;
  final double height;

  const AlbumArtWidget({
    this.width = double.infinity,
    this.height = 250,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    final imageProvider = musicProvider.albumArtImageProvider;

    final fallbackImage = Image.network(
      'https://cdn-images.dzcdn.net/images/cover/ba03f373d0f4ecfce750a899683b2b4c/0x1900-000000-80-0-0.jpg',
      fit: BoxFit.cover,
      width: width,
      height: height,
    );

    if (imageProvider == null) {
      return fallbackImage;
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => fallbackImage,
    );
  }
}

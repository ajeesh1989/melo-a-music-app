import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

class FFmpegService {
  static Future<String?> extractAlbumArt(String musicFilePath) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/album_art.jpg';

      // Run FFmpeg command to extract album art
      final session = await FFmpegKit.execute(
        '-i "$musicFilePath" -an -vcodec copy "$outputPath"',
      );

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        final file = File(outputPath);
        if (await file.exists()) {
          return file.path;
        }
      }
    } catch (e) {
      print('Failed to extract album art: $e');
    }

    return null;
  }
}

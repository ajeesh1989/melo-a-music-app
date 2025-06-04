import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    // Forward player events to the audio service
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: _player.playing,
        processingState:
            {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );

    // Handle when audio finishes playing
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // You can add logic to move to next song or stop
      }
    });
  }

  // Play from a URL or file path
  Future<void> playMedia(String uri) async {
    await _player.setAudioSource(AudioSource.uri(Uri.parse(uri)));
    _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // TODO: Implement skip to next track
  }

  @override
  Future<void> skipToPrevious() async {
    // TODO: Implement skip to previous track
  }
}

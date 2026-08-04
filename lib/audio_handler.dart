import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    // Listen to playback state changes and broadcast them to the system (lock screen)
    _player.playbackEventStream.listen(_broadcastState);
    _loadTestTrack(); // Load a track immediately for testing
  }

  Future<void> _loadTestTrack() async {
    final item = MediaItem(
      id: 'test_track_1',
      title: 'Royalty Free Test Track',
      artist: 'Bensound',
      album: 'Test Album',
      artUri: Uri.parse('https://www.bensound.com/bensound-img/epic.jpg'),
    );

    mediaItem.add(item);

    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse('https://www.bensound.com/bensound-music/bensound-epic.mp3'),
      ));
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));
  }
}
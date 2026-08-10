import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  // Creates an empty playlist that we can dynamically push local files into
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Broadcast playback state changes to the system lock screen
    _player.playbackEventStream.listen(_broadcastState);
    
    // Listen to track changes to update the notification/lock screen details
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    try {
      // Connect the empty playlist to the audio engine
      await _player.setAudioSource(_playlist);
    } catch (e) {
      print("Error initializing audio source: $e");
    }
  }

  /// Takes the list of local MP3s from the home screen and loads them into the engine
  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    queue.add(newQueue);
    
    // Convert the incoming MediaItems into just_audio local file sources
    final audioSources = newQueue.map((item) {
      // We will pass the local file path as the item.id
      return AudioSource.uri(Uri.parse(item.id), tag: item);
    }).toList();
    
    await _playlist.clear();
    await _playlist.addAll(audioSources);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Fires when the user taps Next on the lock screen or in the app
  @override
  Future<void> skipToNext() => _player.seekToNext();

  /// Fires when the user taps Previous on the lock screen or in the app
  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// Allows jumping straight to a specific song in the playlist when tapped
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
    play();
  }

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
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'audio_handler.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize the background audio service
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.gomusic.app.channel.audio',
      androidNotificationChannelName: 'GoMusic Playback',
      androidNotificationOngoing: true,
    ),
  );
  
  // 3. Register it globally
  getIt.registerSingleton<AudioHandler>(audioHandler);

  // 4. Run the app
  runApp(const GoMusicApp());
}

class GoMusicApp extends StatelessWidget {
  const GoMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoMusic',
      theme: ThemeData.dark(useMaterial3: true),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatelessWidget {
  const AudioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = getIt<AudioHandler>();

    return Scaffold(
      appBar: AppBar(title: const Text('GoMusic Engine Test')),
      body: Center(
        child: StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;

            return IconButton(
              iconSize: 100,
              color: Colors.blueAccent,
              icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
              onPressed: () {
                if (playing) {
                  audioHandler.pause();
                } else {
                  audioHandler.play();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
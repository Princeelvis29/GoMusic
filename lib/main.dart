import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'audio_handler.dart';
import 'widgets/main_navigation.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize AdMob
  await MobileAds.instance.initialize();

  // Initialize the background audio service engine
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.gomusic.app.channel.audio',
      androidNotificationChannelName: 'GoMusic Playback',
      androidNotificationOngoing: true,
    ),
  );
  
  getIt.registerSingleton<AudioHandler>(audioHandler);

  runApp(const GoMusicApp());
}

class GoMusicApp extends StatelessWidget {
  const GoMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoMusic',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrange, // Matches the VLC orange vibe
        ),
      ),
      home: const MainNavigationShell(), 
    );
  }
}
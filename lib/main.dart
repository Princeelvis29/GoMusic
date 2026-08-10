import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'audio_handler.dart';

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
          primary: Colors.blueAccent,
        ),
      ),
      home: const SongListScreen(),
    );
  }
}

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  // AdMob Banner Variables
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111'; // Google Test ID

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadBannerAd();
  }

  Future<void> _checkPermissions() async {
    bool hasPermission = await _audioQuery.checkAndRequest(
      retryRequest: true,
    );
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner Ad failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GoMusic - Local Library')),
      body: Column(
        children: [
          Expanded(
            child: !_hasPermission
                ? const Center(child: Text("Storage permission required to scan for music."))
                : FutureBuilder<List<SongModel>>(
                    future: _audioQuery.querySongs(
                      sortType: null,
                      orderType: OrderType.ASC_OR_SMALLER,
                      uriType: UriType.EXTERNAL,
                      ignoreCase: true,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No MP3 files found on this device."));
                      }

                      final songs = snapshot.data!;

                      return ListView.builder(
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.music_note, color: Colors.blueAccent),
                              ),
                            ),
                            title: Text(
                              song.title, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(song.artist ?? "Unknown Artist", style: TextStyle(color: Colors.grey[400])),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onSelected: (value) {
                                print("Menu option selected: $value");
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(value: 'play_next', child: Text('Play Next')),
                                const PopupMenuItem<String>(value: 'add_playlist', child: Text('Add to Playlist')),
                                const PopupMenuItem<String>(value: 'share', child: Text('Share')),
                              ],
                            ),
                            onTap: () async {
                              // MAGIC HAPPENS HERE: Convert local MP3s to a queue and push to engine
                              final audioHandler = getIt<AudioHandler>();
                              
                              final mediaItems = songs.map((s) => MediaItem(
                                id: s.data, // just_audio needs the raw file path here
                                title: s.title,
                                artist: s.artist ?? "Unknown Artist",
                                duration: Duration(milliseconds: s.duration ?? 0),
                                extras: {
                                  'id': s.id, // Save ID so NowPlayingScreen can grab artwork
                                  'size': s.size,
                                  'data': s.data,
                                },
                              )).toList();

                              await audioHandler.updateQueue(mediaItems);
                              await audioHandler.skipToQueueItem(index);
                              await audioHandler.play();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NowPlayingScreen(),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          
          if (_isAdLoaded && _bannerAd != null)
            SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final audioHandler = getIt<AudioHandler>();
  
  bool _isStarred = false;
  bool _isShuffle = false;
  bool _isRepeat = false;
  double _playbackSpeed = 1.0;

  @override
  void dispose() {
    super.dispose();
  }

  void _showShareMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share via", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareIcon(Icons.bluetooth, "Bluetooth", Colors.blue),
                _buildShareIcon(Icons.share, "Quick Share", Colors.lightBlue),
                _buildShareIcon(Icons.mail, "Gmail", Colors.red),
                _buildShareIcon(Icons.message, "Messages", Colors.green),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 25, backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color, size: 28)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showTrashConfirmation() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: 200,
        child: Column(
          children: [
            const Icon(Icons.delete_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Files will move to Trash", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800]),
                onPressed: () => Navigator.pop(context),
                child: const Text("Move 1 file to Trash", style: TextStyle(color: Colors.blueAccent)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showStorageOptions(String title) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text("Internal storage"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.sd_storage),
              title: const Text("SD card"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileInfo(MediaItem currentMedia) {
    // Safely parse the original size injected from the home screen
    String fileSize = "Unknown Size";
    double mb = (currentMedia.extras?['size'] ?? 0) / (1024 * 1024);
    fileSize = "${mb.toStringAsFixed(2)} MB";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.music_note, size: 50, color: Colors.blueAccent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentMedia.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(fileSize, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 40),
            _buildInfoRow("Kind", "MP3"),
            const SizedBox(height: 20),
            _buildInfoRow("Location", currentMedia.extras?['data'] ?? "Unknown Location"),
            const SizedBox(height: 20),
            _buildInfoRow("Artist", currentMedia.artist ?? "Unknown Artist"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  void _showPlaybackSpeed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            height: 200,
            child: Column(
              children: [
                const Text("Playback speed", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 10),
                Text("${_playbackSpeed}x", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Slider(
                  value: _playbackSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey[800],
                  onChanged: (val) {
                    setModalState(() => _playbackSpeed = val); 
                    setState(() {
                      _playbackSpeed = val;
                      audioHandler.setSpeed(val);
                    });      
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("0.5", style: TextStyle(color: Colors.grey)),
                    Text("1.0", style: TextStyle(color: Colors.grey)),
                    Text("2.0", style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The StreamBuilder constantly listens to the engine to fetch the exact song playing
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        int? songId = mediaItem.extras?['id'] as int?;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: _showShareMenu),
              IconButton(
                icon: Icon(_isStarred ? Icons.star : Icons.star_border, color: _isStarred ? Colors.amber : Colors.white),
                onPressed: () {
                  setState(() => _isStarred = !_isStarred);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isStarred ? "Added to Starred" : "Removed from Starred"),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(label: 'View', onPressed: () {}),
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'trash': _showTrashConfirmation(); break;
                    case 'move': _showStorageOptions('Move to'); break;
                    case 'copy': _showStorageOptions('Copy to'); break;
                    case 'info': _showFileInfo(mediaItem); break;
                    case 'ringtone': ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This song was set as your ringtone."))); break;
                    case 'speed': _showPlaybackSpeed(); break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'open_with', child: Text('Open with')),
                  const PopupMenuItem<String>(value: 'trash', child: Text('Move to Trash')),
                  const PopupMenuItem<String>(value: 'move', child: Text('Move to')),
                  const PopupMenuItem<String>(value: 'copy', child: Text('Copy to')),
                  const PopupMenuItem<String>(value: 'safe', child: Text('Move to Safe folder')),
                  const PopupMenuItem<String>(value: 'info', child: Text('File info')),
                  const PopupMenuItem<String>(value: 'ringtone', child: Text('Set as ringtone')),
                  const PopupMenuItem<String>(value: 'speed', child: Text('Playback speed')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  children: [
                    Container(
                      height: 320, width: 320,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: songId != null 
                        ? QueryArtworkWidget(
                            id: songId,
                            type: ArtworkType.AUDIO,
                            artworkHeight: 320,
                            artworkWidth: 320,
                            nullArtworkWidget: const Icon(Icons.music_note, size: 120, color: Colors.blueAccent),
                          )
                        : const Icon(Icons.music_note, size: 120, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 40),
                    Text(mediaItem.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), maxLines: 1),
                    const SizedBox(height: 8),
                    Text(mediaItem.artist ?? "Unknown Artist", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 40),
                    
                    // TRUE PROGRESS BAR: Listens directly to the engine output
                    StreamBuilder<Duration>(
                      stream: AudioService.position,
                      builder: (context, positionSnapshot) {
                        final position = positionSnapshot.data ?? Duration.zero;
                        final duration = mediaItem.duration ?? Duration.zero;
                        
                        double progressValue = 0.0;
                        if (duration.inMilliseconds > 0) {
                          progressValue = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
                        }

                        return SliderTheme(
                          data: SliderThemeData(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                          child: Slider(
                            value: progressValue,
                            onChanged: (val) {
                              final newPosition = Duration(milliseconds: (val * duration.inMilliseconds).round());
                              audioHandler.seek(newPosition);
                            },
                            activeColor: Colors.blueAccent, inactiveColor: Colors.grey[800],
                          ),
                        );
                      }
                    ),
                    
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          iconSize: 28, color: _isShuffle ? Colors.blueAccent : Colors.grey[400],
                          icon: const Icon(Icons.shuffle), onPressed: () => setState(() => _isShuffle = !_isShuffle),
                        ),
                        IconButton(
                          iconSize: 40, color: Colors.white, icon: const Icon(Icons.skip_previous),
                          onPressed: () => audioHandler.skipToPrevious(), // Connected to engine
                        ),
                        
                        // TRUE PLAY/PAUSE: Evaluates if engine is actively playing
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, stateSnapshot) {
                            final playing = stateSnapshot.data?.playing ?? false;
                            return SizedBox(
                              height: 70, width: 70,
                              child: FloatingActionButton(
                                elevation: 0, backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                                onPressed: () {
                                  if (playing) {
                                    audioHandler.pause();
                                  } else {
                                    audioHandler.play();
                                  }
                                }, 
                                shape: const CircleBorder(),
                                child: Icon(playing ? Icons.pause : Icons.play_arrow, size: 38),
                              ),
                            );
                          }
                        ),
                        
                        IconButton(
                          iconSize: 40, color: Colors.white, icon: const Icon(Icons.skip_next),
                          onPressed: () => audioHandler.skipToNext(), // Connected to engine
                        ),
                        IconButton(
                          iconSize: 28, color: _isRepeat ? Colors.blueAccent : Colors.grey[400],
                          icon: const Icon(Icons.repeat), onPressed: () => setState(() => _isRepeat = !_isRepeat),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
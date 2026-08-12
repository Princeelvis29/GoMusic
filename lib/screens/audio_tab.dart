import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import '../main.dart'; 
import '../services/database_helper.dart'; 

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _hasPermission = false;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111'; 

  // Search state variables
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildArtistsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: FutureBuilder<List<ArtistModel>>(
        future: _audioQuery.queryArtists(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data == null || snapshot.data!.isEmpty) return const Center(child: Text("No artists found.", style: TextStyle(color: Colors.grey)));

          final artists = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(12)),
                      child: QueryArtworkWidget(
                        id: artist.id,
                        type: ArtworkType.ARTIST,
                        artworkBorder: BorderRadius.circular(12),
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: const Center(child: Icon(Icons.person_outline, size: 60, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(artist.artist, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("${artist.numberOfAlbums ?? 0} albums • ${artist.numberOfTracks ?? 0} tracks", style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: FutureBuilder<List<AlbumModel>>(
        future: _audioQuery.queryAlbums(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.data == null || snapshot.data!.isEmpty) return const Center(child: Text("No albums found.", style: TextStyle(color: Colors.grey)));

          final albums = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75, 
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(12)),
                      child: QueryArtworkWidget(
                        id: album.id,
                        type: ArtworkType.ALBUM,
                        artworkBorder: BorderRadius.circular(12),
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: const Center(child: Icon(Icons.album, size: 60, color: Colors.grey)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(album.album, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("${album.numOfSongs} tracks", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTracksTab() {
    return Column(
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
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (snapshot.data == null || snapshot.data!.isEmpty) return const Center(child: Text("No MP3 files found on this device."));

                    // Apply the search filter here
                    final allSongs = snapshot.data!;
                    final songs = _searchQuery.isEmpty 
                        ? allSongs 
                        : allSongs.where((song) => 
                            song.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            (song.artist?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                          ).toList();

                    if (songs.isEmpty) return const Center(child: Text("No matches found."));

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
                              decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.music_note, color: Colors.blueAccent),
                            ),
                          ),
                          title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(song.artist ?? "Unknown Artist", style: TextStyle(color: Colors.grey[400])),
                          ),
                          onTap: () async {
                            final audioHandler = getIt<AudioHandler>();
                            final mediaItems = songs.map((s) => MediaItem(
                              id: s.data,
                              title: s.title,
                              artist: s.artist ?? "Unknown Artist",
                              duration: Duration(milliseconds: s.duration ?? 0),
                              extras: {'id': s.id, 'size': s.size, 'data': s.data},
                            )).toList();

                            await DatabaseHelper.instance.logPlay(song.title, song.artist ?? "Unknown Artist");

                            await audioHandler.updateQueue(mediaItems);
                            await audioHandler.skipToQueueItem(index);
                            await audioHandler.play();

                            if (context.mounted) {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const NowPlayingScreen()));
                            }
                          },
                        );
                      },
                    );
                  },
                ),
        ),
        if (_isAdLoaded && _bannerAd != null)
          SafeArea(child: SizedBox(width: _bannerAd!.size.width.toDouble(), height: _bannerAd!.size.height.toDouble(), child: AdWidget(ad: _bannerAd!))),
      ],
    );
  }

  Widget _buildGenresTab() {
    return FutureBuilder<List<GenreModel>>(
      future: _audioQuery.queryGenres(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.data == null || snapshot.data!.isEmpty) return const Center(child: Text("No genres found.", style: TextStyle(color: Colors.grey)));

        final genres = snapshot.data!;
        return ListView.builder(
          itemCount: genres.length,
          itemBuilder: (context, index) {
            final genre = genres[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(8)),
                child: QueryArtworkWidget(
                  id: genre.id,
                  type: ArtworkType.GENRE,
                  nullArtworkWidget: const Icon(Icons.category, color: Colors.deepOrange),
                ),
              ),
              title: Text(genre.genre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text("${genre.numOfSongs ?? 0} tracks", style: TextStyle(color: Colors.grey[400])),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, 
      initialIndex: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search music...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
              : const Text('Audio', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E1E1E), 
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = "";
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            )
          ],
          bottom: const TabBar(
            isScrollable: true, 
            indicatorColor: Colors.deepOrange, 
            labelColor: Colors.deepOrange, 
            unselectedLabelColor: Colors.grey, 
            indicatorWeight: 3.0,
            tabs: [Tab(text: 'ARTISTS'), Tab(text: 'ALBUMS'), Tab(text: 'TRACKS'), Tab(text: 'GENRES')],
          ),
        ),
        body: TabBarView(
          children: [_buildArtistsTab(), _buildAlbumsTab(), _buildTracksTab(), _buildGenresTab()],
        ),
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
  
  SharedPreferences? _prefs;
  StreamSubscription? _mediaSubscription;

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _prefs = await SharedPreferences.getInstance();
    
    if (mounted) {
      setState(() {
        _playbackSpeed = _prefs?.getDouble('playback_speed') ?? 1.0;
      });
      audioHandler.setSpeed(_playbackSpeed);
    }

    _mediaSubscription = audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null && mounted) {
        setState(() {
          _isStarred = _prefs?.getBool('starred_${mediaItem.id}') ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    _mediaSubscription?.cancel();
    super.dispose();
  }

  // Fallback system if device blocks native intent
  void _showEqualizer() async {
    try {
      await EqualizerFlutter.open(0);
    } catch (e) {
      _showCustomEqualizer();
    }
  }

  // Builds a custom flutter UI mapped directly to the hardware backend
  void _showCustomEqualizer() async {
    try {
      await EqualizerFlutter.init(0);
      final bands = await EqualizerFlutter.getBandLevelRange();
      final min = bands[0].toDouble();
      final max = bands[1].toDouble();
      final freqs = await EqualizerFlutter.getCenterBandFreqs();
      
      List<double> currentLevels = [];
      for (int i = 0; i < freqs.length; i++) {
        int level = await EqualizerFlutter.getBandLevel(i);
        currentLevels.add(level.toDouble());
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                height: 350,
                child: Column(
                  children: [
                    const Text("Custom Equalizer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(freqs.length, (idx) {
                          int freqHz = freqs[idx] ~/ 1000;
                          String label = freqHz >= 1000 ? "${(freqHz / 1000).toStringAsFixed(1)}k" : "$freqHz";
                          return Column(
                            children: [
                              Expanded(
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: currentLevels[idx].clamp(min, max),
                                    min: min,
                                    max: max,
                                    activeColor: Colors.deepOrange,
                                    inactiveColor: Colors.grey[800],
                                    onChanged: (val) {
                                      setModalState(() {
                                        currentLevels[idx] = val;
                                      });
                                      EqualizerFlutter.setBandLevel(idx, val.toInt());
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hardware equalizer completely blocked by OS.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) {
          return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        }

        int? songId = mediaItem.extras?['id'] as int?;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_isStarred ? Icons.star : Icons.star_border, color: _isStarred ? Colors.amber : Colors.white),
                onPressed: () {
                  setState(() {
                    _isStarred = !_isStarred;
                    if (mediaItem.id.isNotEmpty) _prefs?.setBool('starred_${mediaItem.id}', _isStarred);
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'equalizer': _showEqualizer(); break; 
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(value: 'equalizer', child: Text('Equalizer')), 
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
                            id: songId, type: ArtworkType.AUDIO, artworkHeight: 320, artworkWidth: 320,
                            nullArtworkWidget: const Icon(Icons.music_note, size: 120, color: Colors.blueAccent),
                          )
                        : const Icon(Icons.music_note, size: 120, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 40),
                    Text(mediaItem.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), maxLines: 1),
                    const SizedBox(height: 8),
                    Text(mediaItem.artist ?? "Unknown Artist", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 40),
                    
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
                      },
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
                          onPressed: () => audioHandler.skipToPrevious(),
                        ),
                        
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
                          },
                        ),
                        
                        IconButton(
                          iconSize: 40, color: Colors.white, icon: const Icon(Icons.skip_next),
                          onPressed: () => audioHandler.skipToNext(),
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
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:simple_pip_mode/simple_pip.dart'; 

class VideoListTab extends StatefulWidget {
  const VideoListTab({super.key});

  @override
  State<VideoListTab> createState() => _VideoListTabState();
}

class _VideoListTabState extends State<VideoListTab> {
  List<File> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _scanForVideos();
  }

  Future<void> _scanForVideos() async {
    List<File> foundVideos = [];
    
    // Standard public directories where videos live on Android
    List<String> searchPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Movies',
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Video'
    ];

    for (String path in searchPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final entities = dir.listSync(recursive: true, followLinks: false);
          for (var entity in entities) {
            if (entity is File && entity.path.toLowerCase().endsWith('.mp4')) {
              foundVideos.add(entity);
            }
          }
        } catch (e) {
          // Silently skip locked system folders to prevent crashes
        }
      }
    }

    if (mounted) {
      setState(() {
        _videos = foundVideos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
    }

    if (_videos.isEmpty) {
      return const Center(
        child: Text("No MP4 videos found in public folders.", style: TextStyle(color: Colors.grey)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0, 
        ),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          final fileName = video.path.split('/').last;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerScreen(videoFile: video),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(child: Icon(Icons.movie_creation_outlined, size: 50, color: Colors.grey)),
                  const Positioned(
                    bottom: 8,
                    right: 8,
                    child: Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 40,
                    child: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.file(widget.videoFile);
    await _videoPlayerController.initialize();
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio > 0 
          ? _videoPlayerController.value.aspectRatio 
          : 16 / 9,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.deepOrange,
        handleColor: Colors.deepOrange,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white,
      ),
    );
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.videoFile.path.split('/').last, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white),
            onPressed: () {
              // CHANGED: Removed the strict array type to let the package apply its 16:9 default natively
              SimplePip().enterPipMode();
            },
          ),
        ],
      ),
      body: Center(
        child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(color: Colors.deepOrange),
      ),
    );
  }
}
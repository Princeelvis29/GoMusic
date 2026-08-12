import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart'; 
import '../services/database_helper.dart';
import 'audio_tab.dart'; // Required to navigate to the NowPlayingScreen

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  Directory _currentDir = Directory('/storage/');
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndLoad();
  }

  Future<void> _requestPermissionsAndLoad() async {
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    _loadDirectory();
  }

  Future<List<FileSystemEntity>> _getStorageVolumes() async {
    List<FileSystemEntity> volumes = [];
    
    volumes.add(Directory('/storage/emulated/0'));
    
    try {
      final mountsFile = File('/proc/mounts');
      if (mountsFile.existsSync()) {
        final lines = mountsFile.readAsLinesSync();
        for (var line in lines) {
          if (line.contains('/storage/') && 
             (line.contains('vfat') || line.contains('exfat') || line.contains('sdcardfs') || line.contains('fuse'))) {
            final parts = line.split(' ');
            for (var part in parts) {
              if (part.startsWith('/storage/') && !part.contains('emulated') && !part.contains('self')) {
                final dir = Directory(part);
                if (dir.existsSync()) {
                  volumes.add(dir);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Mount parse error: $e");
    }

    if (volumes.length == 1) {
      try {
        final dirs = Directory('/storage/').listSync();
        for (var dir in dirs) {
          if (dir.path != '/storage/emulated' && dir.path != '/storage/self') {
             volumes.add(dir);
          }
        }
      } catch (e) {
         debugPrint("Root list error: $e");
      }
    }
    
    final seen = <String>{};
    volumes.retainWhere((v) => seen.add(v.path));
    
    return volumes;
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    
    final isRoot = _currentDir.path == '/storage/' || _currentDir.path == '/storage';
    
    try {
      if (isRoot) {
        _entities = await _getStorageVolumes();
      } else if (await _currentDir.exists()) {
        _entities = _currentDir.listSync(followLinks: false).toList();
        
        _entities.sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir && !bIsDir) return -1;
          if (!aIsDir && bIsDir) return 1;
          return a.path.toLowerCase().compareTo(b.path.toLowerCase());
        });
      } else {
        _entities = [];
      }
    } catch (e) {
      _entities = []; 
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _goUp() {
    if (_currentDir.path != '/storage/' && _currentDir.path != '/storage') {
      setState(() {
        _currentDir = _currentDir.parent;
      });
      _loadDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _currentDir.path == '/storage/' || _currentDir.path == '/storage';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRoot ? "Storage Volumes" : _currentDir.path.split('/').last,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        leading: isRoot 
          ? null 
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goUp,
            ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
        : _entities.isEmpty 
          ? const Center(child: Text("Folder is empty or access denied.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: _entities.length,
              itemBuilder: (context, index) {
                final entity = _entities[index];
                final isDir = entity is Directory;
                String name = entity.path.split('/').last;

                if (isRoot) {
                  if (entity.path == '/storage/emulated/0') {
                    name = "Internal Storage";
                  } else {
                    name = "SD Card ($name)";
                  }
                } else {
                  if (name == 'emulated' || name == 'self') {
                    return const SizedBox.shrink(); 
                  }
                }
                
                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file,
                    color: isDir ? Colors.amber : Colors.grey,
                    size: 40,
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    if (isDir) {
                      setState(() {
                        _currentDir = Directory(entity.path);
                      });
                      _loadDirectory();
                    } else {
                      // Check if the selected file is a supported audio format
                      final ext = name.toLowerCase();
                      if (ext.endsWith('.mp3') || ext.endsWith('.m4a') || ext.endsWith('.wav') || ext.endsWith('.aac') || ext.endsWith('.flac')) {
                        try {
                          final audioHandler = getIt<AudioHandler>();
                          
                          // Gather all audio files in the current folder to create a queue
                          final allAudioFiles = _entities.where((e) {
                            final n = e.path.toLowerCase();
                            return e is File && (n.endsWith('.mp3') || n.endsWith('.m4a') || n.endsWith('.wav') || n.endsWith('.aac') || n.endsWith('.flac'));
                          }).toList();
                          
                          // Convert them into MediaItems
                          final mediaItems = allAudioFiles.map((f) {
                            final fileName = f.path.split('/').last;
                            final cleanTitle = fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''); // Strip extension
                            return MediaItem(
                              id: f.path, // Use physical file path as ID
                              title: cleanTitle,
                              artist: "Local File",
                              extras: {'data': f.path},
                            );
                          }).toList();
                          
                          // Find the index of the file we just tapped
                          final initialIndex = allAudioFiles.indexWhere((f) => f.path == entity.path);
                          
                          final tappedTitle = name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                          await DatabaseHelper.instance.logPlay(tappedTitle, "Local File");
                          
                          // Update queue and play
                          await audioHandler.updateQueue(mediaItems);
                          await audioHandler.skipToQueueItem(initialIndex >= 0 ? initialIndex : 0);
                          await audioHandler.play();

                          if (context.mounted) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const NowPlayingScreen()));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error playing file: $e")),
                            );
                          }
                        }
                      } else {
                        // Not an audio file
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Format not supported: $name")),
                        );
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}
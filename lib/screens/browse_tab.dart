import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

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
    // Request "All Files Access" for modern Android devices
    if (await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    _loadDirectory();
  }

  // Parses Android system files to locate connected SD Cards
  Future<List<FileSystemEntity>> _getStorageVolumes() async {
    List<FileSystemEntity> volumes = [];
    
    // 1. Always ensure Internal Storage is available
    volumes.add(Directory('/storage/emulated/0'));
    
    // 2. Parse /proc/mounts to find the physical SD Card and bypass SELinux root blocks
    try {
      final mountsFile = File('/proc/mounts');
      if (mountsFile.existsSync()) {
        final lines = mountsFile.readAsLinesSync();
        for (var line in lines) {
          // Check for standard external filesystem formats
          if (line.contains('/storage/') && 
             (line.contains('vfat') || line.contains('exfat') || line.contains('sdcardfs') || line.contains('fuse'))) {
            final parts = line.split(' ');
            for (var part in parts) {
              // Extract the true SD card path and ignore internal symlinks
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

    // 3. Fallback to listSync if /proc/mounts is completely restricted
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
    
    // 4. Deduplicate volumes by absolute path just in case
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

                // Clean up UI names for root directories
                if (isRoot) {
                  if (entity.path == '/storage/emulated/0') {
                    name = "Internal Storage";
                  } else {
                    name = "SD Card ($name)";
                  }
                } else {
                  // Hide confusing system symlinks when browsing normally
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
                  onTap: () {
                    if (isDir) {
                      setState(() {
                        _currentDir = Directory(entity.path);
                      });
                      _loadDirectory();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Selected: $name")),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
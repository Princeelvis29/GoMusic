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

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      if (await _currentDir.exists()) {
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
      // FALLBACK: If the OS strictly blocks /storage/ listing via SELinux, 
      // manually inject the Internal Memory path so it is never blank.
      if (_currentDir.path == '/storage/' || _currentDir.path == '/storage') {
        _entities = [Directory('/storage/emulated/0')];
      } else {
        _entities = []; 
      }
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
                if (name == '0' && entity.path.contains('emulated')) {
                  name = "Internal Storage";
                } else if (name == 'emulated' || name == 'self') {
                  return const SizedBox.shrink(); // Hide confusing system symlinks
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
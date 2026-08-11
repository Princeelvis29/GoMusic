import 'package:flutter/material.dart';
import 'dart:io';

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key});

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  Directory _currentDir = Directory('/storage/emulated/0/');
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() => _isLoading = true);
    try {
      if (await _currentDir.exists()) {
        _entities = _currentDir.listSync(followLinks: false).toList();
        
        // Sort: Directories at the top, then files alphabetically
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
    if (_currentDir.path != '/storage/emulated/0/' && _currentDir.path != '/storage/emulated/0') {
      setState(() {
        _currentDir = _currentDir.parent;
      });
      _loadDirectory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRoot = _currentDir.path == '/storage/emulated/0/' || _currentDir.path == '/storage/emulated/0';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRoot ? "Internal Memory" : _currentDir.path.split('/').last,
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
                final name = entity.path.split('/').last;
                
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
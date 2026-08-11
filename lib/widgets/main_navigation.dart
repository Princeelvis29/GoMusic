import 'package:flutter/material.dart';
import '../screens/video_tab.dart';
import '../screens/audio_tab.dart';
import '../screens/browse_tab.dart';
import '../screens/playlists_tab.dart';
import '../screens/more_tab.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  // Set default index to 1 so it opens on the "Audio" tab just like VLC
  int _selectedIndex = 1; 

  // The different screens for each tab.
  final List<Widget> _screens = [
    const VideoListTab(),
    const SongListScreen(), 
    const BrowseTab(), 
    const PlaylistsTab(), 
    const MoreTab(), 
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, 
        backgroundColor: const Color(0xFF1E1E1E), 
        selectedItemColor: Colors.deepOrange, 
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie_creation_outlined), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Audio'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlists'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
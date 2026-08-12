import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../services/database_helper.dart'; 
import 'settings_screen.dart';
import '../main.dart';
import 'audio_tab.dart';

class MoreTab extends StatefulWidget {
  const MoreTab({super.key});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  
  void _showStreamDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text("Play Network Stream", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Paste stream URL or IP...",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context);
                _playStream(url);
              }
            },
            child: const Text("PLAY", style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  Future<void> _playStream(String url) async {
    try {
      final audioHandler = getIt<AudioHandler>();
      
      // Package the network stream URL into a MediaItem
      final mediaItem = MediaItem(
        id: url, // The audio player relies on this ID to fetch the network resource
        title: "Network Stream",
        artist: url, // Display the URL as the artist so the user knows what is playing
        extras: {'data': url},
      );
      
      await DatabaseHelper.instance.logPlay("Network Stream", url);
      
      // Update queue and play immediately
      await audioHandler.updateQueue([mediaItem]);
      await audioHandler.skipToQueueItem(0);
      await audioHandler.play();

      if (mounted) {
        // Refresh the history list on this screen
        setState(() {}); 
        // Push the user directly to the player UI
        Navigator.push(context, MaterialPageRoute(builder: (context) => const NowPlayingScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load stream: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoMusic', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.settings),
                    label: const Text("SETTINGS"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ).then((_) {
                        setState(() {}); 
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      side: const BorderSide(color: Colors.deepOrange),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.info_outline),
                    label: const Text("ABOUT"),
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'GoMusic for Android',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.deepOrange,
                          child: const Icon(Icons.music_note, size: 40, color: Colors.white),
                        ),
                        children: [
                          const Text("GoMusic is a powerful media player designed for your pleasure and comfort. The Android version can read all local files and directories.\n\nPowered and Developed by Arktech Solutions\nhttps://arktechsolution.top"),
                        ]
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Streams",
              style: TextStyle(color: Colors.deepOrange, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Wrapped the Stream UI block in an InkWell for interaction
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showStreamDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.deepOrange, size: 40),
                      SizedBox(height: 8),
                      Text("New stream", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              "History",
              style: TextStyle(color: Colors.deepOrange, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text(
                    "No playback history yet.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                final history = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history, color: Colors.deepOrange),
                      ),
                      title: Text(item['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item['artist'], style: const TextStyle(color: Colors.grey)),
                      onTap: () {
                        // Allows the user to replay a stream directly from their history
                        final possibleUrl = item['artist'];
                        if (possibleUrl.toString().startsWith('http')) {
                           _playStream(possibleUrl);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/database_helper.dart'; 

class MoreTab extends StatefulWidget {
  const MoreTab({super.key});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Settings menu coming soon")),
                      );
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
            Container(
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
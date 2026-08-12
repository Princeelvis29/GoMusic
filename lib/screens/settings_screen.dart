import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _highQualityAudio = true;
  bool _autoPlayNext = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highQualityAudio = prefs.getBool('high_quality_audio') ?? true;
      _autoPlayNext = prefs.getBool('auto_play_next') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text("Clear History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to clear your entire playback history? This cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // Assuming you have a clear method in your DatabaseHelper
              // await DatabaseHelper.instance.clearAllLogs(); 
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Playback history cleared."),
                    backgroundColor: Colors.deepOrange,
                  ),
                );
              }
            },
            child: const Text("CLEAR", style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF121212),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Playback", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          SwitchListTile(
            title: const Text("High Quality Audio", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Stream and play at the highest available bitrate", style: TextStyle(color: Colors.grey)),
            activeColor: Colors.deepOrange,
            value: _highQualityAudio,
            onChanged: (val) {
              setState(() => _highQualityAudio = val);
              _saveSetting('high_quality_audio', val);
            },
          ),
          SwitchListTile(
            title: const Text("Auto-play Next Track", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Automatically play the next song in the queue", style: TextStyle(color: Colors.grey)),
            activeColor: Colors.deepOrange,
            value: _autoPlayNext,
            onChanged: (val) {
              setState(() => _autoPlayNext = val);
              _saveSetting('auto_play_next', val);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.white24, thickness: 1),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text("Data & Storage", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.white),
            title: const Text("Clear Playback History", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Remove all recently played items from the More tab", style: TextStyle(color: Colors.grey)),
            onTap: _clearHistory,
          ),
        ],
      ),
    );
  }
}
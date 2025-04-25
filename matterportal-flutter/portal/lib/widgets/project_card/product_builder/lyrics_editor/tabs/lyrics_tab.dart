import 'package:flutter/material.dart';

class LyricsTab extends StatelessWidget {
  final TextEditingController lyricsController;
  final VoidCallback onChanged;

  const LyricsTab({
    super.key,
    required this.lyricsController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: lyricsController,
        maxLines: null,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Enter lyrics here...',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        onChanged: (text) {
          // TODO: Use logging framework
          // print('Lyrics text changed: "$text"');
          onChanged();
        },
      ),
    );
  }
}

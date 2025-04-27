import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal/Constants/fonts.dart';

class SyncTab extends StatefulWidget {
  final TextEditingController lyricsController;
  final Map<int, Duration> syncedLyrics;
  final ScrollController scrollController;
  final Function(String) onPlayLine;
  final Function(Duration) onSync;
  final Function() onUndo;
  final String Function(Duration) formatDuration;
  final bool isPlaying;
  final Duration currentPosition;
  final int currentLineIndex;

  const SyncTab({
    super.key,
    required this.lyricsController,
    required this.syncedLyrics,
    required this.scrollController,
    required this.onPlayLine,
    required this.onSync,
    required this.onUndo,
    required this.formatDuration,
    required this.isPlaying,
    required this.currentPosition,
    required this.currentLineIndex,
  });

  @override
  State<SyncTab> createState() => _SyncTabState();
}

class _SyncTabState extends State<SyncTab> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleDownArrow() {
    if (widget.isPlaying) {
      widget.onSync(widget.currentPosition);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _handleDownArrow();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        widget.onUndo();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lyricsController.text.split('\n');

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'How to Sync Lyrics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: fontNameBold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Press play to start the music\n'
                  '2. Press SYNC or ↓ when each line should appear\n'
                  '3. Press UNDO or ↑ to remove the last sync\n'
                  '4. Click on timestamps to preview timing',
                  style: TextStyle(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Lyrics list
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                final timestamp = widget.syncedLyrics[index];
                final isSelected = widget.syncedLyrics.containsKey(index);
                final isCurrentLine = index == widget.currentLineIndex;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentLine
                        ? Colors.blue.withOpacity(0.3)
                        : (isSelected
                            ? const Color(0xFF1E1B2C)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (timestamp != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => widget.onPlayLine(index.toString()),
                              child: Text(
                                widget.formatDuration(timestamp),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontFamily: fontNameSemiBold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      line.isEmpty ? ' ' : line,
                      style: TextStyle(
                        color: isCurrentLine ? Colors.white : Colors.grey,
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: isCurrentLine ? fontNameBold : fontName,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sync controls at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1B2C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Undo button
                ElevatedButton.icon(
                  onPressed: widget.onUndo,
                  icon: const Icon(Icons.undo, color: Colors.white),
                  label: const Text(
                    'UNDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontNameBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                // Sync button
                ElevatedButton.icon(
                  onPressed: widget.isPlaying ? _handleDownArrow : null,
                  icon: const Icon(Icons.timer, color: Colors.white),
                  label: const Text(
                    'SYNC',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontNameBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

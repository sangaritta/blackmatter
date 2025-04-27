import 'package:flutter/material.dart';
import 'package:portal/Services/audio_player_service.dart';

class AudioPreview extends StatefulWidget {
  final String fileName;
  final String fileUrl;
  final String title;
  final String artists;
  final String? artworkUrl;
  final bool isUploading;
  final Map<String, dynamic>? trackData;
  final Duration? duration;
  final Duration position;
  final bool isPlaying;
  final bool isLoading;
  final bool isInitialized;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;

  const AudioPreview({
    super.key,
    required this.fileName,
    required this.fileUrl,
    required this.title,
    required this.artists,
    this.artworkUrl,
    required this.isUploading,
    this.trackData,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.isLoading,
    required this.isInitialized,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  final _audioPlayer = audioPlayerService;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  Widget _buildAudioControls() {
    if (widget.isUploading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Audio preview will be available after upload completes',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (widget.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!widget.isInitialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Audio preview not available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final duration = widget.duration ?? const Duration(seconds: 1);
    final position = widget.position;
    final sliderValue = position.inMilliseconds
        .toDouble()
        .clamp(0, duration.inMilliseconds.toDouble())
        .toDouble();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
          color: Colors.white,
          onPressed: widget.onPlayPause,
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(position),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Slider(
            value: sliderValue,
            min: 0,
            max: duration.inMilliseconds.toDouble(),
            onChanged: (value) {
              widget.onSeek(Duration(milliseconds: value.round()));
            },
            activeColor: Colors.white,
            inactiveColor: Colors.grey[700],
          ),
        ),
        Text(
          _formatDuration(duration),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Track artwork
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFF1E1B2C),
                  ),
                  child: widget.artworkUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            widget.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.album,
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.album,
                          color: Colors.grey,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),

                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.artists,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Duration
                Text(
                  _formatDuration(widget.duration),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Audio player controls
            _buildAudioControls(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

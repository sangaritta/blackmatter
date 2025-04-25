import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:portal/services/storage_service.dart'; // Assuming StorageService is needed

// Initializes AudioService with our handler.
Future<AudioHandler> initAudioService() async {
  return await AudioService.init<
      AudioPlayerHandler>(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.blackmatter.portal.channel.audio',
      androidNotificationChannelName: 'Portal Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      // Add other platform-specific configurations as needed
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  MediaItem? _loadedMediaItem;
  final StorageService _storageService = StorageService(); // If needed for URLs

  AudioPlayerHandler() {
    // Listen to playback states from the player and broadcast them.
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Handle errors (optional but recommended)
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        stop(); // Or handle completion differently
      }
    });

    // Listen for duration changes
    _player.durationStream.listen((duration) {
        if (_loadedMediaItem != null && duration != null) {
           final updatedItem = _loadedMediaItem!.copyWith(duration: duration);
           mediaItem.add(updatedItem);
           _loadedMediaItem = updatedItem;
        }
    });
  }

  // --- Override Methods --- 

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  // Custom method to load a media item (replace initializeAudio)
  Future<void> loadMediaItem({
    required String id,
    required String title,
    required String artist,
    String? album,
    String? artworkUrl,
    String? downloadUrl,
    String? storagePath,
    required String fileUrl, // The primary URL or path
  }) async {
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
    ));

    String? effectiveAudioUrl;
    try {
      // Logic to determine the final audio URL (similar to AudioPlayerService)
      if (downloadUrl != null) {
        effectiveAudioUrl = downloadUrl;
      } else if (storagePath != null) {
        effectiveAudioUrl = await _storageService.getDownloadURL(storagePath);
      } else if (fileUrl.isNotEmpty) {
        if (fileUrl.startsWith('http')) {
          effectiveAudioUrl = fileUrl;
        } else {
          effectiveAudioUrl = await _storageService.getDownloadURL(fileUrl);
        }
      }

      if (effectiveAudioUrl == null) {
        throw Exception('No valid audio URL could be determined.');
      }

      final mediaItemData = MediaItem(
        id: id, 
        title: title,
        artist: artist,
        album: album ?? 'Single',
        artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
        extras: {'url': effectiveAudioUrl}, // Store URL in extras
      );

      await _player.setAudioSource(AudioSource.uri(Uri.parse(effectiveAudioUrl)));
      
      // Broadcast the loaded media item
      mediaItem.add(mediaItemData.copyWith(duration: _player.duration));
      _loadedMediaItem = mediaItemData.copyWith(duration: _player.duration);

      playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
          // updateTime: Duration.zero // Reset position if needed
      ));

    } catch (e) {
      print('Error loading media item: $e');
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: e.toString(),
      ));
      // Optionally broadcast a null media item or keep the old one
      mediaItem.add(null);
       _loadedMediaItem = null;
    }
  }

  // --- Helper Methods --- 

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _getProcessingState(event.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioProcessingState _getProcessingState(
      ProcessingState processingState) {
    switch (processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      // Default case removed as all enum values are handled
    }
  }
  
  @override
  Future<void> onTaskRemoved() async {
      await stop();
      await _player.dispose();
      super.onTaskRemoved();
  }

   @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      await super.stop(); // Stop the service
    }
    // Handle other custom actions if needed
  }

}

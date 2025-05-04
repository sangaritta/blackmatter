import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:audio_service/audio_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  AudioPlayer player = AudioPlayer();

  // State variables
  Duration? duration;
  Duration position = Duration.zero;
  bool isPlaying = false;
  bool isLoading = true;
  bool isInitialized = false;
  StreamController<Duration> positionController =
      StreamController<Duration>.broadcast();
  StreamController<bool> playingController = StreamController<bool>.broadcast();
  StreamController<Duration?> durationController =
      StreamController<Duration?>.broadcast();
  StreamController<bool> loadingController = StreamController<bool>.broadcast();
  StreamController<bool> initializedController =
      StreamController<bool>.broadcast();

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal() {
    _initStreams();
  }

  void _initStreams() {
    player.positionStream.listen((pos) {
      position = pos;
      positionController.add(pos);
    });

    player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      playingController.add(state.playing);
    });
  }

  Future<void> initializeAudio({
    required String? downloadUrl,
    required String fileUrl,
    required String title,
    required String artist,
    String? artworkUrl,
  }) async {
    try {
      isLoading = true;
      isInitialized = false;
      loadingController.add(true);
      initializedController.add(false);

      // Stop any existing playback
      await player.stop();
      await player.dispose();

      // Create new player instance while maintaining service singleton
      player = AudioPlayer();
      _initStreams();

      duration = null;
      position = Duration.zero;

      // Prefer downloadUrl, fallback to fileUrl if needed
      final audioSource =
          (downloadUrl != null && downloadUrl.isNotEmpty)
              ? downloadUrl
              : fileUrl;
      if (audioSource.isEmpty) {
        _logError(
          'No audio source provided. downloadUrl: $downloadUrl, fileUrl: $fileUrl',
        );
        throw Exception('No audio source provided.');
      }

      try {
        final mediaItem = MediaItem(
          id: audioSource,
          title: title,
          artist: artist,
          artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
        );
        final audioSourceObj = AudioSource.uri(
          Uri.parse(audioSource),
          tag: mediaItem,
        );
        await player.setAudioSource(audioSourceObj);
      } catch (e) {
        _logError('Failed to set audio URL: $audioSource. Error: $e');
        rethrow;
      }

      // Listen for duration updates
      final subscription = player.durationStream.listen((d) {
        duration = d;
        durationController.add(d);
      });

      // Wait for duration to be loaded
      await player.durationStream.firstWhere((d) => d != null);
      duration = player.duration;
      durationController.add(duration);
      _logDebug('Duration loaded: $duration');
      subscription.cancel();

      isLoading = false;
      isInitialized = true;
      loadingController.add(false);
      initializedController.add(true);
    } catch (e, stack) {
      _logError('Error initializing audio player: $e\n$stack');
      isLoading = false;
      isInitialized = false;
      duration = null;
      position = Duration.zero;
      loadingController.add(false);
      initializedController.add(false);
      durationController.add(null);
      positionController.add(Duration.zero);
    }
  }

  Future<void> play() async {
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  void dispose() {
    player.dispose();
    positionController.close();
    playingController.close();
    durationController.close();
    loadingController.close();
    initializedController.close();
  }

  Future<void> resetPlayer() async {
    await player.stop();
    await player.dispose();
    player = AudioPlayer();
    _initStreams();

    // Reset all stream controllers
    positionController.add(Duration.zero);
    durationController.add(null);
    loadingController.add(false);
    initializedController.add(false);
    playingController.add(false);
  }

  void _logDebug(String message) {
    // Replace this with a proper logger if desired
    assert(() {
      // Only prints in debug mode
      // ignore: avoid_print
      print('AudioPlayerService DEBUG: $message');
      return true;
    }());
  }

  void _logError(String message) {
    // Replace this with a proper logger if desired
    // ignore: avoid_print
    print('AudioPlayerService ERROR: $message');
  }
}

final audioPlayerService = AudioPlayerService();

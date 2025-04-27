import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import 'package:portal/Services/storage_service.dart';

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
    required String? storagePath,
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
      durationController.add(null);
      positionController.add(Duration.zero);

      String? audioUrl;

      // First try to use the provided download URL
      if (downloadUrl != null) {
        print('Debug: Using provided download URL');
        audioUrl = downloadUrl;
      }
      // Then try getting it from storage path
      else if (storagePath != null) {
        try {
          print('Debug: Trying to get URL from storage path: $storagePath');
          audioUrl = await st.getDownloadURL(storagePath);
        } catch (e) {
          print('Error getting download URL from storage path: $e');
        }
      }
      // Finally, fall back to the file URL
      else if (fileUrl.isNotEmpty) {
        if (fileUrl.startsWith('http')) {
          print('Debug: Using direct URL');
          audioUrl = fileUrl;
        } else {
          try {
            print('Debug: Getting download URL from fileUrl');
            audioUrl = await st.getDownloadURL(fileUrl);
          } catch (e) {
            print('Error getting download URL from fileUrl: $e');
          }
        }
      }

      if (audioUrl == null) {
        throw Exception('No valid audio URL found');
      }

      print('Debug: Setting audio source with URL: $audioUrl');

      // Set up duration listener before setting audio source
      var durationCompleter = Completer<Duration>();
      var subscription = player.durationStream.listen(
        (duration) {
          print('Debug: Got duration update: $duration');
          if (duration != null && !durationCompleter.isCompleted) {
            durationCompleter.complete(duration);
          }
        },
        onError: (e) {
          print('Debug: Error in duration stream: $e');
          if (!durationCompleter.isCompleted) {
            durationCompleter.completeError(e);
          }
        },
      );

      // Set the audio source
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrl),
          tag: MediaItem(
            id: '1',
            album: 'Single',
            title: title,
            artist: artist,
            artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
          ),
        ),
      );

      print('Debug: Audio source set successfully');

      // Wait for duration with timeout
      try {
        duration = await durationCompleter.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Debug: Timeout waiting for duration, using default');
            return const Duration(seconds: 0);
          },
        );
        durationController.add(duration);
        print('Debug: Duration loaded: $duration');
      } finally {
        subscription.cancel();
      }

      isLoading = false;
      isInitialized = true;
      loadingController.add(false);
      initializedController.add(true);
    } catch (e) {
      print('Error initializing audio player: $e');
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
}

final audioPlayerService = AudioPlayerService();

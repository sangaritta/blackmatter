import 'dart:async';
import 'package:audio_service/audio_service.dart';

// Static variable to hold the handler instance. Needs to be set by main.dart.
AudioHandler? _audioHandlerInstance;

// Function to set the handler instance, called from main.dart after initAudioService
void setAudioHandlerInstance(AudioHandler handler) {
  _audioHandlerInstance = handler;
}

// Getter to access the stored handler instance.
// Assumes setAudioHandlerInstance has been called.
AudioHandler get _audioHandler {
  if (_audioHandlerInstance == null) {
    // This should ideally not happen if initialization is correct in main.dart
    throw StateError('AudioHandler instance has not been set. Call setAudioHandlerInstance after initializing AudioService.');
  }
  return _audioHandlerInstance!;
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  final StreamController<Duration?> _durationController = StreamController.broadcast();
  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<bool> _playingController = StreamController.broadcast();
  final StreamController<bool> _loadingController = StreamController.broadcast();
  final StreamController<bool> _initializedController = StreamController.broadcast();
  final StreamController<MediaItem?> _mediaItemController = StreamController.broadcast();

  Duration? _duration;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isInitialized = false;
  MediaItem? _currentMediaItem;

  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;

  factory AudioPlayerService() {
    return _instance;
  }

  AudioPlayerService._internal() {
    _initStreams();
  }

  void _initStreams() async {
    final handler = _audioHandler;

    await _playbackStateSubscription?.cancel();
    await _mediaItemSubscription?.cancel();

    _playbackStateSubscription = handler.playbackState.listen((state) {
      _updateStateFromPlaybackState(state);
    });

    _mediaItemSubscription = handler.mediaItem.listen((item) {
      _updateStateFromMediaItem(item);
    });

    _updateStateFromPlaybackState(handler.playbackState.value);
    _updateStateFromMediaItem(handler.mediaItem.value);
  }

  void _updateStateFromPlaybackState(PlaybackState state) {
    final prevPosition = _position;
    final prevIsPlaying = _isPlaying;
    final prevIsLoading = _isLoading;
    final prevIsInitialized = _isInitialized;

    _position = state.updatePosition;
    _isPlaying = state.playing;
    _isLoading = state.processingState == AudioProcessingState.loading ||
                      state.processingState == AudioProcessingState.buffering;
    _isInitialized = state.processingState != AudioProcessingState.idle &&
                          state.processingState != AudioProcessingState.error;

    if (_position != prevPosition) _positionController.add(_position);
    if (_isPlaying != prevIsPlaying) _playingController.add(_isPlaying);
    if (_isLoading != prevIsLoading) _loadingController.add(_isLoading);
    if (_isInitialized != prevIsInitialized) _initializedController.add(_isInitialized);
  }

  void _updateStateFromMediaItem(MediaItem? item) {
    _currentMediaItem = item;
    _mediaItemController.add(item);

    final newDuration = item?.duration;
    if (_duration != newDuration) {
        _duration = newDuration;
        _durationController.add(newDuration);
    }
  }

  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;
  Stream<bool> get initializedStream => _initializedController.stream;
  Stream<MediaItem?> get mediaItemStream => _mediaItemController.stream;

  Duration? get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  MediaItem? get currentMediaItem => _currentMediaItem;

  Future<void> loadAndPrepare({
    required String trackId,
    required String title,
    required String artist,
    String? album,
    String? artworkUrl,
    String? downloadUrl,
    String? storagePath,
    required String fileUrl,
  }) async {
    final handler = _audioHandler;
    await handler.customAction('loadMediaItem', {
        'id': trackId,
        'title': title,
        'artist': artist,
        'album': album,
        'artworkUrl': artworkUrl,
        'downloadUrl': downloadUrl,
        'storagePath': storagePath,
        'fileUrl': fileUrl,
    });
  }

  Future<void> play() async {
    final handler = _audioHandler;
    await handler.play();
  }

  Future<void> pause() async {
    final handler = _audioHandler;
    await handler.pause();
  }

  Future<void> stop() async {
    final handler = _audioHandler;
    await handler.stop();
  }

  Future<void> seek(Duration position) async {
    final handler = _audioHandler;
    await handler.seek(position);
  }

  void disposeStreams() {
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _durationController.close();
    _positionController.close();
    _playingController.close();
    _loadingController.close();
    _initializedController.close();
    _mediaItemController.close();
  }

  Future<void> resetPlayer() async {
    final handler = _audioHandler;
    await handler.stop();
  }
}

final audioPlayerService = AudioPlayerService();

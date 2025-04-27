import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Screens/LyricsEditor/Tabs/lyrics_tab.dart';
import 'package:portal/Screens/LyricsEditor/Tabs/sync_tab.dart';
import 'package:portal/Screens/LyricsEditor/Tabs/tag_tab.dart';
import 'package:portal/Screens/LyricsEditor/Tabs/translate_tab.dart';
import 'package:portal/Services/audio_player_service.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';

class LyricsEditor extends StatefulWidget {
  final String trackTitle;
  final List<String> primaryArtists;
  final Future<String?> audioUrl;
  final String projectId;
  final String productId;
  final String trackId;

  const LyricsEditor({
    super.key,
    required this.trackTitle,
    required this.primaryArtists,
    required this.audioUrl,
    required this.projectId,
    required this.productId,
    required this.trackId,
  });

  @override
  State<LyricsEditor> createState() => _LyricsEditorState();
}

class _LyricsEditorState extends State<LyricsEditor>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _audioPlayer = audioPlayerService.player;
  final TextEditingController _lyricsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<StreamSubscription> _audioSubscriptions = [];

  bool _isPlaying = false;
  bool _isSaving = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final Map<int, Duration> _syncedLyrics = {};
  final List<String> _syncHistory = [];
  int _currentLineIndex = 0;
  String? _selectedLanguage;
  Map<String, String> _translations = {};
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _initAudioPlayer();
    _loadExistingLyrics();
    //alyticsService.logScreenView(screenName: 'lyrics_editor');
  }

  Future<void> _initAudioPlayer() async {
    try {
      final url = await widget.audioUrl;
      if (url == null) {
        throw Exception('Could not get audio URL');
      }
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '1',
            album: 'Single',
            title: widget.trackTitle,
            artist: widget.primaryArtists.join(', '),
          ),
        ),
      );
      _duration = _audioPlayer.duration ?? Duration.zero;
      setState(() {});
      _audioSubscriptions.add(
        _audioPlayer.positionStream.listen((position) {
          setState(() {
            _position = position;
          });
        }),
      );
      _audioSubscriptions.add(
        _audioPlayer.durationStream.listen((duration) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }),
      );
      _audioSubscriptions.add(
        _audioPlayer.playerStateStream.listen((state) {
          setState(() {
            _isPlaying = state.playing;
          });
        }),
      );
    } catch (e) {
      //print('Error initializing audio player: $e');
    }
  }

  Future<void> _loadExistingLyrics() async {
    try {
      final userId = auth.getUser()?.uid;
      if (userId == null) return;

      final tracks = await api.getTracksForProduct(
        userId,
        widget.projectId,
        widget.productId,
      );

      final track = tracks.firstWhere(
        (t) => t['id'] == widget.trackId,
        orElse: () => {},
      );

      if (track.isNotEmpty) {
        setState(() {
          _lyricsController.text = track['lyrics'] ?? '';
          _syncedLyrics.clear();
          if (track['syncedLyrics'] != null) {
            final Map<String, dynamic> syncMap = track['syncedLyrics'];
            syncMap.forEach((key, value) {
              _syncedLyrics[int.parse(key)] = Duration(milliseconds: value);
            });
          }
          _selectedLanguage = track['lyricsLanguage'];
          _translations = Map<String, String>.from(track['translations'] ?? {});
          _tags = List<String>.from(track['tags'] ?? []);
        });
      }
    } catch (e) {
      print('Error loading lyrics: $e');
    }
  }

  Future<void> _saveLyrics() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = auth.getUser()?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Convert synced lyrics to a format suitable for storage
      Map<String, int> syncedLyricsForStorage = {};
      _syncedLyrics.forEach((key, value) {
        syncedLyricsForStorage[key.toString()] = value.inMilliseconds;
      });

      // Prepare the update data
      Map<String, dynamic> updateData = {
        'lyrics': _lyricsController.text,
        'syncedLyrics': syncedLyricsForStorage,
        'lyricsLanguage': _selectedLanguage,
        'translations': _translations,
        'tags': _tags,
      };

      // Save to Firestore
      await api.saveTrack(
        userId,
        widget.projectId,
        widget.productId,
        widget.trackId,
        updateData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lyrics saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving lyrics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _handleLyricsChanged() {
    //int('Lyrics changed handler called'); // Add debug print
    //alyticsService.logLyricsEdited(widget.trackTitle);
    setState(() {
      print('Setting state after lyrics change'); // Add debug print
    }); // Trigger UI update when lyrics change
  }

  void _handleLyricsSynced() {
    //alyticsService.logLyricsSynced(widget.trackTitle);
  }

  @override
  void dispose() {
    for (final sub in _audioSubscriptions) {
      sub.cancel();
    }
    _audioSubscriptions.clear();
    _lyricsController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLyrics = _lyricsController.text.trim().isNotEmpty;
    print('Has lyrics: $hasLyrics'); // Add debug print
    print('Lyrics content: "${_lyricsController.text}"'); // Add debug print

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.trackTitle,
              style: const TextStyle(
                fontFamily: fontNameBold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              widget.primaryArtists.join(', '),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          _isSaving
              ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
              : Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, color: Colors.white, size: 20),
                  label: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: fontNameSemiBold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _saveLyrics,
                ),
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: const BoxDecoration(color: Color(0xFF1E1B2C)),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note), text: 'Lyrics'),
                Tab(icon: Icon(Icons.timer), text: 'Sync'),
                Tab(icon: Icon(Icons.tag), text: 'Tag'),
                Tab(icon: Icon(Icons.translate), text: 'Translate'),
              ],
            ),
          ),
          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LyricsTab(
                  lyricsController: _lyricsController,
                  onChanged: _handleLyricsChanged,
                ),
                hasLyrics
                    ? SyncTab(
                      lyricsController: _lyricsController,
                      syncedLyrics: _syncedLyrics,
                      scrollController: _scrollController,
                      onPlayLine: (indexStr) {
                        final index = int.parse(indexStr);
                        final timestamp = _syncedLyrics[index];
                        if (timestamp != null) {
                          _audioPlayer.seek(timestamp);
                        }
                      },
                      onSync: (position) {
                        final currentText = _lyricsController.text;
                        final lines = currentText.split('\n');
                        if (lines.isNotEmpty) {
                          setState(() {
                            _syncedLyrics[_currentLineIndex] = position;
                            _syncHistory.add(_currentLineIndex.toString());
                            _currentLineIndex = (_currentLineIndex + 1).clamp(
                              0,
                              lines.length - 1,
                            );
                          });
                          _handleLyricsSynced();
                        }
                      },
                      onUndo: () {
                        if (_syncHistory.isNotEmpty) {
                          final lastSyncedLine = int.parse(
                            _syncHistory.removeLast(),
                          );
                          setState(() {
                            _syncedLyrics.remove(lastSyncedLine);
                            _currentLineIndex = lastSyncedLine;
                          });
                        }
                      },
                      formatDuration: _formatDuration,
                      isPlaying: _isPlaying,
                      currentPosition: _position,
                      currentLineIndex: _currentLineIndex,
                    )
                    : _buildEmptyLyricsNotice(),
                hasLyrics
                    ? TagTab(
                      tags: _tags,
                      onTagsChanged: (newTags) {
                        print('Tags changed: $newTags'); // Add debug print
                        setState(() {
                          print(
                            'Setting state with new tags: $newTags',
                          ); // Add debug print
                          _tags = newTags;
                        });
                      },
                    )
                    : _buildEmptyLyricsNotice(),
                hasLyrics
                    ? TranslateTab(
                      originalText: _lyricsController.text,
                      translations: _translations,
                      selectedLanguage: _selectedLanguage,
                      onLanguageChanged: (language) {
                        setState(() {
                          _selectedLanguage = language;
                        });
                      },
                      onTranslationChanged: (language, translation) {
                        setState(() {
                          _translations[language] = translation;
                        });
                      },
                    )
                    : _buildEmptyLyricsNotice(),
              ],
            ),
          ),
          _buildAudioControls(),
        ],
      ),
    );
  }

  Widget _buildEmptyLyricsNotice() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.edit_note, color: Colors.blue, size: 48),
            SizedBox(height: 16),
            Text(
              'Add Lyrics First',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: fontNameBold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please add plain lyrics in the Lyrics tab before using this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.play();
              }
            },
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_position),
            style: const TextStyle(color: Colors.grey),
          ),
          Expanded(
            child: Slider(
              value: _position.inMilliseconds.toDouble(),
              min: 0,
              max:
                  (_duration.inMilliseconds > 0)
                      ? _duration.inMilliseconds.toDouble()
                      : 1.0,
              onChanged: (value) {
                final position = Duration(milliseconds: value.round());
                _audioPlayer.seek(position);
              },
              activeColor: Colors.white,
              inactiveColor: Colors.grey[800],
            ),
          ),
          Text(
            _formatDuration(_duration),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.loop, color: Colors.grey),
            onPressed: () {
              // Implement loop functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.speed, color: Colors.grey),
            onPressed: () {
              // Implement playback speed functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey),
            onPressed: () {
              // Implement history functionality
            },
          ),
        ],
      ),
    );
  }
}

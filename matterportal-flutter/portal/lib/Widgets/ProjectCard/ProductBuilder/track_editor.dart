import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Widgets/ProjectCard/text_fields.dart';
import 'package:portal/Services/storage_service.dart';
import 'package:portal/Constants/countries.dart';
import 'dart:async';
import 'package:portal/Screens/LyricsEditor/lyrics_editor.dart';
import 'package:portal/Services/audio_player_service.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Widgets/ProjectCard/utils.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/audio_preview.dart';
import 'package:portal/Widgets/Common/role_based_artist_selector_dialog.dart';
import 'package:portal/Widgets/Common/artist_selector.dart';
import 'package:portal/Widgets/Common/artist_selector_dialog.dart';
import 'package:portal/Constants/roles.dart';

class TrackEditor extends StatefulWidget {
  final String fileName;
  final String fileUrl;
  final TextEditingController titleController;
  final TextEditingController versionController;
  final TextEditingController remixerController;
  final TextEditingController songwritersController;
  final TextEditingController producersController;
  final TextEditingController isrcController;
  final TextEditingController countryController;
  final TextEditingController nationalityController;
  final List<String> primaryArtists;
  final List<String> featuringArtists;
  final bool isExplicit;
  final String ownership;
  final Function(bool) onExplicitChanged;
  final Function(String) onOwnershipChanged;
  final Function(List<String>) onPrimaryArtistsChanged;
  final Function(List<String>) onFeaturingArtistsChanged;
  final List<String> remixers;
  final Function(List<String>) onRemixersChanged;
  final bool isUploading;
  final List<Map<String, dynamic>> performersWithRoles;
  final Function(List<Map<String, dynamic>>) onPerformersChanged;
  final List<Map<String, dynamic>> songwritersWithRoles;
  final Function(List<Map<String, dynamic>>) onSongwritersChanged;
  final List<Map<String, dynamic>> productionWithRoles;
  final Function(List<Map<String, dynamic>>) onProductionChanged;
  final List<String> productPrimaryArtists;
  final String? artworkUrl;
  final String projectId;
  final String productId;

  const TrackEditor({
    super.key,
    required this.fileName,
    required this.fileUrl,
    required this.titleController,
    required this.versionController,
    required this.remixerController,
    required this.songwritersController,
    required this.producersController,
    required this.isrcController,
    required this.countryController,
    required this.nationalityController,
    required this.primaryArtists,
    required this.featuringArtists,
    required this.isExplicit,
    required this.ownership,
    required this.onExplicitChanged,
    required this.onOwnershipChanged,
    required this.onPrimaryArtistsChanged,
    required this.onFeaturingArtistsChanged,
    required this.remixers,
    required this.onRemixersChanged,
    required this.isUploading,
    required this.performersWithRoles,
    required this.onPerformersChanged,
    required this.songwritersWithRoles,
    required this.onSongwritersChanged,
    required this.productionWithRoles,
    required this.onProductionChanged,
    required this.productPrimaryArtists,
    this.artworkUrl,
    required this.projectId,
    required this.productId,
  });

  @override
  State<TrackEditor> createState() => _TrackEditorState();
}

class _TrackEditorState extends State<TrackEditor> {
  final List<Map<String, dynamic>> ownershipOptions = [
    {"text": "Original Owner", "icon": Icons.copyright, "value": "Original"},
    {
      "text": "Acquired Rights",
      "icon": Icons.real_estate_agent,
      "value": "Acquired",
    },
    {
      "text": "Exclusive License",
      "icon": Icons.verified_user,
      "value": "Exclusive",
    },
    {
      "text": "Non-Exclusive License",
      "icon": Icons.person_outline,
      "value": "Non-Exclusive",
    },
    {"text": "No Rights", "icon": Icons.not_interested, "value": "None"},
  ];

  final _audioPlayer = audioPlayerService;
  final List<StreamSubscription> _audioSubscriptions = [];
  Duration? _duration;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isAutoISRC = true;
  bool _hasBeenSaved = false;
  Map<String, dynamic>? _trackData;
  List<Map<String, dynamic>> _performersWithRoles = [];
  List<Map<String, dynamic>> _songwritersWithRoles = [];
  List<Map<String, dynamic>> _productionWithRoles = [];

  @override
  void initState() {
    super.initState();
    if (!widget.isUploading) {
      _loadTrackData();
    }
    _initSubscriptions();
  }

  @override
  void didUpdateWidget(covariant TrackEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileUrl != widget.fileUrl ||
        oldWidget.fileName != widget.fileName ||
        oldWidget.artworkUrl != widget.artworkUrl) {
      // Clear existing track data and reload for new track
      setState(() {
        _trackData = null;
        _hasBeenSaved = false;
      });
      _loadTrackData(); // Reload metadata for new track
    }
  }

  void _initSubscriptions() {
    _audioSubscriptions.add(
      _audioPlayer.positionController.stream.listen((pos) {
        setState(() {
          _position = pos;
        });
      }),
    );

    _audioSubscriptions.add(
      _audioPlayer.playingController.stream.listen((playing) {
        setState(() {
          _isPlaying = playing;
        });
      }),
    );

    _audioSubscriptions.add(
      _audioPlayer.durationController.stream.listen((duration) {
        setState(() {
          _duration = duration;
        });
      }),
    );

    _audioSubscriptions.add(
      _audioPlayer.loadingController.stream.listen((loading) {
        setState(() {
          _isLoading = loading;
        });
      }),
    );

    _audioSubscriptions.add(
      _audioPlayer.initializedController.stream.listen((initialized) {
        setState(() {
          _isInitialized = initialized;
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _audioSubscriptions) {
      sub.cancel();
    }
    _audioSubscriptions.clear();
    super.dispose();
  }

  Future<void> _loadTrackData() async {
    try {
      final userId = auth.getUser()?.uid;
      if (userId == null) return;

      final tracks = await api.getTracksForProduct(
        userId,
        widget.projectId,
        widget.productId,
      );

      // Find the track with current widget's filename
      final track = tracks.firstWhere((t) {
        // Safely extract fileName, handling both string and map cases
        final fileName = t['fileName'];
        if (fileName == null) return false;

        if (fileName is String) {
          return fileName == widget.fileName;
        }

        if (fileName is Map) {
          return fileName['name'] == widget.fileName;
        }

        return false;
      }, orElse: () => {});

      if (track.isNotEmpty) {
        // Convert roles data to the expected format
        List<Map<String, dynamic>> convertRoles(List<dynamic>? rolesList) {
          if (rolesList == null) return [];
          return rolesList.map((item) {
            if (item is Map) {
              return {
                'name': item['name']?.toString() ?? '',
                'roles':
                    (item['roles'] as List?)
                        ?.map((role) => role.toString())
                        .toList() ??
                    [],
              };
            }
            return {'name': '', 'roles': <String>[]};
          }).toList();
        }

        // Extract fileName safely
        String extractFileName(dynamic fileNameField) {
          if (fileNameField is String) {
            return fileNameField;
          }
          if (fileNameField is Map) {
            return fileNameField['name']?.toString() ?? '';
          }
          return '';
        }

        // Convert track data to ensure all fields are of the correct type
        Map<String, dynamic> convertedTrack = {
          ...track,
          'title': track['title']?.toString() ?? '',
          'version': track['version']?.toString() ?? '',
          'primaryArtists':
              (track['primaryArtists'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          'featuringArtists':
              (track['featuringArtists'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          'remixers':
              (track['remixers'] as List?)?.map((e) => e.toString()).toList() ??
              [],
          'isExplicit': track['isExplicit'] ?? false,
          'ownership': track['ownership']?.toString() ?? '',
          'isrcCode': track['isrcCode']?.toString() ?? '',
          'country': track['country']?.toString() ?? '',
          'nationality': track['nationality']?.toString() ?? '',
          'fileName': extractFileName(track['fileName']),
          'artworkUrl': track['artworkUrl']?.toString() ?? '',
          'downloadUrl': track['downloadUrl']?.toString(),
          'storagePath': track['storagePath']?.toString(),
        };

        setState(() {
          _trackData = convertedTrack;
          _hasBeenSaved = true;

          // Initialize role-based data
          _performersWithRoles = convertRoles(track['performers'] as List?);
          _songwritersWithRoles = convertRoles(track['songwriters'] as List?);
          _productionWithRoles = convertRoles(track['production'] as List?);
        });
      }

      _initAudioPlayer();
    } catch (e) {
      print('Error loading track data: $e');
      _initAudioPlayer();
    }
  }

  Future<void> _initAudioPlayer() async {
    if (widget.isUploading) {
      setState(() {
        _isLoading = false;
        _isInitialized = false;
        _duration = null;
        _position = Duration.zero;
      });
      return;
    }

    // Stop any existing playback and reset state
    await _audioPlayer.player.stop();
    await _audioPlayer.player.dispose();

    // Reinitialize the audio player with new track
    await _audioPlayer.initializeAudio(
      downloadUrl: _trackData?['downloadUrl'],
      storagePath: _trackData?['storagePath'],
      fileUrl: widget.fileUrl,
      title: _formatTitle(),
      artist: _formatArtists(),
      artworkUrl: widget.artworkUrl,
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  String _formatArtists() {
    // Use product primary artists if track primary artists is empty
    List<String> primaryArtistsList =
        widget.primaryArtists.isEmpty
            ? widget.productPrimaryArtists
            : widget.primaryArtists;

    String artists = primaryArtistsList.join(', ');
    if (widget.featuringArtists.isNotEmpty) {
      artists += ' (feat. ${widget.featuringArtists.join(', ')})';
    }
    return artists;
  }

  String _formatTitle() {
    String title =
        widget.titleController.text.isEmpty
            ? widget.fileName
            : widget.titleController.text;

    if (widget.versionController.text.isNotEmpty) {
      title += ' (${widget.versionController.text})';
    }

    return title;
  }

  Widget _buildSpotifyPreview() {
    return AudioPreview(
      fileName: widget.fileName,
      fileUrl: widget.fileUrl,
      title: _formatTitle(),
      artists: _formatArtists(),
      artworkUrl: widget.artworkUrl,
      isUploading: widget.isUploading,
      trackData: _trackData,
      duration: _duration,
      position: _position,
      isPlaying: _isPlaying,
      isLoading: _isLoading,
      isInitialized: _isInitialized,
      onPlayPause: () async {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      },
      onSeek: (position) {
        _audioPlayer.seek(position);
      },
    );
  }

  void _updateMetadata() async {
    await _audioPlayer.initializeAudio(
      downloadUrl: _trackData?['downloadUrl'],
      storagePath: _trackData?['storagePath'],
      fileUrl: widget.fileUrl,
      title: _formatTitle(),
      artist: _formatArtists(),
      artworkUrl: widget.artworkUrl,
    );
  }

  Future<void> _saveTrack() async {
    // Validate required fields
    String errorMessage = '';

    if (widget.titleController.text.isEmpty) {
      errorMessage += 'Track Name is required\n';
    }
    if (widget.primaryArtists.isEmpty) {
      errorMessage += 'Primary Artists is required\n';
    }
    if (_songwritersWithRoles.isEmpty) {
      errorMessage += 'Songwriters is required\n';
    }
    if (_productionWithRoles.isEmpty) {
      errorMessage += 'Production & Engineering is required\n';
    }
    if (!_isAutoISRC && widget.isrcController.text.isEmpty) {
      errorMessage += 'ISRC is required when not set to AUTO\n';
    }
    if (widget.countryController.text.isEmpty) {
      errorMessage += 'Country of Recording is required\n';
    }
    if (widget.nationalityController.text.isEmpty) {
      errorMessage += 'Nationality of Original Copyright Owner is required\n';
    }

    if (errorMessage.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill in all required fields:\n$errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (auth.getUser() == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Clean up role data by removing icon fields
      List<Map<String, dynamic>> cleanPerformers =
          _performersWithRoles
              .map(
                (performer) => {
                  'name': performer['name'],
                  'roles': performer['roles'],
                },
              )
              .toList();

      List<Map<String, dynamic>> cleanSongwriters =
          _songwritersWithRoles
              .map(
                (songwriter) => {
                  'name': songwriter['name'],
                  'roles': songwriter['roles'],
                },
              )
              .toList();

      List<Map<String, dynamic>> cleanProduction =
          _productionWithRoles
              .map(
                (producer) => {
                  'name': producer['name'],
                  'roles': producer['roles'],
                },
              )
              .toList();

      Map<String, dynamic> trackData = {
        'title':
            widget.titleController.text.isEmpty
                ? widget.fileName
                : widget.titleController.text,
        'version': widget.versionController.text,
        'primaryArtists': widget.primaryArtists,
        'featuringArtists': widget.featuringArtists,
        'remixers': widget.remixers,
        'performers': cleanPerformers,
        'songwriters': cleanSongwriters,
        'production': cleanProduction,
        'isExplicit': widget.isExplicit,
        'ownership': widget.ownership,
        'isrcCode': widget.isrcController.text,
        'country': widget.countryController.text,
        'nationality': widget.nationalityController.text,
        'fileName': widget.fileName,
        'artworkUrl': widget.artworkUrl,
        'trackNumber': _trackData?['trackNumber'], // Preserve track number
      };

      // Only include downloadUrl and storagePath if they exist in track data
      if (_trackData != null) {
        if (_trackData!['downloadUrl'] != null) {
          trackData['downloadUrl'] = _trackData!['downloadUrl'];
        }
        if (_trackData!['storagePath'] != null) {
          trackData['storagePath'] = _trackData!['storagePath'];
        }
      }

      // Use existing track ID if available, otherwise generate a new one
      final String trackId = _trackData?['trackId'] ?? generateUID();

      await api.saveTrack(
        auth.getUser()!.uid,
        widget.projectId,
        widget.productId,
        trackId,
        trackData,
      );

      if (mounted) {
        setState(() {
          _hasBeenSaved = true; // Set to true after successful save
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Track saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save track: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSpotifyPreview(),
        const SizedBox(height: 16),

        // Existing track editor in a scrollable container
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              buildTextField(
                controller: widget.titleController,
                label: 'Track Name',
                prefixIcon: const Icon(Icons.title, color: Colors.grey),
                onChanged: (value) {
                  setState(() {
                    // This will trigger a rebuild of the preview
                  });
                },
              ),
              const SizedBox(height: 16),

              // Version (Optional)
              buildTextField(
                controller: widget.versionController,
                label: 'Version (Optional)',
                prefixIcon: const Icon(Icons.sync, color: Colors.grey),
                onChanged: (value) {
                  setState(() {
                    // This will trigger a rebuild of the preview
                  });
                },
              ),
              const SizedBox(height: 16),

              // Primary Artists
              ArtistSelector(
                label: 'Primary Artists',
                selectedArtists: widget.primaryArtists,
                onChanged: (updated) {
                  widget.onPrimaryArtistsChanged(updated);
                },
                collection: 'artists',
              ),
              const SizedBox(height: 16),

              // Featuring Artists
              ArtistSelector(
                label: 'Featuring Artists (Optional)',
                selectedArtists: widget.featuringArtists,
                onChanged: (updated) {
                  widget.onFeaturingArtistsChanged(updated);
                },
                collection: 'artists',
              ),
              const SizedBox(height: 16),

              // Remixers
              ArtistSelector(
                label: 'Remixers (Optional)',
                selectedArtists: widget.remixers,
                onChanged: (updated) {
                  widget.onRemixersChanged(updated);
                },
                collection: 'artists',
              ),
              const SizedBox(height: 16),

              // Performers (ROLE BASED)
              _buildRoleSelector(
                context: context,
                label: 'Performers',
                selectedArtists: _performersWithRoles,
                onChanged:
                    (updated) => setState(() => _performersWithRoles = updated),
                collection: 'artists',
                roles: performerRoles,
                icon: Icons.people,
              ),
              const SizedBox(height: 16),

              // Songwriters (ROLE BASED)
              _buildRoleSelector(
                context: context,
                label: 'Songwriters',
                selectedArtists: _songwritersWithRoles,
                onChanged:
                    (updated) =>
                        setState(() => _songwritersWithRoles = updated),
                collection: 'songwriters',
                roles: writerRoles,
                icon: Icons.edit,
              ),
              const SizedBox(height: 16),

              // Production & Engineering (ROLE BASED)
              _buildRoleSelector(
                context: context,
                label: 'Production & Engineering',
                selectedArtists: _productionWithRoles,
                onChanged:
                    (updated) => setState(() => _productionWithRoles = updated),
                collection: 'artists',
                roles: productionRoles,
                icon: Icons.engineering,
              ),
              const SizedBox(height: 16),

              // ISRC
              Row(
                children: [
                  Expanded(
                    child: buildTextField(
                      controller: widget.isrcController,
                      label: 'ISRC',
                      prefixIcon: const Icon(Icons.numbers, color: Colors.grey),
                      enabled: !_isAutoISRC,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _isAutoISRC,
                        onChanged: (value) {
                          setState(() {
                            _isAutoISRC = value ?? true;
                            widget.isrcController.text =
                                _isAutoISRC ? 'AUTO' : '';
                          });
                        },
                        fillColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.blue;
                          }
                          return Colors.grey;
                        }),
                      ),
                      const Text(
                        'AUTO',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: fontNameSemiBold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ownership Dropdown
              DropdownButtonFormField<String>(
                value: widget.ownership,
                decoration: InputDecoration(
                  labelText: 'Ownership',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1B2C),
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.business, color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1E1B2C),
                items:
                    ownershipOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option["value"],
                        child: Row(
                          children: [
                            Icon(option["icon"], color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(option["text"]),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    widget.onOwnershipChanged(newValue);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Country Dropdown
              DropdownButtonFormField<String>(
                value:
                    widget.countryController.text.isEmpty
                        ? null
                        : widget.countryController.text,
                decoration: InputDecoration(
                  labelText: 'Country of Recording',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1B2C),
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: fontNameSemiBold,
                ),
                dropdownColor: const Color(0xFF1E1B2C),
                menuMaxHeight: 300,
                items:
                    countries.map((Country country) {
                      return DropdownMenuItem<String>(
                        value: country.code,
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: fontNameSemiBold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              country.name,
                              style: const TextStyle(
                                fontFamily: fontNameSemiBold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    widget.countryController.text = newValue;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Nationality of Original Copyright Owner
              DropdownButtonFormField<String>(
                value:
                    widget.nationalityController.text.isEmpty
                        ? null
                        : widget.nationalityController.text,
                decoration: InputDecoration(
                  labelText: 'Nationality of Original Copyright Owner',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1B2C),
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.flag, color: Colors.grey),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: fontNameSemiBold,
                ),
                dropdownColor: const Color(0xFF1E1B2C),
                menuMaxHeight: 300,
                items:
                    countries.map((Country country) {
                      return DropdownMenuItem<String>(
                        value: country.code,
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: fontNameSemiBold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              country.name,
                              style: const TextStyle(
                                fontFamily: fontNameSemiBold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    widget.nationalityController.text = newValue;
                  }
                },
              ),
              const SizedBox(height: 16),

              // Explicit Content Switch
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  title: Row(
                    children: [
                      const Text(
                        'Explicit Content',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: fontNameBold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: widget.isExplicit,
                  onChanged: (value) {
                    // Call the parent's callback to update the state
                    widget.onExplicitChanged(value);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF4A4FBF),
                  inactiveThumbColor: const Color(0xFF4A4A4A),
                  inactiveTrackColor: const Color(0xFF2D2D2D),
                ),
              ),

              // Add this at the bottom of the ListView
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _hasBeenSaved
                              ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => LyricsEditor(
                                          audioUrl: st.getDownloadURL(
                                            widget.fileUrl,
                                          ),
                                          primaryArtists: widget.primaryArtists,
                                          trackTitle:
                                              widget
                                                      .titleController
                                                      .text
                                                      .isEmpty
                                                  ? widget.fileName
                                                  : widget.titleController.text,
                                          projectId: widget.projectId,
                                          productId: widget.productId,
                                          trackId: generateUID(),
                                        ),
                                  ),
                                );
                              }
                              : null,
                      icon: const Icon(
                        Icons.lyrics_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        _hasBeenSaved ? 'Add Lyrics' : 'Save Track First',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF1DB954,
                        ), // Spotify green
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        disabledBackgroundColor:
                            Colors.grey, // Add disabled color
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Add some spacing between buttons
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTrack,
                      icon:
                          _isSaving
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Save Track',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue, // Choose an appropriate color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector({
    required BuildContext context,
    required String label,
    required List<Map<String, dynamic>> selectedArtists,
    required Function(List<Map<String, dynamic>>) onChanged,
    required String collection,
    required List<String> roles,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () async {
        final result = await showDialog<List<Map<String, dynamic>>>(
          context: context,
          builder:
              (context) => RoleBasedArtistSelectorDialog(
                collection: collection,
                initialSelections: selectedArtists,
                availableRoles: roles,
                roleIcon: icon,
              ),
        );
        if (result != null) {
          onChanged(result);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFF1E1B2C),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  selectedArtists
                      .map(
                        (artist) => Chip(
                          label: Text(
                            artist['name'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                          avatar: Icon(icon, size: 16, color: Colors.grey),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      .toList(),
            ),
            if (selectedArtists.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  selectedArtists
                      .map((a) => (a['roles'] as List).join(', '))
                      .join(' | '),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

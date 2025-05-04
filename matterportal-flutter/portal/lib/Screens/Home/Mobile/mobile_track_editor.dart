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
import 'package:portal/Constants/roles.dart';

class MobileTrackEditor extends StatefulWidget {
  final Map<String, dynamic> track;
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
  final List<String> remixers;
  final bool isExplicit;
  final String ownership;
  final List<Map<String, dynamic>> performersWithRoles;
  final List<Map<String, dynamic>> songwritersWithRoles;
  final List<Map<String, dynamic>> productionWithRoles;
  final List<String> productPrimaryArtists;
  final String? artworkUrl;
  final String projectId;
  final String productId;
  final String trackId;

  const MobileTrackEditor({
    super.key,
    required this.track,
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
    required this.remixers,
    required this.isExplicit,
    required this.ownership,
    required this.performersWithRoles,
    required this.songwritersWithRoles,
    required this.productionWithRoles,
    required this.productPrimaryArtists,
    this.artworkUrl,
    required this.projectId,
    required this.productId,
    required this.trackId,
  });

  @override
  State<MobileTrackEditor> createState() => _MobileTrackEditorState();
}

class _MobileTrackEditorState extends State<MobileTrackEditor> {
  final List<Map<String, dynamic>> ownershipOptions = [
    {"text": "Original Owner", "icon": Icons.copyright, "value": "Original"},
    {
      "text": "Acquired Rights",
      "icon": Icons.real_estate_agent,
      "value": "Acquired"
    },
    {
      "text": "Exclusive License",
      "icon": Icons.verified_user,
      "value": "Exclusive"
    },
    {
      "text": "Non-Exclusive License",
      "icon": Icons.person_outline,
      "value": "Non-Exclusive"
    },
    {"text": "No Rights", "icon": Icons.not_interested, "value": "None"}
  ];

  final _audioPlayer = audioPlayerService;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _loadingSubscription;
  StreamSubscription? _initializedSubscription;
  Duration? _duration;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isSaving = false;
  bool _isAutoISRC = true;
  bool _hasBeenSaved = false;
  
  // Track data and role variables
  List<String> _primaryArtists = [];
  List<String> _featuringArtists = [];
  List<String> _remixers = [];
  bool _isExplicit = false;
  String _ownership = 'Original';
  List<Map<String, dynamic>> _performersWithRoles = [];
  List<Map<String, dynamic>> _songwritersWithRoles = [];
  List<Map<String, dynamic>> _productionWithRoles = [];

  @override
  void initState() {
    super.initState();
    _initializeValues();
    _initSubscriptions();
    _initAudioPlayer();
  }

  void _initializeValues() {
    _primaryArtists = List.from(widget.primaryArtists);
    _featuringArtists = List.from(widget.featuringArtists);
    _remixers = List.from(widget.remixers);
    _isExplicit = widget.isExplicit;
    _ownership = widget.ownership;
    _performersWithRoles = List.from(widget.performersWithRoles);
    _songwritersWithRoles = List.from(widget.songwritersWithRoles);
    _productionWithRoles = List.from(widget.productionWithRoles);
    
    // Set ISRC auto state
    _isAutoISRC = widget.isrcController.text.toUpperCase() == 'AUTO' || widget.isrcController.text.isEmpty;
    if (_isAutoISRC) {
      widget.isrcController.text = 'AUTO';
    }
    
    // Check if this track has been saved before
    _hasBeenSaved = widget.trackId.isNotEmpty && 
                   (widget.track['downloadUrl'] != null || widget.track['storagePath'] != null);
  }

  void _initSubscriptions() {
    _positionSubscription = _audioPlayer.positionController.stream.listen((pos) {
      setState(() {
        _position = pos;
      });
    });

    _playingSubscription = _audioPlayer.playingController.stream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });

    _durationSubscription = _audioPlayer.durationController.stream.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _loadingSubscription = _audioPlayer.loadingController.stream.listen((loading) {
      setState(() {
        _isLoading = loading;
      });
    });

    _initializedSubscription = _audioPlayer.initializedController.stream.listen((initialized) {
      setState(() {
        _isInitialized = initialized;
      });
    });
  }

  Future<void> _initAudioPlayer() async {
    // Stop any existing playback and reset state
    await _audioPlayer.player.stop();
    await _audioPlayer.player.dispose();

    // Reinitialize the audio player with new track
    await _audioPlayer.initializeAudio(
      downloadUrl: widget.track['downloadUrl'],
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
    List<String> primaryArtistsList = _primaryArtists.isEmpty
        ? widget.productPrimaryArtists
        : _primaryArtists;

    String artists = primaryArtistsList.join(', ');
    if (_featuringArtists.isNotEmpty) {
      artists += ' (feat. ${_featuringArtists.join(', ')})';
    }
    return artists;
  }

  String _formatTitle() {
    String title = widget.titleController.text.isEmpty
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
      isUploading: false,
      trackData: widget.track,
      duration: _duration,
      position: _position,
      isPlaying: _isPlaying,
      isLoading: _isLoading,
      isInitialized: _isInitialized,      onPlayPause: () async {
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
  
  // Helper method to get the best available artwork URL
  String? _getBestArtworkUrl() {
    // First try to use the preview image if available
    final previewUrl = widget.track['previewArtUrl'];
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return previewUrl;
    }
    
    // Otherwise fall back to the original artwork
    return widget.artworkUrl;
  }

  Future<void> _saveTrack() async {
    // Validate required fields
    String errorMessage = '';

    if (widget.titleController.text.isEmpty) {
      errorMessage += 'Track Name is required\n';
    }
    if (_primaryArtists.isEmpty) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Clean up role data by removing any extra fields
      List<Map<String, dynamic>> cleanPerformers = _performersWithRoles
          .map((performer) => {
                'name': performer['name'],
                'roles': performer['roles'],
              })
          .toList();

      List<Map<String, dynamic>> cleanSongwriters = _songwritersWithRoles
          .map((songwriter) => {
                'name': songwriter['name'],
                'roles': songwriter['roles'],
              })
          .toList();

      List<Map<String, dynamic>> cleanProduction = _productionWithRoles
          .map((producer) => {
                'name': producer['name'],
                'roles': producer['roles'],
              })
          .toList();

      Map<String, dynamic> trackData = {
        'title': widget.titleController.text.isEmpty
            ? widget.fileName
            : widget.titleController.text,
        'version': widget.versionController.text,
        'primaryArtists': _primaryArtists,
        'featuringArtists': _featuringArtists,
        'remixers': _remixers,
        'performers': cleanPerformers,
        'songwriters': cleanSongwriters,
        'production': cleanProduction,
        'isExplicit': _isExplicit,
        'ownership': _ownership,
        'isrcCode': widget.isrcController.text,
        'country': widget.countryController.text,
        'nationality': widget.nationalityController.text,
        'fileName': widget.fileName,
        'artworkUrl': widget.artworkUrl,
        'trackNumber': widget.track['trackNumber'], // Preserve track number
      };

      // Only include downloadUrl and storagePath if they exist in track data
      if (widget.track['downloadUrl'] != null) {
        trackData['downloadUrl'] = widget.track['downloadUrl'];
      }
      if (widget.track['storagePath'] != null) {
        trackData['storagePath'] = widget.track['storagePath'];
      }

      // Use existing track ID or the one provided in constructor
      final String trackId = widget.trackId.isNotEmpty ? widget.trackId : generateUID();

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
  void dispose() {
    // Cancel all subscriptions to avoid memory leaks
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _durationSubscription?.cancel();
    _loadingSubscription?.cancel();
    _initializedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18162E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2C),
        title: Text('Edit Track',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: fontNameSemiBold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Add a save button to the app bar
          IconButton(
            onPressed: _isSaving ? null : _saveTrack,
            icon: _isSaving 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  )
                )
              : const Icon(Icons.save),
            tooltip: 'Save Track',
          ),
        ],
      ),
      body: Column(
        children: [
          // Audio preview at the top
          _buildSpotifyPreview(),
          
          // Form fields in a scrollable container
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track Name
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
                  buildArtistAutocomplete(
                    context: context,
                    controller: TextEditingController(),
                    label: 'Primary Artists',
                    artistSuggestions: const [],
                    selectedArtists: _primaryArtists,
                    onArtistAdded: (artist) {
                      setState(() {
                        _primaryArtists.add(artist);
                      });
                    },
                    onArtistRemoved: (artist) {
                      setState(() {
                        _primaryArtists.remove(artist);
                      });
                    },
                    onArtistsReordered: (artists) {
                      setState(() {
                        _primaryArtists = artists;
                      });
                    },
                    prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    showResetButton: true,
                    onReset: () {
                      setState(() {
                        _primaryArtists = List.from(widget.productPrimaryArtists);
                      });
                    },
                    resetTooltip: 'Reset to Product Artists',
                    collection: 'artists',
                  ),
                  const SizedBox(height: 16),

                  // Featuring Artists
                  buildArtistAutocomplete(
                    context: context,
                    controller: TextEditingController(),
                    label: 'Featuring Artists (Optional)',
                    artistSuggestions: const [],
                    selectedArtists: _featuringArtists,
                    onArtistAdded: (artist) {
                      setState(() {
                        _featuringArtists.add(artist);
                      });
                    },
                    onArtistRemoved: (artist) {
                      setState(() {
                        _featuringArtists.remove(artist);
                      });
                    },
                    onArtistsReordered: (artists) {
                      setState(() {
                        _featuringArtists = artists;
                      });
                    },
                    prefixIcon: const Icon(Icons.group_add, color: Colors.grey),
                    collection: 'artists',
                  ),
                  const SizedBox(height: 16),

                  // Remixers
                  buildArtistAutocomplete(
                    context: context,
                    controller: TextEditingController(),
                    label: 'Remixers (Optional)',
                    artistSuggestions: const [],
                    selectedArtists: _remixers,
                    onArtistAdded: (remixer) {
                      setState(() {
                        _remixers.add(remixer);
                      });
                    },
                    onArtistRemoved: (remixer) {
                      setState(() {
                        _remixers.remove(remixer);
                      });
                    },
                    onArtistsReordered: (artists) {
                      setState(() {
                        _remixers = artists;
                      });
                    },
                    prefixIcon: const Icon(Icons.loop, color: Colors.grey),
                    collection: 'artists',
                  ),
                  const SizedBox(height: 16),

                  // Performers
                  _buildRoleSelector(
                    context: context,
                    label: 'Performers',
                    selectedArtists: _performersWithRoles,
                    onChanged: (updated) => setState(() => _performersWithRoles = updated),
                    collection: 'artists',
                    roles: performerRoles,
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 16),

                  // Songwriters
                  _buildRoleSelector(
                    context: context,
                    label: 'Songwriters',
                    selectedArtists: _songwritersWithRoles,
                    onChanged: (updated) => setState(() => _songwritersWithRoles = updated),
                    collection: 'songwriters',
                    roles: writerRoles,
                    icon: Icons.edit,
                  ),
                  const SizedBox(height: 16),

                  // Production & Engineering
                  _buildRoleSelector(
                    context: context,
                    label: 'Production & Engineering',
                    selectedArtists: _productionWithRoles,
                    onChanged: (updated) => setState(() => _productionWithRoles = updated),
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
                                widget.isrcController.text = _isAutoISRC ? 'AUTO' : '';
                              });
                            },
                            fillColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.blue;
                                }
                                return Colors.grey;
                              },
                            ),
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
                    value: _ownership,
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
                    items: ownershipOptions.map((option) {
                      return DropdownMenuItem<String>(
                        value: option["value"] as String,
                        child: Row(
                          children: [
                            Icon(option["icon"] as IconData, color: Colors.grey, size: 20),
                            const SizedBox(width: 8),
                            Text(option["text"] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _ownership = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Country Dropdown
                  DropdownButtonFormField<String>(
                    value: widget.countryController.text.isEmpty
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
                        color: Colors.white, fontFamily: fontNameSemiBold),
                    dropdownColor: const Color(0xFF1E1B2C),
                    menuMaxHeight: 300,
                    items: countries.map((Country country) {
                      return DropdownMenuItem<String>(
                        value: country.code,
                        child: Row(
                          children: [
                            Text(country.flag,
                                style: const TextStyle(
                                    fontSize: 16, fontFamily: fontNameSemiBold)),
                            const SizedBox(width: 8),
                            Text(country.name,
                                style:
                                    const TextStyle(fontFamily: fontNameSemiBold)),
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
                    value: widget.nationalityController.text.isEmpty
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
                        color: Colors.white, fontFamily: fontNameSemiBold),
                    dropdownColor: const Color(0xFF1E1B2C),
                    menuMaxHeight: 300,
                    items: countries.map((Country country) {
                      return DropdownMenuItem<String>(
                        value: country.code,
                        child: Row(
                          children: [
                            Text(country.flag,
                                style: const TextStyle(
                                    fontSize: 16, fontFamily: fontNameSemiBold)),
                            const SizedBox(width: 8),
                            Text(country.name,
                                style:
                                    const TextStyle(fontFamily: fontNameSemiBold)),
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
                          const Text('Explicit Content',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: fontNameBold,
                                fontSize: 14,
                              )),
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
                      value: _isExplicit,
                      onChanged: (value) {
                        setState(() {
                          _isExplicit = value;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF4A4FBF),
                      inactiveThumbColor: const Color(0xFF4A4A4A),
                      inactiveTrackColor: const Color(0xFF2D2D2D),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Lyrics Button
                  ElevatedButton.icon(
                    onPressed: _hasBeenSaved
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LyricsEditor(
                                  audioUrl: st.getDownloadURL(widget.fileUrl),
                                  primaryArtists: _primaryArtists,
                                  trackTitle:
                                      widget.titleController.text.isEmpty
                                          ? widget.fileName
                                          : widget.titleController.text,
                                  projectId: widget.projectId,
                                  productId: widget.productId,
                                  trackId: widget.trackId.isNotEmpty ? widget.trackId : generateUID(),
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.lyrics_outlined, color: Colors.white),
                    label: Text(
                      _hasBeenSaved ? 'Add Lyrics' : 'Save Track First',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954), // Spotify green
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      disabledBackgroundColor: Colors.grey, // Add disabled color
                    ),
                  ),
                  
                  const SizedBox(height: 50), // Extra space at the bottom for scrolling
                ],
              ),
            ),
          ),
        ],
      ),
      // Floating save button
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _saveTrack,
        backgroundColor: _isSaving ? Colors.grey : Colors.blue,
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ))
            : const Icon(Icons.save),
      ),
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
          builder: (context) => RoleBasedArtistSelectorDialog(
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
              children: selectedArtists
                  .map((artist) => Chip(
                        label: Text(
                          artist['name'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                        avatar: Icon(icon, size: 16, color: Colors.grey),
                        deleteIcon: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                      ))
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
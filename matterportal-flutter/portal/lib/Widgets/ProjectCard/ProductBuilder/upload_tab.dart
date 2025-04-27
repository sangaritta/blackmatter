import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:dotted_border/dotted_border.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:portal/Models/track.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Services/storage_service.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/track_editor.dart';
import 'package:portal/Constants/countries.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Widgets/Common/artist_selector.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:mime/mime.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:portal/BLoC/track_list_bloc.dart';

class UploadTab extends StatefulWidget {
  final String projectId;
  final String productId;
  final List<String> productArtists;
  final String productGenre;
  final String productSubgenre;
  final String coverImageUrl;
  final List<Track> tracks;
  final void Function(Track) onAddTrack;
  final void Function(int, Track) onUpdateTrack;
  final void Function(int) onRemoveTrack;

  const UploadTab({
    super.key,
    required this.projectId,
    required this.productId,
    required this.productArtists,
    required this.productGenre,
    required this.productSubgenre,
    required this.coverImageUrl,
    required this.tracks,
    required this.onAddTrack,
    required this.onUpdateTrack,
    required this.onRemoveTrack,
  });

  @override
  UploadTabState createState() => UploadTabState();
}

class UploadTabState extends State<UploadTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // NOTE: The following field is currently unreferenced or unused, but is retained per strict user policy to never remove code. It is safe to ignore unless explicitly requested for use or documentation.
  late Animation<double> _fadeAnimation;
  final Map<String, TextEditingController> trackTitleControllers = {};
  final Map<String, TextEditingController> trackVersionControllers = {};
  final Map<String, List<String>> trackArtistsMap = {};
  final Map<String, String> trackGenreMap = {};
  final Map<String, String> trackSubgenreMap = {};
  final Map<String, TextEditingController> trackLyricsLanguageControllers = {};
  final Map<String, bool> trackExplicitMap = {};
  int selectedTrackIndex = -1;
  final Map<String, TextEditingController> remixerControllers = {};
  final Map<String, TextEditingController> songwritersControllers = {};
  final Map<String, TextEditingController> producersControllers = {};
  final Map<String, TextEditingController> isrcControllers = {};
  final Map<String, TextEditingController> countryControllers = {};
  final Map<String, TextEditingController> nationalityControllers = {};
  final Map<String, List<String>> featuringArtistsMap = {};
  final Map<String, String> ownershipMap = {};
  final Map<String, bool> autoIsrcMap = {};
  String? coverImageUrl; // Add this state variable
  final List<String> ownershipOptions = [
    "I'm the original master copyright owner",
    "I acquired the master copyright",
    "I am the exclusive licensee (not the owner)",
    "I am a non-exclusive licensee (not the owner)",
    "I have no master rights",
  ];
  final Map<String, List<String>> songwritersMap = {};
  final Map<String, List<String>> producersMap = {};
  final Map<String, List<String>> remixersMap = {};
  late Future<void> _loadingFuture;
  final Map<String, List<Map<String, dynamic>>> performersWithRolesMap = {};
  final Map<String, List<Map<String, dynamic>>> songwritersWithRolesMap = {};
  final Map<String, List<Map<String, dynamic>>> productionWithRolesMap = {};

  final Map<String, int> trackNumberMap = {};
  final Map<String, Map<String, dynamic>> _trackDataMap = {};

  Map<String, double> fileUploadProgress = {};
  Map<String, bool> isUploading = {};
  Map<String, String> fileUrls = {};
  bool isDragging = false;

  late TrackListBloc _trackListBloc;

  String generateUID() {
    return '${DateTime.now().microsecondsSinceEpoch}_${UniqueKey()}';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCirc,
    );
    coverImageUrl = widget.coverImageUrl;
    final userId = auth.getUser()?.uid ?? '';
    _trackListBloc = TrackListBloc(
      userId: userId,
      projectId: widget.projectId,
      productId: widget.productId,
    );
    _loadingFuture = _loadExistingTracks();
    _trackListBloc.add(TrackListStarted());
  }

  @override
  void dispose() {
    _controller.dispose();
    _trackListBloc.close();
    super.dispose();
  }

  Future<void> _loadExistingTracks() async {
    try {
      final userId = auth.getUser()?.uid;
      print('[UploadTab] _loadExistingTracks: userId = ${userId}');
      if (userId == null) return;

      // First check if the product exists
      final productExists = await api.getProduct(
        userId,
        widget.projectId,
        widget.productId,
      );
      print(
        '[UploadTab] _loadExistingTracks: productExists = ${productExists != null}',
      );
      if (productExists == null) {
        // This is a new product, just return without throwing an error
        return;
      }

      // Update cover image URL from product data
      setState(() {
        coverImageUrl = productExists['coverImage'] ?? widget.coverImageUrl;
      });

      final tracks = await api.getTracksForProduct(
        userId,
        widget.projectId,
        widget.productId,
      );

      print(
        '[UploadTab] _loadExistingTracks: tracks loaded = ${tracks.length}',
      );
      // Sort tracks by track number
      tracks.sort((a, b) {
        final aTrackNumber = a['trackNumber'] ?? 0;
        final bTrackNumber = b['trackNumber'] ?? 0;
        return (aTrackNumber is int
                ? aTrackNumber
                : int.tryParse(aTrackNumber.toString()) ?? 0)
            .compareTo(
              bTrackNumber is int
                  ? bTrackNumber
                  : int.tryParse(bTrackNumber.toString()) ?? 0,
            );
      });

      if (!mounted) return;

      setState(() {
        for (var track in tracks) {
          // Safely get values with null checks and handle potential map values
          String fileName;
          String storagePath;

          // Handle fileName which could be a string or a map
          var rawFileName = track['fileName'];
          if (rawFileName is String) {
            fileName = rawFileName;
          } else if (rawFileName is Map) {
            fileName = rawFileName['name']?.toString() ?? '';
          } else {
            fileName = '';
          }

          // Handle storagePath which could be a string or a map
          var rawStoragePath = track['storagePath'];
          if (rawStoragePath is String) {
            storagePath = rawStoragePath;
          } else if (rawStoragePath is Map) {
            storagePath = rawStoragePath['path']?.toString() ?? '';
          } else {
            storagePath = '';
          }

          if (fileName.isEmpty) continue; // Skip if fileName is empty

          print(
            '[UploadTab] _loadExistingTracks: checking fileName = ${fileName}',
          );
          // Add to files list if not already present
          if (!widget.tracks.map((e) => e.fileName).contains(fileName)) {
            print(
              '[UploadTab] _loadExistingTracks: adding track fileName = ${fileName}',
            );
            widget.onAddTrack(
              Track(
                trackNumber:
                    track['trackNumber'] is int
                        ? track['trackNumber']
                        : int.tryParse(track['trackNumber'].toString()) ?? 0,
                title: track['title']?.toString() ?? '',
                version: track['version']?.toString() ?? '',
                isExplicit: track['isExplicit'] as bool? ?? false,
                primaryArtists: _convertToStringList(track['primaryArtists']),
                featuredArtists: _convertToStringList(
                  track['featuringArtists'],
                ),
                genre: widget.productGenre,
                performersWithRoles: _convertToPerformersWithRoles(
                  track['performersWithRoles'],
                ),
                songwritersWithRoles: _convertToSongwritersWithRoles(
                  track['songwritersWithRoles'],
                ),
                productionWithRoles: _convertToProductionWithRoles(
                  track['productionWithRoles'],
                ),
                isrc: track['isrcCode']?.toString() ?? 'AUTO',
                uid: track['trackId']?.toString() ?? '',
                remixers: _convertToStringList(track['remixers']),
                ownership: track['ownership']?.toString() ?? 'Original',
                country: track['country']?.toString() ?? '',
                nationality: track['nationality']?.toString() ?? '',
                artworkUrl: coverImageUrl ?? '',
                downloadUrl: storagePath,
              ),
            );
          }

          // Initialize all the maps and controllers
          fileUrls[fileName] = storagePath;
          isUploading[fileName] = false;
          fileUploadProgress[fileName] = 1.0;

          // Initialize controllers with saved data
          trackTitleControllers[fileName] = TextEditingController(
            text: track['title']?.toString() ?? '',
          );
          trackVersionControllers[fileName] = TextEditingController(
            text: track['version']?.toString() ?? '',
          );
          isrcControllers[fileName] = TextEditingController(
            text: track['isrcCode']?.toString() ?? 'AUTO',
          );
          countryControllers[fileName] = TextEditingController(
            text: track['country']?.toString() ?? '',
          );
          nationalityControllers[fileName] = TextEditingController(
            text: track['nationality']?.toString() ?? '',
          );

          // Initialize lists with null checks and proper type conversion
          trackArtistsMap[fileName] = _convertToStringList(
            track['primaryArtists'],
          );
          featuringArtistsMap[fileName] = _convertToStringList(
            track['featuringArtists'],
          );
          remixersMap[fileName] = _convertToStringList(track['remixers']);
          songwritersMap[fileName] = _convertToStringList(track['songwriters']);
          producersMap[fileName] = _convertToStringList(track['producers']);

          // Initialize other properties with defaults
          ownershipMap[fileName] = track['ownership']?.toString() ?? 'Original';
          trackExplicitMap.putIfAbsent(
            fileName,
            () => track['isExplicit'] as bool? ?? false,
          );

          // Initialize role maps with null checks
          performersWithRolesMap.putIfAbsent(fileName, () => []);
          songwritersWithRolesMap.putIfAbsent(fileName, () => []);
          productionWithRolesMap.putIfAbsent(fileName, () => []);

          // Initialize track number
          trackNumberMap[fileName] =
              track['trackNumber'] is int
                  ? track['trackNumber']
                  : int.tryParse(track['trackNumber'].toString()) ?? 0;
        }
        print(
          '[UploadTab] _loadExistingTracks: widget.tracks after load = ${widget.tracks.length}',
        );
      });
    } catch (e, stackTrace) {
      print('[UploadTab] Error loading tracks: ${e}\n${stackTrace}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tracks: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  // Helper method to convert dynamic list to List<String>
  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _convertToPerformersWithRoles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _convertToSongwritersWithRoles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _convertToProductionWithRoles(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        return BlocBuilder<TrackListBloc, TrackListState>(
          bloc: _trackListBloc,
          builder: (context, state) {
            if (state is TrackListLoading) {
              return const Center(child: LoadingIndicator());
            } else if (state is TrackListLoaded) {
              final trackList = state.tracks;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 700;
                  return isMobile
                      ? _buildMobileLayoutWithTracks(trackList)
                      : _buildDesktopLayoutWithTracks(trackList);
                },
              );
            } else if (state is TrackListError) {
              return Center(child: Text('Error: ${state.error}'));
            } else {
              return const Center(child: Text('No tracks found.'));
            }
          },
        );
      },
    );
  }

  Widget _buildReorderableTrackListWithBloc(
    List<Map<String, dynamic>> tracks,
    bool isMobile,
  ) {
    final List<Track> typedTracks = tracks.map((map) => Track.fromMap(map)).toList();
    // DEBUG: Check for null or duplicate UIDs
    final List<String?> uids = typedTracks.map((t) => t.uid).toList();
    assert(uids.every((uid) => uid != null), 'One or more track.uid is null: uids = ' + uids.toString());
    assert(uids.toSet().length == uids.length, 'Duplicate track.uid detected: uids = ' + uids.toString());
    debugPrint('Track UIDs for ReorderableListView: ' + uids.toString());

    if (typedTracks.isEmpty) {
      return Center(
        child: Text(
          'No tracks to display.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ReorderableListView.builder(
      itemCount: typedTracks.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        _handleReorder(oldIndex, newIndex, tracks);
      },
      itemBuilder: (context, index) {
        final track = typedTracks[index];
        final trackKey = ValueKey('${track.uid ?? 'track'}_$index');
        return isMobile
            ? Card(
              key: trackKey,
              color:
                  selectedTrackIndex == index
                      ? const Color(0xFF301934)
                      : const Color(0xFF1E1E1E),
              elevation: selectedTrackIndex == index ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side:
                    selectedTrackIndex == index
                        ? const BorderSide(color: Color(0xFF9C27B0), width: 2)
                        : BorderSide.none,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedTrackIndex = index;
                  });
                  if (isMobile) {
                    HapticFeedback.selectionClick();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                            size: isMobile ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.music_note, color: Colors.white),
                      ],
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.primaryArtists.join(', '),
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        widget.onRemoveTrack(index);
                      },
                    ),
                  ),
                ),
              ),
            )
            : GestureDetector(
              key: trackKey, // Key moved here!
              onTap: () {
                setState(() {
                  selectedTrackIndex = index;
                });
              },
              child: Card(
                color:
                    selectedTrackIndex == index
                        ? const Color(0xFF301934)
                        : const Color(0xFF1E1E1E),
                elevation: selectedTrackIndex == index ? 4 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side:
                      selectedTrackIndex == index
                          ? const BorderSide(color: Color(0xFF9C27B0), width: 2)
                          : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(
                            Icons.drag_handle,
                            color: Colors.grey,
                            size: isMobile ? 28 : 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.music_note, color: Colors.white),
                      ],
                    ),
                    title: Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.primaryArtists.join(', '),
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        widget.onRemoveTrack(index);
                      },
                    ),
                  ),
                ),
              ),
            );
      },
    );
  }

  Future<void> _handleReorder(
    int oldIndex,
    int newIndex,
    List<Map<String, dynamic>> tracks,
  ) async {
    final user = auth.getUser();
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
      }
      return;
    }
    // Prepare a new order and update Firestore directly, no optimistic UI.
    final reorderedTracks = List<Map<String, dynamic>>.from(tracks);
    final item = reorderedTracks.removeAt(oldIndex);
    reorderedTracks.insert(newIndex, item);
    for (int i = 0; i < reorderedTracks.length; i++) {
      reorderedTracks[i]['trackNumber'] = i + 1;
    }
    try {
      await api.updateMultipleTracks(
        user.uid,
        widget.projectId,
        widget.productId,
        reorderedTracks,
        // Removed onProgress: _onReorderProgress as optimistic UI/progress is not used.
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating track order: $e')),
        );
      }
    }
  }

  Widget _buildMobileLayoutWithTracks(List<Map<String, dynamic>> tracks) {
    return Column(
      children: [
        if (tracks.isNotEmpty)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8.0),
              child: _buildReorderableTrackListWithBloc(tracks, true),
            ),
          ),
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8.0),
            child: _buildDragDropArea(),
          ),
        ),
        if (selectedTrackIndex != -1 && selectedTrackIndex < tracks.length)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                _showMobileTrackEditor(context);
              },
              child: Text(
                'Edit ${Track.fromMap(tracks[selectedTrackIndex]).fileName}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopLayoutWithTracks(List<Map<String, dynamic>> tracks) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (tracks.isNotEmpty)
                Expanded(
                  child: _buildReorderableTrackListWithBloc(tracks, false),
                ),
              Expanded(child: _buildDragDropArea()),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCirc,
          child:
              tracks.isNotEmpty
                  ? const VerticalDivider(color: Colors.grey)
                  : const SizedBox.shrink(),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCirc,
          width:
              tracks.isNotEmpty ? MediaQuery.of(context).size.width * 0.5 : 0,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: MediaQuery.of(context).size.width * 0.5,
              child:
                  tracks.isNotEmpty
                      ? selectedTrackIndex != -1 &&
                              selectedTrackIndex < tracks.length
                          ? _buildTrackEditor()
                          : const Center(
                            child: Text(
                              'Select a track to edit',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  void _showMobileTrackEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Cover most of the screen
          minChildSize: 0.5, // At least half the screen
          maxChildSize: 0.95, // Almost full screen
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Edit Track',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Editor content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildTrackEditor(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTrackEditor() {
    if (selectedTrackIndex == -1 ||
        selectedTrackIndex >= widget.tracks.length) {
      return const Center(
        child: Text(
          'Select a track to edit',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final track = widget.tracks[selectedTrackIndex];
    final fileUrl = fileUrls[track.fileName] ?? ''; // Get the URL for the file

    // Initialize all controllers for this track
    trackTitleControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(text: track.fileName),
    );
    trackVersionControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(text: track.version ?? ''),
    );
    remixerControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(),
    );
    songwritersControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(),
    );
    producersControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(),
    );
    isrcControllers.putIfAbsent(track.fileName, () => TextEditingController());
    countryControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(),
    );
    nationalityControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(),
    );

    // Initialize maps
    trackArtistsMap.putIfAbsent(
      track.fileName,
      () => List.from(widget.productArtists),
    );
    featuringArtistsMap.putIfAbsent(track.fileName, () => []);
    ownershipMap.putIfAbsent(track.fileName, () => "Original");
    trackExplicitMap.putIfAbsent(track.fileName, () => false);
    final storagePath = fileUrls[track.fileName] ?? '';
    final isUploading = this.isUploading[track.fileName] ?? false;
    songwritersMap.putIfAbsent(track.fileName, () => []);
    producersMap.putIfAbsent(track.fileName, () => []);
    remixersMap.putIfAbsent(track.fileName, () => []);

    return TrackEditor(
      performersWithRoles: performersWithRolesMap[track.fileName] ?? [],
      onPerformersChanged:
          (roles) =>
              setState(() => performersWithRolesMap[track.fileName] = roles),
      songwritersWithRoles: songwritersWithRolesMap[track.fileName] ?? [],
      onSongwritersChanged:
          (roles) =>
              setState(() => songwritersWithRolesMap[track.fileName] = roles),
      productionWithRoles: productionWithRolesMap[track.fileName] ?? [],
      onProductionChanged:
          (roles) =>
              setState(() => productionWithRolesMap[track.fileName] = roles),
      productPrimaryArtists: widget.productArtists,
      fileName: track.fileName,
      fileUrl: storagePath,
      isUploading: isUploading,
      titleController: trackTitleControllers[track.fileName]!,
      versionController: trackVersionControllers[track.fileName]!,
      remixerController: remixerControllers[track.fileName]!,
      songwritersController: songwritersControllers[track.fileName]!,
      producersController: producersControllers[track.fileName]!,
      isrcController: isrcControllers[track.fileName]!,
      countryController: countryControllers[track.fileName]!,
      nationalityController: nationalityControllers[track.fileName]!,
      primaryArtists: trackArtistsMap[track.fileName]!,
      featuringArtists: featuringArtistsMap[track.fileName] ?? [],
      isExplicit: trackExplicitMap[track.fileName]!,
      ownership: ownershipMap[track.fileName]!,
      onExplicitChanged: (value) {
        setState(() {
          trackExplicitMap[track.fileName] = value;
        });
      },
      onOwnershipChanged: (value) {
        setState(() {
          ownershipMap[track.fileName] = value;
        });
      },
      onPrimaryArtistsChanged: (artists) {
        setState(() {
          trackArtistsMap[track.fileName] = artists;
        });
      },
      onFeaturingArtistsChanged: (artists) {
        setState(() {
          featuringArtistsMap[track.fileName] = artists;
        });
      },
      remixers: remixersMap[track.fileName]!,
      onRemixersChanged: (remixers) {
        setState(() {
          remixersMap[track.fileName] = remixers;
        });
      },
      projectId: widget.projectId,
      productId: widget.productId,
      artworkUrl:
          coverImageUrl ??
          '', // Use the loaded cover art URL with default empty string
    );
  }

  Widget _buildDragDropArea() {
    return Padding(
      padding: EdgeInsets.all(widget.tracks.isEmpty ? 32.0 : 16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: DottedBorder(
            color: isDragging ? Colors.blue : Colors.grey,
            strokeWidth: 2,
            dashPattern: const [6, 3],
            borderType: BorderType.RRect,
            radius: const Radius.circular(20),
            child: DropTarget(
              onDragEntered: (_) => setState(() => isDragging = true),
              onDragExited: (_) => setState(() => isDragging = false),
              onDragDone: (details) async {
                print('Files dragged: ${details.files.length}');
                setState(() => isDragging = false);
                for (var file in details.files) {
                  final bytes = await file.readAsBytes();
                  final htmlFile = html.File(
                    [bytes],
                    file.name,
                    {'type': file.mimeType},
                  );
                  _handleFileUpload(htmlFile);
                }
              },
              child: Container(
                padding: EdgeInsets.all(widget.tracks.isEmpty ? 32.0 : 16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: isDragging ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Drag and Drop Files Here',
                        style: TextStyle(
                          color: isDragging ? Colors.blue : Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          html.FileUploadInputElement uploadInput =
                              html.FileUploadInputElement();
                          uploadInput.accept = '.wav';
                          uploadInput.multiple = true;
                          uploadInput.click();

                          uploadInput.onChange.listen((e) {
                            final files = uploadInput.files;
                            if (files != null) {
                              for (var file in files) {
                                _handleFileUpload(file);
                              }
                            }
                          });
                        },
                        child: const Text('Or Select Your Files'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleFileUpload(html.File file) async {
    final String lowerFileName = file.name.toLowerCase();
    final mimeType = lookupMimeType(file.name) ?? 'audio/wav';
    if (!lowerFileName.endsWith('.wav')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only .wav files are accepted'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    if (!mimeType.contains('audio/')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The file must be an audio file'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final userId = auth.getUser()?.uid;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      isUploading[file.name] = true;
      fileUploadProgress[file.name] = 0.0;
    });
    try {
      await api.uploadTrack(
        userId: userId,
        projectId: widget.projectId,
        productId: widget.productId,
        file: file,
        primaryArtists: widget.productArtists,
        genre: widget.productGenre,
        artworkUrl: coverImageUrl ?? '',
      );
      if (mounted) {
        setState(() {
          isUploading[file.name] = false;
          fileUploadProgress[file.name] = 1.0;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading[file.name] = false;
          fileUploadProgress[file.name] = 1.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload file: ${file.name} ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // NOTE: The following method is currently unreferenced or unused, but is retained per strict user policy to never remove code. It is safe to ignore unless explicitly requested for use or documentation.
  Future<void> _updateTrackNumbers() async {
    final userId = auth.getUser()?.uid;
    if (userId == null) return;

    try {
      List<Map<String, dynamic>> tracksToUpdate = [];

      for (int i = 0; i < widget.tracks.length; i++) {
        final track = widget.tracks[i];
        final trackNumber = i + 1;

        if (_trackDataMap.containsKey(track.fileName) &&
            _trackDataMap[track.fileName] != null) {
          Map<String, dynamic> trackData = Map.from(
            _trackDataMap[track.fileName]!,
          );
          trackData['trackNumber'] = trackNumber;
          trackData['id'] = trackData['trackId'] ?? '';

          tracksToUpdate.add(trackData);
        }
      }

      if (tracksToUpdate.isNotEmpty) {
        await api.updateMultipleTracks(
          userId,
          widget.projectId,
          widget.productId,
          tracksToUpdate,
        );
      }
    } catch (e) {
      print('Error updating track numbers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating track order: $e')),
        );
      }
    }
  }

  // NOTE: The following method is currently unreferenced or unused, but is retained per strict user policy to never remove code. It is safe to ignore unless explicitly requested for use or documentation.
  Widget _buildTrackMetadata(String fileName) {
    return Column(
      children: [
        TextFormField(
          controller: trackTitleControllers[fileName],
          decoration: InputDecoration(
            labelText:
                'Title${trackVersionControllers[fileName]?.text.isNotEmpty == true ? " (${trackVersionControllers[fileName]?.text})" : ""}',
          ),
        ),
        ArtistSelector(
          label: 'Remixer',
          selectedArtists: trackArtistsMap[fileName] ?? [],
          onChanged: (artists) {
            setState(() {
              trackArtistsMap[fileName] = artists;
            });
          },
          collection: 'artists', // Use artists collection
        ),

        ArtistSelector(
          label: 'Songwriters',
          selectedArtists: songwritersMap[fileName] ?? [],
          onChanged: (writers) {
            setState(() {
              songwritersMap[fileName] = writers;
            });
          },
          collection: 'songwriters', // Use separate collection
        ),

        ArtistSelector(
          label: 'Producer',
          selectedArtists: producersMap[fileName] ?? [],
          onChanged: (producers) {
            setState(() {
              producersMap[fileName] = producers;
            });
          },
          collection: 'artists', // Use artists collection
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto ISRC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: fontNameBold,
                ),
              ),
              Switch(
                value: autoIsrcMap[fileName] ?? true,
                onChanged: (value) {
                  setState(() {
                    autoIsrcMap[fileName] = value;
                    if (value) {
                      isrcControllers[fileName]?.text = 'AUTO';
                    }
                  });
                },
                activeColor: Colors.blue,
                activeTrackColor: Colors.blue.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ),
        if (!(autoIsrcMap[fileName] ?? true))
          TextFormField(
            controller: isrcControllers[fileName],
            decoration: const InputDecoration(labelText: 'ISRC'),
          ),

        DropdownButtonFormField<String>(
          value: ownershipMap[fileName],
          decoration: const InputDecoration(labelText: 'Ownership'),
          items:
              ownershipOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              ownershipMap[fileName] = newValue!;
            });
          },
        ),

        DropdownButtonFormField<Country>(
          value: countries.firstWhere(
            (c) => c.code == (countryControllers[fileName]?.text ?? 'US'),
            orElse: () => countries.firstWhere((c) => c.code == 'US'),
          ),
          decoration: const InputDecoration(labelText: 'Country'),
          items:
              countries.map((Country country) {
                return DropdownMenuItem<Country>(
                  value: country,
                  child: Row(
                    children: [
                      Text(country.flag),
                      const SizedBox(width: 8),
                      Text(country.name),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (Country? newValue) {
            setState(() {
              countryControllers[fileName]?.text = newValue?.code ?? 'US';
            });
          },
        ),
      ],
    );
  }

  // NOTE: The following method is currently unreferenced or unused, but is retained per strict user policy to never remove code. It is safe to ignore unless explicitly requested for use or documentation.
  String _formatTrackDisplayText(Track track) {
    String displayText = track.title;
    if (track.version?.isNotEmpty == true) {
      displayText += ' (${track.version})';
    }
    return displayText;
  }

  // NOTE: The following method is currently unreferenced or unused, but is retained per strict user policy to never remove code. It is safe to ignore unless explicitly requested for use or documentation.
  String _formatArtistsDisplayText(Track track) {
    String artistText = track.primaryArtists.join(', ');
    if (track.featuredArtists?.isNotEmpty == true) {
      artistText += ' (feat. ${track.featuredArtists!.join(', ')})';
    }
    return artistText;
  }
}

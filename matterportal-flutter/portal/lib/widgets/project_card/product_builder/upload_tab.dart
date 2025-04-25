import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:dotted_border/dotted_border.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:portal/models/track.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Services/storage_service.dart';
import 'package:portal/widgets/project_card/product_builder/track_editor.dart';
import 'package:mime/mime.dart';
import 'package:universal_html/html.dart' as html;

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
    _loadingFuture = _loadExistingTracks();
  }

  Future<void> _loadExistingTracks() async {
    try {
      final userId = AuthService.instance.currentUser?.uid;
      if (userId == null) return;

      // First check if the product exists
      final productExists = await ApiService().getProduct(
        userId,
        widget.projectId,
        widget.productId,
      );
      if (productExists == null) {
        // This is a new product, just return without throwing an error
        return;
      }

      // Update cover image URL from product data
      setState(() {
        coverImageUrl = productExists.coverImage;
      });

      final tracks = await ApiService().getTracksForProduct(
        userId,
        widget.projectId,
        widget.productId,
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

          // Add to files list if not already present
          if (!widget.tracks.map((e) => e.fileName).contains(fileName)) {
            widget.onAddTrack(
              Track(
                id: track['id']?.toString() ?? '',
                productId: widget.productId,
                projectId: widget.projectId,
                userId: AuthService.instance.currentUser?.uid ?? '',
                name: fileName,
                fileName: fileName,
                storagePath: storagePath,
                isrcCode: track['isrcCode']?.toString() ?? '',
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
      });
    } catch (e) {
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a mobile device
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.grey[800],
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E)),
      ),
      child: FutureBuilder(
        future: _loadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError &&
              !snapshot.error.toString().contains('Product not found')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tracks: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadingFuture = _loadExistingTracks();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (widget.tracks.isEmpty) {
            _controller.forward();
          } else {
            _controller.reverse();
          }

          // Use a responsive layout that adapts to mobile
          return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
        },
      ),
    );
  }

  // Mobile-specific layout
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Track list with drag handles optimized for touch
        if (widget.tracks.isNotEmpty)
          Expanded(
            flex: 3, // More space for the track list on mobile
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8.0),
              child: _buildReorderableTrackList(true), // true for mobile
            ),
          ),

        // Drag-drop area with mobile optimizations
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8.0),
            child: _buildDragDropArea(),
          ),
        ),

        // Bottom sheet for track editor (appears when track is selected)
        if (selectedTrackIndex != -1 &&
            selectedTrackIndex < widget.tracks.length)
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
                'Edit ${widget.tracks[selectedTrackIndex].fileName}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  // Desktop-specific layout (original layout with refinements)
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Track list and drag-drop area
        Expanded(
          flex: 2, // Smaller flex for the list
          child: Column(
            children: [
              // Reorderable track list
              if (widget.tracks.isNotEmpty)
                Expanded(
                  child: _buildReorderableTrackList(false), // false for desktop
                ),

              // Drag-drop area
              Expanded(child: _buildDragDropArea()),
            ],
          ),
        ),

        // Animated divider
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCirc,
          child:
              widget.tracks.isNotEmpty
                  ? const VerticalDivider(color: Colors.grey)
                  : const SizedBox.shrink(),
        ),

        // Right side - Track editor with animation
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCirc,
          width:
              widget.tracks.isNotEmpty
                  ? MediaQuery.of(context).size.width * 0.5
                  : 0, // Increased width
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth:
                  MediaQuery.of(context).size.width * 0.5, // Increased width
              child:
                  widget.tracks.isNotEmpty
                      ? selectedTrackIndex != -1 &&
                              selectedTrackIndex < widget.tracks.length
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

  // Show mobile track editor in a modal bottom sheet
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

  // Enhanced reorderable track list with mobile optimizations
  Widget _buildReorderableTrackList(bool isMobile) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: widget.tracks.length,
      onReorder: (oldIndex, newIndex) async {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = widget.tracks.removeAt(oldIndex);
          widget.tracks.insert(newIndex, item);

          // Update selected track index if needed
          if (selectedTrackIndex == oldIndex) {
            selectedTrackIndex = newIndex;
          } else if (selectedTrackIndex == newIndex) {
            selectedTrackIndex = oldIndex;
          }
        });

        // Update track numbers for all affected tracks
        await _updateTrackNumbers();
      },
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        final progress = fileUploadProgress[track.fileName] ?? 0;

        // Update track number in the map to match current index
        trackNumberMap[track.fileName] = index + 1;

        return Card(
          key: ValueKey(track.fileName),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color:
              selectedTrackIndex == index
                  ? const Color(0xFF301934) // Deep purple when selected
                  : const Color(0xFF1E1E1E), // Dark background
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

              // For mobile, trigger haptic feedback
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
                    // Extended tap target for mobile
                    Container(
                      width: isMobile ? 44 : 32, // Wider for mobile
                      height: isMobile ? 44 : 32, // Taller for mobile
                      alignment: Alignment.center,
                      child: ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_handle,
                          color: Colors.grey,
                          size: isMobile ? 28 : 24, // Larger icon for mobile
                        ),
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
                  _formatTrackDisplayText(track),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatArtistsDisplayText(track),
                      style: TextStyle(color: Colors.grey.shade300),
                      overflow: TextOverflow.ellipsis,
                    ),
                    AnimatedOpacity(
                      opacity: progress < 1.0 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            tween: Tween<double>(begin: 0, end: progress),
                            builder:
                                (context, value, _) => LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.grey[800],
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF9C27B0),
                                      ),
                                  minHeight: 6,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (track.isExplicit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isMobile) const SizedBox(width: 8),
                    if (isMobile)
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

    // Initialize all controllers for this track
    trackTitleControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(text: track.fileName),
    );
    trackVersionControllers.putIfAbsent(
      track.fileName,
      () => TextEditingController(),
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
    songwritersMap.putIfAbsent(track.fileName, () => []);
    producersMap.putIfAbsent(track.fileName, () => []);
    remixersMap.putIfAbsent(track.fileName, () => []);

    return TrackEditor(
      fileUrl: fileUrls[track.fileName] ?? '',
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
      isUploading: isUploading[track.fileName] ?? false,
      titleController: trackTitleControllers[track.fileName]!,
      versionController: trackVersionControllers[track.fileName]!,
      remixerController: remixerControllers[track.fileName]!,
      songwritersController: songwritersControllers[track.fileName]!,
      producersController: producersControllers[track.fileName]!,
      isrcController: isrcControllers[track.fileName]!,
      countryController: countryControllers[track.fileName]!,
      nationalityController: nationalityControllers[track.fileName]!,
      primaryArtists: trackArtistsMap[track.fileName]!,
      featuringArtists: featuringArtistsMap[track.fileName]!,
      isExplicit: trackExplicitMap[track.fileName]!,
      ownership: ownershipMap[track.fileName]!,
      onExplicitChanged: (value) {
        setState(() {
          trackExplicitMap[track.fileName] = value;
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
          }
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

  void _handleFileUpload(html.File file) async {
    // Validate that this is a .wav file
    final String lowerFileName = file.name.toLowerCase();
    final mimeType = lookupMimeType(file.name) ?? 'audio/wav';

    // Strict validation for .wav files only
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

    // Additional MIME type validation
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

    // Calculate track number from current list length
    final newTrackNumber = widget.tracks.length + 1;

    setState(() {
      fileUploadProgress[file.name] = 0;
      isUploading[file.name] = true;
      trackNumberMap[file.name] = newTrackNumber; // Set initial track number

      // Initialize controllers
      trackTitleControllers[file.name] = TextEditingController(
        text: file.name.replaceAll('.wav', ''),
      );
      trackVersionControllers[file.name] = TextEditingController();
      remixerControllers[file.name] = TextEditingController();
      songwritersControllers[file.name] = TextEditingController();
      producersControllers[file.name] = TextEditingController();
      isrcControllers[file.name] = TextEditingController(text: 'AUTO');
      countryControllers[file.name] = TextEditingController();
      nationalityControllers[file.name] = TextEditingController();

      // Initialize maps
      trackArtistsMap[file.name] = List.from(widget.productArtists);
      featuringArtistsMap[file.name] = [];
      remixersMap[file.name] = [];
      songwritersMap[file.name] = [];
      producersMap[file.name] = [];
      trackExplicitMap.putIfAbsent(file.name, () => false);
      ownershipMap.putIfAbsent(file.name, () => "Original");
      autoIsrcMap[file.name] = true;
    });

    try {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) async {
        final bytes = Uint8List.fromList(reader.result as List<int>);
        final userId = AuthService.instance.currentUser?.uid;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        final trackId = generateUID();
        final fileName = '${trackId}_${file.name}';
        var uploadPath = await ApiService().getAudioUploadPath(
          userId,
          widget.projectId,
          widget.productId,
          fileName,
        );

        var fileInfo = await st.uploadFileFromBytes(bytes, uploadPath, (
          double progress,
        ) {
          setState(() {
            fileUploadProgress[file.name] = progress;
          });
        }, mimeType: mimeType);

        if (fileInfo['url'] != null && fileInfo['path'] != null) {
          setState(() {
            fileUrls[file.name] = fileInfo['path']!;
            isUploading[file.name] = false;
          });

          widget.onAddTrack(
            Track(
              userId: userId,
              name: file.name,
              storagePath: fileInfo['path']!,
              isrcCode: 'AUTO',
              id: trackId,
              trackNumber: newTrackNumber,
              title: file.name.replaceAll('.wav', ''),
              version: '',
              isExplicit: false,
              primaryArtists: widget.productArtists,
              featuredArtists: [],
              genre: widget.productGenre,
              performersWithRoles: [],
              songwritersWithRoles: [],
              productionWithRoles: [],
              isrc: 'AUTO',
              uid: trackId,
              remixers: [],
              ownership: "Original",
              country: '',
              nationality: '',
              artworkUrl: coverImageUrl ?? '',
              downloadUrl: fileInfo['url'] ?? '',
              fileName: fileName,
              projectId: widget.projectId,
              productId: widget.productId,
            ),
          );

          // Trigger haptic feedback on successful upload
          HapticFeedback.mediumImpact();
        }
      });
    } catch (e) {
      setState(() {
        fileUploadProgress[file.name] = 1.0;
        isUploading[file.name] = false;
      });
      if (mounted) {
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

  // Add a method to update track numbers in Firestore after reordering
  Future<void> _updateTrackNumbers() async {
    final userId = AuthService.instance.currentUser!.uid;

    try {
      List<Map<String, dynamic>> tracksToUpdate = [];

      // Prepare all track updates with their new numbers
      for (int i = 0; i < widget.tracks.length; i++) {
        final track = widget.tracks[i];
        final trackNumber = i + 1;

        // Only add to update list if we have track data and the track exists
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

      // Use the batch update method to efficiently update all tracks
      if (tracksToUpdate.isNotEmpty) {
        await ApiService().updateMultipleTracks(
          userId,
          widget.projectId,
          widget.productId,
          tracksToUpdate,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating track order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this function to format track display text
  String _formatTrackDisplayText(Track track) {
    String displayText = track.title;
    if (track.version?.isNotEmpty == true) {
      displayText += ' (${track.version})';
    }
    return displayText;
  }

  // Add this function to format artists display text
  String _formatArtistsDisplayText(Track track) {
    String artistText = track.primaryArtists.join(', ');
    if (track.featuredArtists?.isNotEmpty == true) {
      artistText += ' (feat. ${track.featuredArtists!.join(', ')})';
    }
    return artistText;
  }
}

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:portal/Constants/product.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/storage_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/information_tab.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/release_tab.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/product_status_overlay.dart';
import 'package:portal/Screens/Home/Mobile/mobile_track_editor.dart';
import 'package:portal/Widgets/ProjectCard/utils.dart';
import 'package:mime/mime.dart';
import 'dart:developer' as developer;
import 'package:portal/utils/cross_platform_file_picker.dart';

class MobileProductBuilder extends StatefulWidget {
  final String projectId;
  final String productId;
  final Map<String, dynamic>? product;
  final bool isNew;

  const MobileProductBuilder({
    super.key,
    required this.projectId,
    required this.productId,
    this.product,
    this.isNew = false,
  });

  @override
  State<MobileProductBuilder> createState() => _MobileProductBuilderState();
}

class _MobileProductBuilderState extends State<MobileProductBuilder>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isInformationComplete = false;
  String productStatus = '';
  Map<String, dynamic> _productData = {};

  // Track upload state variables
  Map<String, double> fileUploadProgress = {};
  Map<String, bool> isUploading = {};
  Map<String, String> fileUrls = {};
  final Map<String, Map<String, dynamic>> _trackDataMap = {};
  bool isDragging = false;

  // Controllers for form fields
  final TextEditingController releaseTitleController = TextEditingController();
  final TextEditingController releaseVersionController =
      TextEditingController();
  final TextEditingController primaryArtistsController =
      TextEditingController();
  final TextEditingController songwritersController = TextEditingController();
  final TextEditingController upcController = TextEditingController();
  final TextEditingController uidController = TextEditingController();
  final TextEditingController labelController = TextEditingController();
  final TextEditingController cLineController = TextEditingController();
  final TextEditingController pLineController = TextEditingController();
  // Selected values
  MetadataLanguage? selectedMetadataLanguage;
  String? selectedGenre;
  String? selectedSubgenre;
  String? selectedProductType;
  String? selectedPrice;
  List<String> selectedArtists = [];
  Uint8List? _selectedImageBytes;
  String? coverImageUrl;
  String? previewArtUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isNew) {
        // Set defaults for new product
        selectedProductType = "Single";
        selectedMetadataLanguage =
            metadataLanguages.isNotEmpty ? metadataLanguages[0] : null;
        releaseTitleController.text = 'Untitled';
        selectedArtists = [];
      } else if (widget.product != null) {
        // Use provided product data
        _productData = widget.product!;
        _populateFieldsFromProductData();
      } else {
        // Fetch product data from Firebase
        await _fetchProductData();
      }

      // Fetch product status
      await _fetchProductStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchProductData() async {
    final userId = auth.getUser()?.uid;
    if (userId == null) return;

    final docSnapshot = await FirebaseFirestore.instance
        .collection("catalog")
        .doc(userId)
        .collection('projects')
        .doc(widget.projectId)
        .collection('products')
        .doc(widget.productId)
        .get();

    if (docSnapshot.exists) {
      _productData = docSnapshot.data() ?? {};
      _populateFieldsFromProductData();
    }
  }

  void _populateFieldsFromProductData() {
    // Populate controllers with data
    releaseTitleController.text = _productData['releaseTitle'] ?? 'Untitled';
    releaseVersionController.text = _productData['releaseVersion'] ?? '';
    upcController.text = _productData['upc'] ?? '';
    labelController.text = _productData['label'] ?? '';
    cLineController.text = _productData['cLine'] ?? '';
    pLineController.text = _productData['pLine'] ?? '';

    // Set selected values
    selectedProductType = _productData['type'] ?? "Single";
    selectedGenre = _productData['genre'];
    selectedSubgenre = _productData['subgenre'];
    selectedPrice = _productData['price']?.toString();
    coverImageUrl = _productData['coverImage'];
    previewArtUrl = _productData['previewArtUrl'];

    // Handle language
    String? languageCode = _productData['metadataLanguage'];
    if (languageCode != null) {
      selectedMetadataLanguage = metadataLanguages.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => metadataLanguages.isNotEmpty
            ? metadataLanguages[0]
            : const MetadataLanguage('en', 'English'),
      );
    } else {
      selectedMetadataLanguage = metadataLanguages.isNotEmpty
          ? metadataLanguages[0]
          : const MetadataLanguage('en', 'English');
    }

    // Handle artists
    if (_productData['primaryArtists'] != null) {
      selectedArtists = List<String>.from(_productData['primaryArtists']);
    }
  }

  Future<void> _fetchProductStatus() async {
    try {
      if (widget.productId.isEmpty) return;

      final userId = auth.getUser()?.uid;
      if (userId == null) return;

      final docSnapshot = await FirebaseFirestore.instance
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(widget.projectId)
          .collection('products')
          .doc(widget.productId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('state')) {
          setState(() {
            productStatus = data['state'] ?? '';
          });
        }
      }
    } catch (e) {
      developer.log('Error fetching product status: $e',
          name: 'MobileProductBuilder');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    releaseTitleController.dispose();
    releaseVersionController.dispose();
    primaryArtistsController.dispose();
    songwritersController.dispose();
    upcController.dispose();
    uidController.dispose();
    labelController.dispose();
    cLineController.dispose();
    pLineController.dispose();
    super.dispose();
  }

  void _handleProductTypeChange(String newType) {
    setState(() {
      selectedProductType = newType;
    });
  }

  bool _shouldShowStatusOverlay() {
    return ['Processing', 'In Review', 'Approved'].contains(productStatus);
  }

  Widget _buildMobileUploadTab() {
    final userId = auth.getUser()?.uid;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userId == null
          ? const Stream.empty()
          : api.getTracksStream(userId, widget.projectId, widget.productId),
      builder: (context, snapshot) {
        // Show nothing while waiting for first data to avoid flicker
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
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
                    setState(() {});
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final tracks = snapshot.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _uploadNewTrack(),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload New Track'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: tracks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note,
                              color: Colors.grey[600], size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No tracks yet',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload your first track',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : _buildReorderableTrackList(tracks),
            ),
          ],
        );
      },
    );
  }

  // Reorderable track list for mobile
  Widget _buildReorderableTrackList(List<Map<String, dynamic>> tracks) {
    return Stack(
      children: [
        ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: tracks.length,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) newIndex -= 1;
            final item = tracks.removeAt(oldIndex);
            tracks.insert(newIndex, item);
            for (int i = 0; i < tracks.length; i++) {
              tracks[i]['trackNumber'] = i + 1;
            }
            try {
              await _updateTrackNumbers(tracks);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating track order: $e')),
                );
              }
            }
            HapticFeedback.mediumImpact();
          },
          itemBuilder: (context, index) {
            final track = tracks[index];
            final title = track['title'] ?? 'Untitled Track';
            final version = track['version'] ?? '';
            final displayTitle = version.isNotEmpty ? '$title ($version)' : title;
            final isExplicit = track['isExplicit'] ?? false;
            track['trackNumber'] = index + 1;
            List<String> artists = [];
            if (track['primaryArtists'] != null) {
              artists = List<String>.from(track['primaryArtists']);
            }
            final artistsText = artists.join(', ');
            final isUploading = this.isUploading[track['fileName']] ?? false;
            final progress = fileUploadProgress[track['fileName']] ?? 1.0;
            return Card(
              key: ValueKey(track['id']),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.drag_handle,
                              color: Colors.grey,
                              size: 28,
                            ),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.purple.shade800,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isExplicit)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(4),
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
                      ],
                    ),
                    subtitle: Text(
                      artistsText.isEmpty ? 'No artists' : artistsText,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    onTap: () => _openTrackEditor(track),
                    trailing: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  AnimatedOpacity(
                    opacity: isUploading ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[800],
                          color: Colors.purple,
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Add a method to update track numbers in Firestore after reordering
  Future<void> _updateTrackNumbers(List<Map<String, dynamic>> tracks) async {
    final userId = auth.getUser()?.uid;
    if (userId == null) return;
    try {
      List<Map<String, dynamic>> tracksToUpdate = [];
      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final trackNumber = i + 1;
        Map<String, dynamic> trackData = Map.from(track);
        trackData['trackNumber'] = trackNumber;
        trackData['id'] = track['id'] ?? track['trackId'] ?? '';
        tracksToUpdate.add(trackData);
      }
      if (tracksToUpdate.isNotEmpty) {
        await api.updateMultipleTracks(
          userId,
          widget.projectId,
          widget.productId,
          tracksToUpdate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Track order updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating track numbers: $e');
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

  Future<List<Map<String, dynamic>>> _fetchTracks() async {
    try {
      final userId = auth.getUser()?.uid;
      if (userId == null) return [];

      final tracks = await FirebaseFirestore.instance
          .collection("catalog")
          .doc(userId)
          .collection('projects')
          .doc(widget.projectId)
          .collection('products')
          .doc(widget.productId)
          .collection('tracks')
          .orderBy('trackNumber')
          .get();

      return tracks.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      developer.log('Error fetching tracks: $e', name: 'MobileProductBuilder');
      return [];
    }
  }

  void _uploadNewTrack() async {
    await pickWavFiles(_handleFileUpload);
  }

  Future<void> _handleFileUpload(dynamic file) async {
    // For web: file is html.File. For mobile/desktop: file is PlatformFile.
    final String lowerFileName = file.name.toLowerCase();
    final mimeType = lookupMimeType(file.name) ?? 'audio/wav';
    if (!lowerFileName.endsWith('.wav')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Only .wav files are supported.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    try {
      setState(() {
        isUploading[file.name] = true;
      });
      final userId = auth.getUser()?.uid;
      if (userId == null) throw Exception('User not authenticated');
      final trackId = generateUID();
      final fileName = '${trackId}_${file.name}';
      var uploadPath = await api.getAudioUploadPath(
          userId, widget.projectId, widget.productId, fileName);
      Uint8List bytes;
      if (file.runtimeType.toString() == 'File') {
        // Web: html.File
        final reader = await _getHtmlFileReader();
        final completer = Completer<Uint8List>();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          completer.complete(reader.result as Uint8List);
        });
        bytes = await completer.future;
      } else {
        // Mobile/Desktop: PlatformFile
        bytes = Uint8List.fromList(file.bytes ?? []);
      }
      var fileInfo = await st.uploadFileFromBytes(
        bytes,
        uploadPath,
        (double progress) {
          setState(() {
            fileUploadProgress[file.name] = progress;
          });
        },
        mimeType: mimeType,
      );
      if (fileInfo['url'] != null && fileInfo['path'] != null) {
        final newTrackNumber = await _getNextTrackNumber();
        await api.saveTrackReference(
          userId,
          widget.projectId,
          widget.productId,
          trackId,
          {
            'fileName': file.name,
            'storagePath': fileInfo['path'],
            'downloadUrl': fileInfo['url'],
            'uploadedAt': FieldValue.serverTimestamp(),
            'trackId': trackId,
            'title': file.name.replaceAll('.wav', ''),
            'primaryArtists': selectedArtists,
            'featuringArtists': [],
            'isExplicit': false,
            'ownership': "Original",
            'isrcCode': 'AUTO',
            'trackNumber': newTrackNumber,
          },
        );
        setState(() {
          fileUrls[file.name] = fileInfo['path']!;
          isUploading[file.name] = false;
          fileUploadProgress[file.name] = 1.0;
          _trackDataMap[file.name] = {
            'fileName': file.name,
            'storagePath': fileInfo['path'],
            'downloadUrl': fileInfo['url'],
            'trackId': trackId,
            'title': file.name.replaceAll('.wav', ''),
            'primaryArtists': selectedArtists,
            'featuringArtists': [],
            'isExplicit': false,
            'ownership': "Original",
            'isrcCode': 'AUTO',
            'trackNumber': newTrackNumber,
          };
        });
        HapticFeedback.mediumImpact();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Track "${file.name}" uploaded successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        fileUploadProgress[file.name] = 0;
        isUploading[file.name] = false;
      });
      developer.log('Error uploading file: $e', name: 'MobileProductBuilder');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // Helper for dynamic html FileReader (web only)
  Future<dynamic> _getHtmlFileReader() async {
    // This function will only be used on web, so it's safe to use conditional import here.
    // On non-web, this will never be called.
    return Future.value(null); // Will be replaced by actual FileReader on web.
  }

  // Helper method to get the next track number
  Future<int> _getNextTrackNumber() async {
    try {
      final tracks = await _fetchTracks();
      if (tracks.isEmpty) return 1;

      // Find the highest track number and increment by 1
      int highestTrackNumber = 0;
      for (var track in tracks) {
        final trackNumber = track['trackNumber'] is int
            ? track['trackNumber']
            : int.tryParse(track['trackNumber'].toString()) ?? 0;
        if (trackNumber > highestTrackNumber) {
          highestTrackNumber = trackNumber;
        }
      }
      return highestTrackNumber + 1;
    } catch (e) {
      print('Error determining next track number: $e');
      return 1; // Default to 1 if we can't determine
    }
  }

  void _openTrackEditor(Map<String, dynamic> track) {
    // Create text controllers for the track editor
    final titleController = TextEditingController(text: track['title'] ?? '');
    final versionController =
        TextEditingController(text: track['version'] ?? '');
    final remixerController = TextEditingController();
    final songwritersController = TextEditingController();
    final producersController = TextEditingController();
    final isrcController =
        TextEditingController(text: track['isrcCode'] ?? 'AUTO');
    final countryController =
        TextEditingController(text: track['country'] ?? '');
    final nationalityController =
        TextEditingController(text: track['nationality'] ?? '');

    // Extract lists from track data
    final primaryArtists = track['primaryArtists'] != null
        ? List<String>.from(track['primaryArtists'])
        : <String>[];
    final featuringArtists = track['featuringArtists'] != null
        ? List<String>.from(track['featuringArtists'])
        : <String>[];
    final remixers = track['remixers'] != null
        ? List<String>.from(track['remixers'])
        : <String>[];

    // Extract role-based lists
    final performersWithRoles = _convertListToMapList(track['performers']);
    final songwritersWithRoles = _convertListToMapList(track['songwriters']);
    final productionWithRoles = _convertListToMapList(track['production']);

    // Navigate to track editor screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileTrackEditor(
          projectId: widget.projectId,
          productId: widget.productId,
          trackId: track['id'] ?? '',
          track: track,
          fileName: track['fileName'] ?? 'Unknown',
          fileUrl: track['downloadUrl'] ?? '',
          titleController: titleController,
          versionController: versionController,
          remixerController: remixerController,
          songwritersController: songwritersController,
          producersController: producersController,
          isrcController: isrcController,
          countryController: countryController,
          nationalityController: nationalityController,
          primaryArtists: primaryArtists,
          featuringArtists: featuringArtists,
          remixers: remixers,
          isExplicit: track['isExplicit'] ?? false,
          ownership: track['ownership'] ?? 'Original',
          performersWithRoles: performersWithRoles,
          songwritersWithRoles: songwritersWithRoles,
          productionWithRoles: productionWithRoles,
          productPrimaryArtists: selectedArtists,
          artworkUrl: coverImageUrl,
        ),
      ),
    ).then((_) {
      // Refresh the track list when returning from editor
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Project(id: widget.projectId, name: '', artist: ''),
      child: Scaffold(
        backgroundColor: const Color(0xFF18162E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1B2C),
          title: Text(
            widget.isNew ? 'New Product' : 'Edit Product',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: LoadingIndicator(
                  size: 50,
                  color: Colors.white,
                ),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      // Numbered tabs
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.purple,
                        labelPadding: EdgeInsets.zero, // Remove default padding
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Info',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 2),
                                Icon(
                                  _isInformationComplete
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: _isInformationComplete
                                      ? Colors.green
                                      : Colors.red,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '2',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Tracks',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '3',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Release',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Information Tab (Mobile Optimized)
                            Consumer<Project>(
                              builder: (context, project, child) {
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: InformationTab(
                                    productId: widget.productId,
                                    releaseTitleController:
                                        releaseTitleController,
                                    releaseVersionController:
                                        releaseVersionController,
                                    primaryArtistsController:
                                        primaryArtistsController,
                                    upcController: upcController,
                                    uidController: uidController,
                                    labelController: labelController,
                                    cLineController: cLineController,
                                    pLineController: pLineController,
                                    selectedMetadataLanguage:
                                        selectedMetadataLanguage,
                                    selectedGenre: selectedGenre,
                                    selectedSubgenre: selectedSubgenre,
                                    selectedProductType: selectedProductType,
                                    selectedPrice: selectedPrice,
                                    metadataLanguages: metadataLanguages,
                                    genres: genres,
                                    subgenres: subgenres,
                                    productTypes: productTypes,
                                    prices: prices,
                                    tabController: _tabController,
                                    onPrimaryArtistsChanged: (artists) {
                                      setState(() {
                                        selectedArtists = _normalizeArtistList(artists);
                                      });
                                    },
                                    onProductTypeChanged:
                                        _handleProductTypeChange,
                                    projectId: widget.projectId,
                                    onInformationComplete:
                                        (isComplete) {
                                      setState(() {
                                        _isInformationComplete = isComplete;
                                      });
                                    },
                                    selectedArtists: selectedArtists,
                                    onArtistsUpdated: (artists) {
                                      setState(() {
                                        selectedArtists = _normalizeArtistList(artists);
                                      });
                                    },
                                    selectedImageBytes: _selectedImageBytes,
                                    onImageSelected: (bytes) {
                                      setState(() {
                                        _selectedImageBytes = bytes;
                                      });
                                    },
                                    coverImageUrl: coverImageUrl,
                                    onCoverImageUrlUpdated: (url) {
                                      setState(() {
                                        coverImageUrl = url;
                                      });
                                    },
                                    isMobile: true,
                                  ),
                                );
                              },
                            ),

                            // Upload Tab (Mobile Version)
                            _buildMobileUploadTab(),

                            // Release Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: ReleaseTab(
                                projectId: widget.projectId,
                                productId: widget.productId,
                                isMobile: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Status overlay
                  if (_shouldShowStatusOverlay())
                    ProductStatusOverlay(
                      userId: auth.getUser()!.uid,
                      projectId: widget.projectId,
                      productId: widget.productId,
                      currentStatus: productStatus,
                    ),
                ],
              ),
      ),
    );
  }

  // Utility function to normalize artist input to List<String>
  List<String> _normalizeArtistList(dynamic artists) {
    if (artists is String) {
      return [artists];
    } else if (artists is Iterable && artists is! String) {
      return artists.map((e) => e.toString()).toList();
    } else {
      return [];
    }
  }

  // Helper method to convert list to map list for roles
  List<Map<String, dynamic>> _convertListToMapList(List<dynamic>? list) {
    if (list == null) return [];

    return list.map((item) {
      if (item is Map) {
        return {
          'name': item['name'] ?? '',
          'roles': (item['roles'] is List)
              ? List<String>.from(item['roles'])
              : <String>[],
        };
      }
      return {'name': '', 'roles': <String>[]};
    }).toList();
  }
}

class MobileTabIndicator extends Decoration {
  final Color color;
  final double radius;

  const MobileTabIndicator({
    required this.color,
    this.radius = 8,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CirclePainter(
      color: color,
      radius: radius,
    );
  }
}

class _CirclePainter extends BoxPainter {
  final Color color;
  final double radius;

  _CirclePainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    final Offset circleOffset = offset +
        Offset(
            configuration.size!.width / 2, configuration.size!.height - radius);

    canvas.drawCircle(circleOffset, radius, paint);
  }
}

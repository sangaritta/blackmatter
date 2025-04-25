import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portal/models/product.dart' as unified_product;
import 'package:portal/models/project.dart' as models_project;
import 'package:portal/models/track.dart';
import 'package:portal/models/metadata_language.dart';
import 'package:portal/services/auth_service.dart';
import 'package:portal/widgets/project_card/product_builder/information_tab.dart';
import 'package:portal/widgets/project_card/product_builder/release_tab.dart';
import 'package:portal/widgets/project_card/product_builder/upload_tab.dart';
import 'package:portal/widgets/project_card/product_builder/product_status_overlay.dart';
import 'dart:developer' as developer;
import 'package:provider/provider.dart';
import 'package:portal/Services/api_service.dart';

// Add the correct list of metadata languages for the builder
final List<MetadataLanguage> metadataLanguages = [
  MetadataLanguage('en', 'English'),
  MetadataLanguage('es', 'Spanish'),
  MetadataLanguage('fr', 'French'),
  // Add more as needed
];

// Add the correct genre, subgenre, productTypes, and prices lists/maps
final Map<String, List<String>> genres = {
  'Pop': ['Dance Pop', 'Electropop'],
  'Rock': ['Alternative Rock', 'Classic Rock'],
  // Add more as needed
};
final Map<String, List<String>> subgenres = genres;
final List<String> productTypes = ['Single', 'Album', 'EP'];
final List<String> prices = ['Standard', 'Premium'];

class ProductBuilder extends StatefulWidget {
  final String selectedProductType;
  final String projectId;
  final String productId;
  final bool isNewProduct;

  const ProductBuilder({
    super.key,
    required this.selectedProductType,
    required this.projectId,
    required this.productId,
    this.isNewProduct = false,
  });

  @override
  State<ProductBuilder> createState() => _ProductBuilderState();
}

class _ProductBuilderState extends State<ProductBuilder>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<models_project.Project?> _projectFuture;

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
  MetadataLanguage? selectedMetadataLanguage;
  String? selectedGenre;
  String? selectedSubgenre;
  String? selectedProductType;
  String? selectedPrice;

  bool _isInformationComplete = false;
  String productStatus = '';

  List<String> selectedArtists = [];
  Uint8List? _selectedImageBytes;
  String? coverImageUrl;

  unified_product.Product? _product;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _projectFuture = ApiService().getProjectById(widget.projectId);

    // Initialize with default values for new products
    if (widget.isNewProduct) {
      // Extract base product type (remove any counter suffix)
      String baseType = widget.selectedProductType.split(' (').first;
      selectedProductType = baseType;
      selectedMetadataLanguage = metadataLanguages.isNotEmpty ? metadataLanguages[0] : null;
      selectedGenre = null;
      selectedSubgenre = null;
      selectedPrice = null;
      // Set default title and artists for new products
      releaseTitleController.text = 'Untitled';
      selectedArtists = [];
      // Create a new Product with all required fields
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';
      final productId = UniqueKey().toString();
      _product = unified_product.Product(
        id: productId,
        userId: userId,
        projectId: widget.projectId,
        releaseTitle: 'Untitled',
        releaseVersion: '1.0',
        label: '',
        genre: selectedGenre ?? '',
        subgenre: selectedSubgenre ?? '',
        metadataLanguage: selectedMetadataLanguage,
        type: baseType,
        price: selectedPrice ?? '',
        state: 'Draft',
        coverImage: '',
        previewArtUrl: '',
        cLine: '',
        cLineYear: '',
        pLine: '',
        pLineYear: '',
        upc: '',
        uid: '',
        autoGenerateUPC: false,
        trackCount: 0,
        primaryArtists: [],
        primaryArtistIds: [],
        tracks: [],
        platforms: [],
        platformsSelected: [],
        useRollingRelease: false,
        releaseTime: '', // Fix: always provide a String, not null
        artworkUrl: '',
        country: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        originalPath: {},
        timeZone: '',
      );
    } else {
      selectedProductType = widget.selectedProductType.split(' (').first;
      selectedMetadataLanguage = metadataLanguages.isNotEmpty ? metadataLanguages[0] : null;

      // Fetch product status for existing products
      _fetchProductStatus();
      // TODO: Load the Product from backend and assign to _product
      _product = null; // Ensure it's initialized as null until loaded
    }
  }

  Future<void> _fetchProductStatus() async {
    try {
      if (widget.productId.isEmpty) return;

      final userId = AuthService.instance.currentUser?.uid;
      if (userId == null) return;

      final docSnapshot =
          await FirebaseFirestore.instance
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
      developer.log(
        'Error fetching product status: $e',
        name: 'ProductBuilder',
      );
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

  void _updateInformationStatus(bool isComplete) {
    setState(() {
      _isInformationComplete = isComplete;
    });
  }

  void _updateSelectedArtists(List<String> selectedArtistIds, Map<String, List<String>> roleToArtistIds) {
    setState(() {
      selectedArtists = selectedArtistIds;
      // Cannot set final fields directly, need to create new Product instance or update model
      // _product?.primaryArtistIds = selectedArtistIds;
      // _product?.primaryArtists = roleToArtistIds;
    });
  }

  bool _shouldShowStatusOverlay() {
    return ['Processing', 'In Review', 'Approved'].contains(productStatus);
  }

  void _addTrack(Track track) {
    setState(() {
      _product?.songs.add(track);
    });
  }

  void _updateTrack(int index, Track updatedTrack) {
    setState(() {
      if (_product != null && index >= 0 && index < _product!.songs.length) {
        _product!.songs[index] = updatedTrack;
      }
    });
  }

  void _removeTrack(int index) {
    setState(() {
      if (_product != null && index >= 0 && index < _product!.songs.length) {
        _product!.songs.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models_project.Project?>(
      future: _projectFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final project = snapshot.data!;
        return Provider<models_project.Project>.value(
          value: project,
          child: Provider<unified_product.Product?>.value(
            value: _product,
            child: Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.white,
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Information'),
                                const SizedBox(width: 8),
                                Icon(
                                  _isInformationComplete
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color:
                                      _isInformationComplete
                                          ? Colors.green
                                          : Colors.red,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Text('Upload')],
                            ),
                          ),
                          const Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Text('Release')],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            Consumer<models_project.Project>(
                              builder: (context, project, child) {
                                return InformationTab(
                                  productId: widget.productId,
                                  releaseTitleController: releaseTitleController,
                                  releaseVersionController: releaseVersionController,
                                  primaryArtistsController: primaryArtistsController,
                                  upcController: upcController,
                                  uidController: uidController,
                                  labelController: labelController,
                                  cLineController: cLineController,
                                  pLineController: pLineController,
                                  selectedMetadataLanguage: selectedMetadataLanguage,
                                  selectedGenre: selectedGenre,
                                  selectedSubgenre: selectedSubgenre,
                                  selectedProductType: selectedProductType,
                                  selectedPrice: selectedPrice,
                                  metadataLanguages: metadataLanguages,
                                  genres: genres.keys.toList(),
                                  subgenres: subgenres,
                                  productTypes: productTypes,
                                  prices: prices,
                                  tabController: _tabController,
                                  onReleaseTitleChanged: (title) {
                                    // If you want to update the name, assign directly or call a defined method
                                    // Example: project.name = title;
                                    // Or handle with setState or controller
                                  },
                                  onPrimaryArtistsChanged: (artists) {
                                    // If you want to update the artist, assign directly or call a defined method
                                    // Example: project.primaryArtists = artists;
                                    // Or handle with setState or controller
                                  },
                                  onProductTypeChanged: _handleProductTypeChange,
                                  projectId: widget.projectId,
                                  onInformationComplete: _updateInformationStatus,
                                  selectedArtists: selectedArtists,
                                  onArtistsUpdated: (ids) => _updateSelectedArtists(ids, {}),
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
                                  onSave: (List<Map<String, dynamic>> artistData) {
                                    final List<String> selectedArtistIds = artistData.map((artist) => artist['id'] as String).toList();
                                    final Map<String, List<String>> roleToArtistIds = {};
                                    for (final artist in artistData) {
                                      final String artistId = artist['id'] as String;
                                      final List<String> roles = (artist['roles'] as List<dynamic>).cast<String>();
                                      for (final role in roles) {
                                        roleToArtistIds.putIfAbsent(role, () => []).add(artistId);
                                      }
                                    }
                                    _updateSelectedArtists(selectedArtistIds, roleToArtistIds);
                                  },
                                );
                              },
                            ),
                            UploadTab(
                              projectId: widget.projectId,
                              productId: widget.productId,
                              productArtists: selectedArtists,
                              productGenre: selectedGenre ?? '',
                              productSubgenre: selectedSubgenre ?? '',
                              coverImageUrl: coverImageUrl ?? '',
                              tracks:
                                  _product?.songs ?? [], // Pass the Product.songs list
                              onAddTrack: _addTrack,
                              onUpdateTrack: _updateTrack,
                              onRemoveTrack: _removeTrack,
                            ),
                            ReleaseTab(
                              projectId: widget.projectId,
                              productId: widget.productId,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Status overlay
                  if (_shouldShowStatusOverlay())
                    ProductStatusOverlay(
                      userId:
                          AuthService.instance.currentUser!.uid, // --- Fix for undefined 'auth' ---
                      projectId: widget.projectId,
                      productId: widget.productId,
                      currentStatus: productStatus,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class DisabledTab extends StatelessWidget {
  final String message;

  const DisabledTab({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:portal/Constants/product.dart';
import 'package:portal/Models/product.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Models/track.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/information_tab.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/release_tab.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/upload_tab.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/product_status_overlay.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

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

  Product? _product;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize with default values for new products
    if (widget.isNewProduct) {
      // Extract base product type (remove any counter suffix)
      String baseType = widget.selectedProductType.split(' (').first;
      selectedProductType = baseType;
      selectedMetadataLanguage =
          metadataLanguages.isNotEmpty ? metadataLanguages[0] : null;
      selectedGenre = null;
      selectedSubgenre = null;
      selectedPrice = null;
      // Set default title and artists for new products
      releaseTitleController.text = 'Untitled';
      selectedArtists = [];
      // Create a new Product with empty songs
      _product = Product(
        type: baseType,
        productName: 'Untitled',
        productArtists: [],
        cLine: '',
        pLine: '',
        price: '',
        label: '',
        releaseDate: '',
        upc: '',
        uid: '',
        songs: [],
        coverImage: '',
        state: 'Draft',
      );
    } else {
      selectedProductType = widget.selectedProductType.split(' (').first;
      selectedMetadataLanguage =
          metadataLanguages.isNotEmpty ? metadataLanguages[0] : null;

      // Fetch product status for existing products
      _fetchProductStatus();
      // TODO: Load the Product from backend and assign to _product
      _product = null; // Ensure it's initialized as null until loaded
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
          name: 'ProductBuilder');
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

  void _updateSelectedArtists(List<String> artists) {
    setState(() {
      selectedArtists = artists;
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
    return Expanded(
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
                          color: _isInformationComplete
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
                      children: [
                        Text('Upload'),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Release'),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Consumer<Project>(
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
                          genres: genres,
                          subgenres: subgenres,
                          productTypes: productTypes,
                          prices: prices,
                          tabController: _tabController,
                          onReleaseTitleChanged: (title) {
                            project.updateName(title);
                          },
                          onPrimaryArtistsChanged: (artists) {
                            project.updateArtist(artists);
                          },
                          onProductTypeChanged: _handleProductTypeChange,
                          projectId: widget.projectId,
                          onInformationComplete: _updateInformationStatus,
                          selectedArtists: selectedArtists,
                          onArtistsUpdated: _updateSelectedArtists,
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
                      tracks: _product?.songs ?? [], // Pass the Product.songs list
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
              userId: auth.getUser()!.uid,
              projectId: widget.projectId,
              productId: widget.productId,
              currentStatus: productStatus,
            ),
        ],
      ),
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
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

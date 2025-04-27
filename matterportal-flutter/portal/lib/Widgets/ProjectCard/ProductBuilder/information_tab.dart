import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Constants/product.dart';
import 'package:portal/Models/product_data.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:portal/Widgets/Common/artist_selector.dart';

// Import the component files
import 'InformationTab/cover_image_section.dart';
import 'InformationTab/product_metadata_fields.dart';
import 'InformationTab/artist_section.dart';
import 'InformationTab/product_identity_fields.dart';
import 'InformationTab/rights_fields.dart';
import 'InformationTab/validation_utils.dart';
import 'InformationTab/data_persistence.dart';

class InformationTab extends StatefulWidget {
  final String productId;
  final TextEditingController releaseTitleController;
  final TextEditingController releaseVersionController;
  final TextEditingController primaryArtistsController;
  final TextEditingController upcController;
  final TextEditingController uidController;
  final TextEditingController labelController;
  final TextEditingController cLineController;
  final TextEditingController pLineController;
  final MetadataLanguage? selectedMetadataLanguage;
  final String? selectedGenre;
  final String? selectedSubgenre;
  final String? selectedProductType;
  final String? selectedPrice;
  final List<MetadataLanguage> metadataLanguages;
  final List<String> genres;
  final Map<String, List<String>> subgenres;
  final List<String> productTypes;
  final List<String> prices;
  final TabController tabController;
  final Function(String) onReleaseTitleChanged;
  final Function(String) onPrimaryArtistsChanged;
  final Function(String) onProductTypeChanged;
  final String projectId;
  final Function(bool) onInformationComplete;
  final List<String> selectedArtists;
  final List<String>? selectedArtistIds;
  final Function(List<String>) onArtistsUpdated;
  final Function(List<String>)? onArtistIdsUpdated;
  final Uint8List? selectedImageBytes;
  final Function(Uint8List?) onImageSelected;
  final String? coverImageUrl;
  final Function(String?) onCoverImageUrlUpdated;
  final bool isMobile;

  const InformationTab({
    super.key,
    required this.productId,
    required this.releaseTitleController,
    required this.releaseVersionController,
    required this.primaryArtistsController,
    required this.upcController,
    required this.uidController,
    required this.labelController,
    required this.cLineController,
    required this.pLineController,
    this.selectedMetadataLanguage,
    this.selectedGenre,
    this.selectedSubgenre,
    this.selectedProductType,
    this.selectedPrice,
    required this.metadataLanguages,
    required this.genres,
    required this.subgenres,
    required this.productTypes,
    required this.prices,
    required this.tabController,
    required this.onReleaseTitleChanged,
    required this.onPrimaryArtistsChanged,
    required this.onProductTypeChanged,
    required this.projectId,
    required this.onInformationComplete,
    required this.selectedArtists,
    this.selectedArtistIds,
    required this.onArtistsUpdated,
    this.onArtistIdsUpdated,
    this.selectedImageBytes,
    required this.onImageSelected,
    this.coverImageUrl,
    required this.onCoverImageUrlUpdated,
    this.isMobile = false,
  });

  @override
  InformationTabState createState() => InformationTabState();
}

class InformationTabState extends State<InformationTab> {
  // State variables
  bool _isLoading = false;
  bool _autoGenerateUPC = true;
  Uint8List? _selectedImageBytes;
  String? _coverImageUrl;
  List<String> artistSuggestions = [];
  MetadataLanguage? _selectedMetadataLanguage;
  String? _selectedGenre;
  String? _selectedSubgenre;
  String? _selectedPrice;
  final String _currentYear = DateTime.now().year.toString();
  String _cLineYear = DateTime.now().year.toString();
  String _pLineYear = DateTime.now().year.toString();
  List<Map<String, dynamic>> _labels = [];
  bool _isLoadingProduct = false;
  bool _hasUnsavedChanges = false;
  Map<String, dynamic> _originalData = {};
  bool _hasBeenSaved = false;
  double _uploadProgress = 0.0;
  double _apiProgress = 0.0;
  bool _isUploadingImage = false;
  bool _isProcessingApi = false;
  List<String> _selectedArtistIds = [];

  final ValidationUtils _validationUtils = ValidationUtils();
  late final DataPersistence _dataPersistence;

  // --- Additive Fix for Keyboard Loop: Persistent FocusNode and Debounce ---
  late final FocusNode primaryArtistsFocusNode;
  Timer? _artistDebounceTimer;

  @override
  void initState() {
    super.initState();
    primaryArtistsFocusNode = FocusNode();
    _initializeState();
  }

  @override
  void dispose() {
    primaryArtistsFocusNode.dispose();
    _artistDebounceTimer?.cancel();
    super.dispose();
  }

  // Debounce wrapper for artist add/remove
  void debounceArtistUpdate(VoidCallback callback, {Duration duration = const Duration(milliseconds: 300)}) {
    _artistDebounceTimer?.cancel();
    _artistDebounceTimer = Timer(duration, callback);
  }

  void _initializeState() {
    // Set initial values from props or defaults
    _selectedImageBytes = widget.selectedImageBytes;
    _coverImageUrl = widget.coverImageUrl;
    widget.uidController.text = widget.productId;
    _selectedMetadataLanguage = widget.selectedMetadataLanguage ??
        (widget.metadataLanguages.isNotEmpty
            ? widget.metadataLanguages[0]
            : null);
    _selectedArtistIds = widget.selectedArtistIds ?? [];
    _selectedGenre = widget.selectedGenre;
    _selectedSubgenre = widget.selectedSubgenre;
    _selectedPrice = widget.selectedPrice;
    
    // Initialize the data persistence helper
    _dataPersistence = DataPersistence(
      onProductLoaded: _onProductLoaded,
      onProductSaved: _onProductSaved,
      onError: _onPersistenceError,
    );

    // Add listeners to track changes
    _addControllerListeners();

    // Set initial price based on product type if needed
    if (widget.selectedProductType != null && _selectedPrice == null) {
      _setInitialPrice(widget.selectedProductType!);
    }

    // Load data
    _fetchAllArtists();
    _fetchLabels();
    _loadExistingProduct();
  }

  void _addControllerListeners() {
    widget.releaseTitleController.addListener(_onFieldChanged);
    widget.releaseVersionController.addListener(_onFieldChanged);
    widget.primaryArtistsController.addListener(_onFieldChanged);
    widget.upcController.addListener(_onFieldChanged);
    widget.labelController.addListener(_onFieldChanged);
    widget.cLineController.addListener(_onFieldChanged);
    widget.pLineController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final currentData = _getCurrentData();
    final hasChanges = !_mapsAreEqual(currentData, _originalData);

    setState(() {
      _hasUnsavedChanges = hasChanges;
      _validateAndUpdateStatus();
    });
  }

  Map<String, dynamic> _getCurrentData() {
    return {
      'releaseTitle': widget.releaseTitleController.text,
      'releaseVersion': widget.releaseVersionController.text,
      'primaryArtists': widget.selectedArtists,
      'metadataLanguage': _selectedMetadataLanguage?.code,
      'genre': _selectedGenre,
      'subgenre': _selectedSubgenre,
      'productType': widget.selectedProductType,
      'price': _selectedPrice,
      'upc': widget.upcController.text,
      'label': widget.labelController.text,
      'cLine': widget.cLineController.text,
      'pLine': widget.pLineController.text,
      'cLineYear': _cLineYear,
      'pLineYear': _pLineYear,
      'autoGenerateUPC': _autoGenerateUPC,
    };
  }

  bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    return map1.entries.every((entry) {
      final value2 = map2[entry.key];
      if (entry.value is List && value2 is List) {
        return _listsAreEqual(entry.value as List, value2);
      }
      return entry.value == value2;
    });
  }

  bool _listsAreEqual(List list1, List list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _validateAndUpdateStatus() {
    final isComplete = _validationUtils.canProceedToNext(
      hasImage: _selectedImageBytes != null || 
                widget.selectedImageBytes != null || 
                (_coverImageUrl != null && _coverImageUrl!.isNotEmpty) ||
                (widget.coverImageUrl != null && widget.coverImageUrl!.isNotEmpty),
      hasTitle: widget.releaseTitleController.text.isNotEmpty,
      hasArtists: widget.selectedArtists.isNotEmpty,
      isUpcValid: _autoGenerateUPC || 
                  (!_autoGenerateUPC && _validationUtils.isValidUPC(widget.upcController.text)),
      hasLabel: widget.labelController.text.isNotEmpty,
      hasCLine: widget.cLineController.text.isNotEmpty,
      hasPLine: widget.pLineController.text.isNotEmpty,
      hasMetadataLanguage: _selectedMetadataLanguage != null,
      hasGenre: _selectedGenre != null,
      hasSubgenre: _selectedSubgenre != null,
      hasPrice: _selectedPrice != null,
    );
    
    widget.onInformationComplete(isComplete);
  }

  // Artist management methods
  Future<void> _fetchAllArtists() async {
    try {
      List<String> allArtists = await api.fetchAllArtists();
      setState(() {
        artistSuggestions = allArtists;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _addArtist(String artist) {
    if (artist.isNotEmpty && !widget.selectedArtists.contains(artist)) {
      setState(() {
        widget.onArtistsUpdated([...widget.selectedArtists, artist]);
        widget.primaryArtistsController.clear();
        _validateAndUpdateStatus();
      });
    }
  }

  void _removeArtist(String artist) {
    setState(() {
      final newList = List<String>.from(widget.selectedArtists)..remove(artist);
      widget.onArtistsUpdated(newList);
      _validateAndUpdateStatus();
    });
  }

  Future<void> _fetchLabels() async {
    try {
      final labels = await api.fetchLabels();
      
      setState(() {
        _labels = labels;
      });
      
      // Ensure the selected label exists in the available labels
      if (widget.labelController.text.isNotEmpty &&
          !_labels.any((label) => label['name'] == widget.labelController.text)) {
        widget.labelController.text = ''; // Clear the label if it doesn't exist
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveProductInformation(String productId) async {
    setState(() {
      _isLoading = true;
      _isProcessingApi = true;
      _apiProgress = 0.0;
      _isUploadingImage = _selectedImageBytes != null;
      _uploadProgress = 0.0;
    });

    if (!_validateFields()) {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
        _isProcessingApi = false;
      });
      return;
    }

    try {
      // Create the product data object
      String fullCLine = '© $_cLineYear ${widget.cLineController.text}';
      String fullPLine = '℗ $_pLineYear ${widget.pLineController.text}';

      ProductData productData = ProductData(
        id: productId,
        releaseTitle: widget.releaseTitleController.text,
        releaseVersion: widget.releaseVersionController.text,
        primaryArtists: widget.selectedArtists,
        primaryArtistIds: _selectedArtistIds,
        metadataLanguage: _selectedMetadataLanguage?.code,
        genre: _selectedGenre,
        subgenre: _selectedSubgenre,
        type: widget.selectedProductType,
        price: _selectedPrice,
        upc: widget.upcController.text,
        uid: widget.uidController.text,
        label: widget.labelController.text,
        cLine: fullCLine,
        pLine: fullPLine,
        cLineYear: _cLineYear,
        pLineYear: _pLineYear,
        coverImage: _coverImageUrl ?? widget.coverImageUrl ?? '',
        state: 'Draft',
        autoGenerateUPC: _autoGenerateUPC,
      );

      // Use the data persistence helper to save the product
      await _dataPersistence.saveProductInformation(
        userId: auth.getUser()?.uid,
        projectId: widget.projectId,
        productId: productId,
        productData: productData,
        imageBytes: _selectedImageBytes,
        onProgress: (uploadProgress, apiProgress) {
          setState(() {
            _uploadProgress = uploadProgress;
            _apiProgress = apiProgress;
          });
        },
      );

      widget.tabController.animateTo(1);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
          _isProcessingApi = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool _validateFields() {
    return _validationUtils.validateAllFields(
      title: widget.releaseTitleController.text,
      artists: widget.selectedArtists,
      autoGenerateUPC: _autoGenerateUPC,
      upc: widget.upcController.text,
      label: widget.labelController.text,
      cLine: widget.cLineController.text,
      pLine: widget.pLineController.text,
      image: _selectedImageBytes ?? widget.selectedImageBytes,
      imageUrl: _coverImageUrl ?? widget.coverImageUrl,
      language: _selectedMetadataLanguage?.code,
      genre: _selectedGenre,
      subgenre: _selectedSubgenre,
      price: _selectedPrice,
    );
  }

  Future<void> _loadExistingProduct() async {
    setState(() {
      _isLoadingProduct = true;
    });

    try {
      await _dataPersistence.loadProductData(
        userId: auth.getUser()?.uid,
        projectId: widget.projectId,
        productId: widget.productId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProduct = false;
        });
      }
    }
  }

  void _onProductLoaded(ProductData loadedProduct) {
    setState(() {
      // Update all form fields with the loaded data
      if (loadedProduct.type != null) {
        widget.onProductTypeChanged(loadedProduct.type!);
      }
      
      if (loadedProduct.coverImage.isNotEmpty) {
        _coverImageUrl = loadedProduct.coverImage;
        widget.onCoverImageUrlUpdated(_coverImageUrl);
      }
      
      widget.onArtistsUpdated(loadedProduct.primaryArtists);
      
      if (loadedProduct.primaryArtistIds != null &&
          loadedProduct.primaryArtistIds!.isNotEmpty) {
        _selectedArtistIds = loadedProduct.primaryArtistIds!;
        if (widget.onArtistIdsUpdated != null) {
          widget.onArtistIdsUpdated!(_selectedArtistIds);
        }
      }
      
      if (loadedProduct.metadataLanguage != null) {
        _selectedMetadataLanguage = widget.metadataLanguages.firstWhere(
          (lang) => lang.code == loadedProduct.metadataLanguage,
          orElse: () => widget.metadataLanguages.isNotEmpty
              ? widget.metadataLanguages[0]
              : const MetadataLanguage('en', 'English'),
        );
      }
      
      widget.releaseTitleController.text = loadedProduct.releaseTitle;
      widget.releaseVersionController.text = loadedProduct.releaseVersion;
      widget.labelController.text = loadedProduct.label;
      widget.upcController.text = loadedProduct.upc;
      _autoGenerateUPC = loadedProduct.autoGenerateUPC;
      
      _selectedGenre = loadedProduct.genre;
      _selectedSubgenre = loadedProduct.subgenre;
      _selectedPrice = loadedProduct.price;
      
      _cLineYear = loadedProduct.cLineYear;
      _pLineYear = loadedProduct.pLineYear;
      widget.cLineController.text = loadedProduct.cLine.replaceAll('© $_cLineYear ', '');
      widget.pLineController.text = loadedProduct.pLine.replaceAll('℗ $_pLineYear ', '');
      
      _hasBeenSaved = true;
      _hasUnsavedChanges = false;
      
      // Store original data for change detection
      _originalData = _getCurrentData();
      
      _validateAndUpdateStatus();
    });
  }
  
  void _onProductSaved() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isUploadingImage = false;
        _isProcessingApi = false;
        _hasBeenSaved = true;
        _hasUnsavedChanges = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product information saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _onPersistenceError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _setInitialPrice(String productType) {
    switch (productType.toLowerCase()) {
      case 'single':
        _selectedPrice = widget.prices.firstWhere(
          (price) => price.toLowerCase().contains('single - front'),
          orElse: () => widget.prices.firstWhere(
            (price) => price.toLowerCase().contains('single'),
            orElse: () => widget.prices.first,
          ),
        );
        break;
      case 'ep':
        _selectedPrice = widget.prices.firstWhere(
          (price) => price == "Album - EP",
          orElse: () => widget.prices.firstWhere(
            (price) => price == "Album - Mini EP",
            orElse: () => widget.prices.first,
          ),
        );
        break;
      case 'album':
        _selectedPrice = widget.prices.firstWhere(
          (price) => price.toLowerCase().contains('album front one'),
          orElse: () => widget.prices.firstWhere(
            (price) => price.toLowerCase().contains('album'),
            orElse: () => widget.prices.first,
          ),
        );
        break;
      default:
        _selectedPrice = widget.prices.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: LoadingIndicator(
          size: 50,
          color: Colors.white,
        ),
      );
    }

    // --- Centralized Artist Selector ---
    // Use the new ArtistSelector for primary artists
    final Widget primaryArtistSelector = ArtistSelector(
      label: 'Primary Artists',
      selectedArtists: widget.selectedArtists,
      onChanged: (updated) {
        setState(() {
          widget.onArtistsUpdated(updated);
          _validateAndUpdateStatus();
        });
      },
      collection: 'artists',
      selectedArtistIds: widget.selectedArtistIds,
      onArtistIdsUpdated: widget.onArtistIdsUpdated,
    );

    // LEGACY: The old artist selector code is commented out below and should not be used.
    /*
    // Old artist selector widget here (commented)
    */

    return Stack(
      children: [
        _isLoadingProduct
            ? const Center(child: LoadingIndicator())
            : widget.isMobile
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cover image section
                          Center(
                            child: CoverImageSection(
                              selectedImageBytes: _selectedImageBytes,
                              coverImageUrl: _coverImageUrl ?? widget.coverImageUrl,
                              onImageSelected: (bytes) {
                                setState(() {
                                  _selectedImageBytes = bytes;
                                  widget.onImageSelected(bytes);
                                });
                              },
                            ),
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // Product type and title display
                          Text(
                            widget.selectedProductType ?? "Product Type",
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          Text(
                            widget.releaseTitleController.text.isEmpty
                                ? "Release Title"
                                : "${widget.releaseTitleController.text}${widget.releaseVersionController.text.isNotEmpty ? ' (${widget.releaseVersionController.text})' : ''}",
                            style: const TextStyle(fontSize: 24, color: Colors.white),
                          )
                          ,
                          // Artist display
                          if (widget.selectedArtists.isNotEmpty) ...[

                            const SizedBox(height: 8),
                            ArtistSection.displaySelectedArtists(
                              selectedArtists: widget.selectedArtists,
                            ),
                          ],
                          

                          const SizedBox(height: 16),
                          

                          // Metadata fields section - One field per row for mobile
                          ProductMetadataFields(
                            releaseTitleController: widget.releaseTitleController,
                            releaseVersionController: widget.releaseVersionController,
                            primaryArtistsController: widget.primaryArtistsController,
                            selectedArtists: widget.selectedArtists,
                            artistSuggestions: artistSuggestions,
                            onArtistAdded: _addArtist,
                            onArtistRemoved: _removeArtist,
                            onArtistsReordered: widget.onArtistsUpdated,
                            onReleaseTitleChanged: widget.onReleaseTitleChanged,
                            selectedMetadataLanguage: _selectedMetadataLanguage,
                            metadataLanguages: widget.metadataLanguages,
                            onMetadataLanguageChanged: (value) {
                              setState(() {
                                _selectedMetadataLanguage = value;
                                _validateAndUpdateStatus();
                              });
                            },
                            selectedGenre: _selectedGenre,
                            genres: widget.genres,
                            onGenreChanged: (value) {
                              setState(() {
                                _selectedGenre = value;
                                _selectedSubgenre = null;
                                _validateAndUpdateStatus();
                              });
                            },
                            selectedSubgenre: _selectedSubgenre,
                            subgenres: widget.subgenres,
                            onSubgenreChanged: (value) {
                              setState(() {
                                _selectedSubgenre = value;
                                _validateAndUpdateStatus();
                              });
                            },
                            selectedArtistIds: _selectedArtistIds,
                            onArtistIdsUpdated: (ids) {
                              setState(() {
                                _selectedArtistIds = ids;
                                if (widget.onArtistIdsUpdated != null) {
                                  widget.onArtistIdsUpdated!(ids);
                                }
                              });
                            },
                            isMobile: true,
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // Product type dropdown
                          ProductIdentityFields.buildProductTypeDropdown(
                            selectedProductType: widget.selectedProductType,
                            productTypes: widget.productTypes,
                            onProductTypeChanged: (value) {
                              setState(() {
                                widget.onProductTypeChanged(value);
                                _setInitialPrice(value);
                              });
                            },
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // Price dropdown - One field per row for mobile
                          ProductIdentityFields.buildPriceDropdown(
                            selectedPrice: _selectedPrice,
                            prices: _getFilteredPrices(),
                            onPriceChanged: (value) {
                              setState(() {
                                _selectedPrice = value;
                                _validateAndUpdateStatus();
                              });
                            },
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // UPC field
                          ProductIdentityFields.buildUPCField(
                            upcController: widget.upcController,
                            autoGenerateUPC: _autoGenerateUPC,
                            isExistingProduct: _hasBeenSaved,
                            onAutoGenerateChanged: (value) {
                              setState(() {
                                _autoGenerateUPC = value;
                                if (_autoGenerateUPC) {
                                  widget.upcController.clear();
                                }
                                _onFieldChanged();
                              });
                            },
                            onUpcChanged: () {
                              if (!_hasBeenSaved) {
                                setState(() {
                                  _hasUnsavedChanges = true;
                                });
                                _onFieldChanged();
                              }
                            },
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // UID field
                          ProductIdentityFields.buildUIDField(
                            uidController: widget.uidController,
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // Label dropdown
                          ProductIdentityFields.buildLabelDropdown(
                            labelController: widget.labelController,
                            labels: _labels,
                            onLabelChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  widget.labelController.text = newValue;
                                  final selectedLabel = _labels.firstWhere(
                                    (label) => label['name'] == newValue,
                                    orElse: () => {'cLine': '', 'pLine': ''},
                                  );
                                  widget.cLineController.text =
                                      selectedLabel['cLine'] ?? '';
                                  widget.pLineController.text =
                                      selectedLabel['pLine'] ?? '';
                                });
                              }
                            },
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // Rights fields section
                          RightsFields(
                            cLineController: widget.cLineController,
                            pLineController: widget.pLineController,
                            currentYear: _currentYear,
                            cLineYear: _cLineYear,
                            pLineYear: _pLineYear,
                            onCLineYearChanged: (value) {
                              setState(() {
                                _cLineYear = value ?? _currentYear;
                              });
                            },
                            onPLineYearChanged: (value) {
                              setState(() {
                                _pLineYear = value ?? _currentYear;
                              });
                            },
                            isMobile: true,
                          ),
                          

                          const SizedBox(height: 16),
                          

                          // Save button
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _buildSaveButton(),
                          ),
                          

                          // Space at bottom for scrolling
                          const SizedBox(height: 36),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Desktop layout
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Image
                          CoverImageSection(
                            selectedImageBytes: _selectedImageBytes,
                            coverImageUrl: _coverImageUrl ?? widget.coverImageUrl,
                            onImageSelected: (bytes) {
                              setState(() {
                                _selectedImageBytes = bytes;
                                widget.onImageSelected(bytes);
                              });
                            },
                          ),
                          

                          const SizedBox(width: 24),
                          

                          // Right column - Form fields
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product info
                                Text(
                                  widget.selectedProductType ?? "Product Type",
                                  style: const TextStyle(fontSize: 18, color: Colors.white),
                                ),
                                Text(
                                  widget.releaseTitleController.text.isEmpty
                                      ? "Release Title"
                                      : "${widget.releaseTitleController.text}${widget.releaseVersionController.text.isNotEmpty ? ' (${widget.releaseVersionController.text})' : ''}",
                                  style: const TextStyle(fontSize: 24, color: Colors.white),
                                ),
                                

                                if (widget.selectedArtists.isNotEmpty) ...[

                                  const SizedBox(height: 8),
                                  ArtistSection.displaySelectedArtists(
                                    selectedArtists: widget.selectedArtists,
                                  ),
                                ],
                                

                                const SizedBox(height: 24),
                                

                                // Form fields
                                ProductMetadataFields(
                                  releaseTitleController: widget.releaseTitleController,
                                  releaseVersionController: widget.releaseVersionController,
                                  primaryArtistsController: widget.primaryArtistsController,
                                  selectedArtists: widget.selectedArtists,
                                  artistSuggestions: artistSuggestions,
                                  onArtistAdded: _addArtist,
                                  onArtistRemoved: _removeArtist,
                                  onArtistsReordered: widget.onArtistsUpdated,
                                  onReleaseTitleChanged: widget.onReleaseTitleChanged,
                                  selectedMetadataLanguage: _selectedMetadataLanguage,
                                  metadataLanguages: widget.metadataLanguages,
                                  onMetadataLanguageChanged: (value) {
                                    setState(() {
                                      _selectedMetadataLanguage = value;
                                      _validateAndUpdateStatus();
                                    });
                                  },
                                  selectedGenre: _selectedGenre,
                                  genres: widget.genres,
                                  onGenreChanged: (value) {
                                    setState(() {
                                      _selectedGenre = value;
                                      _selectedSubgenre = null;
                                      _validateAndUpdateStatus();
                                    });
                                  },
                                  selectedSubgenre: _selectedSubgenre,
                                  subgenres: widget.subgenres,
                                  onSubgenreChanged: (value) {
                                    setState(() {
                                      _selectedSubgenre = value;
                                      _validateAndUpdateStatus();
                                    });
                                  },
                                  selectedArtistIds: _selectedArtistIds,
                                  onArtistIdsUpdated: (ids) {
                                    setState(() {
                                      _selectedArtistIds = ids;
                                      if (widget.onArtistIdsUpdated != null) {
                                        widget.onArtistIdsUpdated!(ids);
                                      }
                                    });
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Product type dropdown
                                ProductIdentityFields.buildProductTypeDropdown(
                                  selectedProductType: widget.selectedProductType,
                                  productTypes: widget.productTypes,
                                  onProductTypeChanged: (value) {
                                    setState(() {
                                      widget.onProductTypeChanged(value);
                                      _setInitialPrice(value);
                                    });
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Price, UPC, UID, Label sections
                                Row(
                                  children: [
                                    Expanded(
                                      child: ProductIdentityFields.buildPriceDropdown(
                                        selectedPrice: _selectedPrice,
                                        prices: _getFilteredPrices(),
                                        onPriceChanged: (value) {
                                          setState(() {
                                            _selectedPrice = value;
                                            _validateAndUpdateStatus();
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ProductIdentityFields.buildUPCField(
                                        upcController: widget.upcController,
                                        autoGenerateUPC: _autoGenerateUPC,
                                        isExistingProduct: _hasBeenSaved,
                                        onAutoGenerateChanged: (value) {
                                          setState(() {
                                            _autoGenerateUPC = value;
                                            if (_autoGenerateUPC) {
                                              widget.upcController.clear();
                                            }
                                            _onFieldChanged();
                                          });
                                        },
                                        onUpcChanged: () {
                                          if (!_hasBeenSaved) {
                                            setState(() {
                                              _hasUnsavedChanges = true;
                                            });
                                            _onFieldChanged();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: ProductIdentityFields.buildUIDField(
                                        uidController: widget.uidController,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ProductIdentityFields.buildLabelDropdown(
                                        labelController: widget.labelController,
                                        labels: _labels,
                                        onLabelChanged: (newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              widget.labelController.text = newValue;
                                              final selectedLabel = _labels.firstWhere(
                                                (label) => label['name'] == newValue,
                                                orElse: () => {'cLine': '', 'pLine': ''},
                                              );
                                              widget.cLineController.text =
                                                  selectedLabel['cLine'] ?? '';
                                              widget.pLineController.text =
                                                  selectedLabel['pLine'] ?? '';
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Rights fields section
                                RightsFields(
                                  cLineController: widget.cLineController,
                                  pLineController: widget.pLineController,
                                  currentYear: _currentYear,
                                  cLineYear: _cLineYear,
                                  pLineYear: _pLineYear,
                                  onCLineYearChanged: (value) {
                                    setState(() {
                                      _cLineYear = value ?? _currentYear;
                                    });
                                  },
                                  onPLineYearChanged: (value) {
                                    setState(() {
                                      _pLineYear = value ?? _currentYear;
                                    });
                                  },
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Save button
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: _buildSaveButton(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
        
        // Progress overlay
        _buildProgressOverlay(),
      ],
    );
  }
  
  // Helper method to get filtered prices based on product type
  List<String> _getFilteredPrices() {
    if (widget.selectedProductType == null) return widget.prices;

    switch (widget.selectedProductType!.toLowerCase()) {
      case 'single':
        return widget.prices
            .where((price) => price.toLowerCase().contains('single'))
            .toList();
      case 'ep':
        return widget.prices
            .where(
                (price) => price == "Album - EP" || price == "Album - Mini EP")
            .toList();
      case 'album':
        return widget.prices
            .where((price) => price.toLowerCase().contains('album'))
            .toList();
      default:
        return widget.prices;
    }
  }

  Widget _buildSaveButton() {
    final bool hasRequiredFields = _validateFields();
    final bool canSave = hasRequiredFields && _hasUnsavedChanges;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: canSave
            ? [
                BoxShadow(
                  color: const Color(0xFF9D6BFF).withAlpha(128),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed:
            canSave ? () => _saveProductInformation(widget.productId) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave ? const Color(0xFF2D2D3A) : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _hasBeenSaved ? 'Update' : 'Save',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: fontNameSemiBold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverlay() {
    if (!_isLoading) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          color: const Color(0xFF2D2D3A),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingIndicator(
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saving product information...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_apiProgress * 0.2) + (_uploadProgress * 0.8),
                          backgroundColor: const Color(0xFF1E1B2C),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF9D6BFF),
                          ),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(((_apiProgress * 0.2) + (_uploadProgress * 0.8)) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (_isUploadingImage)
                            const Text(
                              'Uploading image...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            )
                          else if (_isProcessingApi)
                            const Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

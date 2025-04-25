import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/models/project.dart';
import 'package:portal/models/product.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:portal/widgets/forms/new_artist_form.dart';
import 'package:portal/widgets/project_card/product_builder/product_builder.dart';
import 'package:extended_image/extended_image.dart';

class MobileProjectView extends StatefulWidget {
  final String projectId;
  final Project project;
  final bool newProject;
  final String? productUPC;
  final String? initialProductId;
  final TextEditingController? nameController;
  final TextEditingController? artistController;
  final TextEditingController? notesController;

  const MobileProjectView({
    super.key,
    required this.projectId,
    required this.project,
    required this.newProject,
    this.productUPC,
    this.initialProductId,
    this.nameController,
    this.artistController,
    this.notesController,
  });

  @override
  State<MobileProjectView> createState() => _MobileProjectViewState();
}

class _MobileProjectViewState extends State<MobileProjectView> {
  ApiService api = ApiService();
  late final TextEditingController _nameController;
  late final TextEditingController _artistController;
  late final TextEditingController _notesController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _artistFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  bool _isLoading = false;
  bool _isSaving = false;
  List<Product> _products = [];
  bool _isUsingSharedControllers = false;
  List<String> _artistSuggestions = [];
  bool _isProjectSaved = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        widget.nameController ??
        TextEditingController(text: widget.project.projectName);
    _artistController =
        widget.artistController ??
        TextEditingController(text: widget.project.projectArtist);
    _notesController =
        widget.notesController ??
        TextEditingController(text: widget.project.notes);
    _isUsingSharedControllers = widget.nameController != null;

    _isProjectSaved = !widget.newProject;

    _loadProjectDetails();
    _fetchAllArtists();
  }

  Future<void> _fetchAllArtists() async {
    try {
      List<Map<String, dynamic>> allArtistsRaw =
          await api.fetchAllArtistsWithIds();
      List<String> allArtists =
          allArtistsRaw.map((artist) => artist['id'] as String).toList();
      if (mounted) {
        setState(() {
          _artistSuggestions = allArtists;
        });
      }
    } catch (e) {
      debugPrint('Error fetching artists: $e');
    }
  }

  @override
  void dispose() {
    if (!_isUsingSharedControllers) {
      _nameController.dispose();
      _artistController.dispose();
      _notesController.dispose();
    }

    _nameFocus.dispose();
    _artistFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProjectDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!widget.newProject) {
        _products = await api.getProductsByProjectId(widget.projectId);
      }

      if (widget.initialProductId != null && !widget.newProject) {
        _navigateToProduct(widget.initialProductId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading project: $e'),
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

  void _navigateToProduct(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse:
          () =>
              _products.isNotEmpty
                  ? _products.first
                  : throw Exception('No products available'),
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductBuilder(
              projectId: widget.projectId,
              productId: productId,
              selectedProductType: product.type,
              isNewProduct: false,
            ),
      ),
    ).then((_) => _refreshProducts());
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _products = await api.getProductsByProjectId(widget.projectId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing products: $e'),
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

  Future<void> _saveProject() async {
    if (_nameController.text.isEmpty || _artistController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name and artist are required.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = AuthService.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      if (widget.newProject) {
        await api.createProject(
          Project(
            id: widget.projectId,
            projectName: _nameController.text,
            projectArtist: _artistController.text,
            uid: userId,
            notes: _notesController.text,
          ),
        );
      } else {
        await api.updateProject(
          widget.projectId,
          userId,
          Project(
            id: widget.projectId,
            projectName: _nameController.text,
            projectArtist: _artistController.text,
            uid: userId,
            notes: _notesController.text,
          ).toMap(),
        );
      }

      if (mounted) {
        setState(() {
          _isProjectSaved = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
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

  Future<void> _createNewProduct() async {
    if (widget.newProject && _nameController.text.isNotEmpty) {
      await _saveProject();
    }

    final productId = 'PRD${DateTime.now().millisecondsSinceEpoch}';

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductBuilder(
              projectId: widget.projectId,
              productId: productId,
              selectedProductType: '',
              isNewProduct: true,
            ),
      ),
    ).then((_) => _refreshProducts());
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'processing':
        return const Color.fromARGB(255, 111, 59, 255);
      case 'in review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'published':
        return Colors.blue;
      case 'takedown':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18162E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2C),
        title: Text(widget.newProject ? 'New Project' : 'Edit Project'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSaving ? Icons.hourglass_empty : Icons.save,
              color: Colors.white,
            ),
            onPressed:
                _isSaving ||
                        _nameController.text.isEmpty ||
                        _artistController.text.isEmpty
                    ? null
                    : _saveProject,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: LoadingIndicator(size: 50, color: Colors.white),
              )
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B2C),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(51),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Project Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Project Name',
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(
                                Icons.folder,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2D2D3A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Autocomplete<String>(
                            initialValue: TextEditingValue(
                              text: _artistController.text,
                            ),
                            optionsBuilder: (
                              TextEditingValue textEditingValue,
                            ) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _artistSuggestions.where((String option) {
                                return option.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                );
                              });
                            },
                            onSelected: (String selection) {
                              setState(() {
                                _artistController.text = selection;
                              });
                            },
                            fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              if (textEditingController.text !=
                                  _artistController.text) {
                                textEditingController.text =
                                    _artistController.text;
                              }

                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (value) {
                                  _artistController.text = value;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Artist',
                                  labelStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2D2D3A),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Create New Artist',
                                    onPressed: () async {
                                      bool? artistCreated =
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return const NewArtistForm();
                                            },
                                          );
                                      if (artistCreated == true) {
                                        _fetchAllArtists();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: 4.0,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width - 32,
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (
                                        BuildContext context,
                                        int index,
                                      ) {
                                        final String option = options.elementAt(
                                          index,
                                        );
                                        return ListTile(
                                          title: Text(
                                            option,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          onTap: () {
                                            onSelected(option);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            focusNode: _notesFocus,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              labelStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(
                                Icons.note,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF2D2D3A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isProjectSaved) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Products',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: fontNameSemiBold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _createNewProduct,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'New Product',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  96,
                                  33,
                                  243,
                                ),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _products.isEmpty
                          ? Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 32),
                                Icon(
                                  Icons.album_outlined,
                                  color: Colors.white70,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No products yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create your first product',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _products.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final List<String> artists = List<String>.from(
                                product.primaryArtists,
                              );
                              final String artistNames = artists.join(', ');
                              final String coverUrl = product.coverImage;
                              final String title = product.releaseTitle;
                              final String version = product.releaseVersion;
                              final String displayTitle =
                                  version.isNotEmpty
                                      ? '$title ($version)'
                                      : title;
                              final String type = product.type;
                              final String state = product.state;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                color: const Color(0xFF1E1B2C),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _navigateToProduct(product.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child:
                                              coverUrl.isNotEmpty
                                                  ? ExtendedImage.network(
                                                    coverUrl,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    cache: true,
                                                    loadStateChanged: (state) {
                                                      if (state
                                                              .extendedImageLoadState ==
                                                          LoadState.loading) {
                                                        return const Center(
                                                          child:
                                                              LoadingIndicator(
                                                                size: 20,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                        );
                                                      }
                                                      return null;
                                                    },
                                                  )
                                                  : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[850],
                                                    child: const Icon(
                                                      Icons.album,
                                                      color: Colors.grey,
                                                      size: 40,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withAlpha(51),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      type,
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getStateColor(
                                                        state,
                                                      ).withAlpha(51),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 8,
                                                          height: 8,
                                                          decoration:
                                                              BoxDecoration(
                                                                color:
                                                                    _getStateColor(
                                                                      state,
                                                                    ),
                                                                shape:
                                                                    BoxShape
                                                                        .circle,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          state,
                                                          style: TextStyle(
                                                            color:
                                                                _getStateColor(
                                                                  state,
                                                                ),
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                displayTitle,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                artistNames.isNotEmpty
                                                    ? artistNames
                                                    : 'No Artists',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.audiotrack,
                                                    size: 16,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${product.trackCount} track${product.trackCount == 1 ? '' : 's'}',
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
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
                              );
                            },
                          ),
                    ],

                    if (!_isProjectSaved)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.save_outlined,
                                color: Colors.white70,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Save the project first',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You need to save the project before adding products',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}

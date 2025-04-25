import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/models/project.dart';
import 'package:portal/models/product.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/widgets/project_card/product_builder/product_builder.dart';
import 'text_fields.dart';
import 'product_list.dart';
import 'utils.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class ProjectCard extends StatefulWidget {
  final String projectId;
  final TextEditingController projectNameController;
  final TextEditingController uuidNameController;
  final TextEditingController artistNameController;
  final TextEditingController idController;
  final FocusNode artistFocusNode;
  final bool newProject;
  final TextEditingController notesController;
  final bool isExistingProject;
  final String? initialProductId;

  const ProjectCard({
    super.key,
    required this.projectId,
    required this.projectNameController,
    required this.uuidNameController,
    required this.artistNameController,
    required this.idController,
    required this.artistFocusNode,
    required this.newProject,
    required this.notesController,
    required this.isExistingProject,
    this.initialProductId,
  });

  @override
  ProjectCardState createState() => ProjectCardState();
}

class ProjectCardState extends State<ProjectCard> {
  List<String> products = [];
  Map<String, String> productIds = {};
  String? selectedProduct;
  List<String> artistSuggestions = [];
  String? selectedProductType;
  DocumentSnapshot? lastArtistDocument;
  bool isLoadingMoreArtists = false;
  bool isEditMode = false;
  bool isSaving = false;
  bool isProjectSaved = false;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();
  bool _hasUnsavedChanges = false;
  Map<String, dynamic> _originalData = {};
  final Set<String> _newProducts = {};

  double _opacity = 0.0; // Add a state variable for opacity

  // Ensure these controllers are initialized once and not reset
  late final TextEditingController projectNameController;
  late final TextEditingController uuidNameController;
  late final TextEditingController artistNameController;
  late final TextEditingController idController;
  late final TextEditingController notesController;
  late final String productId;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing widget controllers
    projectNameController = widget.projectNameController;
    uuidNameController = widget.uuidNameController;
    artistNameController = widget.artistNameController;
    idController = widget.idController;
    notesController = widget.notesController;
    _fetchAllArtists(); // Fetch all artists at once

    // For existing projects, assume they are valid
    if (!widget.newProject) {
      _isLoading = true;
      _fetchProducts().then((_) {
        if (widget.initialProductId != null) {
          String? productType;
          for (var entry in productIds.entries) {
            if (entry.value == widget.initialProductId) {
              productType = entry.key;
              break;
            }
          }
          if (productType != null) {
            setState(() {
              selectedProduct = productType;
              selectedProductType = productType;
            });
          }
        }

        _fetchAndSetArtist().then((_) {
          if (mounted) {
            setState(() {
              _hasUnsavedChanges = false;
              _originalData = _getCurrentData();
              _isLoading = false;
              _opacity = 1.0;
              isProjectSaved = true; // Mark as saved for existing projects
            });
          }
        });
      });
    } else {
      isEditMode = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _opacity = 1.0;
          });
        }
      });
    }

    // Add listeners to track changes
    widget.projectNameController.addListener(_onFieldChanged);
    widget.artistNameController.addListener(_onFieldChanged);
    widget.notesController.addListener(_onFieldChanged);
  }

  Map<String, dynamic> _getCurrentData() {
    return {
      'name': widget.projectNameController.text.trim(),
      'artist': widget.artistNameController.text.trim(),
      'notes': widget.notesController.text.trim(),
    };
  }

  void _onFieldChanged() {
    if (!mounted) return;

    final currentData = _getCurrentData();
    final hasChanges = !_mapsAreEqual(currentData, _originalData);

    setState(() {
      _hasUnsavedChanges = hasChanges;
    });
  }

  bool _mapsAreEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    return map1.entries.every((entry) {
      final value2 = map2[entry.key];
      return entry.value == value2;
    });
  }

  Future<Project?> _fetchProjectDetails() async {
    if (widget.newProject) {
      return null;
    }
    try {
      Project? project = await ApiService().getProjectById(widget.projectId);
      return project;
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchAllArtists() async {
    setState(() {
      isLoadingMoreArtists = true;
    });

    try {
      List<Map<String, dynamic>> allArtists =
          await ApiService()
              .fetchAllArtistsWithIds(); // Assume this method fetches all artists

      if (mounted) {
        setState(() {
          artistSuggestions =
              allArtists.map((artist) => artist['name'] as String).toList();
          isLoadingMoreArtists = false;
        });
      }
      // Debug statement
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMoreArtists = false;
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    try {
      List<Product> fetchedProducts = await ApiService().getProductsByProjectId(
        widget.projectId,
      );

      setState(() {
        products.clear();
        productIds.clear();
        _newProducts.clear(); // Clear the new products set

        for (var product in fetchedProducts) {
          String type = product.type;
          String id = product.id;

          // Generate a unique key for products of the same type
          String productKey = type;
          int counter = 1;
          while (products.contains(productKey)) {
            counter++;
            productKey = '$type ($counter)';
          }

          products.add(productKey);
          productIds[productKey] = id;
        }
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  String addProduct(String productType) {
    String productId = generateUID();

    setState(() {
      // Don't clear existing products, just add the new one
      products.add(productType);
      productIds[productType] = productId;
      selectedProduct = productType;
      selectedProductType = productType;
      _newProducts.add(productType);

      // Debug the state
      //print('Added new product:');
      //print('Type: $productType');
      //print('ID: $productId');
      //print('All products: $products');
      //print('Product IDs: $productIds');
      //print('New products: $_newProducts');
    });

    return productId;
  }

  void onProductSelected(String selected) {
    setState(() {
      selectedProduct = selected;
      selectedProductType = selected;
    });
  }

  Widget cardBody() {
    if (selectedProduct == null) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextField(
                  controller: widget.projectNameController,
                  enabled: isEditMode,
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    prefixIcon: const Icon(Icons.title, color: Colors.grey),
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
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: fontNameSemiBold,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: fontNameSemiBold,
                  ),
                ),
                const SizedBox(height: 16),
                buildAutocompleteTextField(
                  controller: artistNameController,
                  focusNode: widget.artistFocusNode,
                  label: 'Project Artist',
                  enabled: isEditMode,
                  artistSuggestions: artistSuggestions,
                  refreshSuggestions: _fetchAllArtists,
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: idController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'ID',
                    prefixIcon: const Icon(Icons.key, color: Colors.grey),
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
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                      fontFamily: fontNameSemiBold,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: fontNameSemiBold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: const Color(0xFF1E1B2C),
                  ),
                  child: TextField(
                    controller: notesController,
                    enabled: isEditMode,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Project Notes',
                      prefixIcon: Icon(Icons.notes, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.0),
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: fontNameSemiBold,
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: fontNameSemiBold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      );
    } else {
      return ProductBuilder(
        selectedProductType: selectedProductType ?? selectedProduct ?? '',
        projectId: widget.projectId,
        productId: productIds[selectedProduct] ?? '',
        isNewProduct: _newProducts.contains(selectedProduct),
      );
    }
  }

  Widget _buildSaveButton() {
    bool canSave =
        widget.projectNameController.text.trim().isNotEmpty &&
        widget.artistNameController.text.trim().isNotEmpty &&
        widget.idController.text.trim().isNotEmpty &&
        _hasUnsavedChanges;

    if (isSaving) {
      return const Center(
        child: LoadingIndicator(size: 50, color: Colors.white),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            canSave
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
        onPressed: canSave ? _saveProjectInformation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSave ? const Color(0xFF9D6BFF) : const Color(0xFF2D2D3A),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          !widget.newProject ? 'Update' : 'Save',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: fontNameSemiBold,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProject() async {
    if (widget.projectNameController.text.isEmpty ||
        widget.artistNameController.text.isEmpty ||
        widget.idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (widget.newProject) {
      setState(() {
        isSaving = true;
      });

      try {
        String userId = AuthService.instance.currentUser!.uid;
        Project newProject = Project(
          projectName: widget.projectNameController.text,
          projectArtist: widget.artistNameController.text,
          id: widget.idController.text,
          notes: widget.notesController.text,
          uid: userId + widget.idController.text,
        );

        await ApiService().createProject(newProject);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project created successfully')),
          );
        }

        setState(() {
          isSaving = false;
          isEditMode = false; // Disable edit mode after creation
          isProjectSaved = true;
        });
      } catch (e) {
        setState(() {
          isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create project')),
          );
        }
      }
    } else {
      // Implement save logic for existing projects
      setState(() {
        isSaving = true;
      });

      try {
        String userId = AuthService.instance.currentUser!.uid;

        // Update the project with new notes
        await ApiService().updateProject(userId, widget.projectId, {
          'notes': widget.notesController.text,
          'projectName': widget.projectNameController.text,
          'projectArtist': widget.artistNameController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project updated successfully')),
          );
        }

        setState(() {
          isSaving = false;
          isEditMode = false;
        });
      } catch (e) {
        setState(() {
          isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update project')),
          );
        }
      }
    }
  }

  Future<void> _fetchAndSetArtist() async {
    try {
      String userId = AuthService.instance.currentUser!.uid;
      String? artistName = await ApiService().getArtistByProjectId(
        userId,
        widget.projectId,
      );
      if (artistName != null) {
        setState(() {
          widget.artistNameController.text = artistName;
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> _saveProjectInformation() async {
    setState(() {
      isSaving = true;
    });

    try {
      await _saveProject();

      setState(() {
        _hasUnsavedChanges = false;
        _originalData = _getCurrentData();
        isProjectSaved = true; // Mark as saved after successful save
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project information saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.newProject) {
      isEditMode = true;
      return Stack(
        children: [
          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: _buildNewProjectCard(),
          ),
          if (_isLoading)
            AnimatedOpacity(
              opacity: 1 - _opacity,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: const Center(
                child: LoadingIndicator(size: 50, color: Colors.white),
              ),
            ),
        ],
      );
    } else {
      return FutureBuilder<Project?>(
        future: _fetchProjectDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Project not found'));
          } else {
            // When data is loaded, trigger the fade in
            if (_isLoading) {
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _opacity = 1.0;
                  });
                }
              });
            }

            Project project = snapshot.data!;
            projectNameController.text = project.projectName;
            uuidNameController.text = project.id;
            artistNameController.text = project.projectArtist;
            idController.text = project.id;
            isEditMode = false;

            return Stack(
              children: [
                AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: _buildExistingProjectCard(),
                ),
                if (_isLoading)
                  AnimatedOpacity(
                    opacity: 1 - _opacity,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: const Center(
                      child: LoadingIndicator(size: 50, color: Colors.white),
                    ),
                  ),
              ],
            );
          }
        },
      );
    }
  }

  Widget _buildNewProjectCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Card(
          color: Theme.of(context).cardColor, // Use theme card color
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: ListView(
                  children: [
                    ListTile(
                      title: Center(
                        child: Text(
                          'Project Information',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedProduct = null;
                        });
                      },
                    ),
                    if (isProjectSaved) // Show only if the project is saved
                      buildAddProductButton(
                        isProjectSaved: isProjectSaved,
                        addProduct: addProduct,
                      ),
                    ...products.map(
                      (product) => ProductListTile(
                        product: product,
                        products: products,
                        projectId: widget.projectId,
                        onProductSelected: onProductSelected,
                        productIds: productIds,
                        isExistingProject: widget.isExistingProject,
                        isNewProduct: _newProducts.contains(product),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.black),
              cardBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingProjectCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Card(
          color: Theme.of(context).cardColor, // Use theme card color
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: ListView(
                  children: [
                    ListTile(
                      title: Center(
                        child: Text(
                          'Project Information',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          selectedProduct = null;
                        });
                      },
                    ),
                    buildAddProductButton(
                      isProjectSaved: true,
                      addProduct: addProduct,
                    ),
                    ...products.map(
                      (product) => ProductListTile(
                        product: product,
                        products: products,
                        projectId: widget.projectId,
                        onProductSelected: onProductSelected,
                        productIds: productIds,
                        isExistingProject: widget.isExistingProject,
                        isNewProduct: _newProducts.contains(product),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.black),
              cardBody(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.projectNameController.removeListener(_onFieldChanged);
    widget.artistNameController.removeListener(_onFieldChanged);
    widget.notesController.removeListener(_onFieldChanged);
    super.dispose();
  }
}

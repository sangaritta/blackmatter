import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/product_builder.dart';
import 'text_fields.dart';
import 'product_list.dart';
import 'utils.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class ProjectCard extends StatefulWidget {
  final String projectId;
  final bool newProject;
  final String? initialProductId;

  const ProjectCard({
    super.key,
    required this.projectId,
    required this.newProject,
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

  late final TextEditingController projectNameController;
  late final TextEditingController uuidNameController;
  late final TextEditingController artistNameController;
  late final TextEditingController idController;
  late final TextEditingController notesController;
  late final FocusNode artistFocusNode;

  @override
  void initState() {
    super.initState();
    projectNameController = TextEditingController();
    uuidNameController = TextEditingController();
    artistNameController = TextEditingController();
    idController = TextEditingController();
    notesController = TextEditingController();
    artistFocusNode = FocusNode();
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
        }
      });
    } else {
      isEditMode = true;
      idController.text = widget.projectId; // Ensure ID is shown for new projects
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
    projectNameController.addListener(_onFieldChanged);
    artistNameController.addListener(_onFieldChanged);
    notesController.addListener(_onFieldChanged);
  }

  Map<String, dynamic> _getCurrentData() {
    return {
      'name': projectNameController.text.trim(),
      'artist': artistNameController.text.trim(),
      'notes': notesController.text.trim(),
    };
  }

  void _onFieldChanged() {
    if (!mounted) return;

    final currentData = _getCurrentData();
    final hasChanges = !_mapsAreEqual(currentData, _originalData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasUnsavedChanges = hasChanges;
        });
      }
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
      String userId = auth.getUser()!.uid;
      Project? project = await api.getProjectById(userId, widget.projectId);
      if (project == null) {}
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
      List<String> allArtists =
          await api.fetchAllArtists(); // Assume this method fetches all artists

      if (mounted) {
        setState(() {
          artistSuggestions = allArtists;
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
      String userId = auth.getUser()!.uid;
      List<Map<String, dynamic>> fetchedProducts =
          await api.getProductsForProject(userId, widget.projectId);

      setState(() {
        products.clear();
        productIds.clear();
        _newProducts.clear(); // Clear the new products set

        for (var product in fetchedProducts) {
          String type = product['type'] as String;
          String id = product['id'] as String;

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
      print('Added new product:');
      print('Type: $productType');
      print('ID: $productId');
      print('All products: $products');
      print('Product IDs: $productIds');
      print('New products: $_newProducts');
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
                  controller: projectNameController,
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
                  focusNode: artistFocusNode,
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
                _buildSaveButton()
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
    bool canSave = projectNameController.text.trim().isNotEmpty &&
        artistNameController.text.trim().isNotEmpty &&
        idController.text.trim().isNotEmpty &&
        _hasUnsavedChanges;

    if (isSaving) {
      return const Center(
        child: LoadingIndicator(
          size: 50,
          color: Colors.white,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: canSave
            ? [
                BoxShadow(
                  color: const Color(0xFF9D6BFF).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: canSave ? _saveProject : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave ? const Color(0xFF9D6BFF) : const Color(0xFF2D2D3A),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
    if (projectNameController.text.isEmpty ||
        artistNameController.text.isEmpty ||
        idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }

    if (widget.newProject) {
      setState(() {
        isSaving = true;
      });

      try {
        String userId = auth.getUser()!.uid;
        Project newProject = Project(
          name: projectNameController.text,
          artist: artistNameController.text,
          id: idController.text,
          notes: notesController.text,
        );

        await api.createProject(userId, newProject);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project created successfully')));
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
              const SnackBar(content: Text('Failed to create project')));
        }
      }
    } else {
      // Implement save logic for existing projects
      setState(() {
        isSaving = true;
      });

      try {
        String userId = auth.getUser()!.uid;

        // Update the project with new notes
        await api.updateProject(userId, widget.projectId, {
          'notes': notesController.text,
          'projectName': projectNameController.text,
          'projectArtist': artistNameController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project updated successfully')));
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
              const SnackBar(content: Text('Failed to update project')));
        }
      }
    }
  }

  Future<void> _fetchAndSetArtist() async {
    try {
      String userId = auth.getUser()!.uid;
      String? artistName =
          await api.getArtistByProjectId(userId, widget.projectId);
      setState(() {
        artistNameController.text = artistName!;
      });
    } catch (e) {
      throw Exception(e);
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
                child: LoadingIndicator(
                  size: 50,
                  color: Colors.white,
                ),
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
            projectNameController.text = project.name;
            uuidNameController.text = project.id;
            artistNameController.text = project.artist;
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
                      child: LoadingIndicator(
                        size: 50,
                        color: Colors.white,
                      ),
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
                child: Stack(
                  children: [
                    ListView(
                      children: [
                        ListTile(
                          title: Center(
                            child: Text(
                              'Project Information',
                              style: TextStyle(color: Theme.of(context).primaryColor),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              selectedProduct = null;
                            });
                          },
                        ),
                        if (isProjectSaved)
                          buildAddProductButton(
                            isProjectSaved: isProjectSaved,
                            addProduct: addProduct,
                          ),
                        ...products.map((product) => ProductListTile(
                              product: product,
                              products: products,
                              projectId: widget.projectId,
                              onProductSelected: onProductSelected,
                              productIds: productIds,
                              isExistingProject: !widget.newProject,
                              isNewProduct: _newProducts.contains(product),
                            )),
                      ],
                    ),
                    if (!isProjectSaved)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: false,
                          child: Container(
                            color: Colors.black.withOpacity(0.7),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.lock_outline, color: Colors.white, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'Save project information before adding products.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.black),
              cardBody()
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
                          style: TextStyle(color: Theme.of(context).primaryColor),
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
                    ...products.map((product) => ProductListTile(
                          product: product,
                          products: products,
                          projectId: widget.projectId,
                          onProductSelected: onProductSelected,
                          productIds: productIds,
                          isExistingProject: !widget.newProject,
                          isNewProduct: _newProducts.contains(product),
                        )),
                  ],
                ),
              ),
              const VerticalDivider(color: Colors.black),
              cardBody()
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    projectNameController.dispose();
    uuidNameController.dispose();
    artistNameController.dispose();
    idController.dispose();
    notesController.dispose();
    artistFocusNode.dispose();
    super.dispose();
  }
}

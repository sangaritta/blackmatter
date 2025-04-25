import 'package:flutter/material.dart';
import 'package:portal/screens/home/project_view/responsive_project_view.dart';
import 'package:portal/services/api_service.dart';
import 'package:portal/widgets/common/loading_indicator.dart';
import 'package:portal/models/index_entry.dart';
import 'package:extended_image/extended_image.dart';
import 'package:portal/screens/home/project_view/project_view.dart';

final api = ApiService();

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[400],
              labelStyle: const TextStyle(
                fontFamily: 'Bold',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'SemiBold',
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              tabs: const [Tab(text: 'Products'), Tab(text: 'Projects')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_ProductsTab(), _ProjectsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        // Default route: list of products
        return MaterialPageRoute(builder: (context) => _ProductsList());
      },
    );
  }
}

class _ProductsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IndexEntry>>(
      stream: api.streamProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('No products found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final entry = products[index];
            return _ProductTile(
              entry: entry,
              onTap: () async {
                final userId = api.auth.currentUser?.uid;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: User not found')),
                  );
                  return;
                }
                // FIX: Use correct IDs for project and product
                final product = await api.getProductById(entry.projectId ?? entry.id, entry.id);
                final project = await api.getProjectById(entry.projectId ?? entry.id);
                if (product == null || project == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: Product or Project not found\n'
                        'projectId: ${entry.projectId ?? entry.id}\n'
                        'productId: ${entry.id}',
                      ),
                    ),
                  );
                  return;
                }
                final projectNameController = TextEditingController(
                  text: project.name,
                );
                final artistNameController = TextEditingController(
                  text: project.projectArtist,
                );
                final notesController = TextEditingController(
                  text: project.notes,
                );
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                MediaQuery.of(context).size.width > 600
                                    ? ProjectView(
                                      projectId: project.id,
                                      project: project,
                                      newProject: false,
                                      productUPC: product.upc,
                                      initialProductId: product.id,
                                      projectNameController:
                                          projectNameController,
                                      uuidNameController:
                                          TextEditingController(),
                                      artistNameController:
                                          artistNameController,
                                      idController: TextEditingController(),
                                      notesController: notesController,
                                      artistFocusNode: FocusNode(),
                                    )
                                    : ResponsiveProjectView(
                                      projectId: project.id,
                                      project: project,
                                      newProject: false,
                                      productUPC: '',
                                      initialProductId: '',
                                    ),
                      ),
                    )
                    .then((_) {
                      projectNameController.dispose();
                      artistNameController.dispose();
                      notesController.dispose();
                    });
              },
            );
          },
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final IndexEntry entry;
  final VoidCallback? onTap;
  const _ProductTile({required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final String displayTitle =
        (entry.releaseVersion != null && entry.releaseVersion!.isNotEmpty)
            ? '${entry.releaseTitle ?? entry.name} (${entry.releaseVersion})'
            : (entry.releaseTitle != null && entry.releaseTitle!.isNotEmpty
                ? entry.releaseTitle!
                : entry.name);
    final String artistNames =
        (entry.primaryArtists != null && entry.primaryArtists!.isNotEmpty)
            ? entry.primaryArtists!.join(', ')
            : 'No Artists';
    final String type = entry.type ?? 'Unknown Type';
    final String state = entry.state ?? 'Unknown';
    final String coverUrl = entry.coverImage ?? '';
    final String updatedAtStr =
        entry.updatedAt != null
            ? entry.updatedAt!.toLocal().toString().split(" ")[0]
            : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1B2C),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image - optimized to reduce memory usage
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    coverUrl.isNotEmpty
                        ? ExtendedImage.network(
                          coverUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          cache: true,
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState ==
                                LoadState.loading) {
                              return Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[850],
                                child: const Center(
                                  child: LoadingIndicator(
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                          imageCacheName: "productList",
                          clearMemoryCacheWhenDispose: true,
                        )
                        : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[850],
                          child: const Icon(
                            Icons.album,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontFamily: 'SemiBold',
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStateColor(state).withAlpha(51),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getStateColor(state),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state,
                                style: TextStyle(
                                  fontFamily: 'SemiBold',
                                  color: _getStateColor(state),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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
                        fontFamily: 'Bold',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artistNames.isNotEmpty ? artistNames : 'No Artists',
                      style: TextStyle(
                        fontFamily: 'SemiBold',
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                          '${entry.trackCount} track${entry.trackCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontFamily: 'SemiBold',
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          updatedAtStr,
                          style: TextStyle(
                            fontFamily: 'SemiBold',
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
}

class _ProjectsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IndexEntry>>(
      stream: api.streamProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LoadingIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final projects = snapshot.data ?? [];
        if (projects.isEmpty) {
          return const Center(child: Text('No projects found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final entry = projects[index];
            return GestureDetector(
              onTap: () async {
                final userId = api.auth.currentUser?.uid;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: User not found')),
                  );
                  return;
                }
                final project = await api.getProjectById(entry.id);
                if (project == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Project not found')),
                  );
                  return;
                }
                final projectNameController = TextEditingController(
                  text: project.name,
                );
                final uuidNameController = TextEditingController(
                  text: project.id,
                );
                final artistNameController = TextEditingController(
                  text: project.projectArtist,
                );
                final idController = TextEditingController(text: project.id);
                final notesController = TextEditingController(
                  text: project.notes,
                );
                final artistFocusNode = FocusNode();
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                MediaQuery.of(context).size.width > 600
                                    ? ProjectView(
                                      projectId: project.id,
                                      project: project,
                                      newProject: false,
                                      projectNameController:
                                          projectNameController,
                                      uuidNameController: uuidNameController,
                                      artistNameController:
                                          artistNameController,
                                      idController: idController,
                                      notesController: notesController,
                                      artistFocusNode: artistFocusNode,
                                    )
                                    : ResponsiveProjectView(
                                      projectId: project.id,
                                      project: project,
                                      newProject: false,
                                      productUPC: '',
                                      initialProductId: '',
                                    ),
                      ),
                    )
                    .then((_) {
                      projectNameController.dispose();
                      uuidNameController.dispose();
                      artistNameController.dispose();
                      idController.dispose();
                      notesController.dispose();
                      artistFocusNode.dispose();
                    });
              },
              child: _ProjectTile(entry: entry),
            );
          },
        );
      },
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final IndexEntry entry;
  const _ProjectTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final String displayTitle =
        entry.releaseTitle != null && entry.releaseTitle!.isNotEmpty
            ? entry.releaseTitle!
            : entry.name;
    final String artistNames =
        (entry.primaryArtists != null && entry.primaryArtists!.isNotEmpty)
            ? entry.primaryArtists!.join(', ')
            : 'No Artists';
    final String state = entry.state ?? 'Unknown';
    final String coverUrl = entry.coverImage ?? '';
    final String updatedAtStr =
        entry.updatedAt != null
            ? entry.updatedAt!.toLocal().toString().split(" ")[0]
            : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1B2C),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            coverUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExtendedImage.network(
                    coverUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    loadStateChanged:
                        (state) =>
                            state.extendedImageLoadState == LoadState.failed
                                ? Container(
                                  color: Colors.grey[900],
                                  width: 64,
                                  height: 64,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white38,
                                  ),
                                )
                                : null,
                  ),
                )
                : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white38,
                  ),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          fontFamily: 'Bold',
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStateColor(state).withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStateColor(state),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state,
                              style: TextStyle(
                                fontFamily: 'SemiBold',
                                color: _getStateColor(state),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    artistNames.isNotEmpty ? artistNames : 'No Artists',
                    style: TextStyle(
                      fontFamily: 'SemiBold',
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        updatedAtStr,
                        style: TextStyle(
                          fontFamily: 'SemiBold',
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
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
}

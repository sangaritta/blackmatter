import 'package:flutter/material.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Widgets/ProjectCard/ProductBuilder/product_builder.dart';
import 'package:portal/Widgets/ProjectCard/utils.dart';
import 'package:extended_image/extended_image.dart';

Color getProductStateColor(String state) {
  switch (state.toLowerCase()) {
    case 'draft':
      return Colors.grey;
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

Widget buildProductStateChip(String state) {
  return Chip(
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6.0,
          height: 6.0,
          decoration: BoxDecoration(
            color: getProductStateColor(state),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: getProductStateColor(state).withValues(
                  red: getProductStateColor(state).r,
                  green: getProductStateColor(state).g,
                  blue: getProductStateColor(state).b,
                  alpha: 0.6,
                ),
                blurRadius: 4.0,
                spreadRadius: 1.0,
              ),
            ],
          ),
        ),
        const SizedBox(width: 2.0),
        Text(
          state,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    ),
    backgroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
      side: const BorderSide(color: Colors.black),
    ),
  );
}

IconData getProductIcon(String productType) {
  switch (productType) {
    case 'Single':
      return Icons.music_note;
    case 'EP':
      return Icons.album;
    case 'Album':
      return Icons.library_music;
    case 'Compilation':
      return Icons.queue_music;
    case 'Music Video':
      return Icons.videocam;
    default:
      return Icons.music_note;
  }
}

enum ProductState {
  newUnsaved, // Product in a new project, not saved yet
  existingUnsaved, // Product in existing project, not saved yet
  saved // Product has been saved and has data
}

class ProductListTile extends StatefulWidget {
  final String product; // This is the product type (Single, EP, etc.)
  final List<String> products;
  final Function(String) onProductSelected;
  final String projectId;
  final Map<String, String> productIds;
  final bool isExistingProject;
  final bool isNewProduct; // Add this to track if it's a newly added product

  const ProductListTile({
    super.key,
    required this.product,
    required this.products,
    required this.onProductSelected,
    required this.projectId,
    required this.productIds,
    required this.isExistingProject,
    this.isNewProduct = false, // Default to false
  });

  @override
  State<ProductListTile> createState() => _ProductListTileState();
}

class _ProductListTileState extends State<ProductListTile> {
  String formatArtists(List<String> artists) {
    if (artists.isEmpty) return "No artists";
    if (artists.length == 1) return artists[0];
    final lastArtist = artists.last;
    final otherArtists = artists.sublist(0, artists.length - 1);
    return '${otherArtists.join(", ")} & $lastArtist';
  }

  Widget _buildNewProductTile() {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF1E1B2C),
        ),
        child: Icon(
          getProductIcon(widget.product),
          color: Colors.blue,
          size: 24,
        ),
      ),
      title: Text(
        'New ${widget.product}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: const Text(
        'Click to configure',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(red: Colors.grey.r, green: Colors.grey.g, blue: Colors.grey.b, alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_new, color: Colors.grey, size: 16),
            SizedBox(width: 4),
            Text(
              'Draft',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      onTap: () => widget.onProductSelected(widget.product),
    );
  }

  Widget _buildSavedProductTile() {
    final productId = widget.productIds[widget.product];
    if (productId == null) {
      return _buildNewProductTile();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: () async {
        final user = auth.getUser();
        if (user == null) {
          //print('Debug: No authenticated user found in _buildSavedProductTile');
          return null;
        }
        if (!mounted) return null;

        return api.getProduct(
          user.uid,
          widget.projectId,
          productId,
        );
      }(),
      builder: (context, snapshot) {
        if (!mounted) return const SizedBox.shrink();

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            title: Text('Loading...', style: TextStyle(color: Colors.grey)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _buildNewProductTile();
        }

        final productData = snapshot.data!;
        final title = productData['releaseTitle'] ?? 'Untitled';
        final version = productData['releaseVersion'] ?? '';
        final artists = List<String>.from(productData['primaryArtists'] ?? []);
        final state = productData['state'] ?? 'Draft';
        final coverImageUrl = productData['coverImage'];

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF1E1B2C),
            ),
            child: coverImageUrl != null && coverImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ExtendedImage.network(
                      coverImageUrl,
                      fit: BoxFit.cover,
                      cache: true,
                      loadStateChanged: (state) {
                        if (state.extendedImageLoadState == LoadState.loading) {
                          return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2));
                        }
                        if (state.extendedImageLoadState == LoadState.failed) {
                          return Icon(
                            getProductIcon(widget.product),
                            color: Colors.blue,
                            size: 24,
                          );
                        }
                        return null;
                      },
                    ),
                  )
                : Icon(
                    getProductIcon(widget.product),
                    color: Colors.blue,
                    size: 24,
                  ),
          ),
          title: Text(
            version.isNotEmpty ? '$title ($version)' : title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatArtists(artists),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: () async {
                  if (!mounted) return <Map<String, dynamic>>[];

                  final user = auth.getUser();
                  //print('Debug: Auth state check in track fetching');
                  //print('Debug: User object exists: ${user != null}');

                  if (user == null || user.uid.isEmpty) {
                    //print(
                    //    'Debug: Invalid user state - user: ${user?.email}, uid: ${user?.uid}');
                    return <Map<String, dynamic>>[];
                  }

                  //print('Debug: Valid user found - uid: ${user.uid}');
                  //print(
                  //    'Debug: Fetching tracks for - projectId: ${widget.projectId}, productId: $productId');

                  try {
                    final tracks = await api.getTracksForProduct(
                      user.uid,
                      widget.projectId,
                      productId,
                    );
                    //print(
                    //    'Debug: Successfully fetched ${tracks.length} tracks for product $productId');
                    return tracks;
                  } catch (error) {
                    //print('Error fetching tracks: $error');
                    //print('Error stack trace: ${StackTrace.current}');
                    return <Map<String, dynamic>>[];
                  }
                }(),
                builder: (context, trackSnapshot) {
                  if (!mounted) return const SizedBox.shrink();

                  if (trackSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Text(
                      'Loading tracks...',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    );
                  }

                  if (trackSnapshot.hasError) {
                    //print('Error fetching tracks: ${trackSnapshot.error}');
                    return Text(
                      'Error loading tracks',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 12,
                      ),
                    );
                  }

                  final trackCount = trackSnapshot.data?.length ?? 0;
                  return Text(
                    '$trackCount track${trackCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getProductStateColor(state).withValues(
                red: getProductStateColor(state).r,
                green: getProductStateColor(state).g,
                blue: getProductStateColor(state).b,
                alpha: 0.2
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getProductStateIcon(state),
                  color: getProductStateColor(state),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  state,
                  style: TextStyle(
                    color: getProductStateColor(state),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          onTap: () => widget.onProductSelected(widget.product),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If it's a new product or doesn't have an ID yet, show the new product tile
    if (widget.isNewProduct || !widget.productIds.containsKey(widget.product)) {
      return _buildNewProductTile();
    }
    // Otherwise, show the saved product tile
    return _buildSavedProductTile();
  }
}

IconData getProductStateIcon(String state) {
  switch (state.toLowerCase()) {
    case 'draft':
      return Icons.edit;
    case 'in review':
      return Icons.pending;
    case 'approved':
      return Icons.check_circle;
    case 'rejected':
      return Icons.cancel;
    case 'published':
      return Icons.public;
    case 'takedown':
      return Icons.remove_circle;
    default:
      return Icons.help_outline;
  }
}

Widget buildAddProductButton({
  required bool isProjectSaved,
  required Function(String) addProduct,
}) {
  return PopupMenuButton<String>(
    onSelected: (String type) {
      if (isProjectSaved) {
        addProduct(type);
      }
    },
    itemBuilder: (BuildContext context) => [
      const PopupMenuItem(
        value: 'Single',
        child: Row(
          children: [
            Icon(Icons.music_note),
            SizedBox(width: 8),
            Text('Single'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'EP',
        child: Row(
          children: [
            Icon(Icons.album),
            SizedBox(width: 8),
            Text('EP'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'Album',
        child: Row(
          children: [
            Icon(Icons.library_music),
            SizedBox(width: 8),
            Text('Album'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'Compilation',
        child: Row(
          children: [
            Icon(Icons.queue_music),
            SizedBox(width: 8),
            Text('Compilation'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'Music Video',
        child: Row(
          children: [
            Icon(Icons.videocam),
            SizedBox(width: 8),
            Text('Music Video'),
          ],
        ),
      ),
    ],
    enabled: isProjectSaved,
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Add Product',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white, // Changed to white for better visibility
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            Icons.add,
            color: Colors.white, // Changed to white for better visibility
          ),
        ],
      ),
    ),
  );
}

Future<String> addProduct(
    String type, String projectId, BuildContext context) async {
  final String productId = generateUID();

  if (context.mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductBuilder(
          selectedProductType: type,
          projectId: projectId,
          productId: productId,
          isNewProduct: true,
        ),
      ),
    );
  }

  return productId;
}

import 'package:flutter/material.dart';
import 'package:portal/Screens/Home/project_view.dart';
import 'package:portal/Screens/Home/Mobile/mobile_project_view.dart';
import 'package:portal/Services/api_service.dart';
import 'package:extended_image/extended_image.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class ProductsListView extends StatefulWidget {
  const ProductsListView({super.key});

  @override
  ProductsListViewState createState() => ProductsListViewState();
}

class ProductsListViewState extends State<ProductsListView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: api.productsStreamIndex(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingIndicator(size: 50, color: Colors.white),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.album, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new product to get started',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final List<String> artists = List<String>.from(
              product['primaryArtists'] ?? [],
            );
            final String artistNames = artists.join(', ');
            final String coverUrl = product['coverImage'] ?? '';
            final String title = product['releaseTitle'] ?? 'Unknown Product';
            final String version = product['releaseVersion'] ?? '';
            final String displayTitle =
                version.isNotEmpty ? '$title ($version)' : title;
            final String type = product['type'] ?? 'Unknown Type';
            final String state = product['state'] ?? 'Unknown';

            return Card(
              margin: const EdgeInsets.all(16),
              color: const Color(0xFF1E1B2C),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _navigateToProduct(product),
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
                                  // Use simple fade transition to reduce memory usage
                                  loadStateChanged: (state) {
                                    if (state.extendedImageLoadState ==
                                        LoadState.loading) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[850],
                                        child: const Center(
                                          child: LoadingIndicator(
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    }
                                    return null;
                                  },
                                  // Set memory cache size to reduce memory usage
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 4.0,
                          ),
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
                                      color: _getStateColor(
                                        state,
                                      ).withAlpha(51),
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
                                  color: Colors.white,
                                  fontSize: 18,
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
                                    '${product['trackCount'] ?? 0} track${(product['trackCount'] ?? 0) == 1 ? '' : 's'}',
                                    style: TextStyle(
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
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToProduct(Map<String, dynamic> product) async {
    try {
      final String projectId = product['projectId'];
      if (projectId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Project ID not found')),
          );
        }
        return;
      }

      final bool isMobileView = MediaQuery.of(context).size.width <= 600;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) =>
                  isMobileView
                      ? MobileProjectView(
                        projectId: projectId,
                        newProject: false,
                        initialProductId: product['id'],
                      )
                      : ProjectView(
                        projectId: projectId,
                        productUPC: product['upc'] ?? '',
                        newProject: false,
                        initialProductId: product['id'],
                      ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading project: $e')));
      }
    }
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

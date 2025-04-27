import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Screens/Home/Marketplace/product_repository.dart';
import 'package:portal/Screens/Home/Marketplace/product_model.dart';
import 'package:portal/Screens/Home/Marketplace/seller_model.dart';
import 'package:portal/Screens/Home/Marketplace/widgets/product_card.dart';
import 'package:extended_image/extended_image.dart';
import 'package:portal/Screens/Home/Marketplace/product_detail_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerId;

  const SellerProfileScreen({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final productRepository =
        ProductRepository(Provider.of<ApiService>(context));

    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          productRepository.getSellerProfile(sellerId),
          productRepository.getSellerListings(sellerId)
        ]).then((results) => {'seller': results[0], 'products': results[1]}),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final Seller seller = snapshot.data!['seller'];
          final List<Product> products = snapshot.data!['products'];

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            ExtendedNetworkImageProvider(seller.avatarUrl),
                      ),
                      const SizedBox(height: 16),
                      Text(seller.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(' ${seller.rating.toStringAsFixed(1)}',
                              style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, size: 20),
                          Text(seller.location,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('About Seller',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(seller.bio),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(
                      product: products[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            product: products[index],
                            seller: seller,
                          ),
                        ),
                      ),
                    ),
                    childCount: products.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

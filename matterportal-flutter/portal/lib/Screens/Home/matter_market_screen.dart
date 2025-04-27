import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Screens/Home/Marketplace/product_repository.dart';
import 'package:portal/Screens/Home/Marketplace/cart_provider.dart';
import 'package:portal/Screens/Home/Marketplace/product_detail_screen.dart';
import 'package:portal/Screens/Home/Marketplace/product_model.dart';
import 'package:portal/Widgets/Common/under_construction_overlay.dart';
import 'package:portal/main.dart';

class MatterMarketScreen extends StatefulWidget {
  const MatterMarketScreen({super.key});

  @override
  State<MatterMarketScreen> createState() => _MatterMarketScreenState();
}

class _MatterMarketScreenState extends State<MatterMarketScreen> {
  late final ProductRepository _productRepository;

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepository(ApiService());
  }

  @override
  Widget build(BuildContext context) {
    return UnderConstructionOverlay(
      show: showUnderConstructionOverlay,
      child: ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Matter Market'),
            actions: [
              Consumer<CartProvider>(
                builder:
                    (context, cart, _) => Badge(
                      label: Text(cart.items.length.toString()),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: () => _showCartDialog(context),
                      ),
                    ),
              ),
            ],
          ),
          body: FutureBuilder<List<Product>>(
            future: _productRepository.getMarketplaceProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final products = snapshot.data!;

              return products.isEmpty
                  ? const Center(child: Text('No products available'))
                  : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemCount: products.length,
                      itemBuilder:
                          (context, index) => ProductCard(
                            product: products[index],
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ProductDetailScreen(
                                          product: products[index],
                                          seller: products[index].seller!,
                                        ),
                                  ),
                                ),
                          ),
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  void _showCartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Consumer<CartProvider>(
            builder:
                (context, cart, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Shopping Cart (${cart.items.length} items)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder:
                              (context, index) => ListTile(
                                //leading: CachedNetworkImage(
                                //  imageUrl: cart.items[index].imageUrl,
                                //  width: 50,
                                //  height: 50,
                                //  fit: BoxFit.cover,
                                //),
                                title: Text(cart.items[index].title),
                                subtitle: Text(
                                  '\$${cart.items[index].price.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle),
                                  onPressed:
                                      () => cart.removeFromCart(
                                        cart.items[index].id,
                                      ),
                                ),
                              ),
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '\$${cart.totalPrice.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium,
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
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.asset(
              product.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: TextStyle(fontFamily: fontNameSemiBold),
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontFamily: fontNameBold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14),
                    Text(
                      product.location,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onTap,
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

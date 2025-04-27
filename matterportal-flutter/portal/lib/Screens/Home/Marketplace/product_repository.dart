import 'package:portal/Services/api_service.dart';
import 'product_model.dart';
import 'seller_model.dart';

class ProductRepository {
  final ApiService _apiService;

  ProductRepository(this._apiService);

  Future<List<Product>> getMarketplaceProducts({int limit = 20}) async {
    try {
      final result = await _apiService.getAllProductsForUser(limit: limit);
      final products = result['products'] as List<Map<String, dynamic>>;

      return products
          .map((product) => Product.fromFirestore(product, product['id'] ?? ''))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<Seller> getSellerProfile(String sellerId) async {
    try {
      final sellerData = await _apiService.getUserProfile(sellerId);
      return Seller.fromFirestore(sellerData, sellerId);
    } catch (e) {
      throw Exception('Failed to load seller profile: $e');
    }
  }

  Future<List<Product>> getSellerListings(String sellerId) async {
    try {
      final listings = await _apiService.getProductsBySeller(sellerId);
      return listings
          .map((doc) => Product.fromFirestore(doc, doc['id'] ?? ''))
          .toList();
    } catch (e) {
      throw Exception('Failed to load seller listings: $e');
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    try {
      final result = await _apiService.getAllProductsForUser(limit: 10);
      final products = result['products'] as List<Map<String, dynamic>>;

      // Filter for featured products (you might want to add a 'featured' field to your products)
      final featuredProducts = products
          .where((p) =>
              p['featured'] == true ||
              (p['rating'] != null && (p['rating'] as num) >= 4.0))
          .take(5)
          .toList();

      return featuredProducts
          .map((product) => Product.fromFirestore(product, product['id'] ?? ''))
          .toList();
    } catch (e) {
      throw Exception('Failed to load featured products: $e');
    }
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final result = await _apiService.getAllProductsForUser(limit: 50);
      final products = result['products'] as List<Map<String, dynamic>>;

      // Filter by category
      final categoryProducts = products
          .where((p) =>
              p['category']?.toString().toLowerCase() == category.toLowerCase())
          .toList();

      return categoryProducts
          .map((product) => Product.fromFirestore(product, product['id'] ?? ''))
          .toList();
    } catch (e) {
      throw Exception('Failed to load products by category: $e');
    }
  }

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      // Implement this method once you add the getProductReviews method to your API service
      // For now, return an empty list
      return [];
    } catch (e) {
      throw Exception('Failed to load product reviews: $e');
    }
  }

  Future<bool> addProductReview(String productId, Review review) async {
    try {
      // Implement this method once you add the addProductReview method to your API service
      // For now, return success
      return true;
    } catch (e) {
      throw Exception('Failed to add product review: $e');
    }
  }

  Future<bool> createMarketListing(Product product) async {
    try {
      // Implement this method to create a new marketplace listing
      // This would need to be added to your API service
      return true;
    } catch (e) {
      throw Exception('Failed to create product listing: $e');
    }
  }
}

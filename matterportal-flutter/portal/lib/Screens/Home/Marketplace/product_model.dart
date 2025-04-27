import 'package:portal/Screens/Home/Marketplace/seller_model.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String location;
  final double rating;
  final int reviewCount;
  final bool featured;
  final DateTime createdAt;
  final Seller? seller;
  final List<String> tags;
  final int stockQuantity;
  final bool isDigital;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.location,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.featured = false,
    required this.createdAt,
    this.seller,
    this.tags = const [],
    this.stockQuantity = 0,
    this.isDigital = false,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      title: data['releaseTitle'] ?? data['title'] ?? 'Untitled Product',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['coverImage'] ?? data['imageUrl'] ?? '',
      category: data['category'] ?? 'Music',
      location: data['location'] ?? 'Worldwide',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: (data['reviewCount'] ?? 0),
      featured: data['featured'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      stockQuantity: data['stockQuantity'] ?? 0,
      isDigital: data['isDigital'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'featured': featured,
      'createdAt': createdAt,
      'sellerId': seller?.id,
      'tags': tags,
      'stockQuantity': stockQuantity,
      'isDigital': isDigital,
    };
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String productId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      productId: data['productId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'productId': productId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}

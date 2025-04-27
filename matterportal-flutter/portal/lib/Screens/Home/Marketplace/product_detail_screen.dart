import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:portal/Screens/Home/Marketplace/product_model.dart';
import 'package:portal/Screens/Home/Marketplace/seller_model.dart';
import 'package:portal/Screens/Home/Marketplace/seller_profile_screen.dart';
import 'package:portal/Screens/Home/Marketplace/product_repository.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Seller seller;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.seller,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductRepository _repository = ProductRepository(ApiService());
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  String _errorMessage = '';
  bool _isAddingToCart = false;
  bool _showReviewForm = false;
  final _reviewFormKey = GlobalKey<FormState>();

  // Review form fields
  double _rating = 5.0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoadingReviews = true;
      _errorMessage = '';
    });

    try {
      // In a real app, you would fetch real reviews here
      final reviews = await _repository.getProductReviews(widget.product.id);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reviews: $e';
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    // In a real app, you would actually add to cart
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isAddingToCart = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_reviewFormKey.currentState!.validate()) {
      // In a real app, you would submit the review
      try {
        final newReview = Review(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'current-user-id', // In a real app, get this from auth
          userName: 'Current User', // In a real app, get this from auth
          userPhotoUrl: '', // In a real app, get this from auth
          productId: widget.product.id,
          rating: _rating,
          comment: _reviewController.text,
          createdAt: DateTime.now(),
        );

        await _repository.addProductReview(widget.product.id, newReview);

        if (mounted) {
          setState(() {
            _reviews = [newReview, ..._reviews];
            _showReviewForm = false;
            _reviewController.clear();
            _rating = 5.0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Review submitted successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit review: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share product
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ExtendedImage.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      return const Center(child: LoadingIndicator(size: 40));
                    case LoadState.completed:
                      return null;
                    case LoadState.failed:
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                  }
                },
              ),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRatingStars(widget.product.rating),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.product.rating.toStringAsFixed(1)} (${widget.product.reviewCount} reviews)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Seller Info
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SellerProfileScreen(
                                sellerId: widget.seller.id,
                              ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: ExtendedNetworkImageProvider(
                              widget.seller.avatarUrl.isNotEmpty
                                  ? widget.seller.avatarUrl
                                  : 'https://via.placeholder.com/100',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.seller.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Seller | ${widget.seller.rating.toStringAsFixed(1)} ★',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'No description provided.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                  ),

                  // Tags
                  if (widget.product.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          widget.product.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],

                  const Divider(height: 32),

                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews (${_reviews.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (!_showReviewForm)
                        TextButton.icon(
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Write a Review'),
                          onPressed: () {
                            setState(() {
                              _showReviewForm = true;
                            });
                          },
                        ),
                    ],
                  ),

                  // Review Form
                  if (_showReviewForm) _buildReviewForm(),

                  // Reviews List
                  _buildReviewsList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Wish List Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  // Add to wishlist
                },
              ),
            ),
            const SizedBox(width: 16),
            // Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: _isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child:
                    _isAddingToCart
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text('ADD TO CART'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final starIcons = List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber[700],
        size: 20,
      );
    });

    return Row(mainAxisSize: MainAxisSize.min, children: starIcons);
  }

  // Add a new method that returns just the list of star icons
  List<Widget> _buildRatingStarIcons(double rating) {
    return List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber[700],
        size: 20,
      );
    });
  }

  Widget _buildReviewForm() {
    return Form(
      key: _reviewFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Your Rating:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _rating.toString(),
            onChanged: (value) {
              setState(() {
                _rating = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildRatingStarIcons(_rating), // Use the new method here
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reviewController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Your Review',
              hintText: 'Share your experience with this product...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your review';
              }
              if (value.length < 10) {
                return 'Review is too short (minimum 10 characters)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showReviewForm = false;
                    _reviewController.clear();
                    _rating = 5.0;
                  });
                },
                child: const Text('CANCEL'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitReview,
                child: const Text('SUBMIT REVIEW'),
              ),
            ],
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: LoadingIndicator(size: 30),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No reviews yet. Be the first to leave a review!',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: ExtendedNetworkImageProvider(
                      review.userPhotoUrl.isNotEmpty
                          ? review.userPhotoUrl
                          : 'https://via.placeholder.com/32',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: _buildRatingStarIcons(
                  review.rating,
                ), // Use the new method here
              ),
              const SizedBox(height: 4),
              Text(
                review.comment,
                style: TextStyle(fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Screens/Home/Marketplace/product_repository.dart';
import 'package:portal/Screens/Home/Marketplace/product_model.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class SellProductScreen extends StatefulWidget {
  const SellProductScreen({super.key});

  @override
  State<SellProductScreen> createState() => _SellProductScreenState();
}

class _SellProductScreenState extends State<SellProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Beats';
  final List<String> _selectedTags = [];
  bool _isDigital = true;
  int _stockQuantity = 1;
  File? _imageFile;
  bool _isSubmitting = false;

  // Repository for API calls
  final ProductRepository _repository = ProductRepository(api);

  // Available categories
  final List<String> _categories = [
    'Beats',
    'Samples',
    'Instrumentals',
    'Vocal Presets',
    'Sound Kits',
    'MIDI Packs',
    'Plugins',
    'Services',
  ];

  // Available tags
  final List<String> _availableTags = [
    'Hip Hop',
    'R&B',
    'Pop',
    'EDM',
    'Trap',
    'Rock',
    'Jazz',
    'Dance',
    'Lofi',
    'Soul',
    'Funk',
    'Country',
    'Latin',
    'World',
    'Reggae',
    'Classical',
    'Ambient',
    'Drum & Bass',
    'House',
    'Techno',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate() && _validateForm()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // In a real app, you would upload the image first
        String userId = auth.getUser()?.uid ?? '';
        if (userId.isEmpty) {
          throw Exception('User not authenticated');
        }

        // Creating a product for demonstration
        final newProduct = Product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          imageUrl: _imageFile != null
              ? _imageFile!.path
              : 'https://via.placeholder.com/500',
          category: _selectedCategory,
          location: 'Worldwide', // In a real app, get from user profile
          createdAt: DateTime.now(),
          tags: _selectedTags,
          stockQuantity: _stockQuantity,
          isDigital: _isDigital,
        );

        final success = await _repository.createMarketListing(newProduct);

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product listed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to list product. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _validateForm() {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a product image'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List a Product'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Add Product Image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Product Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  hintText: 'Enter a descriptive title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your product in detail',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  hintText: 'Enter the price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tags
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tags (select up to 5)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              if (_selectedTags.length < 5) {
                                _selectedTags.add(tag);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('You can select up to 5 tags'),
                                  ),
                                );
                              }
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Digital or Physical
              Row(
                children: [
                  const Text(
                    'Product Type:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Digital'),
                    selected: _isDigital,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isDigital = true;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Physical'),
                    selected: !_isDigital,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _isDigital = false;
                        });
                      }
                    },
                  ),
                ],
              ),

              if (!_isDigital) ...[
                const SizedBox(height: 16),
                // Stock Quantity (only for physical products)
                TextFormField(
                  initialValue: _stockQuantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_isDigital) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (int.parse(value) <= 0) {
                        return 'Quantity must be greater than zero';
                      }
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _stockQuantity = int.tryParse(value) ?? 1;
                    });
                  },
                ),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: LoadingIndicator(size: 20),
                        )
                      : const Text('LIST MY PRODUCT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

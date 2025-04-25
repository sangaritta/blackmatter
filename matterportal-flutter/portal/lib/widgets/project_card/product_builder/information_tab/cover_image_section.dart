import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:extended_image/extended_image.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;

class CoverImageSection extends StatefulWidget {
  final Uint8List? selectedImageBytes;
  final String? coverImageUrl;
  final Function(Uint8List?) onImageSelected;

  const CoverImageSection({
    super.key, 
    required this.selectedImageBytes,
    required this.coverImageUrl,
    required this.onImageSelected,
  });

  @override
  State<CoverImageSection> createState() => _CoverImageSectionState();
}

class _CoverImageSectionState extends State<CoverImageSection> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cover image container
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 36, 32, 46),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _buildImageContent(),
                ),
                
                // Edit button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(128), 
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(128), 
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => _pickImage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.selectedImageBytes != null) {
      return ExtendedImage.memory(
        widget.selectedImageBytes!,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8.0),
        shape: BoxShape.rectangle,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return const Center(child: CircularProgressIndicator());
            case LoadState.failed:
              return const Center(child: Icon(Icons.error));
            default:
              return null;
          }
        },
      );
    } else if (widget.coverImageUrl != null && widget.coverImageUrl!.isNotEmpty) {
      return ExtendedImage.network(
        widget.coverImageUrl!,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(8.0),
        shape: BoxShape.rectangle,
        cache: true,
        loadStateChanged: (ExtendedImageState state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return const Center(child: CircularProgressIndicator());
            case LoadState.failed:
              return const Center(child: Icon(Icons.error));
            default:
              return null;
          }
        },
      );
    } else {
      return const Icon(
        Icons.image,
        size: 150,
        color: Color.fromARGB(255, 54, 50, 114),
      );
    }
  }

  Future<void> _pickImage() async {
    final BuildContext localContext = context;
    Uint8List? imageBytes;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        if (kIsWeb) {
          imageBytes = result.files.single.bytes;
        } else {
          String? filePath = result.files.single.path;
          imageBytes = io.File(filePath!).readAsBytesSync();
        }

        if (imageBytes != null) {
          // Decode the image to check its dimensions
          final image = await decodeImageFromList(imageBytes);

          if (image.width >= 3000 &&
              image.height >= 3000 &&
              image.width == image.height) {
            widget.onImageSelected(imageBytes);
          } else {
            if (mounted) {
              _showImageSizeError(localContext);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSizeError(BuildContext context) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select a square image that is at least 3000x3000 pixels.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
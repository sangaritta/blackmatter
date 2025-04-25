import 'dart:typed_data';

/// Utility class for validating Information Tab fields
class ValidationUtils {
  /// Validates all fields in the information tab to determine if they're complete
  bool validateAllFields({
    required String title,
    required List<String> artists,
    required bool autoGenerateUPC,
    required String upc,
    required String label,
    required String cLine,
    required String pLine,
    required Uint8List? image,
    required String? imageUrl,
    required String? language,
    required String? genre,
    required String? subgenre,
    required String? price,
  }) {
    // Check if all required fields are filled
    return title.isNotEmpty &&
        artists.isNotEmpty &&
        (autoGenerateUPC || isValidUPC(upc)) &&
        label.isNotEmpty &&
        cLine.isNotEmpty &&
        pLine.isNotEmpty &&
        (image != null || (imageUrl != null && imageUrl.isNotEmpty)) &&
        language != null &&
        genre != null &&
        subgenre != null &&
        price != null;
  }

  /// Validates UPC code format
  bool isValidUPC(String upc) {
    // UPC must be 12 or 13 digits
    if (upc.isEmpty || !RegExp(r'^\d{12,13}$').hasMatch(upc)) {
      return false;
    }

    // If 13 digits, validate as an EAN-13 code
    if (upc.length == 13) {
      int sum = 0;
      for (int i = 0; i < 12; i++) {
        int digit = int.parse(upc[i]);
        sum += (i % 2 == 0) ? digit : digit * 3;
      }
      int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(upc[12]);
    }
    
    // If 12 digits, validate as UPC-A
    else {
      int sum = 0;
      for (int i = 0; i < 11; i++) {
        int digit = int.parse(upc[i]);
        sum += (i % 2 == 0) ? digit * 3 : digit;
      }
      int checkDigit = (10 - (sum % 10)) % 10;
      return checkDigit == int.parse(upc[11]);
    }
  }

  /// Determines if a user can proceed to the next tab
  bool canProceedToNext({
    required bool hasImage,
    required bool hasTitle,
    required bool hasArtists,
    required bool isUpcValid,
    required bool hasLabel,
    required bool hasCLine,
    required bool hasPLine,
    required bool hasMetadataLanguage,
    required bool hasGenre,
    required bool hasSubgenre,
    required bool hasPrice,
  }) {
    return hasImage &&
        hasTitle &&
        hasArtists &&
        isUpcValid &&
        hasLabel &&
        hasCLine &&
        hasPLine &&
        hasMetadataLanguage &&
        hasGenre &&
        hasSubgenre &&
        hasPrice;
  }
}
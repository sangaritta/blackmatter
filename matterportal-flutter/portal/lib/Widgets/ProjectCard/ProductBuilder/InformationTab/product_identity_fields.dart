import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal/Constants/fonts.dart';

class ProductIdentityFields {
  // Builder for product type dropdown
  static Widget buildProductTypeDropdown({
    required String? selectedProductType,
    required List<String> productTypes,
    required Function(String) onProductTypeChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedProductType,
      items: productTypes.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: fontNameSemiBold,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onProductTypeChanged(newValue);
        }
      },
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: 'Product Type',
        prefixIcon: const Icon(Icons.album, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1B2C),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: fontNameSemiBold,
        ),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: fontNameSemiBold,
      ),
    );
  }

  // Builder for price dropdown
  static Widget buildPriceDropdown({
    required String? selectedPrice,
    required List<String> prices,
    required Function(String?) onPriceChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedPrice,
      items: prices.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: fontNameSemiBold,
            ),
          ),
        );
      }).toList(),
      onChanged: onPriceChanged,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: 'Price',
        prefixIcon: const Icon(Icons.attach_money, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1B2C),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: fontNameSemiBold,
        ),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: fontNameSemiBold,
      ),
    );
  }

  // Builder for UPC field
  static Widget buildUPCField({
    required TextEditingController upcController,
    required bool autoGenerateUPC,
    required bool isExistingProduct,
    required Function(bool) onAutoGenerateChanged,
    required Function() onUpcChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2C),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: TextField(
              controller: upcController,
              enabled: !isExistingProduct && !autoGenerateUPC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: InputDecoration(
                labelText: 'UPC',
                prefixIcon: const Icon(Icons.qr_code, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1E1B2C),
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontFamily: fontNameSemiBold,
                ),
              ),
              style: TextStyle(
                color: !isExistingProduct && !autoGenerateUPC
                    ? Colors.white
                    : Colors.grey,
                fontFamily: fontNameSemiBold,
              ),
              onChanged: (value) => onUpcChanged(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2C),
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Auto',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontFamily: fontNameSemiBold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: autoGenerateUPC && !isExistingProduct
                      ? [
                          BoxShadow(
                            color: const Color(0xFF9D6BFF).withOpacity(0.5),
                            spreadRadius: 0,
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ]
                      : null,
                ),
                child: SizedBox(
                  height: 36,
                  child: Switch(
                    value: autoGenerateUPC,
                    onChanged: isExistingProduct
                        ? null
                        : (bool value) => onAutoGenerateChanged(value),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF4A4FBF),
                    inactiveThumbColor: const Color(0xFF4A4A4A),
                    inactiveTrackColor: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Builder for UID field
  static Widget buildUIDField({
    required TextEditingController uidController,
  }) {
    return TextField(
      controller: uidController,
      enabled: false,
      decoration: InputDecoration(
        labelText: 'UID',
        prefixIcon: const Icon(Icons.key, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1B2C),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: fontNameSemiBold,
        ),
      ),
      style: const TextStyle(
        color: Colors.grey,
        fontFamily: fontNameSemiBold,
      ),
    );
  }

  // Builder for label dropdown
  static Widget buildLabelDropdown({
    required TextEditingController labelController,
    required List<Map<String, dynamic>> labels,
    required Function(String?) onLabelChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: labelController.text.isEmpty ? null : labelController.text,
      items: labels.map((label) {
        return DropdownMenuItem<String>(
          value: label['name'],
          child: Text(
            label['name'],
            style: const TextStyle(
              color: Colors.white,
              fontFamily: fontNameSemiBold,
            ),
          ),
        );
      }).toList(),
      onChanged: onLabelChanged,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: 'Label',
        prefixIcon: const Icon(Icons.label, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF1E1B2C),
        labelStyle: const TextStyle(
          color: Colors.grey,
          fontFamily: fontNameSemiBold,
        ),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: fontNameSemiBold,
      ),
    );
  }
}
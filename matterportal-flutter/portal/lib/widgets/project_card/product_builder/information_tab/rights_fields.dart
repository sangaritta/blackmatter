import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';

class RightsFields extends StatelessWidget {
  final TextEditingController cLineController;
  final TextEditingController pLineController;
  final String currentYear;
  final String cLineYear;
  final String pLineYear;
  final Function(String?) onCLineYearChanged;
  final Function(String?) onPLineYearChanged;
  final bool isMobile;

  const RightsFields({
    super.key,
    required this.cLineController,
    required this.pLineController,
    required this.currentYear,
    required this.cLineYear,
    required this.pLineYear,
    required this.onCLineYearChanged,
    required this.onPLineYearChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // C-Line Row
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  // CLine Year Dropdown
                  SizedBox(
                    width: 100,
                    child: _buildYearDropdown(
                      value: cLineYear,
                      label: ' Year',
                      onChanged: onCLineYearChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // CLine Text Field
                  Expanded(
                    child: _buildRightsTextField(
                      controller: cLineController,
                      prefix: ' C Line',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // P-Line Row
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  // PLine Year Dropdown
                  SizedBox(
                    width: 100,
                    child: _buildYearDropdown(
                      value: pLineYear,
                      label: ' Year',
                      onChanged: onPLineYearChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // PLine Text Field
                  Expanded(
                    child: _buildRightsTextField(
                      controller: pLineController,
                      prefix: ' P Line',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearDropdown({
    required String value,
    required String label,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: List.generate(2025 - 1900 + 1, (index) {
        int year = 2025 - index;
        return DropdownMenuItem(
          value: year.toString(),
          child: Text(
            year.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: fontNameSemiBold,
            ),
          ),
        );
      }),
      onChanged: onChanged,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildRightsTextField({
    required TextEditingController controller,
    required String prefix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            prefix,
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: fontNameSemiBold,
            ),
          ),
        ),
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
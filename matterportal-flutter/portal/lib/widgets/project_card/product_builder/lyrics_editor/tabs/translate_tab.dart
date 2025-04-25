import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Constants/product.dart';

class TranslateTab extends StatefulWidget {
  final String originalText;
  final Map<String, String> translations;
  final String? selectedLanguage;
  final Function(String) onLanguageChanged;
  final Function(String, String) onTranslationChanged;

  const TranslateTab({
    super.key,
    required this.originalText,
    required this.translations,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onTranslationChanged,
  });

  @override
  State<TranslateTab> createState() => _TranslateTabState();
}

class _TranslateTabState extends State<TranslateTab> {
  late TextEditingController _translationController;
  late String? _currentLanguage;

  @override
  void initState() {
    super.initState();
    _currentLanguage = widget.selectedLanguage;
    _translationController = TextEditingController(
      text:
          _currentLanguage != null ? widget.translations[_currentLanguage] : '',
    );
  }

  @override
  void dispose() {
    _translationController.dispose();
    super.dispose();
  }

  void _handleLanguageChange(String? newLanguage) {
    if (newLanguage == null) return;

    // Save current translation if language was selected
    if (_currentLanguage != null) {
      widget.onTranslationChanged(
        _currentLanguage!,
        _translationController.text,
      );
    }

    setState(() {
      _currentLanguage = newLanguage;
      _translationController.text = widget.translations[newLanguage] ?? '';
    });
    widget.onLanguageChanged(newLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector
          DropdownButtonFormField<String>(
            value: _currentLanguage,
            decoration: InputDecoration(
              labelText: 'Select Language',
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1B2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.language, color: Colors.grey),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: fontNameSemiBold,
            ),
            dropdownColor: const Color(0xFF1E1B2C),
            items: metadataLanguages.map((language) {
              return DropdownMenuItem<String>(
                value: language['code'],
                child: Text(language['name'] ?? language['code'] ?? ''),
              );
            }).toList(),
            onChanged: _handleLanguageChange,
          ),
          const SizedBox(height: 16),

          // Original lyrics display
          const Text(
            'Original Lyrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: fontNameBold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.originalText,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Translation input
          if (_currentLanguage != null) ...[
            Text(
              'Translation (${metadataLanguages.firstWhere((l) => l['code'] == _currentLanguage)['name'] ?? _currentLanguage})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: fontNameBold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _translationController,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter translation here...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1B2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  widget.onTranslationChanged(_currentLanguage!, value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

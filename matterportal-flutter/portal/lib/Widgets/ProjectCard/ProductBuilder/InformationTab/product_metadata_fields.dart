import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Constants/product.dart';
import 'package:portal/Widgets/ProjectCard/text_fields.dart';

class ProductMetadataFields extends StatelessWidget {
  final TextEditingController releaseTitleController;
  final TextEditingController releaseVersionController;
  final TextEditingController primaryArtistsController;
  final List<String> selectedArtists;
  final List<String> artistSuggestions;
  final Function(String) onArtistAdded;
  final Function(String) onArtistRemoved;
  final Function(List<String>) onArtistsReordered;
  final Function(String) onReleaseTitleChanged;
  final MetadataLanguage? selectedMetadataLanguage;
  final List<MetadataLanguage> metadataLanguages;
  final Function(MetadataLanguage?) onMetadataLanguageChanged;
  final String? selectedGenre;
  final List<String> genres;
  final Function(String?) onGenreChanged;
  final String? selectedSubgenre;
  final Map<String, List<String>> subgenres;
  final Function(String?) onSubgenreChanged;
  final List<String> selectedArtistIds;
  final Function(List<String>) onArtistIdsUpdated;
  final bool isMobile;

  const ProductMetadataFields({
    super.key,
    required this.releaseTitleController,
    required this.releaseVersionController,
    required this.primaryArtistsController,
    required this.selectedArtists,
    required this.artistSuggestions,
    required this.onArtistAdded,
    required this.onArtistRemoved,
    required this.onArtistsReordered,
    required this.onReleaseTitleChanged,
    required this.selectedMetadataLanguage,
    required this.metadataLanguages,
    required this.onMetadataLanguageChanged,
    required this.selectedGenre,
    required this.genres,
    required this.onGenreChanged,
    required this.selectedSubgenre,
    required this.subgenres,
    required this.onSubgenreChanged,
    required this.selectedArtistIds,
    required this.onArtistIdsUpdated,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Version
        Row(
          children: [
            Expanded(
              child: _buildTitleField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildVersionField(),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Language and Artists
        Row(
          children: [
            Expanded(
              child: _buildLanguageDropdown(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildArtistField(context),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Genre and Subgenre
        Row(
          children: [
            Expanded(
              child: _buildGenreDropdown(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSubgenreDropdown(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: releaseTitleController,
      onChanged: onReleaseTitleChanged,
      decoration: InputDecoration(
        labelText: 'Release Title',
        prefixIcon: const Icon(Icons.title, color: Colors.grey),
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
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildVersionField() {
    return TextField(
      controller: releaseVersionController,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Release Version (Optional)',
        prefixIcon: const Icon(Icons.tag, color: Colors.grey),
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
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildLanguageDropdown() {
    return DropdownButtonFormField<MetadataLanguage>(
      value: selectedMetadataLanguage,
      items: metadataLanguages.map((MetadataLanguage language) {
        return DropdownMenuItem<MetadataLanguage>(
          value: language,
          child: Text(language.name),
        );
      }).toList(),
      onChanged: onMetadataLanguageChanged,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: 'Metadata Language',
        prefixIcon: const Icon(Icons.language, color: Colors.grey),
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
        labelStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontFamily: fontNameSemiBold,
      ),
    );
  }

  Widget _buildArtistField(BuildContext context) {
    final state = context.findAncestorStateOfType<State<StatefulWidget>>();
    FocusNode? focusNode;
    // Defensive: only assign if InformationTabState is detected
    if (state != null && state.runtimeType.toString() == 'InformationTabState') {
      // ignore: invalid_use_of_protected_member
      focusNode = (state as dynamic).primaryArtistsFocusNode;
    }
    return buildArtistAutocomplete(
      context: context,
      controller: primaryArtistsController,
      label: 'Primary Artists',
      artistSuggestions: artistSuggestions,
      selectedArtists: selectedArtists,
      onArtistAdded: onArtistAdded,
      onArtistRemoved: onArtistRemoved,
      onArtistsReordered: onArtistsReordered,
      prefixIcon: const Icon(Icons.person, color: Colors.grey),
      collection: 'artists',
      selectedArtistIds: selectedArtistIds,
      onArtistIdsUpdated: onArtistIdsUpdated,
      focusNode: focusNode,
    );
  }

  Widget _buildGenreDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedGenre,
      items: genres.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onGenreChanged,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: 'Genre',
        prefixIcon: const Icon(Icons.category, color: Colors.grey),
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

  Widget _buildSubgenreDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSubgenre,
      items: selectedGenre != null
          ? subgenres[selectedGenre]
              ?.map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ))
              .toList()
          : null,
      onChanged: onSubgenreChanged,
      menuMaxHeight: 400,
      dropdownColor: const Color(0xFF2D2D3A),
      decoration: InputDecoration(
        labelText: 'Subgenre',
        prefixIcon: const Icon(Icons.subdirectory_arrow_right, color: Colors.grey),
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
import 'package:flutter/material.dart';
import 'package:portal/Widgets/ProjectCard/text_fields.dart';

class ArtistSelector extends StatelessWidget {
  final String label;
  final List<String> selectedArtists;
  final Function(List<String>) onChanged;
  final String collection;
  final List<String>? selectedArtistIds;
  final Function(List<String>)? onArtistIdsUpdated;

  const ArtistSelector({
    required this.label,
    required this.selectedArtists,
    required this.onChanged,
    required this.collection,
    this.selectedArtistIds,
    this.onArtistIdsUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    print('BUILDING ARTIST SELECTOR: $label');
    print('CURRENT ARTISTS: $selectedArtists');

    return buildArtistAutocomplete(
      context: context,
      controller: TextEditingController(),
      label: label,
      artistSuggestions: const [], // Will be populated from API
      selectedArtists: selectedArtists,
      onArtistAdded: (artist) {
        print('ARTIST_SELECTOR - Artist Added: $artist');
        if (!selectedArtists.contains(artist)) {
          final updatedList = [...selectedArtists, artist];
          print('ARTIST_SELECTOR - Updated list: $updatedList');
          onChanged(updatedList);
        }
      },
      onArtistRemoved: (artist) {
        print('ARTIST_SELECTOR - Artist Removed: $artist');
        final updatedList = selectedArtists.where((a) => a != artist).toList();
        print('ARTIST_SELECTOR - Updated list: $updatedList');
        onChanged(updatedList);
      },
      onArtistsReordered: (artists) {
        print('ARTIST_SELECTOR - Artists Reordered: $artists');
        onChanged(artists);
      },
      collection: collection,
      selectedArtistIds: selectedArtistIds,
      onArtistIdsUpdated: onArtistIdsUpdated != null
          ? (ids) {
              print('ARTIST_SELECTOR - Artist IDs Updated: $ids');
              onArtistIdsUpdated!(ids);
            }
          : null,
    );
  }
}

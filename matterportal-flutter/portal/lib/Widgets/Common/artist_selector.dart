import 'package:flutter/material.dart';
import 'package:portal/Widgets/ProjectCard/text_fields.dart';

class ArtistSelector extends StatefulWidget {
  final String label;
  final List<String> selectedArtists;
  final Function(List<String>) onChanged;
  final String collection;
  final List<String>? selectedArtistIds;
  final Function(List<String>)? onArtistIdsUpdated;
  final Widget? prefixIcon;

  const ArtistSelector({
    required this.label,
    required this.selectedArtists,
    required this.onChanged,
    required this.collection,
    this.selectedArtistIds,
    this.onArtistIdsUpdated,
    this.prefixIcon,
    super.key,
  });

  @override
  State<ArtistSelector> createState() => _ArtistSelectorState();
}

class _ArtistSelectorState extends State<ArtistSelector> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildArtistAutocomplete(
      context: context,
      controller: _controller,
      label: widget.label,
      artistSuggestions: const [], // Will be populated from API
      selectedArtists: widget.selectedArtists,
      onArtistAdded: (artist) {
        if (!widget.selectedArtists.contains(artist)) {
          final updatedList = [...widget.selectedArtists, artist];
          widget.onChanged(updatedList);
        }
      },
      onArtistRemoved: (artist) {
        final updatedList =
            widget.selectedArtists.where((a) => a != artist).toList();
        widget.onChanged(updatedList);
      },
      onArtistsReordered: (artists) {
        widget.onChanged(artists);
      },
      collection: widget.collection,
      selectedArtistIds: widget.selectedArtistIds,
      onArtistIdsUpdated:
          widget.onArtistIdsUpdated != null
              ? (ids) {
                widget.onArtistIdsUpdated!(ids);
              }
              : null,
      prefixIcon: widget.prefixIcon,
    );
  }
}

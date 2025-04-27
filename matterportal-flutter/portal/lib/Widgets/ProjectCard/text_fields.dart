import 'dart:async';

import 'package:flutter/material.dart';
import 'package:portal/Screens/Home/Forms/new_artist_form.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:reorderables/reorderables.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String label,
  FocusNode? focusNode,
  bool enabled = true,
  VoidCallback? onSubmitted,
  Widget? suffixIcon,
  Widget? prefixIcon,
  Function(String)? onChanged,
}) {
  return TextField(
    controller: controller,
    focusNode: focusNode,
    enabled: enabled,
    onChanged: onChanged,
    onSubmitted: (value) {
      if (onSubmitted != null) {
        onSubmitted();
      }
    },
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
      labelStyle: const TextStyle(color: Colors.grey),
      hintStyle: const TextStyle(color: Colors.grey),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    ),
    style: const TextStyle(color: Colors.white),
  );
}

Widget buildAutocompleteTextField({
  required TextEditingController controller,
  required String label,
  FocusNode? focusNode,
  bool enabled = true,
  required List<String> artistSuggestions,
  required Function refreshSuggestions,
  Widget? prefixIcon,
}) {
  return Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return artistSuggestions;
      }
      return artistSuggestions.where((String option) {
        return option.toLowerCase().contains(
          textEditingValue.text.toLowerCase(),
        );
      });
    },
    onSelected: (String selection) {
      controller.text = selection;
    },
    fieldViewBuilder: (
      BuildContext context,
      TextEditingController fieldTextEditingController,
      FocusNode fieldFocusNode,
      VoidCallback onFieldSubmitted,
    ) {
      fieldTextEditingController.text = controller.text;
      return TextFormField(
        controller: fieldTextEditingController,
        focusNode: fieldFocusNode,
        enabled: enabled,
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
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: prefixIcon,
        ),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an artist';
          }
          return null;
        },
      );
    },
    optionsViewBuilder: (
      BuildContext context,
      AutocompleteOnSelected<String> onSelected,
      Iterable<String> options,
    ) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              shrinkWrap: true,
              itemCount: options.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return TextButton.icon(
                    onPressed: () async {
                      bool? artistCreated = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return const NewArtistForm();
                        },
                      );
                      if (artistCreated == true) {
                        refreshSuggestions();
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.blue),
                    label: const Text(
                      'Create New Artist',
                      style: TextStyle(color: Colors.blue),
                    ),
                  );
                } else {
                  final String option = options.elementAt(index - 1);
                  return GestureDetector(
                    onTap: () {
                      onSelected(option);
                    },
                    child: ListTile(
                      title: Text(
                        option,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      );
    },
  );
}

Widget buildMultiArtistAutocompleteTextField({
  required TextEditingController controller,
  required String label,
  FocusNode? focusNode,
  bool enabled = true,
  required List<String> artistSuggestions,
  required List<String> selectedArtists,
  required Function(String) onArtistAdded,
  required Function(String) onArtistRemoved,
  required Function(List<String>) onArtistsReordered,
  Widget? prefixIcon,
  bool showResetButton = false,
  VoidCallback? onReset,
  String? resetTooltip,
  String? collection,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ReorderableWrap(
        spacing: 8.0,
        runSpacing: 4.0,
        onReorder: (int oldIndex, int newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final List<String> newList = List.from(selectedArtists);
          final String artist = newList.removeAt(oldIndex);
          newList.insert(newIndex, artist);
          onArtistsReordered(newList);
        },
        children:
            selectedArtists.map((artist) {
              return Padding(
                key: ValueKey(artist), // Ensure each chip has a unique key
                padding: const EdgeInsets.all(4.0),
                child: Chip(
                  label: Text(
                    artist,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onDeleted: () => onArtistRemoved(artist),
                  backgroundColor: Colors.grey[800],
                ),
              );
            }).toList(),
      ),
      Row(
        children: [
          Expanded(
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return artistSuggestions.where(
                    (artist) => !selectedArtists.contains(artist),
                  );
                }
                return artistSuggestions.where(
                  (String option) =>
                      option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ) &&
                      !selectedArtists.contains(option),
                );
              },
              onSelected: (String selection) {
                if (!selectedArtists.contains(selection)) {
                  onArtistAdded(selection);
                  controller.clear();
                }
              },
              fieldViewBuilder: (
                BuildContext context,
                TextEditingController fieldTextEditingController,
                FocusNode fieldFocusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return TextField(
                  controller: fieldTextEditingController,
                  focusNode: fieldFocusNode,
                  enabled: enabled,
                  autofocus: false, // Ensure autofocus is always off to avoid unwanted rebuilds
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
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: prefixIcon,
                  ),
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          if (showResetButton && onReset != null)
            Tooltip(
              message: resetTooltip ?? 'Reset',
              child: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onReset,
              ),
            ),
        ],
      ),
    ],
  );
}

Widget buildMultiSongwriterAutocompleteTextField({
  required TextEditingController controller,
  required String label,
  FocusNode? focusNode,
  bool enabled = true,
  required List<String> songwriterSuggestions,
  required List<String> selectedSongwriters,
  required Function(String) onSongwriterAdded,
  required Function(String) onSongwriterRemoved,
  required Function(List<String>) onSongwritersReordered,
  Widget? prefixIcon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ReorderableWrap(
        spacing: 8.0,
        runSpacing: 4.0,
        onReorder: (int oldIndex, int newIndex) {
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          final String songwriter = selectedSongwriters.removeAt(oldIndex);
          selectedSongwriters.insert(newIndex, songwriter);
          onSongwritersReordered(selectedSongwriters);
        },
        children:
            selectedSongwriters.map((songwriter) {
              return Padding(
                key: ValueKey(songwriter),
                padding: const EdgeInsets.all(4.0),
                child: Chip(
                  label: Text(
                    songwriter,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onDeleted: () => onSongwriterRemoved(songwriter),
                  backgroundColor: Colors.grey[800],
                ),
              );
            }).toList(),
      ),
      Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return songwriterSuggestions;
          }
          return songwriterSuggestions.where((String option) {
            return option.toLowerCase().contains(
              textEditingValue.text.toLowerCase(),
            );
          });
        },
        onSelected: (String selection) {
          controller.text = selection;
          onSongwriterAdded(selection);
        },
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          fieldTextEditingController.text = controller.text;
          return TextField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            enabled: enabled,
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
              labelStyle: const TextStyle(color: Colors.grey),
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: prefixIcon,
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (value) {
              value.split(',').forEach((songwriter) {
                onSongwriterAdded(songwriter.trim());
              });
              fieldTextEditingController.clear();
            },
          );
        },
        optionsViewBuilder: (
          BuildContext context,
          AutocompleteOnSelected<String> onSelected,
          Iterable<String> options,
        ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.3,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return GestureDetector(
                      onTap: () {
                        onSelected(option);
                      },
                      child: ListTile(
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

// Add new widget for project card artist field
Widget buildProjectArtistAutocomplete({
  required TextEditingController controller,
  required String label,
  required List<String> artistSuggestions,
  required Function refreshSuggestions,
  FocusNode? focusNode,
  Widget? prefixIcon,
}) {
  return Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return artistSuggestions;
      }
      return artistSuggestions.where((String option) {
        return option.toLowerCase().contains(
          textEditingValue.text.toLowerCase(),
        );
      });
    },
    onSelected: (String selection) {
      controller.text = selection;
    },
    fieldViewBuilder: (
      context,
      fieldTextEditingController,
      fieldFocusNode,
      onFieldSubmitted,
    ) {
      return TextField(
        controller: fieldTextEditingController,
        focusNode: fieldFocusNode,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon,
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
        ),
      );
    },
    optionsViewBuilder: (context, onSelected, options) {
      return Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2C),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final String option = options.elementAt(index);
                return ListTile(
                  leading: FutureBuilder<String?>(
                    future: _getArtistProfileImage(option),
                    builder: (context, snapshot) {
                      return CircleAvatar(
                        backgroundImage:
                            snapshot.data != null
                                ? NetworkImage(snapshot.data!)
                                : null,
                        child:
                            snapshot.data == null
                                ? const Icon(Icons.person)
                                : null,
                      );
                    },
                  ),
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

// Add new widget for information tab artist field
Widget buildArtistAutocomplete({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  required List<String> artistSuggestions,
  required List<String> selectedArtists,
  required Function(String) onArtistAdded,
  required Function(String) onArtistRemoved,
  required Function(List<String>) onArtistsReordered,
  required String collection,
  Icon? prefixIcon,
  bool showResetButton = false,
  VoidCallback? onReset,
  String? resetTooltip,
  bool showRoles = false,
  List<Map<String, dynamic>>? artistRoles,
  Function(String)? onEditRoles,
  List<String>? selectedArtistIds,
  Function(List<String>)? onArtistIdsUpdated,
  FocusNode? focusNode, // Additive: persistent FocusNode support
}) {
  String formatArtistsText(List<String> artists) {
    if (artists.isEmpty) return '';
    if (artists.length == 1) return artists[0];

    final lastArtist = artists.last;
    final otherArtists = artists.sublist(0, artists.length - 1);
    return '${otherArtists.join(", ")} & $lastArtist';
  }

  void showArtistSelectorDialog() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext dialogContext) {
          return FractionallySizedBox(
            heightFactor: 0.95,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                color: const Color(0xFF1E1B2C),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future:
                      collection == 'songwriters'
                          ? api.fetchAllSongwritersWithIds()
                          : api.fetchAllArtistsWithIds(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LoadingIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Failed to load $collection: \\${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    } else {
                      List<Map<String, dynamic>> artistsData =
                          snapshot.data ?? [];
                      List<String> availableArtists =
                          artistsData
                              .map((artist) => artist['name'] as String)
                              .toList();

                      return SafeArea(
                        child: _ArtistSelectorDialog(
                          artistsData: artistsData,
                          availableArtists: availableArtists,
                          initialSelectedArtists: selectedArtists,
                          initialSelectedArtistIds: selectedArtistIds ?? [],
                          collection: collection,
                          showResetButton: showResetButton,
                          onReset: onReset,
                          resetTooltip: resetTooltip,
                          showRoles: showRoles,
                          artistRoles: artistRoles,
                          onEditRoles: onEditRoles,
                          isMobile: true,
                          onSave: (names, ids) {
                            onArtistsReordered(names);
                            if (onArtistIdsUpdated != null) {
                              onArtistIdsUpdated(ids);
                            }
                            Navigator.pop(dialogContext);
                          },
                          onCancel: () {
                            Navigator.pop(dialogContext);
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future:
                collection == 'songwriters'
                    ? api.fetchAllSongwritersWithIds()
                    : api.fetchAllArtistsWithIds(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: LoadingIndicator());
              } else if (snapshot.hasError) {
                return AlertDialog(
                  title: const Text('Error'),
                  content: Text(
                    'Failed to load $collection: \\${snapshot.error}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('OK'),
                    ),
                  ],
                );
              } else {
                List<Map<String, dynamic>> artistsData = snapshot.data ?? [];
                List<String> availableArtists =
                    artistsData
                        .map((artist) => artist['name'] as String)
                        .toList();

                return _ArtistSelectorDialog(
                  artistsData: artistsData,
                  availableArtists: availableArtists,
                  initialSelectedArtists: selectedArtists,
                  initialSelectedArtistIds: selectedArtistIds ?? [],
                  collection: collection,
                  showResetButton: showResetButton,
                  onReset: onReset,
                  resetTooltip: resetTooltip,
                  showRoles: showRoles,
                  artistRoles: artistRoles,
                  onEditRoles: onEditRoles,
                  isMobile: false,
                  onSave: (names, ids) {
                    onArtistsReordered(names);
                    if (onArtistIdsUpdated != null) {
                      onArtistIdsUpdated(ids);
                    }
                    Navigator.pop(dialogContext);
                  },
                  onCancel: () {
                    Navigator.pop(dialogContext);
                  },
                );
              }
            },
          );
        },
      );
    }
  }

  return InkWell(
    onTap: showArtistSelectorDialog,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon,
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
      isEmpty: selectedArtists.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedArtists.isEmpty ? '' : formatArtistsText(selectedArtists),
            style: const TextStyle(color: Colors.white),
          ),
          if (showRoles && artistRoles != null && selectedArtists.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    selectedArtists.map((artist) {
                      final artistRole = artistRoles.firstWhere(
                        (role) => role['name'] == artist,
                        orElse: () => <String, dynamic>{},
                      );
                      return artistRole.isNotEmpty
                          ? Chip(
                            label: Text(
                              (artistRole['roles'] as List).join(', '),
                            ),
                          )
                          : const SizedBox.shrink();
                    }).toList(),
              ),
            ),
        ],
      ),
    ),
  );
}

// Create a separate StatefulWidget for the artist selector dialog
class _ArtistSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> artistsData;
  final List<String> availableArtists;
  final List<String> initialSelectedArtists;
  final List<String> initialSelectedArtistIds;
  final String collection;
  final bool showResetButton;
  final VoidCallback? onReset;
  final String? resetTooltip;
  final bool showRoles;
  final List<Map<String, dynamic>>? artistRoles;
  final Function(String)? onEditRoles;
  final Function(List<String>, List<String>) onSave;
  final VoidCallback onCancel;
  final bool isMobile;

  const _ArtistSelectorDialog({
    required this.artistsData,
    required this.availableArtists,
    required this.initialSelectedArtists,
    required this.initialSelectedArtistIds,
    required this.collection,
    required this.showResetButton,
    this.onReset,
    this.resetTooltip,
    required this.showRoles,
    this.artistRoles,
    this.onEditRoles,
    required this.onSave,
    required this.onCancel,
    required this.isMobile,
  });

  @override
  State<_ArtistSelectorDialog> createState() => _ArtistSelectorDialogState();
}

class _ArtistSelectorDialogState extends State<_ArtistSelectorDialog> {
  late List<String> selectedArtists;
  late List<String> selectedArtistIds;
  late List<String> filteredArtists;
  Timer? _artistDebounceTimer;

  void debounceArtistUpdate(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _artistDebounceTimer?.cancel();
    _artistDebounceTimer = Timer(duration, callback);
  }

  @override
  void dispose() {
    _artistDebounceTimer?.cancel();
    super.dispose();
  }

  void addArtist(String artistName) {
    debugPrint('Adding artist: $artistName');
    if (artistName.isEmpty || selectedArtists.contains(artistName)) {
      return;
    }

    // Find the artist ID
    String? artistId;
    for (var artist in widget.artistsData) {
      if (artist['name'] == artistName) {
        artistId = artist['id'];
        break;
      }
    }
    debounceArtistUpdate(() {
      if (!mounted) return;
      setState(() {
        debugPrint('UPDATING STATE: Adding $artistName to selected artists');
        selectedArtists.add(artistName);
        selectedArtistIds.add(artistId ?? '');
        debugPrint('SELECTED ARTISTS NOW: $selectedArtists');
      });
    });
  }

  void removeArtist(int index) {
    if (index < 0 || index >= selectedArtists.length) return;
    debounceArtistUpdate(() {
      if (!mounted) return;
      setState(() {
        selectedArtists.removeAt(index);
        if (index < selectedArtistIds.length) {
          selectedArtistIds.removeAt(index);
        }
      });
    });
  }

  void filterArtists(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredArtists = List.from(widget.availableArtists);
      } else {
        filteredArtists =
            widget.availableArtists
                .where(
                  (name) => name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    selectedArtists = List.from(widget.initialSelectedArtists);
    selectedArtistIds = List.from(widget.initialSelectedArtistIds);
    filteredArtists = List.from(widget.availableArtists);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Artists',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search artists...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.black12,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: filterArtists,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  // Selected Artists List
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Selected Artists',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.showResetButton && selectedArtists.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton.icon(
                              onPressed: widget.onReset,
                              icon: const Icon(
                                Icons.restore,
                                color: Colors.blue,
                              ),
                              label: Text(
                                widget.resetTooltip ?? 'Reset to Default',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                        Expanded(
                          child: ReorderableListView(
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final artist = selectedArtists.removeAt(
                                  oldIndex,
                                );
                                selectedArtists.insert(newIndex, artist);

                                // Also reorder IDs if available
                                if (oldIndex < selectedArtistIds.length) {
                                  final id = selectedArtistIds.removeAt(
                                    oldIndex,
                                  );
                                  if (newIndex < selectedArtistIds.length) {
                                    selectedArtistIds.insert(newIndex, id);
                                  } else {
                                    selectedArtistIds.add(id);
                                  }
                                }
                              });
                            },
                            children:
                                selectedArtists.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final artist = entry.value;
                                  final artistRole =
                                      widget.showRoles &&
                                              widget.artistRoles != null
                                          ? widget.artistRoles!.firstWhere(
                                            (role) => role['name'] == artist,
                                            orElse: () => <String, dynamic>{},
                                          )
                                          : null;

                                  return ListTile(
                                    key: ValueKey('selected-$artist-$index'),
                                    leading: FutureBuilder<String?>(
                                      future: _getArtistProfileImage(artist),
                                      builder: (context, snapshot) {
                                        return CircleAvatar(
                                          radius: 16,
                                          backgroundImage:
                                              snapshot.data != null
                                                  ? NetworkImage(snapshot.data!)
                                                  : null,
                                          backgroundColor: Colors.grey[800],
                                          child:
                                              snapshot.data == null
                                                  ? const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 20,
                                                  )
                                                  : null,
                                        );
                                      },
                                    ),
                                    title: Text(
                                      artist,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle:
                                        artistRole != null &&
                                                (artistRole['roles'] as List)
                                                    .isNotEmpty
                                            ? Text(
                                              (artistRole['roles'] as List)
                                                  .join(', '),
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            )
                                            : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (widget.showRoles &&
                                            widget.onEditRoles != null)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed:
                                                () =>
                                                    widget.onEditRoles!(artist),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => removeArtist(index),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(color: Colors.grey),
                  // Available Artists List
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Available Artists',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount:
                                filteredArtists.length +
                                1, // +1 for "New Artist" button
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // New Artist Button
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey[800],
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    'New ${widget.collection == 'songwriters' ? 'Songwriter' : 'Artist'}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onTap: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) =>
                                              widget.collection == 'songwriters'
                                                  ? const NewSongwriterForm()
                                                  : const NewArtistForm(),
                                    );

                                    if (result == true) {
                                      // Refresh artists list - we'd normally do this by updating the whole dialog,
                                      // but for simplicity we'll just close the dialog and let the user reopen it
                                      widget.onCancel();
                                    }
                                  },
                                );
                              }

                              final artist = filteredArtists[index - 1];
                              if (selectedArtists.contains(artist)) {
                                return const SizedBox.shrink(); // Skip already selected artists
                              }

                              return ListTile(
                                leading: FutureBuilder<String?>(
                                  future: _getArtistProfileImage(artist),
                                  builder: (context, snapshot) {
                                    return CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          snapshot.data != null
                                              ? NetworkImage(snapshot.data!)
                                              : null,
                                      backgroundColor: Colors.grey[800],
                                      child:
                                          snapshot.data == null
                                              ? const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 20,
                                              )
                                              : null,
                                    );
                                  },
                                ),
                                title: Text(
                                  artist,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    debugPrint(
                                      'ADD BUTTON PRESSED FOR: $artist',
                                    );
                                    addArtist(artist);
                                  },
                                ),
                                onTap: () {
                                  debugPrint('TILE TAPPED FOR: $artist');
                                  addArtist(artist);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E1B2C),
        title: Text(
          'Select ${widget.collection.substring(0, 1).toUpperCase() + widget.collection.substring(1)}',
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search artists...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.black12,
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: filterArtists,
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Selected Artists List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Selected Artists',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (widget.showResetButton && selectedArtists.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton.icon(
                                onPressed: widget.onReset,
                                icon: const Icon(
                                  Icons.restore,
                                  color: Colors.blue,
                                ),
                                label: Text(
                                  widget.resetTooltip ?? 'Reset to Default',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                          Expanded(
                            child: ReorderableListView(
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final artist = selectedArtists.removeAt(
                                    oldIndex,
                                  );
                                  selectedArtists.insert(newIndex, artist);

                                  // Also reorder IDs if available
                                  if (oldIndex < selectedArtistIds.length) {
                                    final id = selectedArtistIds.removeAt(
                                      oldIndex,
                                    );
                                    if (newIndex < selectedArtistIds.length) {
                                      selectedArtistIds.insert(newIndex, id);
                                    } else {
                                      selectedArtistIds.add(id);
                                    }
                                  }
                                });
                              },
                              children:
                                  selectedArtists.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final artist = entry.value;
                                    final artistRole =
                                        widget.showRoles &&
                                                widget.artistRoles != null
                                            ? widget.artistRoles!.firstWhere(
                                              (role) => role['name'] == artist,
                                              orElse: () => <String, dynamic>{},
                                            )
                                            : null;

                                    return ListTile(
                                      key: ValueKey('selected-$artist-$index'),
                                      leading: FutureBuilder<String?>(
                                        future: _getArtistProfileImage(artist),
                                        builder: (context, snapshot) {
                                          return CircleAvatar(
                                            radius: 16,
                                            backgroundImage:
                                                snapshot.data != null
                                                    ? NetworkImage(
                                                      snapshot.data!,
                                                    )
                                                    : null,
                                            backgroundColor: Colors.grey[800],
                                            child:
                                                snapshot.data == null
                                                    ? const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 20,
                                                    )
                                                    : null,
                                          );
                                        },
                                      ),
                                      title: Text(
                                        artist,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle:
                                          artistRole != null &&
                                                  (artistRole['roles'] as List)
                                                      .isNotEmpty
                                              ? Text(
                                                (artistRole['roles'] as List)
                                                    .join(', '),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              )
                                              : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (widget.showRoles &&
                                              widget.onEditRoles != null)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blue,
                                              ),
                                              onPressed:
                                                  () => widget.onEditRoles!(
                                                    artist,
                                                  ),
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                () => removeArtist(index),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(color: Colors.grey),
                    // Available Artists List
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Available Artists',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount:
                                  filteredArtists.length +
                                  1, // +1 for "New Artist" button
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  // New Artist Button
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey[800],
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      'New ${widget.collection == 'songwriters' ? 'Songwriter' : 'Artist'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () async {
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) =>
                                                widget.collection ==
                                                        'songwriters'
                                                    ? const NewSongwriterForm()
                                                    : const NewArtistForm(),
                                      );

                                      if (result == true) {
                                        // Refresh artists list - we'd normally do this by updating the whole dialog,
                                        // but for simplicity we'll just close the dialog and let the user reopen it
                                        widget.onCancel();
                                      }
                                    },
                                  );
                                }

                                final artist = filteredArtists[index - 1];
                                if (selectedArtists.contains(artist)) {
                                  return const SizedBox.shrink(); // Skip already selected artists
                                }

                                return ListTile(
                                  leading: FutureBuilder<String?>(
                                    future: _getArtistProfileImage(artist),
                                    builder: (context, snapshot) {
                                      return CircleAvatar(
                                        radius: 16,
                                        backgroundImage:
                                            snapshot.data != null
                                                ? NetworkImage(snapshot.data!)
                                                : null,
                                        backgroundColor: Colors.grey[800],
                                        child:
                                            snapshot.data == null
                                                ? const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 20,
                                                )
                                                : null,
                                      );
                                    },
                                  ),
                                  title: Text(
                                    artist,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      debugPrint(
                                        'ADD BUTTON PRESSED FOR: $artist',
                                      );
                                      addArtist(artist);
                                    },
                                  ),
                                  onTap: () {
                                    debugPrint('TILE TAPPED FOR: $artist');
                                    addArtist(artist);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('SAVING ARTIST SELECTIONS: $selectedArtists');
              debugPrint('SAVING ARTIST IDs: $selectedArtistIds');
              widget.onSave(selectedArtists, selectedArtistIds);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A4FBF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      );
    }
  }
}

// Helper function to get artist profile image
Future<String?> _getArtistProfileImage(String artistName) async {
  // Implement this to fetch the artist's profile image URL from your backend
  // Return null if no image is available
  try {
    final imageUrl = await api.getArtistProfileImage(artistName);
    return imageUrl;
  } catch (e) {
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Services/api_service.dart';

class RoleBasedArtistSelector extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> selectedArtistsWithRoles;
  final Function(List<Map<String, dynamic>>) onChanged;
  final String collection;
  final List<String> availableRoles;

  const RoleBasedArtistSelector({
    required this.label,
    required this.selectedArtistsWithRoles,
    required this.onChanged,
    required this.collection,
    required this.availableRoles,
    super.key,
  });

  @override
  State<RoleBasedArtistSelector> createState() =>
      _RoleBasedArtistSelectorState();
}

class _RoleBasedArtistSelectorState extends State<RoleBasedArtistSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchArtists(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ApiService().searchInCollection(
        widget.collection,
        query,
      );
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
    }
  }

  void _showRoleSelectionDialog(String artist) {
    Set<String> selectedRoles = {};

    // Get existing roles if artist already exists
    final existingArtist = widget.selectedArtistsWithRoles.firstWhere(
      (a) => a['name'] == artist,
      orElse: () => <String, dynamic>{'roles': []},
    );
    if (existingArtist.isNotEmpty) {
      selectedRoles = Set.from(existingArtist['roles'] as List);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B2C),
              title: Text(
                'Select Roles for $artist',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search roles...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF2A2639),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.availableRoles.length,
                        itemBuilder: (context, index) {
                          final role = widget.availableRoles[index];
                          return CheckboxListTile(
                            title: Text(
                              role,
                              style: const TextStyle(color: Colors.white),
                            ),
                            value: selectedRoles.contains(role),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedRoles.add(role);
                                } else {
                                  selectedRoles.remove(role);
                                }
                              });
                            },
                            activeColor: Colors.blue,
                            checkColor: Colors.white,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      selectedRoles.isEmpty
                          ? null
                          : () {
                            final updatedList = List<Map<String, dynamic>>.from(
                              widget.selectedArtistsWithRoles,
                            );
                            final existingIndex = updatedList.indexWhere(
                              (a) => a['name'] == artist,
                            );

                            if (existingIndex != -1) {
                              updatedList[existingIndex] = {
                                'name': artist,
                                'roles': selectedRoles.toList(),
                              };
                            } else {
                              updatedList.add({
                                'name': artist,
                                'roles': selectedRoles.toList(),
                              });
                            }

                            widget.onChanged(updatedList);
                            Navigator.pop(context);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: fontNameSemiBold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search artists...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon:
                        _isSearching
                            ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2639),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    _searchArtists(value);
                  },
                ),
              ),
              // Suggestions list
              if (_suggestions.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final artist = _suggestions[index];
                      return ListTile(
                        title: Text(
                          artist,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          _showRoleSelectionDialog(artist);
                          setState(() {
                            _searchController.clear();
                            _suggestions = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              // Selected artists with roles
              if (widget.selectedArtistsWithRoles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children:
                        widget.selectedArtistsWithRoles.map((artist) {
                          return Card(
                            color: const Color(0xFF2A2639),
                            child: ListTile(
                              title: Text(
                                artist['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: fontNameSemiBold,
                                ),
                              ),
                              subtitle: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children:
                                    (artist['roles'] as List).map((role) {
                                      return Chip(
                                        label: Text(
                                          role,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue.withAlpha(
                                          77,
                                        ),
                                      );
                                    }).toList(),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _showRoleSelectionDialog(
                                          artist['name'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      final updatedList =
                                          List<Map<String, dynamic>>.from(
                                            widget.selectedArtistsWithRoles,
                                          )..removeWhere(
                                            (a) => a['name'] == artist['name'],
                                          );
                                      widget.onChanged(updatedList);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

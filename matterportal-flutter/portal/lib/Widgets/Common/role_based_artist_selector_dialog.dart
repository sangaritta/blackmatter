import 'package:flutter/material.dart';
import 'package:portal/Services/api_service.dart';

class RoleBasedArtistSelectorDialog extends StatefulWidget {
  final String collection;
  final List<Map<String, dynamic>> initialSelections;
  final List<String> availableRoles;
  final IconData roleIcon;

  const RoleBasedArtistSelectorDialog({
    required this.collection,
    required this.initialSelections,
    required this.availableRoles,
    required this.roleIcon,
    super.key,
  });

  @override
  State<RoleBasedArtistSelectorDialog> createState() =>
      _RoleBasedArtistSelectorDialogState();
}

class _RoleBasedArtistSelectorDialogState
    extends State<RoleBasedArtistSelectorDialog> {
  List<Map<String, dynamic>> _selectedArtists = [];
  String _searchQuery = '';
  List<String> _filteredArtists = [];
  bool _isLoading = true;
  final String _roleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedArtists = List.from(widget.initialSelections);
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);
    try {
      if (widget.collection == 'songwriters') {
        _filteredArtists = await api.fetchAllSongwriters();
      } else {
        _filteredArtists = await api.fetchAllArtists();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterArtists(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _loadArtists();
      } else {
        _filteredArtists = _filteredArtists
            .where(
                (artist) => artist.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _showRoleSelectionDialog(String artist) async {
    final existingRoles = _selectedArtists.firstWhere(
      (a) => a['name'] == artist,
      orElse: () => {'roles': <String>[]},
    )['roles'] as List<String>;

    final selectedRoles = await showDialog<Set<String>>(
      context: context,
      builder: (context) => Dialog(
        child: RoleSelectionContent(
          artist: artist,
          existingRoles: existingRoles,
          availableRoles: widget.availableRoles,
        ),
      ),
    );

    if (selectedRoles != null) {
      setState(() {
        _selectedArtists.removeWhere((a) => a['name'] == artist);
        if (selectedRoles.isNotEmpty) {
          _selectedArtists.add({
            'name': artist,
            'roles': List<String>.from(selectedRoles),
            'icon': widget.roleIcon,
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText:
                    'Search ${widget.collection == 'songwriters' ? 'songwriters' : 'artists'}...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF151521),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _filterArtists,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSelectedArtistsList(),
                  ),
                  const VerticalDivider(color: Colors.grey),
                  Expanded(
                    child: _buildAvailableArtistsList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedArtists),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child:
                      const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedArtistsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selected Artists',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _selectedArtists.length,
            itemBuilder: (context, index) {
              final artist = _selectedArtists[index];
              return ListTile(
                leading: FutureBuilder<String?>(
                  future: api.getArtistProfileImage(artist['name']),
                  builder: (context, snapshot) => CircleAvatar(
                    backgroundImage: snapshot.data != null
                        ? NetworkImage(snapshot.data!)
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: snapshot.data == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
                title: Text(artist['name'],
                    style: const TextStyle(color: Colors.grey)),
                subtitle: Wrap(
                  spacing: 4,
                  children: (artist['roles'] as List<String>)
                      .map((role) => Chip(
                            label: Text(role,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            backgroundColor: Colors.blue.withOpacity(0.3),
                          ))
                      .toList(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      setState(() => _selectedArtists.removeAt(index)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableArtistsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Artists',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _filteredArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _filteredArtists[index];
                    return ListTile(
                      leading: FutureBuilder<String?>(
                        future: api.getArtistProfileImage(artist),
                        builder: (context, snapshot) => CircleAvatar(
                          backgroundImage: snapshot.data != null
                              ? NetworkImage(snapshot.data!)
                              : null,
                          backgroundColor: Colors.grey[800],
                          child: snapshot.data == null
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                      ),
                      title: Text(artist,
                          style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () => _showRoleSelectionDialog(artist),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class RoleSelectionContent extends StatefulWidget {
  final String artist;
  final List<String> existingRoles;
  final List<String> availableRoles;

  const RoleSelectionContent({
    super.key,
    required this.artist,
    required this.existingRoles,
    required this.availableRoles,
  });

  @override
  State<RoleSelectionContent> createState() => _RoleSelectionContentState();
}

class _RoleSelectionContentState extends State<RoleSelectionContent> {
  late Set<String> tempSelected;
  String _roleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    tempSelected = Set.from(widget.existingRoles);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1B2C),
      insetPadding: EdgeInsets.zero,
      title: Text(
        'Select Roles for ${widget.artist}',
        style: const TextStyle(color: Colors.grey),
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
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF2A2639),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) =>
                  setState(() => _roleSearchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableRoles
                    .where(
                        (role) => role.toLowerCase().contains(_roleSearchQuery))
                    .length,
                itemBuilder: (context, index) {
                  final filteredRoles = widget.availableRoles
                      .where((r) => r.toLowerCase().contains(_roleSearchQuery))
                      .toList();
                  final role = filteredRoles[index];
                  final iconList = [
                    Icons.music_note,
                    Icons.mic,
                    Icons.audiotrack,
                    Icons.library_music,
                    Icons.album,
                    Icons.queue_music,
                    Icons.headset,
                    Icons.surround_sound,
                    Icons.volume_up,
                    Icons.person,
                  ];
                  final icon = iconList[index % iconList.length];
                  return CheckboxListTile(
                    secondary: Icon(icon, color: Colors.blueGrey[200]),
                    title: Text(
                      role,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    value: tempSelected.contains(role),
                    onChanged: (value) => setState(() {
                      value!
                          ? tempSelected.add(role)
                          : tempSelected.remove(role);
                    }),
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
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, tempSelected),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

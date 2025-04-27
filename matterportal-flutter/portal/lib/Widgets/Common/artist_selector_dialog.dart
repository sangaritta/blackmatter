import 'package:flutter/material.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Screens/Home/Forms/new_artist_form.dart';

class ArtistSelectorDialog extends StatefulWidget {
  final String collection;

  const ArtistSelectorDialog({
    required this.collection,
    super.key,
  });

  @override
  State<ArtistSelectorDialog> createState() => _ArtistSelectorDialogState();
}

class _ArtistSelectorDialogState extends State<ArtistSelectorDialog> {
  String searchQuery = '';
  List<String> filteredArtists = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() => isLoading = true);
    try {
      if (widget.collection == 'songwriters') {
        filteredArtists = await api.fetchAllSongwriters();
      } else {
        filteredArtists = await api.fetchAllArtists();
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterArtists(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        _loadArtists();
      } else {
        filteredArtists = filteredArtists
            .where(
                (artist) => artist.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _showAddNewForm() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return widget.collection == 'songwriters'
            ? const NewSongwriterForm()
            : const NewArtistForm();
      },
    );

    if (result == true) {
      await _loadArtists();
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
                hintText: 'Search artists...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF151521),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: _filterArtists,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Artists Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Artists',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Selected artists list would go here
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Unselected Artists Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unselected Artists',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          children: [
                            // New Artist Button
                            ListTile(
                              onTap: _showAddNewForm,
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                child: const Icon(Icons.add, color: Colors.white),
                              ),
                              title: const Text(
                                'New Artist',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const Divider(color: Colors.grey),
                            // Artist List
                            SizedBox(
                              height: 300,
                              child: ListView.builder(
                                itemCount: filteredArtists.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: FutureBuilder<String?>(
                                      future: api.getArtistProfileImage(filteredArtists[index]),
                                      builder: (context, snapshot) {
                                        return CircleAvatar(
                                          radius: 20,
                                          backgroundImage: snapshot.data != null ?
                                            NetworkImage(snapshot.data!) :
                                            const AssetImage('assets/images/placeholder.png') as ImageProvider,
                                        );
                                      },
                                    ),
                                    title: Text(
                                      filteredArtists[index],
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                      onPressed: () {
                                        Navigator.of(context).pop(filteredArtists[index]);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

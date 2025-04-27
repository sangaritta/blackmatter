import 'package:flutter/material.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Services/spotify_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portal/Services/song_import_service.dart';
import 'package:portal/Services/api_service.dart'; // Add this import

class ImportReleasesScreen extends StatefulWidget {
  const ImportReleasesScreen({super.key});

  @override
  State<ImportReleasesScreen> createState() => _ImportReleasesScreenState();
}

class _ImportReleasesScreenState extends State<ImportReleasesScreen> {
  final SpotifyService _spotifyService = SpotifyService();
  final SongImportService _importService = SongImportService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  List<dynamic> _artists = [];
  List<dynamic> _albums = [];
  List<dynamic> _filteredAlbums = []; // Add filtered albums list
  dynamic _selectedArtist;
  List<dynamic> _selectedAlbums = [];
  bool _isSearching = false;
  bool _isLoadingAlbums = false;
  bool _isImporting = false;
  bool _isFilteringAlbums = false; // Add flag for filtering state
  String _errorMessage = '';
  bool _isUrlSearch = false;
  ThemeMode _themeMode = ThemeMode.dark; // Default to dark mode

  // Progress tracking variables
  int _importedCount = 0;
  int _totalToImport = 0;
  String _currentImportName = '';
  int _filteredOutCount = 0; // Track how many albums were filtered out

  @override
  void initState() {
    super.initState();
    _setDarkMode();
  }

  void _setDarkMode() {
    setState(() {
      _themeMode = ThemeMode.dark;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _searchArtist() async {
    final String query =
        _isUrlSearch ? _urlController.text : _searchController.text;
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _artists = [];
      _albums = [];
      _selectedArtist = null;
      _selectedAlbums = [];
    });

    try {
      if (_isUrlSearch) {
        // Extract artist ID from Spotify URL
        // Format: https://open.spotify.com/artist/[artist_id]?si=[...]
        final Uri uri = Uri.parse(query);
        if (uri.host != 'open.spotify.com' ||
            !uri.pathSegments.contains('artist')) {
          throw Exception('Invalid Spotify artist URL');
        }

        final String artistId = uri.pathSegments.last;
        // Load artist details directly
        final Map<String, dynamic> artistDetails =
            await _spotifyService.getArtistById(artistId);

        setState(() {
          _artists = [artistDetails]; // Just one artist in the list
          _isSearching = false;
        });
      } else {
        // Regular search by name
        final result =
            await _spotifyService.searchArtist(_searchController.text);
        setState(() {
          _artists = result['artists']['items'];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching for artist: $e';
      });
    }
  }

  Future<void> _loadArtistAlbums(dynamic artist) async {
    setState(() {
      _isLoadingAlbums = true;
      _errorMessage = '';
      _albums = [];
      _filteredAlbums = [];
      _selectedArtist = artist;
      _selectedAlbums = [];
      _filteredOutCount = 0;
    });

    try {
      final result = await _spotifyService.getArtistAlbums(artist['id']);

      // Fetch all album details to get UPCs
      setState(() {
        _isFilteringAlbums = true;
      });

      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final allAlbums = result['items'] as List;
      _albums = allAlbums;

      // Filter out albums that are already imported
      List<dynamic> filteredAlbums = [];

      for (var album in allAlbums) {
        try {
          // Get full album details to access UPC
          final albumDetails =
              await _spotifyService.getAlbumDetails(album['id']);
          final upc = albumDetails['external_ids']?['upc'] ?? '';

          // Check if this UPC exists in the user's catalog
          // Usage of checkProductExistsByUPC should use named parameters for indexKey/indexValue
          // Example: await api.checkProductExistsByUPC(upc, indexKey: 'projectId', indexValue: someProjectId);
          final exists = await api.checkProductExistsByUPC(upc);

          if (!exists) {
            // Only add albums that don't already exist
            filteredAlbums.add(album);
          } else {
            _filteredOutCount++;
          }
        } catch (e) {
          // If we can't get details, include the album anyway
          filteredAlbums.add(album);
        }
      }

      setState(() {
        _filteredAlbums = filteredAlbums;
        _isLoadingAlbums = false;
        _isFilteringAlbums = false;
      });

      // Show a message if albums were filtered out
      if (_filteredOutCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '$_filteredOutCount album(s) already imported were hidden'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingAlbums = false;
        _isFilteringAlbums = false;
        _errorMessage = 'Error loading albums: $e';
      });
    }
  }

  void _toggleAlbumSelection(dynamic album) {
    setState(() {
      if (_selectedAlbums.any((a) => a['id'] == album['id'])) {
        _selectedAlbums.removeWhere((a) => a['id'] == album['id']);
      } else {
        _selectedAlbums.add(album);
      }
    });
  }

  void _selectAllAlbums() {
    setState(() {
      if (_selectedAlbums.length == _filteredAlbums.length) {
        // If all are selected, deselect all
        _selectedAlbums = [];
      } else {
        // Otherwise select all (from filtered albums)
        _selectedAlbums = List.from(_filteredAlbums);
      }
    });
  }

  Future<void> _importSelectedAlbums() async {
    if (_selectedAlbums.isEmpty) return;

    setState(() {
      _isImporting = true;
      _errorMessage = '';
      _importedCount = 0;
      _totalToImport = _selectedAlbums.length;
      _currentImportName = '';
    });

    try {
      // Get current user
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Use the song import service to handle the import process
      List<Project> projects = await _importService.importSpotifyAlbums(
        selectedAlbums: _selectedAlbums,
        userId: user.uid,
        onProgress: (message, current, total) {
          setState(() {
            _currentImportName = message;
            _importedCount = current;
            _totalToImport = total;
          });
        },
      );

      // Show success message and close the screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully imported ${projects.length} projects with ${_selectedAlbums.length} releases'),
        ),
      );

      // Return with success flag to trigger refresh of product list
      Navigator.pop(context, true);
    } catch (e) {
      String errorDetails = e.toString();

      // Check for Firestore permission errors
      if (errorDetails.contains('permission-denied')) {
        errorDetails =
            'Firestore permission denied. Please check the collection paths in Firestore Rules.\n\n'
            'Required paths: catalog/{userId}/projects/{projectId}/products/{productId}/tracks/{trackId}';
      } else if (errorDetails.contains('dropdown')) {
        // Catch dropdown-related errors which might be due to missing metadata
        errorDetails =
            'Error with form fields. Please check that all imported music has proper genre and metadata information.';
      }

      setState(() {
        _isImporting = false;
        _errorMessage = 'Error importing releases: $errorDetails';
      });

      // Show error in a more prominent way
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${errorDetails.split(':').last}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Import Releases from Spotify'),
              actions: [
                if (_selectedAlbums.isNotEmpty && !_isImporting)
                  TextButton.icon(
                    onPressed: _importSelectedAlbums,
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: Text(
                      'Import ${_selectedAlbums.length} Release${_selectedAlbums.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                if (_selectedArtist == null) _buildSearchOptions(),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: _selectedArtist == null
                      ? _buildArtistsList()
                      : _buildAlbumsList(),
                ),
              ],
            ),
          ),

          // Show import progress overlay when importing
          if (_isImporting) _buildImportProgressOverlay(),
        ],
      ),
    );
  }

  Widget _buildImportProgressOverlay() {
    // Calculate progress percentage
    double progress =
        _totalToImport > 0 ? _importedCount / _totalToImport : 0.0;
    final int percentage = (progress * 100).round();

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_download,
                  size: 48,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Importing Releases ($percentage%)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentImportName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchOptions() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle between search modes
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isUrlSearch = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isUrlSearch
                          ? Colors.deepPurple
                          : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                    child: const Text('Search by Name'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isUrlSearch = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUrlSearch
                          ? Colors.deepPurple
                          : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    child: const Text('Enter URL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search input
            if (!_isUrlSearch)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search for an artist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Enter artist name',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onSubmitted: (_) => _searchArtist(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchArtist,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Search'),
                      ),
                    ],
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Artist Spotify URL',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: 'https://open.spotify.com/artist/...',
                            prefixIcon: Icon(Icons.link),
                          ),
                          onSubmitted: (_) => _searchArtist(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchArtist,
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Load'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Example: https://open.spotify.com/artist/0EmeFodog0BfCgMzAIvKQp',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistsList() {
    if (_artists.isEmpty) {
      return const Center(
        child: Text('Search for an artist to see results'),
      );
    }

    return ListView.builder(
      itemCount: _artists.length,
      itemBuilder: (context, index) {
        final artist = _artists[index];
        final artistName = artist['name'] ?? 'Unknown Artist';
        final artistImage = artist['images']?.isNotEmpty == true
            ? artist['images'][0]['url']
            : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: artistImage != null
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(artistImage),
                  )
                : const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
            title: Text(
              artistName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${artist['followers']['total']} followers',
              style: const TextStyle(color: Colors.grey),
            ),
            onTap: () => _loadArtistAlbums(artist),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsList() {
    if (_isLoadingAlbums) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isFilteringAlbums) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Filtering ${_albums.length} albums...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_filteredAlbums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filteredOutCount > 0 ? Icons.check_circle : Icons.album_outlined,
              size: 64,
              color: _filteredOutCount > 0 ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _filteredOutCount > 0
                  ? 'All ${_albums.length} albums have already been imported'
                  : 'No albums found for this artist',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedArtist = null;
                });
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: _selectedArtist['images']?.isNotEmpty == true
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        NetworkImage(_selectedArtist['images'][0]['url']),
                  )
                : const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
            title: Text(
              _selectedArtist['name'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_filteredOutCount > 0)
                  Chip(
                    label: Text('$_filteredOutCount hidden'),
                    backgroundColor: Colors.deepPurple.withOpacity(0.2),
                    avatar: const Icon(Icons.filter_alt, size: 16),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: Icon(
                    _selectedAlbums.length == _filteredAlbums.length
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 18,
                  ),
                  label: Text(
                    _selectedAlbums.length == _filteredAlbums.length
                        ? 'Deselect All'
                        : 'Select All',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                  ),
                  onPressed: _selectAllAlbums,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  onPressed: () {
                    setState(() {
                      _selectedArtist = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            // Calculate number of items per row based on screen width
            final double itemWidth = 160; // Target width for each item
            final int crossAxisCount =
                (constraints.maxWidth / itemWidth).floor().clamp(2, 6);

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.9, // More square appearance
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredAlbums.length, // Use filtered albums
              itemBuilder: (context, index) {
                final album = _filteredAlbums[index]; // Use filtered albums
                final albumName = album['name'] ?? 'Unknown Album';
                final albumImage = album['images']?.isNotEmpty == true
                    ? album['images'][0]['url']
                    : null;
                final releaseDate = album['release_date'] ?? '';
                final isSelected =
                    _selectedAlbums.any((a) => a['id'] == album['id']);

                return GestureDetector(
                  onTap: () => _toggleAlbumSelection(album),
                  child: Card(
                    elevation: isSelected ? 8 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? const BorderSide(color: Colors.deepPurple, width: 2)
                          : BorderSide.none,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  image: albumImage != null
                                      ? DecorationImage(
                                          image: NetworkImage(albumImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: albumImage == null
                                    ? const Center(
                                        child: Icon(
                                          Icons.album,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      )
                                    : null,
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                albumName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${album['album_type']?.toUpperCase() ?? 'ALBUM'} • $releaseDate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

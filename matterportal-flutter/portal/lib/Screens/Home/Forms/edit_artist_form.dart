import 'package:flutter/material.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/music_verification_service.dart';

// Platform to asset image mapping for DSP icons
const Map<String, String> platformAssetMap = {
  'Spotify': 'assets/images/dsps/spotify.png',
  'Apple Music': 'assets/images/dsps/Apple Music.png',
  'YouTube': 'assets/images/dsps/youtube.png',
  'Instagram': 'assets/images/dsps/instagram.png',
  'Facebook': 'assets/images/dsps/Facebook.png',
  'X': 'assets/images/dsps/x.png',
  'TikTok': 'assets/images/dsps/tiktok.png',
  'Soundcloud': 'assets/images/dsps/soundcloud.png',
  // Add more as needed, matching filenames in assets/images/dsps/
};

class EditArtistForm extends StatefulWidget {
  final Map<String, dynamic> artistData;

  const EditArtistForm({super.key, required this.artistData});

  @override
  EditArtistFormState createState() => EditArtistFormState();
}

class EditArtistFormState extends State<EditArtistForm> {
  final _formKey = GlobalKey<FormState>();
  String? _previewImageUrl;
  late Map<String, TextEditingController> _controllers;
  late Map<String, bool> _isEnabled;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _previewImageUrl = widget.artistData['imageUrl'];
    _controllers = {
      'name': TextEditingController(text: widget.artistData['name'] ?? ''),
      'spotifyUrl':
          TextEditingController(text: widget.artistData['spotifyUrl'] ?? ''),
      'appleMusicUrl':
          TextEditingController(text: widget.artistData['appleMusicUrl'] ?? ''),
      'youtubeUrl':
          TextEditingController(text: widget.artistData['youtubeUrl'] ?? ''),
      'instagramURL':
          TextEditingController(text: widget.artistData['instagramURL'] ?? ''),
      'facebookUrl':
          TextEditingController(text: widget.artistData['facebookUrl'] ?? ''),
      'xUrl': TextEditingController(text: widget.artistData['xUrl'] ?? ''),
      'tiktokUrl':
          TextEditingController(text: widget.artistData['tiktokUrl'] ?? ''),
      'soundcloudUrl':
          TextEditingController(text: widget.artistData['soundcloudUrl'] ?? ''),
    };

    _isEnabled = {
      'spotifyUrl': (widget.artistData['spotifyUrl']?.isNotEmpty ?? false),
      'appleMusicUrl':
          (widget.artistData['appleMusicUrl']?.isNotEmpty ?? false),
      'youtubeUrl': (widget.artistData['youtubeUrl']?.isNotEmpty ?? false),
      'instagramURL': (widget.artistData['instagramURL']?.isNotEmpty ?? false),
      'facebookUrl': (widget.artistData['facebookUrl']?.isNotEmpty ?? false),
      'xUrl': (widget.artistData['xUrl']?.isNotEmpty ?? false),
      'tiktokUrl': (widget.artistData['tiktokUrl']?.isNotEmpty ?? false),
      'soundcloudUrl':
          (widget.artistData['soundcloudUrl']?.isNotEmpty ?? false),
    };

    // Add listeners to detect changes
    _controllers.forEach((key, controller) {
      controller.addListener(_onFormChanged);
    });

    // Fetch Spotify image if URL exists
    if (widget.artistData['spotifyUrl']?.isNotEmpty ?? false) {
      _fetchSpotifyImage(widget.artistData['spotifyUrl']);
    }
  }

  void _onFormChanged() {
    bool hasChanges = false;
    _controllers.forEach((key, controller) {
      if (controller.text != (widget.artistData[key] ?? '')) {
        hasChanges = true;
      }
    });
    
    _isEnabled.forEach((key, value) {
      if (value != (widget.artistData[key]?.isNotEmpty ?? false)) {
        hasChanges = true;
      }
    });

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _fetchSpotifyImage(String spotifyUrl) async {
    final imageUrl = await MusicVerificationService()
        .getSpotifyArtistImage(spotifyUrl);
    if (mounted) {
      setState(() {
        _previewImageUrl = imageUrl;
      });
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1B2C),
      title: const Text('Edit Artist', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400, // Fixed width
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Artist Image Preview
                Container(
                  width: 150,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ClipOval(
                    child: _previewImageUrl != null
                        ? FadeInImage.assetNetwork(
                            placeholder: 'assets/images/placeholder.png',
                            image: _previewImageUrl!,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                          )
                        : Image.asset(
                            'assets/images/placeholder.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                // Name field
                TextFormField(
                  controller: _controllers['name'],
                  decoration: const InputDecoration(
                    labelText: 'Artist Name',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                // Platform fields with same styling as NewArtistForm
                _buildPlatformField('Spotify', 'spotifyUrl'),
                _buildPlatformField('Apple Music', 'appleMusicUrl'),
                _buildPlatformField('YouTube', 'youtubeUrl'),
                _buildPlatformField('Instagram', 'instagramURL'),
                _buildPlatformField('Facebook', 'facebookUrl'),
                _buildPlatformField('X', 'xUrl'),
                _buildPlatformField('TikTok', 'tiktokUrl'),
                _buildPlatformField('Soundcloud', 'soundcloudUrl'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () async {
            if (!_hasChanges) {
              Navigator.of(context).pop();
              return;
            }
            
            if (_formKey.currentState!.validate()) {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                // First ensure we have a valid ID
                final artistId = widget.artistData['id'];
                if (artistId == null) {
                  throw Exception('Artist ID is missing');
                }

                Map<String, String> updatedArtistData = {
                  'name': _controllers['name']!.text,
                  'imageUrl': _previewImageUrl ?? '',
                };

                // Only add enabled fields
                final fields = [
                  'spotifyUrl', 'appleMusicUrl', 'youtubeUrl',
                  'instagramURL', 'facebookUrl', 'xUrl',
                  'tiktokUrl', 'soundcloudUrl',
                ];

                for (var field in fields) {
                  updatedArtistData[field] = _isEnabled[field] == true 
                    ? _controllers[field]!.text 
                    : '';
                }

                await ApiService().updateArtist(
                  artistId.toString(), // Ensure ID is converted to string
                  updatedArtistData,
                );

                if (mounted) {
                  nav.pop(true);
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error updating artist: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: Text(
            _hasChanges ? 'Save' : 'Done',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformField(String platform, String fieldKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              platformAssetMap[platform] ?? 'assets/images/dsps/spotify.png',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _controllers[fieldKey],
                keyboardType: _isLinkField(fieldKey)
                    ? TextInputType.url
                    : TextInputType.text,
                onChanged: (value) async {
                  if (platform == 'Spotify' && value.isNotEmpty) {
                    final imageUrl = await MusicVerificationService()
                        .getSpotifyArtistImage(value);
                    if (!mounted) return;
                    setState(() {
                      _previewImageUrl = imageUrl;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: '$platform URL',
                  labelStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(
                    color: _isEnabled[fieldKey]! ? Colors.white : Colors.grey),
                enabled: _isEnabled[fieldKey],
                validator: (value) {
                  if (_isEnabled[fieldKey]! &&
                      (value == null || value.isEmpty)) {
                    return '$platform URL cannot be empty if enabled';
                  }
                  return null;
                },
              ),
            ),
            Checkbox(
              value: _isEnabled[fieldKey],
              onChanged: (value) {
                setState(() {
                  _isEnabled[fieldKey] = value!;
                });
              },
            ),
          ],
        ),
        Visibility(
          visible: !_isEnabled[fieldKey]!,
          child: Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              platform == 'Spotify' || platform == 'Apple Music'
                  ? 'A new $platform profile will be created with this name'
                  : 'No $platform profile will be linked',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  bool _isLinkField(String fieldKey) {
    const linkFields = [
      'spotifyUrl',
      'appleMusicUrl',
      'youtubeUrl',
      'instagramURL',
      'facebookUrl',
      'xUrl',
      'tiktokUrl',
      'soundcloudUrl',
    ];
    return linkFields.contains(fieldKey);
  }

  Future<bool> _verifySpotifyLink(String spotifyUrl, String artistName) async {
    return await MusicVerificationService().verifySpotifyArtist(spotifyUrl, artistName);
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B2C),
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          content: Text(message, style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

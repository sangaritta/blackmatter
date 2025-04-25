import 'package:flutter/material.dart';
import 'package:portal/constants/music_constants.dart';
import 'package:portal/services/api_service.dart';
import 'package:portal/services/music_verification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/songwriter/songwriter_bloc.dart';

class NewArtistForm extends StatefulWidget {
  const NewArtistForm({super.key});

  @override
  NewArtistFormState createState() => NewArtistFormState();
}

class NewArtistFormState extends State<NewArtistForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'spotifyUrl': TextEditingController(),
    'appleMusicUrl': TextEditingController(),
    'youtubeUrl': TextEditingController(),
    'instagramURL': TextEditingController(),
    'facebookUrl': TextEditingController(),
    'xUrl': TextEditingController(),
    'tiktokUrl': TextEditingController(),
    'soundcloudUrl': TextEditingController(),
  };

  final Map<String, bool> _isEnabled = {
    'spotifyUrl': false,
    'appleMusicUrl': false,
    'youtubeUrl': false,
    'instagramURL': false,
    'facebookUrl': false,
    'xUrl': false,
    'tiktokUrl': false,
    'soundcloudUrl': false,
  };

  final _musicVerificationService = MusicVerificationService();
  String? _previewImageUrl;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to detect changes
    _controllers.forEach((key, controller) {
      controller.addListener(_onFormChanged);
    });
  }

  void _onFormChanged() {
    bool hasChanges = false;
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        hasChanges = true;
      }
    });

    _isEnabled.forEach((key, value) {
      if (value) {
        hasChanges = true;
      }
    });

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
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
      title: const Text('New Artist', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 20),
                  child: ClipOval(
                    child:
                        _previewImageUrl != null
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
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Artist Name cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
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
          onPressed: () async {
            bool confirmCancel = await _showCancelConfirmationDialog(context);
            if (confirmCancel && mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () async {
            if (!_hasChanges) {
              Navigator.of(context).pop();
              return;
            }

            if (_formKey.currentState!.validate()) {
              final artistName = _controllers['name']!.text;
              final nav = Navigator.of(context);

              try {
                // First verify if artist exists in your database
                final artistExists = await ApiService().checkArtistExists(
                  artistName,
                );
                if (artistExists && mounted) {
                  _showErrorDialog(
                    context,
                    'Artist already exists in your account.',
                  );
                  return;
                }

                // Then verify music platforms
                final platformsVerified = await _verifyMusicPlatforms(
                  artistName,
                );
                if (!platformsVerified || !mounted) return;

                // If all verifications pass, save the artist
                final artistData = {
                  ..._controllers.map(
                    (key, controller) => MapEntry(key, controller.text),
                  ),
                  'imageUrl': _previewImageUrl,
                };

                await ApiService().createArtist(artistData);
                //await analyticsService.logArtistCreated(artistName);
                if (mounted) nav.pop(true);
              } catch (e) {
                if (mounted) {
                  _showErrorDialog(
                    context,
                    'Failed to create artist: ${e.toString()}',
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
              'assets/images/dsps/$platform.png',
              height: 20,
              width: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _controllers[fieldKey],
                onChanged: (value) async {
                  if (platform == 'Spotify' && value.isNotEmpty) {
                    final imageUrl = await MusicVerificationService()
                        .getSpotifyArtistImage(value);
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
                ),
                style: TextStyle(
                  color: _isEnabled[fieldKey]! ? Colors.white : Colors.grey,
                ),
                enabled: _isEnabled[fieldKey],
                validator: (value) {
                  if (_isEnabled[fieldKey]! && value!.isEmpty) {
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

  Future<bool> _showCancelConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1B2C),
              title: const Text(
                'Confirm Cancel',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to cancel?',
                style: TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('No', style: TextStyle(color: Colors.blue)),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Yes', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;
    if (result && Navigator.of(context).context != null) {
      Navigator.of(context).pop();
    }
    return result;
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

  Future<bool> _verifyMusicPlatforms(String artistName) async {
    try {
      if (_isEnabled['spotifyUrl']! &&
          (_controllers['spotifyUrl']!.text.isNotEmpty)) {
        final isSpotifyValid = await _musicVerificationService
            .verifySpotifyArtist(_controllers['spotifyUrl']!.text, artistName);

        if (!isSpotifyValid) {
          _showErrorDialog(
            context,
            'The Spotify URL does not match the artist name provided',
          );
          return false;
        }
        //await analyticsService.logArtistVerified(artistName, 'spotify');
        // TODO: Add analytics logging
      }

      return true;
    } catch (e) {
      //await analyticsService.logError(
      //  'artist_verification_error',
      //  e.toString(),
      //);
      return false;
    }
  }
}

class NewSongwriterForm extends StatefulWidget {
  const NewSongwriterForm({super.key});

  @override
  NewSongwriterFormState createState() => NewSongwriterFormState();
}

class NewSongwriterFormState extends State<NewSongwriterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  String? _selectedCountry;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _middleNameController.addListener(_onFormChanged);
    _lastNameController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    bool hasChanges =
        _nameController.text.isNotEmpty ||
        _middleNameController.text.isNotEmpty ||
        _lastNameController.text.isNotEmpty ||
        _selectedCountry != null;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1B2C),
      title: const Text(
        'New Songwriter',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
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
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'First Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'Middle Name (Optional)',
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
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Middle Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
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
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Last Name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(
                  labelText: 'Country of Origin',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1E1B2C),
                items:
                    countries.map((Country country) {
                      return DropdownMenuItem<String>(
                        value: country.name,
                        child: Row(
                          children: [
                            Text(country.flag),
                            const SizedBox(width: 8),
                            Text(country.name),
                          ],
                        ),
                      );
                    }).toList(),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please select a country';
                  }
                  return null;
                },
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCountry = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () async {
            if (!_hasChanges) {
              Navigator.of(context).pop();
              return;
            }

            if (_formKey.currentState!.validate()) {
              final fullName = [
                _nameController.text,
                _middleNameController.text,
                _lastNameController.text,
              ].where((part) => part.isNotEmpty).join(' ');

              final songwriterData = {
                'name': fullName,
                'firstName': _nameController.text,
                'middleName': _middleNameController.text,
                'lastName': _lastNameController.text,
                'country': _selectedCountry,
              };

              // Use BLoC instead of direct API call
              context.read<SongwriterBloc>().add(
                CreateSongwriterRequested(songwriterData),
              );
              Navigator.of(context).pop(true);
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
}

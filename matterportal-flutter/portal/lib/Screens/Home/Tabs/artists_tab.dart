import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/music_verification_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';
import 'package:portal/Screens/Home/Forms/edit_artist_form.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:portal/Models/artist.dart';

class ArtistsTab extends StatefulWidget {
  const ArtistsTab({super.key});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final stream = showFavoritesOnly
        ? ApiService().getFavoriteArtistsStream()
        : ApiService().getArtistsStream();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                showFavoritesOnly ? Icons.star : Icons.star_border,
                color: showFavoritesOnly ? Colors.amber : Colors.white,
              ),
              tooltip: showFavoritesOnly ? 'Show All Artists' : 'Show Only Favorites',
              onPressed: () {
                setState(() {
                  showFavoritesOnly = !showFavoritesOnly;
                });
              },
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: LoadingIndicator(
                    size: 50,
                    color: Colors.white,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No artists found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create a new artist to get started',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final artists = snapshot.data!.map((artistMap) => Artist.fromMap(artistMap)).toList();
              return ListView.builder(
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return FutureBuilder<String?>(
                    future: artist.spotifyUrl != null && artist.spotifyUrl!.isNotEmpty
                        ? MusicVerificationService().getSpotifyArtistImage(artist.spotifyUrl!)
                        : Future.value(artist.imageUrl),
                    builder: (context, imageSnapshot) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: imageSnapshot.data != null && imageSnapshot.data!.isNotEmpty
                                      ? NetworkImage(imageSnapshot.data!)
                                      : null,
                                  backgroundColor: Colors.grey[800],
                                  child: (imageSnapshot.data == null || imageSnapshot.data!.isEmpty)
                                      ? const Icon(Icons.person, color: Colors.white, size: 30)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artist.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    artist.isFavorite ? Icons.star : Icons.star_border,
                                    color: artist.isFavorite ? Colors.amber : Colors.white,
                                  ),
                                  tooltip: artist.isFavorite ? 'Unfavorite' : 'Favorite',
                                  onPressed: () async {
                                    await ApiService().toggleArtistFavorite(artist.id, !artist.isFavorite);
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: () async {
                                      final result = await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return EditArtistForm(
                                            artistData: {
                                              ...artist.toMap(),
                                              'id': artist.id,
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (artist.instagramURL != null && artist.instagramURL!.isNotEmpty)
                                  IconButton(
                                    onPressed: () async {
                                      final url = artist.instagramURL!;
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/dsps/instagram.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                                if (artist.youtubeUrl != null && artist.youtubeUrl!.isNotEmpty)
                                  IconButton(
                                    onPressed: () async {
                                      final url = artist.youtubeUrl!;
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/dsps/youtube.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                                if (artist.appleMusicUrl != null && artist.appleMusicUrl!.isNotEmpty)
                                  IconButton(
                                    onPressed: () async {
                                      final url = artist.appleMusicUrl!;
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/dsps/Apple Music.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                                if (artist.soundcloudUrl != null && artist.soundcloudUrl!.isNotEmpty)
                                  IconButton(
                                    onPressed: () async {
                                      final url = artist.soundcloudUrl!;
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/dsps/soundcloud.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                                if (artist.tiktokUrl != null && artist.tiktokUrl!.isNotEmpty)
                                  IconButton(
                                    onPressed: () async {
                                      final url = artist.tiktokUrl!;
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/dsps/tiktok.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                                if (artist.spotifyUrl != null && artist.spotifyUrl!.isNotEmpty)
                                  IconButton(
                                    onPressed: () async {
                                      final url = artist.spotifyUrl!;
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url));
                                      }
                                    },
                                    icon: Image.asset(
                                      'assets/images/dsps/spotify.png',
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
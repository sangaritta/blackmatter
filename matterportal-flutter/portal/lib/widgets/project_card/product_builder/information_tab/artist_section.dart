import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Services/api_service.dart'; 

class ArtistSection {
  // Static method to display selected artists in a row
  static Widget displaySelectedArtists({required List<String> selectedArtists}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildArtistAvatars(selectedArtists),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _formatArtistNames(selectedArtists),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: fontNameSemiBold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Format artist names for display
  static String _formatArtistNames(List<String> artists) {
    if (artists.isEmpty) return '';
    if (artists.length == 1) return artists[0];
    
    // Handle two artists
    if (artists.length == 2) {
      return '${artists[0]} & ${artists[1]}';
    }
    
    // Handle more than two artists
    final lastArtist = artists.last;
    final otherArtists = artists.sublist(0, artists.length - 1);
    return '${otherArtists.join(', ')} & $lastArtist';
  }

  // Build artist avatars
  static Widget _buildArtistAvatars(List<String> selectedArtists) {
    if (selectedArtists.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Calculate width based on number of avatars (25px overlap per avatar after first)
    final int numAvatars = selectedArtists.length;
    final int visibleAvatars = numAvatars > 3 ? 4 : numAvatars;
    final double width = 40.0 + ((visibleAvatars - 1) * 25.0);
    
    return SizedBox(
      width: width,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ...selectedArtists.take(3).toList().asMap().entries.map(
            (entry) {
              return Positioned(
                left: entry.key * 25.0,
                child: FutureBuilder<String?>(
                  future: ApiService().getArtistProfileImage(entry.value),
                  builder: (context, snapshot) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF1E1B2C), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(77),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: snapshot.data != null
                            ? Image.network(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              )
                            : Center(
                                child: Text(
                                  entry.value.isNotEmpty ? entry.value[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (selectedArtists.length > 3)
            Positioned(
              left: 75,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D3A), // Dark purple/blue color
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1E1B2C), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(77),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '+${selectedArtists.length - 3}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
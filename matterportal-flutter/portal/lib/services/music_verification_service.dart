import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' show parse;

class MusicVerificationService {
  static const String _spotifyClientId = '0417a39abe1d401bbf75166b9a695013';
  static const String _spotifyClientSecret = 'e082c66c2f06421089478d7ea101c6b1';

  Future<bool> verifySpotifyArtist(String spotifyUrl, String artistName) async {
    try {
      final artistId = spotifyUrl.split('/').last.split('?').first;

      final tokenResponse = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_spotifyClientId:$_spotifyClientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      final tokenData = json.decode(tokenResponse.body);
      final accessToken = tokenData['access_token'];

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final artistData = json.decode(response.body);
        final spotifyArtistName = artistData['name'].toLowerCase();
        return spotifyArtistName.contains(artistName.toLowerCase()) ||
            artistName.toLowerCase().contains(spotifyArtistName);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyAppleMusicArtist(
      String appleMusicUrl, String artistName) async {
    try {
      // Make a GET request to the Apple Music URL
      final response = await http.get(Uri.parse(appleMusicUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      });

      if (response.statusCode == 200) {
        // Parse the HTML content
        final document = parse(response.body);

        // Try to find the artist name in the page title or meta tags
        final pageTitle = document.querySelector('title')?.text ?? '';
        final metaDescription = document
                .querySelector('meta[name="description"]')
                ?.attributes['content'] ??
            '';

        // Convert everything to lowercase for comparison
        final pageTitleLower = pageTitle.toLowerCase();
        final metaDescriptionLower = metaDescription.toLowerCase();
        final artistNameLower = artistName.toLowerCase();

        // Check if the artist name appears in either the title or description
        return pageTitleLower.contains(artistNameLower) ||
            metaDescriptionLower.contains(artistNameLower);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getSpotifyArtistImage(String spotifyUrl) async {
    try {
      final artistId = spotifyUrl.split('/').last.split('?').first;

      final tokenResponse = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_spotifyClientId:$_spotifyClientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      final tokenData = json.decode(tokenResponse.body);
      final accessToken = tokenData['access_token'];

      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/artists/$artistId'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final artistData = json.decode(response.body);
        return artistData['images']?[0]?['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

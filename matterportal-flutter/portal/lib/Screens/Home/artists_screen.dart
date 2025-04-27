import 'package:flutter/material.dart';
import 'package:portal/Screens/Home/Forms/new_artist_form.dart';
import 'package:portal/Screens/Home/Forms/new_songwriter_form.dart'
    as songwriter;
import 'package:portal/Screens/Home/Tabs/artists_tab.dart';
import 'package:portal/Screens/Home/Tabs/songwriters_tab.dart';

class ArtistsScreen extends StatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ArtistsScreenState createState() => ArtistsScreenState();
}

class ArtistsScreenState extends State<ArtistsScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _selectedPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildToggleButton(String title, int pageIndex) {
    return TextButton(
      onPressed: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      style: TextButton.styleFrom(
        backgroundColor: _selectedPageIndex == pageIndex
            ? const Color.fromARGB(255, 96, 33, 243)
            : Colors.transparent,
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  void _showNewItemDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return _selectedPageIndex == 0
            ? const NewArtistForm()
            : const songwriter.NewSongwriterForm();
      },
    );
    if (result == true) {
      setState(() {
        // Refresh the current tab
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black45,
        centerTitle: false,
        title: SizedBox(
          width: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: _buildToggleButton("Artists", 0),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: _buildToggleButton("Songwriters", 1),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showNewItemDialog(context),
            label: Text(
              _selectedPageIndex == 0 ? 'New Artist' : 'New Songwriter',
              style: const TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedPageIndex = index;
          });
        },
        children: const [
          ArtistsTab(),
          SongwritersTab(),
        ],
      ),
    );
  }
}

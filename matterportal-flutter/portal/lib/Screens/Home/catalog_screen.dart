import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Screens/Home/import_releases_screen.dart'; // Add this import
import 'package:portal/Screens/Home/products_list_view.dart';
import 'package:portal/Screens/Home/project_list_view.dart';
import 'package:portal/Screens/Home/responsive_project_view.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(
    initialPage: 0,
  ); // Set initialPage to 0

  List<Project> projects = [];
  bool isLoading = false;
  bool hasMoreProjects = true;
  DocumentSnapshot? lastDocument; // Add this line
  int _selectedPageIndex = 0; // Set default selected page index to 0

  // Add these keys to access the list views
  final GlobalKey<ProductsListViewState> _productsKey = GlobalKey();
  final GlobalKey<ProjectListViewState> _projectsKey = GlobalKey();

  // Generates a new Project ID in the format PRTL+14 digit UID
  String _generateProjectId() {
    final random = Random();
    final id = List.generate(14, (_) => random.nextInt(10)).join();
    return 'PRTL$id';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
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
                child: _buildToggleButton(
                  "Projects",
                  1,
                ), // Projects should open the second page
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: _buildToggleButton(
                  "Products",
                  0,
                ), // Products should open the first page
              ),
            ],
          ),
        ),
        actions: [
          // Responsive New Project button
          Builder(
            builder: (context) {
              final isWideEnough = MediaQuery.of(context).size.width > 600;
              return TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        String newProjectId = _generateProjectId();
                        final isWideEnough =
                            MediaQuery.of(context).size.width > 600;

                        return ResponsiveProjectView(
                          projectId: newProjectId,

                          newProject: true,
                          useDesktopUI:
                              isWideEnough, // Flag to determine which UI to use
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label:
                    isWideEnough ? const Text('New Project') : const Text(''),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideEnough ? 16.0 : 8.0,
                  ),
                ),
              );
            },
          ),
          // Responsive Import Releases button
          Builder(
            builder: (context) {
              final isWideEnough = MediaQuery.of(context).size.width > 600;
              return TextButton.icon(
                onPressed: () {
                  // Navigate to the ImportReleasesScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportReleasesScreen(),
                    ),
                  ).then((result) {
                    // If result is true, refresh both lists
                    // Remove call to refreshProjects and refreshProducts as those methods no longer exist in the new stream-based implementation.
                    // If you need to trigger a UI update, use setState or rely on the stream updates.
                  });
                },
                icon: const Icon(Icons.file_download),
                label:
                    isWideEnough
                        ? const Text('Import Releases')
                        : const Text(''),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWideEnough ? 16.0 : 8.0,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        reverse: true, // This line ensures the animation direction is correct
        onPageChanged: (index) {
          if (mounted) {
            setState(() {
              _selectedPageIndex = index;
            });
          }
        },
        children: [
          ProductsListView(key: _productsKey),
          ProjectListView(key: _projectsKey),
        ],
      ),
    );
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
        backgroundColor:
            _selectedPageIndex == pageIndex
                ? const Color.fromARGB(255, 96, 33, 243)
                : Colors.transparent,
      ),
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  // Add a method to expose refreshing functionality
  void refreshLists() {
    // This method can be called from outside to refresh the lists
    // Remove call to refreshProjects and refreshProducts as those methods no longer exist in the new stream-based implementation.
    // If you need to trigger a UI update, use setState or rely on the stream updates.
  }
}

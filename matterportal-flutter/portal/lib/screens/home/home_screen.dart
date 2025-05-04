import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:portal/Screens/Home/analytics_screen.dart';
import 'package:portal/Screens/Home/artists_screen.dart';
import 'package:portal/Screens/Home/bank_screen.dart';
import 'package:portal/Screens/Home/catalog_screen.dart';
import 'package:portal/Screens/Home/dashboard_screen.dart';
import 'package:portal/Screens/Home/logout_helper.dart';
import 'package:portal/Screens/Home/matter_market_screen.dart';
import 'package:portal/Screens/Home/marketing_screen.dart';
import 'package:portal/Screens/Home/products_list_view.dart';
import 'package:portal/Screens/Home/settings_screen.dart';
import 'package:portal/Services/auth_service.dart';
//import 'package:portal/Services/analytics_service.dart';
// import 'package:portal/Services/fcm_service.dart';  // Commented out FCM service
import 'package:portal/Services/api_service.dart';
import 'package:portal/Widgets/Common/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = [
    // Content for Home tab
    const DashboardScreen(),
    const CatalogScreen(),
    const ArtistsScreen(),
    const AnalyticsScreen(),
    const BankScreen(),
    const MatterMarketScreen(),
    const MarketingScreen(),
    const SettingsScreen(),
  ];

  int _selectedIndex = 1;
  final PageController _pageController = PageController(initialPage: 1);
  bool _isLoggingOut = false;

  bool isMobile(BuildContext c) {
    if (MediaQuery.of(c).size.width < 640) {
      return true;
    } else {
      return false;
    }
  }

  final GlobalKey<ProductsListViewState> _productsListKey =
      GlobalKey<ProductsListViewState>();

  @override
  void initState() {
    super.initState();
    //analyticsService.logScreenView(screenName: 'home_screen');

    // FCM permission requests removed
    // _requestNotificationPermissions();
    // _schedulePermissionRequest();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);

    // Track screen views for different tabs
    // Uncomment and use this when analytics service is implemented
    /*
    final screenNames = [
      'dashboard_screen',
      'catalog_screen',
      'artists_screen',
      'analytics_screen',
      'bank_screen',
      'matter_market_screen',
      'marketing_screen',
      'settings_screen',
    ];
    analyticsService.logScreenView(screenName: screenNames[index]);
    */
  }

  // Method is used in production but marked as unused due to being indirectly referenced
  // Keep it for future use and reference from the catalog screen
  /* 
  void _openImportReleasesScreen() async {
    // Wait for a result from the import screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImportReleasesScreen()),
    );

    // If import was successful (result is true), refresh the products list
    if (result == true) {
      _refreshProductsList();
    }
  }
  */

  void _refreshProductsList() {
    // Clear the API cache to ensure fresh data
    api.clearProductCache(auth.getUser()?.uid ?? '');

    // Find the products list within the catalog screen to refresh it
    if (_selectedIndex == 1) {
      // In catalog screen, find all product list views that need refreshing
      final ProductsListViewState? productsListState =
          _productsListKey.currentState;

      if (productsListState != null) {
        // Remove call to refreshProducts as this method no longer exists in ProductsListViewState.
        // If you need to trigger a UI update, use setState or rely on the stream updates.
        // productsListState.refreshProducts();
      } else {
        // If we can't find the state directly, attempt to refresh after a brief delay
        // This handles cases where the widget might not be fully built
        Future.delayed(const Duration(milliseconds: 100), () {
          final ProductsListViewState? delayedState =
              _productsListKey.currentState;
          // Remove call to refreshProducts as this method no longer exists in ProductsListViewState.
          // If you need to trigger a UI update, use setState or rely on the stream updates.
          // delayedState?.refreshProducts();
        });
      }

      // Force a rebuild of the page to ensure updated data is shown
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // Added logo
        leading: Image.asset('assets/images/ico.png'),
        title: Text(
          "Portal",
          style: TextStyle(
            fontFamily: fontNameBold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (dialogContext) => AlertDialog(
                  icon: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    "Log out?",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  backgroundColor:
                      Theme.of(context).scaffoldBackgroundColor,
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('No'),
                    ),
                    StatefulBuilder(
                      builder: (statefulContext, setInnerState) {
                        return TextButton(
                          onPressed:
                              _isLoggingOut
                                  ? null
                                  : () async {
                                    setInnerState(() => _isLoggingOut = true);
                                    // Close the dialog first
                                    Navigator.of(dialogContext).pop();
                                    // Use the logout helper to safely perform logout
                                    await LogoutHelper.performLogout(context);
                                    // No need to handle state after this point as we will navigate away
                                  },
                          child:
                              _isLoggingOut
                                  ? const LoadingIndicator(
                                    size: 20,
                                    color: Colors.blue,
                                  )
                                  : const Text('Yes'),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.login, color: Colors.red),
          ),

        ],
      ),
      bottomNavigationBar:
          MediaQuery.of(context).size.width < 640
              ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                backgroundColor: Colors.black, // Set background color to black
                type:
                    BottomNavigationBarType
                        .shifting, // Explicitly set to shifting
                selectedItemColor: Colors.white, // Use white for selected items
                unselectedItemColor:
                    Colors.grey, // Use grey for unselected items
                showUnselectedLabels:
                    false, // Show labels for unselected items too
                onTap: _onTabChanged,
                // bottom tab items
                items: const [
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black, // Set each item's background
                    icon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.library_music_rounded),
                    label: 'Catalog',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.spatial_audio_off),
                    label: 'Artists',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.analytics),
                    label: 'Analytics',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.attach_money_rounded),
                    label: 'Finances',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.store),
                    label: 'Market',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.campaign),
                    label: 'Marketing',
                  ),
                  BottomNavigationBarItem(
                    backgroundColor: Colors.black,
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              )
              : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 640)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 36, 9, 51),
                    Color.fromARGB(255, 13, 0, 43),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                extended: true,
                selectedIconTheme: IconThemeData(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.secondary, // Use theme secondary color
                ),
                unselectedIconTheme: const IconThemeData(),
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  _pageController.jumpToPage(index);
                },
                selectedIndex: _selectedIndex,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.dashboard,
                      color:
                          _selectedIndex == 0
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Dashboard',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 0 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.library_music_rounded,
                      color:
                          _selectedIndex == 1
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Catalog',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 1 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.spatial_audio_off,
                      color:
                          _selectedIndex == 2
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Artists',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 2 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.analytics,
                      color:
                          _selectedIndex == 3
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Analytics',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 3 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.attach_money_rounded,
                      color:
                          _selectedIndex == 4
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Finances',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 4 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.store,
                      color:
                          _selectedIndex == 5
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Matter Market',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 5 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.campaign,
                      color:
                          _selectedIndex == 6
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Marketing',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 6 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  NavigationRailDestination(
                    icon: Icon(
                      Icons.settings,
                      color:
                          _selectedIndex == 7
                              ? Theme.of(context).colorScheme.secondary
                              : Colors.grey,
                    ),
                    label: Text(
                      'Settings',
                      style: TextStyle(
                        fontFamily: fontNameSemiBold,
                        color: _selectedIndex == 7 ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
                labelType: NavigationRailLabelType.none,
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.white, // Set selected label color to white
                ),
                unselectedLabelTextStyle: const TextStyle(
                  color: Colors.grey, // Set unselected label color to grey
                ),
                leading: const Column(children: []),
                indicatorColor:
                    Colors.transparent, // Set indicator color to transparent
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}

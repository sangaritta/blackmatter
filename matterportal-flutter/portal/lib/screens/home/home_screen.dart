import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:portal/screens/home/nav/analytics_screen.dart';
import 'package:portal/screens/home/nav/artists_screen.dart';
import 'package:portal/screens/home/nav/bank_screen.dart';
import 'package:portal/screens/home/nav/catalog_screen.dart';
import 'package:portal/screens/home/nav/dashboard_screen.dart';
import 'package:portal/screens/home/nav/matter_market_screen.dart';
import 'package:portal/screens/home/nav/marketing_screen.dart';
import 'package:portal/screens/home/nav/settings_screen.dart';
import 'package:portal/services/auth_service.dart';
import 'package:portal/widgets/common/loading_indicator.dart';
import 'package:portal/constants/fonts.dart';

final auth = AuthService.instance;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoggingOut = false;

  final List<_NavItem> _navItems = [
    _NavItem('Dashboard', Icons.dashboard, const DashboardScreen()),
    _NavItem('Catalog', Icons.library_music_rounded, const CatalogScreen()),
    _NavItem('Artists', Icons.spatial_audio_off, const ArtistsScreen()),
    _NavItem('Analytics', Icons.analytics, const AnalyticsScreen()),
    _NavItem('Finances', Icons.attach_money_rounded, const BankScreen()),
    _NavItem('Market', Icons.store, const MatterMarketScreen()),
    _NavItem('Marketing', Icons.campaign, const MarketingScreen()),
    _NavItem('Settings', Icons.settings, const SettingsScreen()),
  ];

  bool get isMobile => MediaQuery.of(context).size.width < 640;

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  void _logout() async {
    setState(() => _isLoggingOut = true);
    await auth.signOut();
    if (!mounted) return;
    context.go('/login');
    setState(() => _isLoggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/ico.png'),
        ),
        title: Text(
          'Portal',
          style: TextStyle(
            fontFamily: fontNameBold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isLoggingOut ? null : _logout,
            icon:
                _isLoggingOut
                    ? const LoadingIndicator(size: 20, color: Colors.blue)
                    : const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              backgroundColor: Colors.transparent,
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavTap,
              destinations:
                  _navItems
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(
                            item.label,
                            style: const TextStyle(fontFamily: fontNameSemiBold),
                          ),
                        ),
                      )
                      .toList(),
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.secondary,
              ),
              unselectedIconTheme: const IconThemeData(color: Colors.grey),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontFamily: fontNameSemiBold,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Colors.grey,
                fontFamily: fontNameSemiBold,
              ),
              indicatorColor: Colors.transparent,
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _navItems.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          isMobile
              ? BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onNavTap,
                type: BottomNavigationBarType.shifting,
                backgroundColor: Colors.black,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: const TextStyle(
                  fontFamily: fontNameBold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: fontNameSemiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                items:
                    _navItems
                        .map(
                          (item) => BottomNavigationBarItem(
                            icon: Icon(item.icon),
                            label: item.label,
                            backgroundColor: Colors.black, // Ensure shifting tabs stay black
                          ),
                        )
                        .toList(),
              )
              : null,
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const _NavItem(this.label, this.icon, this.screen);
}

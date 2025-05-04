import 'package:flutter/material.dart';
import 'package:portal/Models/project.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Screens/Home/catalog_screen.dart';
import 'package:portal/Screens/Home/products_list_view.dart';
import 'package:portal/Screens/Home/Tabs/artists_tab.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFF18162A),
      body: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = isMobile ? constraints.maxWidth * 0.9 : 350.0;
              final cardHeight = isMobile ? 170.0 : 220.0;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 12,
                  ),
                  child:
                      isMobile
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _DashboardCard(
                                type: DashboardCardType.projects,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                              const SizedBox(height: 24),
                              _DashboardCard(
                                type: DashboardCardType.products,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                              const SizedBox(height: 24),
                              _DashboardCard(
                                type: DashboardCardType.artists,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _DashboardCard(
                                type: DashboardCardType.projects,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                              const SizedBox(width: 32),
                              _DashboardCard(
                                type: DashboardCardType.products,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                              const SizedBox(width: 32),
                              _DashboardCard(
                                type: DashboardCardType.artists,
                                width: cardWidth,
                                height: cardHeight,
                              ),
                            ],
                          ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum DashboardCardType { projects, products, artists }

class _DashboardCard extends StatelessWidget {
  final DashboardCardType type;
  final double width;
  final double height;
  const _DashboardCard({
    required this.type,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case DashboardCardType.projects:
        return _ProjectsSummaryCard(width: width, height: height);
      case DashboardCardType.products:
        return _ProductsSummaryCard(width: width, height: height);
      case DashboardCardType.artists:
        return _ArtistsSummaryCard(width: width, height: height);
    }
  }
}

class _DashboardPreviewList extends StatelessWidget {
  final List<Widget> children;
  final int totalCount;
  final String moreLabel;
  const _DashboardPreviewList({
    required this.children,
    required this.totalCount,
    required this.moreLabel,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showMore = totalCount > 3;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...children,
          if (showMore)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${totalCount - 3} $moreLabel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectsSummaryCard extends StatelessWidget {
  final double width;
  final double height;
  const _ProjectsSummaryCard({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 10,
          color: const Color(0xFF232040),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220, maxHeight: 340),
            child: StreamBuilder<List<Project>>(
              stream: api.getProjectsStream(),
              builder: (context, snapshot) {
                final projects = snapshot.data ?? [];
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue[200],
                            radius: 24,
                            child: Icon(
                              Icons.library_music_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Projects',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${projects.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DashboardPreviewList(
                        children: List.generate(
                          projects.length > 3 ? 3 : projects.length,
                          (i) => Chip(
                            backgroundColor: Colors.blue[100]?.withOpacity(0.2),
                            label: Text(
                              projects[i].name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        totalCount: projects.length,
                        moreLabel: 'more',
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[400],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View All'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const CatalogScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ProductsSummaryCard extends StatelessWidget {
  final double width;
  final double height;
  const _ProductsSummaryCard({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 10,
          color: const Color(0xFF232040),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220, maxHeight: 340),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: api.getUserProductsStream(),
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            products.length.toString(),
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View All'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ProductsListView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ArtistsSummaryCard extends StatelessWidget {
  final double width;
  final double height;
  const _ArtistsSummaryCard({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 10,
          color: const Color(0xFF232040),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220, maxHeight: 340),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: api.getArtistsStream(),
              builder: (context, snapshot) {
                final artists = snapshot.data ?? [];
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green[200],
                            radius: 24,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Artists',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${artists.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DashboardPreviewList(
                        children: List.generate(
                          artists.length > 3 ? 3 : artists.length,
                          (i) => Chip(
                            backgroundColor: Colors.green[100]?.withOpacity(
                              0.2,
                            ),
                            label: Text(
                              artists[i]['artistName'] ?? 'No name',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        totalCount: artists.length,
                        moreLabel: 'more',
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[400],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('View All'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ArtistsTab(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

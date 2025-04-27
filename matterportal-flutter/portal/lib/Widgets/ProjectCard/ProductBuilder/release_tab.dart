import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';
import 'package:extended_image/extended_image.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:portal/Screens/Congratulations/distribution_success.dart';
import 'package:portal/Models/product.dart';
import 'package:portal/Models/track.dart';

class ReleaseTab extends StatefulWidget {
  final String projectId;
  final String productId;
  final bool isMobile;

  const ReleaseTab({
    super.key,
    required this.projectId,
    required this.productId,
    this.isMobile = false,
  });

  @override
  State<ReleaseTab> createState() => _ReleaseTabState();
}

class _ReleaseTabState extends State<ReleaseTab> {
  // Common time zones list with display names and UTC offsets
  final List<Map<String, String>> timeZones = [
    {'value': 'UTC', 'display': 'UTC+00:00 - Coordinated Universal Time'},
    // Africa
    {'value': 'Africa/Cairo', 'display': 'UTC+02:00 - Cairo (EET)'},
    {'value': 'Africa/Casablanca', 'display': 'UTC+00:00 - Casablanca (WET)'},
    {
      'value': 'Africa/Johannesburg',
      'display': 'UTC+02:00 - Johannesburg (SAST)',
    },
    {'value': 'Africa/Lagos', 'display': 'UTC+01:00 - Lagos (WAT)'},
    {'value': 'Africa/Nairobi', 'display': 'UTC+03:00 - Nairobi (EAT)'},
    // Americas
    {
      'value': 'America/Anchorage',
      'display': 'UTC-09:00 - Anchorage (AKST/AKDT)',
    },
    {
      'value': 'America/Argentina/Buenos_Aires',
      'display': 'UTC-03:00 - Buenos Aires (ART)',
    },
    {'value': 'America/Asuncion', 'display': 'UTC-04:00 - Asuncion (PYT)'},
    {'value': 'America/Bogota', 'display': 'UTC-05:00 - Bogota (COT)'},
    {'value': 'America/Caracas', 'display': 'UTC-04:00 - Caracas (VET)'},
    {'value': 'America/Chicago', 'display': 'UTC-06:00 - Chicago (CST/CDT)'},
    {'value': 'America/Costa_Rica', 'display': 'UTC-06:00 - Costa Rica (CST)'},
    {'value': 'America/Denver', 'display': 'UTC-07:00 - Denver (MST/MDT)'},
    {'value': 'America/Godthab', 'display': 'UTC-03:00 - Godthab (WGT)'},
    {'value': 'America/Guatemala', 'display': 'UTC-06:00 - Guatemala (CST)'},
    {'value': 'America/Halifax', 'display': 'UTC-04:00 - Halifax (AST/ADT)'},
    {'value': 'America/Havana', 'display': 'UTC-05:00 - Havana (CST/CDT)'},
    {'value': 'America/La_Paz', 'display': 'UTC-04:00 - La Paz (BOT)'},
    {'value': 'America/Lima', 'display': 'UTC-05:00 - Lima (PET)'},
    {
      'value': 'America/Los_Angeles',
      'display': 'UTC-08:00 - Los Angeles (PST/PDT)',
    },
    {
      'value': 'America/Mexico_City',
      'display': 'UTC-06:00 - Mexico City (CST/CDT)',
    },
    {'value': 'America/Montevideo', 'display': 'UTC-03:00 - Montevideo (UYT)'},
    {'value': 'America/New_York', 'display': 'UTC-05:00 - New York (EST/EDT)'},
    {'value': 'America/Phoenix', 'display': 'UTC-07:00 - Phoenix (MST)'},
    {'value': 'America/Regina', 'display': 'UTC-06:00 - Regina (CST)'},
    {'value': 'America/Santiago', 'display': 'UTC-04:00 - Santiago (CLT)'},
    {'value': 'America/Sao_Paulo', 'display': 'UTC-03:00 - Sao Paulo (BRT)'},
    {'value': 'America/St_Johns', 'display': 'UTC-03:30 - St Johns (NST/NDT)'},
    {'value': 'America/Toronto', 'display': 'UTC-05:00 - Toronto (EST/EDT)'},
    {
      'value': 'America/Vancouver',
      'display': 'UTC-08:00 - Vancouver (PST/PDT)',
    },
    // Asia
    {'value': 'Asia/Baghdad', 'display': 'UTC+03:00 - Baghdad (AST)'},
    {'value': 'Asia/Bangkok', 'display': 'UTC+07:00 - Bangkok (ICT)'},
    {'value': 'Asia/Dhaka', 'display': 'UTC+06:00 - Dhaka (BST)'},
    {'value': 'Asia/Dubai', 'display': 'UTC+04:00 - Dubai (GST)'},
    {'value': 'Asia/Ho_Chi_Minh', 'display': 'UTC+07:00 - Ho Chi Minh (ICT)'},
    {'value': 'Asia/Hong_Kong', 'display': 'UTC+08:00 - Hong Kong (HKT)'},
    {'value': 'Asia/Jakarta', 'display': 'UTC+07:00 - Jakarta (WIB)'},
    {'value': 'Asia/Jerusalem', 'display': 'UTC+02:00 - Jerusalem (IST)'},
    {'value': 'Asia/Karachi', 'display': 'UTC+05:00 - Karachi (PKT)'},
    {'value': 'Asia/Kolkata', 'display': 'UTC+05:30 - Kolkata (IST)'},
    {'value': 'Asia/Kuwait', 'display': 'UTC+03:00 - Kuwait (AST)'},
    {'value': 'Asia/Manila', 'display': 'UTC+08:00 - Manila (PHT)'},
    {'value': 'Asia/Qatar', 'display': 'UTC+03:00 - Qatar (AST)'},
    {'value': 'Asia/Riyadh', 'display': 'UTC+03:00 - Riyadh (AST)'},
    {'value': 'Asia/Seoul', 'display': 'UTC+09:00 - Seoul (KST)'},
    {'value': 'Asia/Shanghai', 'display': 'UTC+08:00 - Shanghai (CST)'},
    {'value': 'Asia/Singapore', 'display': 'UTC+08:00 - Singapore (SGT)'},
    {'value': 'Asia/Taipei', 'display': 'UTC+08:00 - Taipei (CST)'},
    {'value': 'Asia/Tehran', 'display': 'UTC+03:30 - Tehran (IRST)'},
    {'value': 'Asia/Tokyo', 'display': 'UTC+09:00 - Tokyo (JST)'},
    // Australia and Pacific
    {
      'value': 'Australia/Adelaide',
      'display': 'UTC+09:30 - Adelaide (ACST/ACDT)',
    },
    {'value': 'Australia/Brisbane', 'display': 'UTC+10:00 - Brisbane (AEST)'},
    {'value': 'Australia/Darwin', 'display': 'UTC+09:30 - Darwin (ACST)'},
    {'value': 'Australia/Hobart', 'display': 'UTC+10:00 - Hobart (AEDT)'},
    {
      'value': 'Australia/Melbourne',
      'display': 'UTC+10:00 - Melbourne (AEST/AEDT)',
    },
    {'value': 'Australia/Perth', 'display': 'UTC+08:00 - Perth (AWST)'},
    {'value': 'Australia/Sydney', 'display': 'UTC+10:00 - Sydney (AEST/AEDT)'},
    {
      'value': 'Pacific/Auckland',
      'display': 'UTC+12:00 - Auckland (NZST/NZDT)',
    },
    {'value': 'Pacific/Fiji', 'display': 'UTC+12:00 - Fiji (FJT)'},
    {'value': 'Pacific/Guam', 'display': 'UTC+10:00 - Guam (ChST)'},
    {'value': 'Pacific/Honolulu', 'display': 'UTC-10:00 - Honolulu (HST)'},
    {'value': 'Pacific/Samoa', 'display': 'UTC-11:00 - Samoa (SST)'},
    // Europe
    {
      'value': 'Europe/Amsterdam',
      'display': 'UTC+01:00 - Amsterdam (CET/CEST)',
    },
    {'value': 'Europe/Athens', 'display': 'UTC+02:00 - Athens (EET/EEST)'},
    {'value': 'Europe/Belgrade', 'display': 'UTC+01:00 - Belgrade (CET/CEST)'},
    {'value': 'Europe/Berlin', 'display': 'UTC+01:00 - Berlin (CET/CEST)'},
    {'value': 'Europe/Brussels', 'display': 'UTC+01:00 - Brussels (CET/CEST)'},
    {
      'value': 'Europe/Bucharest',
      'display': 'UTC+02:00 - Bucharest (EET/EEST)',
    },
    {'value': 'Europe/Budapest', 'display': 'UTC+01:00 - Budapest (CET/CEST)'},
    {
      'value': 'Europe/Copenhagen',
      'display': 'UTC+01:00 - Copenhagen (CET/CEST)',
    },
    {'value': 'Europe/Dublin', 'display': 'UTC+00:00 - Dublin (IST/GMT)'},
    {'value': 'Europe/Helsinki', 'display': 'UTC+02:00 - Helsinki (EET/EEST)'},
    {'value': 'Europe/Istanbul', 'display': 'UTC+03:00 - Istanbul (TRT)'},
    {'value': 'Europe/Kiev', 'display': 'UTC+02:00 - Kiev (EET/EEST)'},
    {'value': 'Europe/Lisbon', 'display': 'UTC+00:00 - Lisbon (WET/WEST)'},
    {'value': 'Europe/London', 'display': 'UTC+00:00 - London (GMT/BST)'},
    {'value': 'Europe/Madrid', 'display': 'UTC+01:00 - Madrid (CET/CEST)'},
    {'value': 'Europe/Moscow', 'display': 'UTC+03:00 - Moscow (MSK)'},
    {'value': 'Europe/Oslo', 'display': 'UTC+01:00 - Oslo (CET/CEST)'},
    {'value': 'Europe/Paris', 'display': 'UTC+01:00 - Paris (CET/CEST)'},
    {'value': 'Europe/Prague', 'display': 'UTC+01:00 - Prague (CET/CEST)'},
    {'value': 'Europe/Rome', 'display': 'UTC+01:00 - Rome (CET/CEST)'},
    {
      'value': 'Europe/Stockholm',
      'display': 'UTC+01:00 - Stockholm (CET/CEST)',
    },
    {'value': 'Europe/Vienna', 'display': 'UTC+01:00 - Vienna (CET/CEST)'},
    {'value': 'Europe/Warsaw', 'display': 'UTC+01:00 - Warsaw (CET/CEST)'},
    {'value': 'Europe/Zurich', 'display': 'UTC+01:00 - Zurich (CET/CEST)'},
  ];

  final List<String> platforms = [
    '7Digital',
    'ACRCloud',
    'Alibaba',
    'Amazon',
    'AMI Entertainment',
    'Anghami',
    'Apple',
    'Audible Magic',
    'Audiomack',
    'BMAT',
    'Boomplay',
    'Claro',
    'ClicknClear',
    'd\'Music',
    'Deezer',
    'Meta',
    'Gracenote',
    'iHeartRadio',
    'JioSaavn',
    'JOOX',
    'Kan Music',
    'KDM(K Digital Media)',
    'KK Box',
    'LiveOne',
    'Medianet',
    'Mixcloud',
    'Mood Media',
    'Pandora',
    'Peloton',
    'Pretzel',
    'Qobuz',
    'Resso',
    'Soundcloud',
    'Spotify',
    'Tidal',
    'TikTok',
    'TouchTunes',
    'Trebel',
    'Tuned Global',
    'USEA',
    'VL Group',
    'YouSee',
    'YouTube',
  ];

  final Map<String, String> platformIcons = {
    '7Digital': '7digital.jpg',
    'ACRCloud': 'acrcloud.jpg',
    'Alibaba': 'alibaba.jpg',
    'Amazon': 'amazon.png',
    'AMI Entertainment': 'ami.png',
    'Anghami': 'Anghami.jpg',
    'Apple': 'Apple Music.png',
    'Audible Magic': 'Audible Magic.png',
    'Audiomack': 'Audiomack.png',
    'BMAT': 'BMAT.jpg',
    'Boomplay': 'Boomplay.jpg',
    'Claro': 'Claro.png',
    'ClicknClear': 'ClicknClear.png',
    'd\'Music': 'd\'Music.png',
    'Deezer': 'Deezer.png',
    'Meta': 'Facebook.png',
    'Gracenote': 'Gracenote.png',
    'iHeartRadio': 'iHeartRadio.png',
    'JioSaavn': 'JioSaavn.png',
    'JOOX': 'JOOX.jpg',
    'Kan Music': 'Kan Music.jpg',
    'KDM(K Digital Media)': 'KDM(K Digital Media).png',
    'KK Box': 'KK Box.png',
    'LiveOne': 'LiveOne.jpg',
    'Medianet': 'Medianet.png',
    'Mixcloud': 'Mixcloud.svg',
    'Mood Media': 'Mood Media.svg',
    'Pandora': 'Pandora.png',
    'Peloton': 'Peloton.png',
    'Pretzel': 'Pretzel.png',
    'Qobuz': 'Qobuz.jpg',
    'Resso': 'Resso.png',
    'Soundcloud': 'soundcloud.png',
    'Spotify': 'spotify.png',
    'Tidal': 'tidal.png',
    'TikTok': 'tiktok.png',
    'TouchTunes': 'TouchTunes.jpg',
    'Trebel': 'Trebel.png',
    'Tuned Global': 'Tuned Global.png',
    'USEA': 'USEA.png',
    'VL Group': 'VL Group.webp',
    'YouSee': 'YouSee.png',
    'YouTube': 'youtube.png',
  };

  // Additional icons for special platforms
  final Map<String, List<String>> additionalIcons = {
    'Meta': ['Facebook.png', 'instagram.png'],
    'Apple': ['Apple Music.png', 'shazam.png'],
  };

  // Additional descriptions for special platforms
  final Map<String, String> platformDescriptions = {
    'Meta': 'Includes Instagram & Facebook',
    'Apple': 'Includes Apple Music & Shazam',
    'YouTube': 'Includes Content ID & Art Tracks',
  };

  late Map<String, bool> selectedPlatforms;
  late List<String> selectedStores;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  bool useSpecificTime = false;
  bool useRollingRelease = true;
  String selectedTimeZone = 'UTC';
  final bool _hasUnsavedChanges = false;
  String _currentState = 'Draft';
  bool _isLoading = false;

  // --- VALIDATION HELPERS ---
  String? _validateProduct(Product product) {
    if (product.releaseTitle.isEmpty) return 'Release title is required.';
    if (product.productArtists.isEmpty)
      return 'At least one primary artist name is required.';
    if (product.productArtistIds == null || product.productArtistIds!.isEmpty)
      return 'At least one primary artist ID is required.';
    if (product.genre.isEmpty) return 'Genre is required.';
    if (product.subgenre.isEmpty) return 'Subgenre is required.';
    if (product.label.isEmpty) return 'Label name is required.';
    if (product.cLine.isEmpty) return 'C Line is required.';
    if (product.pLine.isEmpty) return 'P Line is required.';
    if (product.price.isEmpty) return 'Price tier is required.';
    if (product.coverImage.isEmpty) return 'Artwork is required.';
    if (product.type.isEmpty) return 'Product type is required.';
    if (product.metadataLanguage.isEmpty)
      return 'Metadata language is required.';
    return null;
  }

  String? _validateTrack(Track track, int index) {
    if (track.title.isEmpty) return 'Track ${index + 1}: Title is required.';
    if (track.primaryArtists.isEmpty)
      return 'Track ${index + 1}: At least one primary artist name is required.';
    if (track.primaryArtistIds == null || track.primaryArtistIds!.isEmpty)
      return 'Track ${index + 1}: At least one primary artist ID is required.';
    if (track.downloadUrl.isEmpty)
      return 'Track ${index + 1}: File URL is required.';
    if (track.performersWithRoles.isEmpty)
      return 'Track ${index + 1}: At least one performer is required.';
    if (track.productionWithRoles.isEmpty)
      return 'Track ${index + 1}: At least one producer is required.';
    if (track.songwritersWithRoles.isEmpty)
      return 'Track ${index + 1}: At least one songwriter is required.';
    if (track.ownership == null || track.ownership!.isEmpty)
      return 'Track ${index + 1}: Ownership is required.';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadProductState();
    selectedPlatforms = {for (var platform in platforms) platform: true};
    selectedStores = List.from(platforms);
  }

  Future<void> _loadProductState() async {
    try {
      final user = auth.getUser();
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final productData = await api.getProduct(
        user.uid,
        widget.projectId,
        widget.productId,
      );

      if (productData != null && mounted) {
        setState(() {
          _currentState = productData['state'] ?? 'Draft';

          // Load release date and time
          if (productData['releaseDate'] != null) {
            selectedDate = DateTime.parse(productData['releaseDate']);
          }

          // Load time if specified
          if (productData['releaseTime'] != null) {
            final timeParts = productData['releaseTime'].split(':');
            if (timeParts.length == 2) {
              selectedTime = TimeOfDay(
                hour: int.parse(timeParts[0]),
                minute: int.parse(timeParts[1]),
              );
              useSpecificTime = true;
            }
          }

          // Load rolling release preference
          useRollingRelease = productData['useRollingRelease'] ?? true;

          // Load time zone if not using rolling release
          if (!useRollingRelease && productData['timeZone'] != null) {
            selectedTimeZone = productData['timeZone'];
          }

          // Load selected platforms
          if (productData['platformsSelected'] != null) {
            final platformsData = List<Map<String, dynamic>>.from(
              productData['platformsSelected'],
            );
            selectedStores =
                platformsData.map((p) => p['name'] as String).toList();
            selectedPlatforms = {
              for (var platform in platforms)
                platform: selectedStores.contains(platform),
            };
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _distributeProduct() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a release date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = auth.getUser();
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // --- FETCH PRODUCT OBJECT (replace this with your actual fetch logic) ---
      final product = await api.getProductObject(
        user.uid,
        widget.projectId,
        widget.productId,
      );
      if (product == null) {
        throw Exception('Product not found');
      }
      // --- SKIP PRODUCT VALIDATION AS REQUESTED ---
      // final productError = _validateProduct(product);
      // if (productError != null) {
      //   setState(() { _isLoading = false; });
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text(productError), backgroundColor: Colors.red),
      //   );
      //   return;
      // }
      // --- VALIDATE TRACKS ---
      // for (int i = 0; i < product.songs.length; i++) {
      //     final trackError = _validateTrack(product.songs[i], i);
      //    if (trackError != null) {
      //       setState(() { _isLoading = false; });
      //        ScaffoldMessenger.of(context).showSnackBar(
      //          SnackBar(content: Text(trackError), backgroundColor: Colors.red),
      //        );
      //         return;
      //      }
      //     }

      await api.distributeProduct(
        user.uid,
        widget.projectId,
        widget.productId,
        selectedStores,
        selectedDate!,
        useSpecificTime ? selectedTime : null,
        useRollingRelease,
        !useRollingRelease ? selectedTimeZone : null,
      );

      if (mounted) {
        setState(() {
          _currentState = 'Processing';
          _isLoading = false;
        });

        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DistributionSuccessScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error distributing product: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool _canDistribute() {
    return _currentState == 'Draft' &&
        selectedDate != null &&
        selectedStores.isNotEmpty;
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);

      if (useSpecificTime) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() => selectedTime = pickedTime);
        }
      }
    }
  }

  String _formatDateTime() {
    if (selectedDate == null) return 'Select Release Date';

    String dateStr =
        '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

    if (useSpecificTime && selectedTime != null) {
      dateStr +=
          ' ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
      if (!useRollingRelease) {
        dateStr += ' $selectedTimeZone';
      }
    }

    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    // Use safer layout structure for mobile to prevent flex/constraint errors
    return widget.isMobile ? _buildMobileLayout() : _buildDesktopLayout();
  }

  // Optimized layout for mobile to avoid flex constraint issues
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Release Date/Time Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _formatDateTime(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message:
                                'For best results, schedule your release 1-3 weeks in advance to ensure proper distribution across all platforms.',
                            child: Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time options always stacked in column for mobile
                  _buildSpecificTimeSection(),
                  if (useSpecificTime) _buildRollingReleaseSection(),

                  if (useSpecificTime && !useRollingRelease)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildTimeZoneDropdown(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stores Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Stores:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: fontNameSemiBold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      final bool allSelected =
                          selectedStores.length == platforms.length;
                      for (var platform in platforms) {
                        selectedPlatforms[platform] = !allSelected;
                      }
                      selectedStores = allSelected ? [] : List.from(platforms);
                    });
                  },
                  icon: Icon(
                    selectedStores.length == platforms.length
                        ? Icons.deselect
                        : Icons.select_all,
                    color: Colors.blue,
                    size: 20,
                  ),
                  label: Text(
                    selectedStores.length == platforms.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fixed height grid to avoid layout issues
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.5, // Fixed height for grid
              child: GridView.builder(
                physics:
                    const ScrollPhysics(), // Allow scrolling within the grid
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns for mobile
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 60,
                ),
                shrinkWrap: true, // Important to prevent unbounded height
                itemCount: platforms.length,
                itemBuilder: (context, index) {
                  final platform = platforms[index];
                  final hasAdditionalIcons = additionalIcons.containsKey(
                    platform,
                  );

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            selectedPlatforms[platform] == true
                                ? Colors.blue
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedPlatforms[platform] =
                              !(selectedPlatforms[platform] ?? false);
                          if (selectedPlatforms[platform] == true) {
                            selectedStores.add(platform);
                          } else {
                            selectedStores.remove(platform);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (hasAdditionalIcons)
                                  Row(
                                    children:
                                        additionalIcons[platform]!
                                            .map(
                                              (icon) => Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 4,
                                                ),
                                                child: ExtendedImage.asset(
                                                  'assets/images/dsps/$icon',
                                                  width: 36,
                                                  height: 36,
                                                  border: Border.all(
                                                    color: Colors.transparent,
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                  shape: BoxShape.rectangle,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  )
                                else
                                  ExtendedImage.asset(
                                    'assets/images/dsps/${platformIcons[platform]}',
                                    width: 40,
                                    height: 40,
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        platform,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasAdditionalIcons)
                                        Text(
                                          platformDescriptions[platform]!,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 9,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (selectedPlatforms[platform] == true)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Save Button
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${selectedStores.length} stores selected',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow:
                          _canDistribute()
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF9D6BFF,
                                  ).withOpacity(0.5),
                                  spreadRadius: 0,
                                  blurRadius: 12,
                                  offset: const Offset(0, 0),
                                ),
                              ]
                              : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _canDistribute() ? _distributeProduct : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canDistribute()
                                ? const Color(0xFF2D2D3A)
                                : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentState == 'Draft' ? 'Distribute' : 'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: fontNameSemiBold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Original layout for desktop
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Release Date/Time Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _selectDateTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Tooltip(
                                message:
                                    'For best results, schedule your release 1-3 weeks in advance to ensure proper distribution across all platforms.',
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.grey.shade400,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildSpecificTimeSection()),
                          if (useSpecificTime)
                            Expanded(child: _buildRollingReleaseSection()),
                        ],
                      ),
                      if (useSpecificTime && !useRollingRelease)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _buildTimeZoneDropdown(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stores Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Stores:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: fontNameSemiBold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          final bool allSelected =
                              selectedStores.length == platforms.length;
                          for (var platform in platforms) {
                            selectedPlatforms[platform] = !allSelected;
                          }
                          selectedStores =
                              allSelected ? [] : List.from(platforms);
                        });
                      },
                      icon: Icon(
                        selectedStores.length == platforms.length
                            ? Icons.deselect
                            : Icons.select_all,
                        color: Colors.blue,
                        size: 20,
                      ),
                      label: Text(
                        selectedStores.length == platforms.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Grid View
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: 60,
                        ),
                    itemCount: platforms.length,
                    itemBuilder: (context, index) {
                      final platform = platforms[index];
                      final hasAdditionalIcons = additionalIcons.containsKey(
                        platform,
                      );

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1B2C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                selectedPlatforms[platform] == true
                                    ? Colors.blue
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedPlatforms[platform] =
                                  !(selectedPlatforms[platform] ?? false);
                              if (selectedPlatforms[platform] == true) {
                                selectedStores.add(platform);
                              } else {
                                selectedStores.remove(platform);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (hasAdditionalIcons)
                                      Row(
                                        children:
                                            additionalIcons[platform]!
                                                .map(
                                                  (icon) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          right: 4,
                                                        ),
                                                    child: ExtendedImage.asset(
                                                      'assets/images/dsps/$icon',
                                                      width: 36,
                                                      height: 36,
                                                      border: Border.all(
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                            Radius.circular(8),
                                                          ),
                                                      shape: BoxShape.rectangle,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                      )
                                    else
                                      ExtendedImage.asset(
                                        'assets/images/dsps/${platformIcons[platform]}',
                                        width: 40,
                                        height: 40,
                                        border: Border.all(
                                          color: Colors.transparent,
                                        ),
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                        shape: BoxShape.rectangle,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            platform,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (hasAdditionalIcons)
                                            Text(
                                              platformDescriptions[platform]!,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 9,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selectedPlatforms[platform] == true)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Save Button
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${selectedStores.length} stores selected',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    if (_isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow:
                              _canDistribute()
                                  ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF9D6BFF,
                                      ).withOpacity(0.5),
                                      spreadRadius: 0,
                                      blurRadius: 12,
                                      offset: const Offset(0, 0),
                                    ),
                                  ]
                                  : [],
                        ),
                        child: ElevatedButton(
                          onPressed:
                              _canDistribute() ? _distributeProduct : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _canDistribute()
                                    ? const Color(0xFF2D2D3A)
                                    : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentState == 'Draft' ? 'Distribute' : 'Save',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: fontNameSemiBold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Extract time section for reuse
  Widget _buildSpecificTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text(
            'Specific Time',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: fontNameBold,
            ),
          ),
          value: useSpecificTime,
          onChanged: (bool? value) {
            setState(() {
              useSpecificTime = value ?? false;
              if (!useSpecificTime) {
                selectedTime = null;
                useRollingRelease = false;
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        if (useSpecificTime)
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: InkWell(
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() => selectedTime = pickedTime);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade700),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedTime?.format(context) ?? 'Select Time',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Extract rolling release section for reuse
  Widget _buildRollingReleaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Row(
            children: [
              const Text(
                'Rolling Release',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: fontNameBold,
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'When enabled, your release will be available at the specified time in each time zone. For example, if you set 00:00, it will be released at midnight in each region.',
                child: Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ),
            ],
          ),
          value: useRollingRelease,
          onChanged: (bool? value) {
            setState(() => useRollingRelease = value ?? true);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const Padding(
          padding: EdgeInsets.only(left: 32.0),
          child: Text(
            'Release at the specified time in each time zone',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Extract timezone dropdown for reuse
  Widget _buildTimeZoneDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: fontNameBold),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedTimeZone,
        decoration: InputDecoration(
          labelText: 'Time Zone',
          labelStyle: TextStyle(
            color: Colors.grey.shade400,
            fontFamily: fontNameBold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          filled: true,
          fillColor: const Color(0xFF1E1B2C),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(color: Colors.white, fontFamily: fontNameBold),
        dropdownColor: const Color(0xFF1E1B2C),
        borderRadius: BorderRadius.circular(20),
        items:
            timeZones.map((tz) {
              return DropdownMenuItem<String>(
                value: tz['value']!,
                child: Text(
                  tz['display']!,
                  style: const TextStyle(fontFamily: fontNameBold),
                ),
              );
            }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() => selectedTimeZone = newValue);
          }
        },
      ),
    );
  }
}

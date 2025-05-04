import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenHomepageButton extends StatelessWidget {
  const OpenHomepageButton({super.key});

  Future<void> _launchHomepage() async {
    const String homepageUrl = 'https://www.matter.lat';
    final Uri uri = Uri.parse(homepageUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $homepageUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFF4361EE), size: 32),
      tooltip: 'Back to Matter Homepage',
      onPressed: _launchHomepage,
      splashRadius: 24,
    );
  }
}

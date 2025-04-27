import 'package:flutter/material.dart';
import 'package:portal/Constants/fonts.dart';

class UnderConstructionOverlay extends StatelessWidget {
  final Widget child;
  final bool show;

  const UnderConstructionOverlay({
    super.key,
    required this.child,
    required this.show,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return child;
    }

    return Stack(
      children: [
        child,
        Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3A1C71),
                    Color(0xFFD76D77),
                    Color(0xFFFFAF7B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "This Feature is Under Construction",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontNameBold,
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We're working hard to bring you this feature soon. Stay tuned for updates!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontName,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          "Coming Soon",
                          style: TextStyle(
                            fontFamily: fontNameSemiBold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

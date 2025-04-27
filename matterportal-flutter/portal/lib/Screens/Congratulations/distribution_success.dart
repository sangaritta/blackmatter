import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:portal/Constants/fonts.dart';

class DistributionSuccessScreen extends StatefulWidget {
  const DistributionSuccessScreen({super.key});

  @override
  State<DistributionSuccessScreen> createState() =>
      _DistributionSuccessScreenState();
}

class _DistributionSuccessScreenState extends State<DistributionSuccessScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B1F),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF1DB954),
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontFamily: fontNameBold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your release has been submitted for distribution',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontFamily: fontNameSemiBold,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Back to My Catalog',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: fontNameBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:portal/Screens/Finance/finance_dashboard.dart';
import 'package:portal/Widgets/Common/under_construction_overlay.dart';
import 'package:portal/main.dart';

class BankScreen extends StatelessWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UnderConstructionOverlay(
      show: showUnderConstructionOverlay,
      child: const FinanceDashboard(),
    );
  }
}

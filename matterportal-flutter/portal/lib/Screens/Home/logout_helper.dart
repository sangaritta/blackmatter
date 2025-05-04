import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:portal/Services/auth_service.dart';

// Helper class to handle the logout process safely
class LogoutHelper {
  // Method to handle logout and navigation
  static Future<void> performLogout(BuildContext context) async {
    try {
      // Get the BuildContext that will be used for navigation
      final BuildContext rootContext = GoRouter.of(context).routerDelegate.navigatorKey.currentContext!;
      
      // Sign out from Firebase Auth
      await auth.signOut();
      
      // Schedule the navigation to happen in the next frame to avoid widget tree issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (rootContext.mounted) {
          GoRouter.of(rootContext).go('/login');
        }
      });
    } catch (e) {
      debugPrint('Error during logout: $e');
      // In case of error, still try to navigate to login
      if (context.mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }
}

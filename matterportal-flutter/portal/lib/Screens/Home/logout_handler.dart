import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:portal/Services/auth_service.dart';

class LogoutHandler {
  static Future<void> logout(BuildContext context) async {
    try {
      // Get the router context before doing anything
      final router = GoRouter.of(context);
      
      // Sign out the user
      await auth.signOut();
      
      // Navigate to login screen after a short delay to ensure all logout processes complete
      Future.delayed(const Duration(milliseconds: 100), () {
        router.go('/login');
      });
    } catch (e) {
      debugPrint('Logout error: $e');
      // Try to navigate anyway
      GoRouter.of(context).go('/login');
    }
  }
}

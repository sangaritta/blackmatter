import 'package:flutter/material.dart';
import 'package:portal/main.dart';
import 'package:portal/Services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:portal/Services/api_service.dart';
import 'package:portal/Services/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isNotificationsEnabled = true;
  final User? currentUser = auth.getUser();
  Map<String, dynamic> _userProfile = {};
  bool _isLoadingProfile = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _appVersion = '';

  // Profile edit controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  // Password change controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadSettings() async {
    isNotificationsEnabled = await settingsService.getNotificationsEnabled();
    setState(() {});
  }

  Future<void> _loadUserProfile() async {
    if (currentUser != null) {
      setState(() => _isLoadingProfile = true);

      try {
        final userProfile = await api.getUserProfile(currentUser!.uid);

        setState(() {
          _userProfile = userProfile;
          _firstNameController.text = userProfile['firstName'] ?? '';
          _lastNameController.text = userProfile['lastName'] ?? '';
          _isLoadingProfile = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingProfile = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      // If there's an error, use a default version
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      await _uploadProfileImage();
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_imageFile == null || currentUser == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading profile image...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${currentUser!.uid}.jpg');

      await storageRef.putFile(_imageFile!);
      final imageUrl = await storageRef.getDownloadURL();

      // Update Firestore and Auth profile
      await api.updateUserProfile(currentUser!.uid, {'photoURL': imageUrl});
      await currentUser!.updatePhotoURL(imageUrl);

      // Update local state
      setState(() {
        _userProfile['photoURL'] = imageUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update profile image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final firstName = _firstNameController.text.trim();
              final lastName = _lastNameController.text.trim();

              if (firstName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('First name cannot be empty')),
                );
                return;
              }

              try {
                // Update Firestore
                await api.updateUserProfile(currentUser!.uid, {
                  'firstName': firstName,
                  'lastName': lastName,
                  'displayName':
                      '$firstName ${lastName.isNotEmpty ? lastName : ''}'
                          .trim(),
                });

                // Update Firebase Auth display name
                await currentUser!.updateDisplayName(
                    '$firstName ${lastName.isNotEmpty ? lastName : ''}'.trim());

                // Update local state
                setState(() {
                  _userProfile['firstName'] = firstName;
                  _userProfile['lastName'] = lastName;
                  _userProfile['displayName'] =
                      '$firstName ${lastName.isNotEmpty ? lastName : ''}'
                          .trim();
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Failed to update profile: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    // Validate inputs
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Password must be at least 6 characters long');
      return;
    }

    try {
      // Reauthenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser?.email ?? '',
        password: _currentPasswordController.text,
      );

      await currentUser?.reauthenticateWithCredential(credential);

      // Change password
      await currentUser?.updatePassword(_newPasswordController.text);

      // Clear controllers
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Show success message
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(_getErrorMessage(e.code));
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again later.');
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'wrong-password':
        return 'Current password is incorrect';
      case 'weak-password':
        return 'Password is too weak';
      case 'requires-recent-login':
        return 'Please log out and log back in before changing your password';
      default:
        return 'An error occurred ($errorCode)';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Error', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK',
                style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Change Password',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.purpleAccent),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('CHANGE PASSWORD'),
          ),
        ],
      ),
    );
  }

  void _navigateToSecurityScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SecurityScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName =
        _userProfile['displayName'] ?? currentUser?.displayName ?? 'User';
    final String? photoURL = _userProfile['photoURL'] ?? currentUser?.photoURL;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with full width gradient
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 70,
                  bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade800,
                    Colors.deepPurple.shade900,
                    Colors.black
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        // Profile image
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: photoURL != null
                              ? NetworkImage(photoURL) as ImageProvider
                              : null,
                          child: photoURL == null
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade200,
                                )
                              : null,
                        ),
                        // Edit icon - positioned more visibly
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    currentUser?.email ?? 'No email',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    onPressed: _showEditProfileDialog,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account settings
            _buildSettingsSection(
              title: 'Account Settings',
              icon: Icons.person_outline,
              children: [
                _buildSettingsTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: _showChangePasswordDialog,
                ),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: 'Manage login sessions and security options',
                  onTap: _navigateToSecurityScreen,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // App settings
            _buildSettingsSection(
              title: 'App Settings',
              icon: Icons.settings_outlined,
              children: [
                _buildSettingsSwitch(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Enable push notifications',
                  value: isNotificationsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      isNotificationsEnabled = value;
                    });
                    await settingsService.setNotificationsEnabled(value);
                  },
                ),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Set your preferred language',
                  onTap: () {
                    // Show language options
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Developer options
            _buildSettingsSection(
              title: 'Developer Options',
              icon: Icons.code,
              children: [
                _buildSettingsSwitch(
                  icon: Icons.construction,
                  title: 'Construction Overlay',
                  subtitle: 'Show "Under Construction" elements',
                  value: showUnderConstructionOverlay,
                  onChanged: (value) async {
                    setState(() {
                      showUnderConstructionOverlay = value;
                    });
                    await settingsService.setUnderConstructionOverlay(value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await auth.signOut();
                  if (mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red.shade800,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // App version
            Text(
              'BlackMatter Portal $_appVersion',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _buildSettingsSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;
  final String _noSessionsMessage =
      'No active login sessions found.\n\nThis feature requires session tracking to be enabled for your account. Your administrator may need to configure this feature.';
  StreamSubscription<QuerySnapshot>? _sessionsSubscription;
  bool _isTerminatingAll = false;

  @override
  void initState() {
    super.initState();
    _startSessionsStream();
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    super.dispose();
  }

  void _startSessionsStream() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = auth.getUser()?.uid;
      if (userId == null) {
        setState(() {
          _errorMessage = 'You must be logged in to view sessions';
          _isLoading = false;
        });
        return;
      }

      _sessionsSubscription = FirebaseFirestore.instance
          .collection('user_sessions')
          .doc(userId)
          .collection('sessions')
          .orderBy('lastActivityAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final sessions = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          _errorMessage =
              'Error loading sessions: ${error.toString().replaceAll(RegExp(r'\[.*?\]'), '')}';
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to load session data: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSessions() async {
    // Refresh the stream
    _sessionsSubscription?.cancel();
    _startSessionsStream();
  }

  Future<void> _terminateSession(String sessionId) async {
    try {
      await api.terminateSession(sessionId);
      // The stream will automatically update the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session terminated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to terminate session: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}')),
        );
      }
    }
  }

  Future<void> _terminateAllSessions() async {
    if (_sessions.length <= 1) return;

    setState(() {
      _isTerminatingAll = true;
    });

    try {
      // Get all sessions except the current one (assumed to be first in the list)
      final sessionsToTerminate = _sessions.skip(1).toList();

      if (sessionsToTerminate.isEmpty) {
        setState(() {
          _isTerminatingAll = false;
        });
        return;
      }

      // Show confirmation dialog
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text(
            'End All Other Sessions?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will end ${sessionsToTerminate.length} session(s) on all other devices. This action cannot be undone.',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child:
                  const Text('END ALL', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (shouldProceed != true) {
        setState(() {
          _isTerminatingAll = false;
        });
        return;
      }

      // Terminate all other sessions
      for (final session in sessionsToTerminate) {
        await api.terminateSession(session['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Ended ${sessionsToTerminate.length} session(s) successfully'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to end all sessions: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      setState(() {
        _isTerminatingAll = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSessions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: _sessions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.security_outlined,
                                    size: 64, color: Colors.grey.shade600),
                                const SizedBox(height: 16),
                                Text(
                                  _noSessionsMessage,
                                  style: const TextStyle(color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                  onPressed: _loadSessions,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side:
                                        BorderSide(color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // Only show "End All Other Sessions" button if we have more than 1 session
                            if (_sessions.length > 1)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: _isTerminatingAll
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.logout_rounded,
                                            color: Colors.black),
                                    label: Text(
                                      _isTerminatingAll
                                          ? 'Ending sessions...'
                                          : 'End All Other Sessions (${_sessions.length - 1})',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade400,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      disabledBackgroundColor:
                                          Colors.grey.shade600,
                                    ),
                                    onPressed: _isTerminatingAll
                                        ? null
                                        : _terminateAllSessions,
                                  ),
                                ),
                              ),

                            // Session list
                            Expanded(
                              child: ListView.builder(
                                itemCount: _sessions.length,
                                itemBuilder: (context, index) {
                                  final session = _sessions[index];
                                  // Determine if this is the current session
                                  final bool isCurrentSession = index ==
                                      0; // For simplicity, assume most recent is current

                                  return _buildSessionCard(
                                      session, isCurrentSession);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security_update_warning,
                size: 56, color: Colors.orange.shade800),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _loadSessions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(
      Map<String, dynamic> session, bool isCurrentSession) {
    // Get location data
    Map<String, dynamic> locationData = session['lastLocation'] ?? {};
    double? latitude = locationData['latitude'] as double?;
    double? longitude = locationData['longitude'] as double?;
    bool hasLocation = latitude != null && longitude != null;

    // Get device info
    Map<String, dynamic> deviceInfo = session['deviceInfo'] ?? {};

    // Format the device model - convert "BrowserName.NAME Win32" to "NAME on Windows"
    String deviceModel = deviceInfo['model'] ?? 'Unknown';
    if (deviceModel.startsWith('BrowserName.') &&
        deviceModel.endsWith('Win32')) {
      final browserName = deviceModel.substring(
          'BrowserName.'.length, deviceModel.length - ' Win32'.length);
      deviceModel = '$browserName on Windows';
    }

    String devicePlatform =
        deviceInfo['platform'] ?? session['platform'] ?? 'Unknown';
    String deviceVersion = deviceInfo['version'] ?? 'Unknown';

    // Format dates
    String createdAt = session['createdAt'] != null
        ? DateFormat('MMM d, yyyy - h:mm a')
            .format((session['createdAt'] as Timestamp).toDate())
        : 'Unknown';

    String lastActive = session['lastActivityAt'] != null
        ? DateFormat('MMM d, yyyy - h:mm a')
            .format((session['lastActivityAt'] as Timestamp).toDate())
        : 'Unknown';

    String expiresAt = session['expiresAt'] != null
        ? DateFormat('MMM d, yyyy - h:mm a')
            .format((session['expiresAt'] as Timestamp).toDate())
        : 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with device info & status badge
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    deviceModel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                if (isCurrentSession)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current Session',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Platform: $devicePlatform',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                if (session['sessionId'] != null)
                  Text(
                    'Session ID: ${session['sessionId']}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey.shade800),

          // Location map if available
          if (hasLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(latitude, longitude),
                          initialZoom: 10,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(latitude, longitude),
                                width: 80,
                                height: 80,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    api.getFormattedLocation(session),
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (locationData['ip'] != null)
                    Text(
                      'IP: ${locationData['ip']}',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

          // Session details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Session Details'),
                const SizedBox(height: 8),
                _buildDetailRow('Created:', createdAt),
                _buildDetailRow('Last Activity:', lastActive),
                _buildDetailRow('Expires:', expiresAt),
                _buildDetailRow(
                    'Login Type:', session['loginType'] ?? 'Unknown'),
                _buildDetailRow('Login Attempts:',
                    (session['loginAttempts'] ?? 0).toString()),
                _buildDetailRow(
                    'User Agent:', session['userAgent'] ?? deviceVersion),
                _buildDetailRow('Status:',
                    (session['isValid'] ?? true) ? 'Valid' : 'Invalid'),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Action buttons
          if (!isCurrentSession)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  label: const Text(
                    'End Session',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _terminateSession(session['id']),
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

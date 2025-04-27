import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:portal/Services/device_info.dart'
    if (kIsWeb) 'device_info_web.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import Flutter Secure Storage
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
export 'device_info.dart' if (kIsWeb) 'device_info_web.dart';

class AuthenticationService {
  AuthenticationService() {
    // Get existing instances - DO NOT initialize
    _fireAuth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _secureStorage = const FlutterSecureStorage();
  }

  late final FirebaseAuth _fireAuth;
  late final FirebaseFirestore _firestore;
  late final FlutterSecureStorage _secureStorage;

  static const int maxConcurrentSessions = 5;

  Future<void> signIn(String username, String password) async {
    try {
      // First authenticate with Firebase Auth
      UserCredential userCredential = await _fireAuth
          .signInWithEmailAndPassword(email: username, password: password);

      // Verify the user is properly authenticated
      User? currentUser = _fireAuth.currentUser;
      if (currentUser == null || currentUser.uid != userCredential.user!.uid) {
        throw FirebaseAuthException(
          code: 'auth-error',
          message: 'Authentication failed',
        );
      }

      // Create the session
      await _createSession(userCredential.user!.uid);

      // NO PERMISSION REQUEST HERE!
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      // Convert general exceptions to FirebaseAuthException for consistent handling
      throw FirebaseAuthException(
        code: 'session-error',
        message: 'Failed to create session: ${e.toString()}',
      );
    }
  }

  Future<void> _createSession(String userId) async {
    // Add error handling and retry logic
    int retryCount = 0;
    Exception? lastError;

    while (retryCount < 3) {
      try {
        // Verify user is still authenticated
        if (_fireAuth.currentUser == null) {
          throw Exception('User not authenticated');
        }

        final deviceInfo = await _getDeviceInfo();
        final ipAddress = await _getIpAddress();
        final sessionId = const Uuid().v4();
        final expiresAt = DateTime.now().add(const Duration(days: 7));

        // First enforce session limit
        await _enforceSessionLimit(userId);

        // Create the session document
        await _firestore
            .collection('user_sessions')
            .doc(userId)
            .collection('sessions')
            .doc(sessionId)
            .set({
              'deviceInfo': deviceInfo,
              'ipAddress': ipAddress,
              'createdAt': FieldValue.serverTimestamp(),
              'lastActivityAt': FieldValue.serverTimestamp(),
              'expiresAt': Timestamp.fromDate(expiresAt),
              'isValid': true,
              'sessionId': sessionId,
              'userAgent':
                  deviceInfo['version'] ??
                  'Unknown', // Use version as userAgent
              'loginType': 'email',
              'activityCount': 0,
              'lastLocation': await _getLocationInfo(ipAddress),
              'deviceType': deviceInfo['deviceType'] ?? 'Unknown',
              'platform': deviceInfo['platform'] ?? 'Unknown',
              'loginAttempts': 1,
            });

        // Store session locally only after successful Firestore write
        await _secureStorage.write(key: 'sessionId', value: sessionId);
        await _secureStorage.write(
          key: 'sessionExpiry',
          value: expiresAt.toIso8601String(),
        );

        // Update analytics last, as it's less critical
        try {
          await _updateUserSessionAnalytics(userId);
        } catch (e) {
          // Don't throw error for analytics failure
          //ogger.w('Analytics update failed: ${e.toString()}');
        }

        // If we get here, everything worked
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        //ogger.e(
        //  'Session creation attempt ${retryCount + 1} failed: ${e.toString()}');
        retryCount++;
        if (retryCount >= 3) {
          throw Exception(
            'Failed to create session after 3 attempts: ${lastError.toString()}',
          );
        }
        // Wait before retrying
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
  }

  Future<void> _enforceSessionLimit(String userId) async {
    try {
      // Check if the user document exists
      DocumentReference userSessionsRef = _firestore
          .collection('user_sessions')
          .doc(userId);
      DocumentSnapshot userSessionsDoc = await userSessionsRef.get();

      // If the document does not exist, create it
      if (!userSessionsDoc.exists) {
        try {
          await userSessionsRef.set({
            'createdAt': FieldValue.serverTimestamp(),
            'lastActivityAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          //logger.e('Error creating user session document: ${e.toString()}');
          // Still continue with the process rather than failing completely
        }
      }

      // Now proceed to get the sessions with timeout handling
      QuerySnapshot sessions;
      try {
        sessions = await userSessionsRef
            .collection('sessions')
            .where('isValid', isEqualTo: true)
            .orderBy('lastActivityAt')
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Session query timed out');
              },
            );
      } catch (e) {
        //ogger.e('Error fetching sessions: ${e.toString()}');
        // If we can't get sessions, don't fail the login - assume no sessions exist
        return;
      }

      if (sessions.docs.length >= maxConcurrentSessions) {
        // Remove oldest sessions to maintain limit
        int sessionsToRemove = sessions.docs.length - maxConcurrentSessions + 1;
        for (int i = 0; i < sessionsToRemove; i++) {
          try {
            if (i < sessions.docs.length) {
              await invalidateSession(userId, sessions.docs[i]['sessionId']);
            }
          } catch (e) {
            //logger.e('Error invalidating old session: ${e.toString()}');
            // Continue to the next session rather than failing completely
          }
        }
      }
    } catch (e) {
      // Log error but don't prevent login
      //logger.e('Session limit enforcement error: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> _getLocationInfo(String ipAddress) async {
    try {
      final response = await http.get(
        Uri.parse('https://ipapi.co/$ipAddress/json/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'ip': data['ip'] ?? 'Unknown',
          'network': data['network'] ?? 'Unknown',
          'version': data['version'] ?? 'Unknown',
          'city': data['city'] ?? 'Unknown',
          'region': data['region'] ?? 'Unknown',
          'region_code': data['region_code'] ?? 'Unknown',
          'country': data['country'] ?? 'Unknown',
          'country_name': data['country_name'] ?? 'Unknown',
          'country_code': data['country_code'] ?? 'Unknown',
          'country_code_iso3': data['country_code_iso3'] ?? 'Unknown',
          'country_capital': data['country_capital'] ?? 'Unknown',
          'country_tld': data['country_tld'] ?? 'Unknown',
          'continent_code': data['continent_code'] ?? 'Unknown',
          'in_eu': data['in_eu'] ?? false,
          'postal': data['postal'] ?? 'Unknown',
          'latitude': data['latitude'] ?? 0.0,
          'longitude': data['longitude'] ?? 0.0,
          'timezone': data['timezone'] ?? 'Unknown',
          'utc_offset': data['utc_offset'] ?? 'Unknown',
          'country_calling_code': data['country_calling_code'] ?? 'Unknown',
          'currency': data['currency'] ?? 'Unknown',
          'currency_name': data['currency_name'] ?? 'Unknown',
          'languages': data['languages'] ?? 'Unknown',
          'country_area': data['country_area'] ?? 0.0,
          'country_population': data['country_population'] ?? 0,
          'asn': data['asn'] ?? 'Unknown',
          'org': data['org'] ?? 'Unknown',
        };
      }
    } catch (e) {
      // Handle error silently and return default values
    }
    return {
      'ip': 'Unknown',
      'network': 'Unknown',
      'version': 'Unknown',
      'city': 'Unknown',
      'region': 'Unknown',
      'region_code': 'Unknown',
      'country': 'Unknown',
      'country_name': 'Unknown',
      'country_code': 'Unknown',
      'country_code_iso3': 'Unknown',
      'country_capital': 'Unknown',
      'country_tld': 'Unknown',
      'continent_code': 'Unknown',
      'in_eu': false,
      'postal': 'Unknown',
      'latitude': 0.0,
      'longitude': 0.0,
      'timezone': 'Unknown',
      'utc_offset': 'Unknown',
      'country_calling_code': 'Unknown',
      'currency': 'Unknown',
      'currency_name': 'Unknown',
      'languages': 'Unknown',
      'country_area': 0.0,
      'country_population': 0,
      'asn': 'Unknown',
      'org': 'Unknown',
    };
  }

  Future<void> _updateUserSessionAnalytics(String userId) async {
    DocumentReference userAnalyticsRef = _firestore
        .collection('user_analytics')
        .doc(userId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot userAnalytics = await transaction.get(userAnalyticsRef);

      if (!userAnalytics.exists) {
        transaction.set(userAnalyticsRef, {
          'totalSessions': 1,
          'lastLogin': FieldValue.serverTimestamp(),
          'activeSessions': 1,
          'deviceTypes': {},
          'loginLocations': {},
        });
      } else {
        Map<String, dynamic> data =
            userAnalytics.data() as Map<String, dynamic>;
        transaction.update(userAnalyticsRef, {
          'totalSessions': (data['totalSessions'] ?? 0) + 1,
          'lastLogin': FieldValue.serverTimestamp(),
          'activeSessions': (data['activeSessions'] ?? 0) + 1,
        });
      }
    });
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    return getDeviceInfo();
  }

  Future<String> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      return response.body;
    } catch (e) {
      return 'Unknown';
    }
  }

  // Modify the signOut method to update the auth state
  Future<void> signOut() async {
    try {
      User? currentUser = _fireAuth.currentUser;
      if (currentUser != null) {
        // Retrieve the session ID from local storage or a secure place
        String? currentSessionId = await _getCurrentSessionId();

        if (currentSessionId != null) {
          await _firestore
              .collection('user_sessions')
              .doc(currentUser.uid)
              .collection('sessions')
              .doc(currentSessionId)
              .update({'isValid': false});
        }
      }
      // Sign out the user
      _fireAuth.signOut();
      _authStateController.add(false);
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to retrieve the current session ID
  Future<String?> _getCurrentSessionId() async {
    return await _secureStorage.read(
      key: 'sessionId',
    ); // Retrieve the session ID from secure storage
  }

  Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    QuerySnapshot sessions =
        await _firestore
            .collection('user_sessions')
            .doc(userId)
            .collection('sessions')
            .orderBy('createdAt', descending: true)
            .get();

    return sessions.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> invalidateSession(String userId, String sessionId) async {
    try {
      await _firestore
          .collection('user_sessions')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .update({'isValid': false})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Session invalidation timed out');
            },
          );
    } catch (e) {
      //logger.e('Error invalidating session $sessionId: ${e.toString()}');
      // Rethrow to allow caller to decide whether to fail or continue
      rethrow;
    }
  }

  Future<bool> isSessionValid(String userId) async {
    User? user = _fireAuth.currentUser;
    if (user == null || user.uid != userId) {
      return false;
    }

    String? currentSessionId = await _getCurrentSessionId();
    if (currentSessionId == null) {
      return false;
    }

    // Check local expiration first
    String? expiryStr = await _secureStorage.read(key: 'sessionExpiry');
    final expiry = DateTime.parse(expiryStr!);
    if (DateTime.now().isAfter(expiry)) {
      await _invalidateCurrentSession(userId);
      return false;
    }

    DocumentSnapshot sessionDoc =
        await _firestore
            .collection('user_sessions')
            .doc(userId)
            .collection('sessions')
            .doc(currentSessionId)
            .get();

    if (!sessionDoc.exists) return false;

    Map<String, dynamic> data = sessionDoc.data() as Map<String, dynamic>;

    // Check if session is expired or invalid
    if (!data['isValid'] ||
        (data['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) {
      await _invalidateCurrentSession(userId);
      return false;
    }

    // Update last activity timestamp
    await sessionDoc.reference.update({
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<void> _invalidateCurrentSession(String userId) async {
    String? currentSessionId = await _getCurrentSessionId();
    if (currentSessionId != null) {
      await invalidateSession(userId, currentSessionId);
      await _secureStorage.delete(key: 'sessionId');
      await _secureStorage.delete(key: 'sessionExpiry');
    }
  }

  // Add method to refresh session
  Future<void> refreshSession(String userId) async {
    String? currentSessionId = await _getCurrentSessionId();
    if (currentSessionId != null) {
      final expiresAt = DateTime.now().add(const Duration(days: 7));

      await _firestore
          .collection('user_sessions')
          .doc(userId)
          .collection('sessions')
          .doc(currentSessionId)
          .update({
            'expiresAt': Timestamp.fromDate(expiresAt),
            'lastActivityAt': FieldValue.serverTimestamp(),
          });

      await _secureStorage.write(
        key: 'sessionExpiry',
        value: expiresAt.toIso8601String(),
      );
    }
  }

  User? getUser() {
    return _fireAuth.currentUser;
  }

  Future<void> resetPassword(String email) async {
    await _fireAuth.sendPasswordResetEmail(email: email);
  }

  Future<bool> authStatus() async {
    User? user = _fireAuth.currentUser;
    return user != null;
  }

  // Add this new stream controller
  final _authStateController = StreamController<bool>.broadcast();

  // Add this getter for the stream
  Stream<bool> get authStateStream => _authStateController.stream;

  // Modify the isSessionValid method to use a stream
  Stream<bool> isSessionValidStream(String userId) async* {
    User? user = _fireAuth.currentUser;
    if (user == null || user.uid != userId) {
      yield false;
      return;
    }

    // Retrieve the current session ID from secure storage
    String? currentSessionId = await _getCurrentSessionId();
    if (currentSessionId == null) {
      yield false;
      return;
    }

    // Stream the session document from Firestore and map to a boolean
    yield* _firestore
        .collection('user_sessions')
        .doc(userId)
        .collection('sessions')
        .doc(currentSessionId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          return snapshot.data()?['isValid'] == true;
        });
  }

  // Modify the handleRemoteLogout method to delay navigation
  Future<void> handleRemoteLogout(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    await signOut();
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Session expired. Please login again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Add a dispose method to close the stream controller
  void dispose() {
    _authStateController.close();
  }

  // New analytics methods
  Future<Map<String, dynamic>> getSessionAnalytics(String userId) async {
    try {
      // Get all sessions
      QuerySnapshot sessions =
          await _firestore
              .collection('user_sessions')
              .doc(userId)
              .collection('sessions')
              .get();

      // Get user analytics
      DocumentSnapshot userAnalytics =
          await _firestore.collection('user_analytics').doc(userId).get();

      Map<String, dynamic> analytics = {
        'totalSessions': sessions.docs.length,
        'activeSessions':
            sessions.docs.where((doc) => doc['isValid'] == true).length,
        'deviceTypes': _aggregateDeviceTypes(sessions.docs),
        'locations': _aggregateLocations(sessions.docs),
        'lastLogin': userAnalytics['lastLogin'],
        'averageSessionDuration': _calculateAverageSessionDuration(
          sessions.docs,
        ),
      };

      return analytics;
    } catch (e) {
      return {};
    }
  }

  Map<String, int> _aggregateDeviceTypes(List<DocumentSnapshot> sessions) {
    Map<String, int> deviceTypes = {};
    for (var session in sessions) {
      String deviceType = session['deviceInfo']['deviceType'] ?? 'Unknown';
      deviceTypes[deviceType] = (deviceTypes[deviceType] ?? 0) + 1;
    }
    return deviceTypes;
  }

  Map<String, int> _aggregateLocations(List<DocumentSnapshot> sessions) {
    Map<String, int> locations = {};
    for (var session in sessions) {
      String location =
          '${session['lastLocation']['country']}, ${session['lastLocation']['city']}';
      locations[location] = (locations[location] ?? 0) + 1;
    }
    return locations;
  }

  double _calculateAverageSessionDuration(List<DocumentSnapshot> sessions) {
    var validSessions = sessions.where(
      (doc) => doc['lastActivityAt'] != null && doc['createdAt'] != null,
    );

    if (validSessions.isEmpty) return 0;

    double totalDuration = 0;
    for (var session in validSessions) {
      Timestamp lastActivity = session['lastActivityAt'];
      Timestamp created = session['createdAt'];
      totalDuration += lastActivity.seconds - created.seconds;
    }

    return totalDuration / validSessions.length;
  }

  // Method to get active sessions with details
  Future<List<Map<String, dynamic>>> getActiveSessions(String userId) async {
    QuerySnapshot sessions =
        await _firestore
            .collection('user_sessions')
            .doc(userId)
            .collection('sessions')
            .where('isValid', isEqualTo: true)
            .orderBy('lastActivityAt', descending: true)
            .get();

    return sessions.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return {
        'sessionId': data['sessionId'],
        'deviceInfo': data['deviceInfo'],
        'location': data['lastLocation'],
        'createdAt': data['createdAt'],
        'lastActivityAt': data['lastActivityAt'],
        'deviceType': data['deviceType'],
        'platform': data['platform'],
      };
    }).toList();
  }
}

AuthenticationService auth = AuthenticationService();

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

//FirebaseMessaging messaging = FirebaseMessaging.instance;
//PermissionsService permissionsService = PermissionsService();

class PermissionsService {
  Future<PermissionStatus> requestPhotos() async {
    await Permission.photos.request();
    return await Permission.photos.status;
  }

  Future<PermissionStatus> requestCam() async {
    await Permission.camera.request();
    return await Permission.camera.status;
  }

  Future<PermissionStatus> requestFiles() async {
    await Permission.storage.request();
    return await Permission.storage.status;
  }

  //Uncomment to allow notifications
  //Future<AuthorizationStatus> requestNotifications() async {
  //NotificationSettings settings = await messaging.requestPermission(
  //alert: true,
  //announcement: false,
  //badge: true,
  //carPlay: false,
  //criticalAlert: false,
  //provisional: false,
  //sound: true,
  //);
  //return settings.authorizationStatus;
  //}
}

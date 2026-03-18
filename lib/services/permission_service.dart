import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<void> requestStartupPermissions() async {
    await [
      Permission.location,
      Permission.notification,
    ].request();
  }
}

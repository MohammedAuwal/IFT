import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:mix/services/notification_navigation_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5EF),
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1D1D1F)),
        actions: [
          TextButton(
            onPressed: () async {
              await firebaseService.markAllNotificationsAsRead();
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.poppins(
                color: const Color(0xFFC29B40),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firebaseService.watchNotifications(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No notifications yet',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final id = (item['id'] ?? '').toString();
              final title = (item['title'] ?? 'Notification').toString();
              final body = (item['body'] ?? '').toString();
              final type = (item['type'] ?? '').toString();
              final isRead = (item['isRead'] ?? false) == true;
              final createdAt = (item['createdAt'] ?? '').toString();

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  if (id.isNotEmpty) {
                    await firebaseService.markNotificationAsRead(id);
                  }
                  await NotificationNavigationService.instance.handlePayload({
                    'type': type,
                    'targetScreen': (item['targetScreen'] ?? '').toString(),
                    'targetId': (item['targetId'] ?? '').toString(),
                    'notificationId': id,
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isRead
                          ? const Color(0xFFE9DFC6)
                          : const Color(0xFFC29B40).withOpacity(0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isRead
                            ? const Color(0xFFF3E8C8)
                            : const Color(0xFFC29B40).withOpacity(0.18),
                        child: Icon(
                          _iconForType(type),
                          color: const Color(0xFFC29B40),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: const Color(0xFF1D1D1F),
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Colors.black87,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              createdAt.isEmpty ? '' : createdAt,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    final value = type.toLowerCase();
    if (value.contains('order')) return Icons.receipt_long_rounded;
    if (value.contains('ride')) return Icons.local_taxi_rounded;
    if (value.contains('delivery')) return Icons.delivery_dining_rounded;
    if (value.contains('admin')) return Icons.admin_panel_settings_rounded;
    if (value.contains('escalation')) return Icons.warning_amber_rounded;
    return Icons.notifications_none_rounded;
  }
}

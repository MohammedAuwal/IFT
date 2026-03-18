import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/products/presentation/screens/product_list_screen.dart';
import 'services/firebase_auth_service.dart';

const String kAdminUid = 'PUT_ADMIN_UID_HERE';

class MixBootstrap extends StatelessWidget {
  const MixBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuthService();

    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: StreamBuilder<User?>(
            stream: auth.authStateChanges,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final user = snap.data;
              if (user == null) {
                return const LoginScreen();
              }

              if (user.uid == kAdminUid) {
                return AdminDashboardScreen();
              }

              return ProductListScreen();
            },
          ),
        );
      },
    );
  }
}

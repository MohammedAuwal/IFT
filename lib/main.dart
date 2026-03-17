import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'services/firebase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaamahsMixApp());
}

class MaamahsMixApp extends StatelessWidget {
  const MaamahsMixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Maamah's Mix",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12060A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD166),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuthService();

    return StreamBuilder(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoading();
        }

        if (snapshot.hasData) {
          return _SignedInHome(
            onSignOut: () async => auth.signOut(),
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}

class _SignedInHome extends StatelessWidget {
  const _SignedInHome({required this.onSignOut});

  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maamah's Mix"),
        actions: [
          TextButton(
            onPressed: () async => onSignOut(),
            child: const Text('Sign out'),
          )
        ],
      ),
      body: const Center(
        child: Text(
          "You're signed in.\n(Next: route to your premium home/products screen.)",
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

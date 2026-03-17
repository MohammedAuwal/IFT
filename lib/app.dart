import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaamahsMix',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaamahsMix'),
      ),
      body: const Center(
        child: Text(
          'Welcome to MaamahsMix 🔥',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

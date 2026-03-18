import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/services/firebase_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _firebaseService = FirebaseService();
  final _categoryCtrl = TextEditingController();

  Future<void> _addCategory() async {
    final name = _categoryCtrl.text.trim();
    if (name.isEmpty) return;

    await _firebaseService.addCategory(name);
    _categoryCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category added')),
    );
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Manage Categories',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _categoryCtrl,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Category name',
                    hintStyle: GoogleFonts.poppins(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF11141A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addCategory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Add Category'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<List<String>>(
            stream: _firebaseService.watchCategories(),
            builder: (context, snapshot) {
              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return Text(
                  'No categories yet',
                  style: GoogleFonts.poppins(color: Colors.white70),
                );
              }

              return Column(
                children: categories.map((category) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      title: Text(
                        category,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      trailing: IconButton(
                        onPressed: () async {
                          await _firebaseService.removeCategory(category);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

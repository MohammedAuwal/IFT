import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/services/firebase_service.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() =>
      _ManageCategoriesScreenState();
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

  Future<void> _removeCategory(String category) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove Category'),
            content: Text('Remove "$category"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await _firebaseService.removeCategory(category);
  }

  @override
  void initState() {
    super.initState();
    _firebaseService.seedDefaultCategoriesIfMissing();
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    const bg = Color(0xFF0F1115);
    const card = Color(0xFF171A21);
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'M',
                  style: GoogleFonts.cinzel(
                    color: wine,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Manage Categories',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () =>
                themeController.toggleDarkMode(!themeController.isDarkMode),
            icon: Icon(
              themeController.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
          ),
        ],
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
                  final isProtected = const [
                    'General',
                    'Trending',
                    'Featured',
                  ].contains(category);

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
                      subtitle: isProtected
                          ? Text(
                              'Default category',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      trailing: IconButton(
                        onPressed: isProtected
                            ? null
                            : () async {
                                await _removeCategory(category);
                              },
                        icon: Icon(
                          Icons.delete_outline,
                          color: isProtected
                              ? Colors.white24
                              : Colors.redAccent,
                        ),
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

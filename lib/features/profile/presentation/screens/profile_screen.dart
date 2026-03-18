import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/services/cloudinary_service.dart';
import 'package:mix/services/firebase_auth_service.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:mix/services/image_pick_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mix/features/favorites/presentation/screens/favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = FirebaseAuthService();
  final _firebaseService = FirebaseService();
  final _imageService = ImagePickService();
  final _cloudinaryService = CloudinaryService();
  final _addressCtrl = TextEditingController();

  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadProfileImage() async {
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final photoUrl = await _cloudinaryService.uploadImage(file);
      await _firebaseService.updateProfilePhoto(photoUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _addAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) return;

    await _firebaseService.addAddress(address);
    _addressCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address added')),
    );
  }

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse('https://wa.me/2340000000000?text=Hello%20Mix%20support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _firebaseService.watchUserProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data ?? {};
          final name = (profile['displayName'] ?? 'Mix User').toString();
          final email = (profile['email'] ?? 'No email').toString();
          final photoUrl = (profile['photoUrl'] ?? '').toString();
          final favorites = List<String>.from(profile['favorites'] ?? []);
          final cart = List<Map<String, dynamic>>.from(profile['cart'] ?? []);
          final addresses = List<String>.from(profile['addresses'] ?? []);
          final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickAndUploadProfileImage,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFFC29B40),
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                initial,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                          if (_uploadingPhoto)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Uploading photo...',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _StatBox(title: 'Favorites', value: '${favorites.length}')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox(title: 'Cart Items', value: '${cart.length}')),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileTile(
                icon: Icons.dark_mode_rounded,
                title: 'Dark mode',
                subtitle: 'Switch between light and dark theme',
                trailing: Switch(
                  value: themeController.isDarkMode,
                  onChanged: themeController.toggleDarkMode,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved addresses',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _addressCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add address',
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addAddress,
                        child: const Text('Save Address'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...addresses.map((address) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(address),
                          trailing: IconButton(
                            onPressed: () async {
                              await _firebaseService.removeAddress(address);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        )),
                  ],
                ),
              ),
              _ProfileTile(
                icon: Icons.favorite_border_rounded,
                title: 'Favorites',
                subtitle: 'View all your favorite products',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FavoritesScreen()),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.support_agent_rounded,
                title: 'Help & support',
                subtitle: 'Chat with us on WhatsApp',
                onTap: _openWhatsAppSupport,
              ),
              _ProfileTile(
                icon: Icons.info_outline_rounded,
                title: 'About Mix',
                subtitle: 'Learn more about Maamah’s Mix',
                onTap: () {},
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    'Log out',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: const Color(0xFFC29B40),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tileColor = Theme.of(context).cardTheme.color ?? Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC29B40).withOpacity(0.15),
          child: Icon(icon, color: const Color(0xFFC29B40)),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: textColor.withOpacity(0.6),
          ),
        ),
        trailing: trailing ??
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.black45,
            ),
      ),
    );
  }
}

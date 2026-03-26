import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mix/config/routes/route_names.dart';
import 'package:mix/core/routing/app_router.dart';
import 'package:mix/core/theme/theme_scope.dart';
import 'package:mix/features/auth/presentation/screens/login_screen.dart';
import 'package:mix/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:mix/features/profile/presentation/widgets/address_autocomplete_field.dart';
import 'package:mix/models/place_suggestion_model.dart';
import 'package:mix/services/cloudinary_service.dart';
import 'package:mix/services/firebase_auth_service.dart';
import 'package:mix/services/firebase_service.dart';
import 'package:mix/services/image_pick_service.dart';
import 'package:mix/services/local_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final bool showScaffold;

  const ProfileScreen({super.key, this.showScaffold = true});

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
  bool _loggingOut = false;
  bool _savingName = false;
  PlaceSuggestionModel? _selectedAddressSuggestion;

  String _currentNotifSound = 'default';

  bool get _isGuest => FirebaseAuth.instance.currentUser == null;

  @override
  void initState() {
    super.initState();
    _loadNotificationSound();
  }

  Future<void> _loadNotificationSound() async {
    final sound = await LocalNotificationService.instance.getNotificationSound();
    if (mounted) setState(() => _currentNotifSound = sound);
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(
          redirectTo: RouteNames.redirectProfile,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    if (_isGuest) { await _goToLogin(); return; }
    final file = await _imageService.pickImageWithFallback();
    if (file == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final photoUrl = await _cloudinaryService.uploadImage(file);
      await _firebaseService.updateProfilePhoto(photoUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editDisplayName(String currentName) async {
    if (_isGuest) { await _goToLogin(); return; }
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Edit name', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller, textCapitalization: TextCapitalization.words,
          autofocus: true, style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: 'Enter your full name', hintStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC29B40), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Save', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (newName == null || newName.trim().isEmpty || !mounted) return;
    setState(() => _savingName = true);
    try {
      await _firebaseService.updateDisplayName(newName.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _addAddress() async {
    if (_isGuest) { await _goToLogin(); return; }
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    try {
      await _firebaseService.addAddress(address);
      _addressCtrl.clear();
      setState(() { _selectedAddressSuggestion = null; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added and selected'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add address: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _removeAddress(String address) async {
    if (_isGuest) { await _goToLogin(); return; }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove address', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove this address?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firebaseService.removeAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address removed'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove address: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _selectAddress(String address) async {
    if (_isGuest) { await _goToLogin(); return; }
    try {
      await _firebaseService.setSelectedAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery address selected'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select address: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse('https://wa.me/2340000000000?text=Hello%20Mix%20support');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _showAboutDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("Maamah's Mix", style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w800, fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Premium African spices, flours & traditional foods delivered to your doorstep.',
              style: GoogleFonts.poppins(fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 16),
            Text('Version 1.0.0', style: GoogleFonts.poppins(
              fontSize: 12, color: Theme.of(ctx).textTheme.bodyMedium?.color?.withOpacity(0.5))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (_isGuest) { await _goToLogin(); return; }
    if (_loggingOut) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Log out', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.poppins())),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log out', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loggingOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showNotificationSoundPicker() {
    final sounds = LocalNotificationService.instance.availableSounds;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42, height: 4,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Notification Sound', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Choose how notification alerts sound',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54)),
                const SizedBox(height: 16),
                ...sounds.map((sound) {
                  final isSelected = sound == _currentNotifSound;
                  final label = sound == 'default' ? 'Default Sound' : 'Silent (No Sound)';
                  final icon = sound == 'default' ? Icons.volume_up_rounded : Icons.volume_off_rounded;

                  return ListTile(
                    onTap: () async {
                      await LocalNotificationService.instance.setNotificationSound(sound);
                      setState(() => _currentNotifSound = sound);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    leading: Icon(icon, color: isSelected ? const Color(0xFFC29B40) : Colors.black38),
                    title: Text(label, style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFFC29B40) : Colors.black87,
                    )),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFC29B40))
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: isSelected ? const Color(0xFFC29B40).withOpacity(0.08) : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const gold = Color(0xFFC29B40);
    const wine = Color(0xFF7C1820);

    if (_isGuest) {
      final guestContent = CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Column(children: [
                    Container(
                      width: 92, height: 92,
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.14), shape: BoxShape.circle,
                        border: Border.all(color: gold.withOpacity(0.25)),
                      ),
                      child: Center(child: Container(
                        width: 58, height: 58,
                        decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                        child: Center(child: Text('M', style: GoogleFonts.cinzel(
                          color: wine, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
                      )),
                    ),
                    const SizedBox(height: 14),
                    Text('Continue as Guest', style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 8),
                    Text('Browse products freely. Sign in to save favorites, track orders, manage addresses, and enjoy the full Mix experience.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12.5, height: 1.5,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.login_rounded),
                        label: Text('Sign In / Create Account', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 18),
                _ProfileTile(icon: Icons.dark_mode_rounded, title: 'Dark mode',
                  subtitle: 'Switch between light and dark theme',
                  trailing: Switch(value: themeController.isDarkMode,
                    onChanged: themeController.toggleDarkMode, activeColor: gold)),
                _ProfileTile(icon: Icons.notifications_outlined, title: 'Notification sound',
                  subtitle: 'Current: ${_currentNotifSound == 'default' ? 'Default Sound' : 'Silent'}',
                  onTap: _showNotificationSoundPicker),
                _ProfileTile(icon: Icons.favorite_border_rounded, title: 'Favorites',
                  subtitle: 'Sign in to save your favorite products', onTap: _goToLogin),
                _ProfileTile(icon: Icons.location_on_outlined, title: 'Saved addresses',
                  subtitle: 'Sign in to save delivery addresses', onTap: _goToLogin),
                _ProfileTile(icon: Icons.receipt_long_rounded, title: 'Orders',
                  subtitle: 'Sign in to track your order history', onTap: _goToLogin),
                _ProfileTile(icon: Icons.support_agent_rounded, title: 'Help & support',
                  subtitle: 'Chat with us on WhatsApp', onTap: _openWhatsAppSupport),
                _ProfileTile(icon: Icons.info_outline_rounded, title: 'About Mix',
                  subtitle: "Learn more about Maamah's Mix", onTap: _showAboutDialog),
                const SizedBox(height: 24),
                Center(child: Text('Version 1.0.0', style: GoogleFonts.poppins(
                  fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3)))),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      );

      if (!widget.showScaffold) {
        return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(child: guestContent));
      }
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0,
          title: Row(children: [
            Container(width: 30, height: 30,
              decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
              child: Center(child: Text('M', style: GoogleFonts.cinzel(
                color: wine, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)))),
            const SizedBox(width: 10),
            Text('Profile', style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w700)),
          ]),
          iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        body: guestContent,
      );
    }

    final content = StreamBuilder<Map<String, dynamic>?>(
      stream: _firebaseService.watchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC29B40)));
        }

        final profile = snapshot.data ?? {};
        final name = (profile['displayName'] ?? '').toString();
        final displayName = name.isNotEmpty ? name : 'Mix User';
        final email = (profile['email'] ?? '').toString();
        final displayEmail = email.isNotEmpty ? email : 'No email';
        final photoUrl = (profile['photoUrl'] ?? '').toString();
        final favorites = List<String>.from(profile['favorites'] ?? []);
        final cart = List<Map<String, dynamic>>.from(profile['cart'] ?? []);
        final addresses = List<String>.from(profile['addresses'] ?? []);
        final selectedAddress = (profile['selectedAddress'] ?? '').toString();
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Row(children: [
                      GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickAndUploadProfileImage,
                        child: Stack(children: [
                          CircleAvatar(
                            radius: 32, backgroundColor: const Color(0xFFC29B40),
                            backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                            child: photoUrl.isEmpty ? Text(initial, style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24)) : null,
                          ),
                          Positioned(bottom: 0, right: 0, child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: const Color(0xFFC29B40), shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).cardTheme.color ?? Colors.white, width: 2)),
                            child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                          )),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _savingName ? null : () => _editDisplayName(displayName),
                            child: Row(children: [
                              Flexible(child: Text(displayName, style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color))),
                              const SizedBox(width: 6),
                              Icon(Icons.edit_rounded, size: 16,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
                            ]),
                          ),
                          const SizedBox(height: 4),
                          Text(displayEmail, style: GoogleFonts.poppins(fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                          if (_uploadingPhoto) Padding(padding: const EdgeInsets.only(top: 6),
                            child: Row(children: [
                              const SizedBox(width: 12, height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC29B40))),
                              const SizedBox(width: 6),
                              Text('Uploading photo...', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFC29B40))),
                            ])),
                          if (_savingName) Padding(padding: const EdgeInsets.only(top: 6),
                            child: Text('Saving name...', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFC29B40)))),
                        ],
                      )),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: _StatBox(title: 'Favorites', value: '${favorites.length}')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(title: 'Cart Items', value: '${cart.length}')),
                  ]),
                  const SizedBox(height: 18),
                  _ProfileTile(icon: Icons.dark_mode_rounded, title: 'Dark mode',
                    subtitle: 'Switch between light and dark theme',
                    trailing: Switch(value: themeController.isDarkMode,
                      onChanged: themeController.toggleDarkMode, activeColor: gold)),
                  _ProfileTile(icon: Icons.notifications_outlined, title: 'Notification sound',
                    subtitle: 'Current: ${_currentNotifSound == 'default' ? 'Default Sound' : 'Silent'}',
                    onTap: _showNotificationSoundPicker),

                  // Addresses section
                  Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(radius: 16, backgroundColor: gold.withOpacity(0.15),
                          child: const Icon(Icons.location_on_rounded, color: gold, size: 18)),
                        const SizedBox(width: 10),
                        Text('Saved addresses', style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ]),
                      const SizedBox(height: 8),
                      Text(selectedAddress.isEmpty ? 'No selected delivery address' : 'Selected: $selectedAddress',
                        style: GoogleFonts.poppins(fontSize: 12,
                          color: selectedAddress.isEmpty ? Colors.redAccent : gold, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: AddressAutocompleteField(
                          controller: _addressCtrl,
                          onSuggestionSelected: (suggestion) { _selectedAddressSuggestion = suggestion; },
                        )),
                        const SizedBox(width: 8),
                        SizedBox(height: 48, child: ElevatedButton(
                          onPressed: _addAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Icon(Icons.add_rounded, size: 22),
                        )),
                      ]),
                      if (addresses.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...addresses.map((address) {
                          final isSelected = selectedAddress == address;
                          return Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? gold : Colors.transparent, width: 1.2),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Padding(padding: const EdgeInsets.only(top: 2),
                                child: Icon(isSelected ? Icons.check_circle_rounded : Icons.place_outlined,
                                  size: 18, color: isSelected ? gold
                                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5))),
                              const SizedBox(width: 8),
                              Expanded(child: Text(address, style: GoogleFonts.poppins(fontSize: 13))),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                TextButton(onPressed: () => _selectAddress(address),
                                  child: Text(isSelected ? 'Selected' : 'Use',
                                    style: GoogleFonts.poppins(color: gold, fontWeight: FontWeight.w700, fontSize: 12))),
                                IconButton(onPressed: () => _removeAddress(address),
                                  icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.withOpacity(0.7)),
                                  padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                              ]),
                            ]),
                          );
                        }),
                      ] else ...[
                        const SizedBox(height: 12),
                        Center(child: Text('No saved addresses yet', style: GoogleFonts.poppins(
                          fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)))),
                      ],
                    ]),
                  ),
                  _ProfileTile(icon: Icons.favorite_border_rounded, title: 'Favorites',
                    subtitle: 'View all your favorite products',
                    onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (_) => FavoritesScreen())); }),
                  _ProfileTile(icon: Icons.cleaning_services_rounded, title: 'Clean old notifications',
                    subtitle: 'Delete notifications older than 30 days',
                    onTap: () async {
                      final count = await _firebaseService.cleanupOldNotifications(days: 30);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deleted $count old notification${count == 1 ? '' : 's'}'),
                          behavior: SnackBarBehavior.floating),
                      );
                    }),
                  _ProfileTile(icon: Icons.support_agent_rounded, title: 'Help & support',
                    subtitle: 'Chat with us on WhatsApp', onTap: _openWhatsAppSupport),
                  _ProfileTile(icon: Icons.info_outline_rounded, title: 'About Mix',
                    subtitle: "Learn more about Maamah's Mix", onTap: _showAboutDialog),
                  const SizedBox(height: 18),
                  SizedBox(height: 52, child: ElevatedButton.icon(
                    onPressed: _loggingOut ? null : _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.red.withOpacity(0.15) : Colors.red.withOpacity(0.08),
                      foregroundColor: Colors.red, disabledBackgroundColor: Colors.red.withOpacity(0.05),
                      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: _loggingOut
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                        : const Icon(Icons.logout_rounded),
                    label: Text(_loggingOut ? 'Logging out...' : 'Log out',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  )),
                  const SizedBox(height: 24),
                  Center(child: Text('Version 1.0.0', style: GoogleFonts.poppins(
                    fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3)))),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
          ],
        );
      },
    );

    if (!widget.showScaffold) {
      return Scaffold(backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(child: content));
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, elevation: 0,
        title: Row(children: [
          Container(width: 30, height: 30,
            decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
            child: Center(child: Text('M', style: GoogleFonts.cinzel(
              color: wine, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0)))),
          const SizedBox(width: 10),
          Text('Profile', style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w700)),
        ]),
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: content,
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20, color: const Color(0xFFC29B40))),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.poppins(fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
      ]),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title,
    required this.subtitle, this.trailing, this.onTap});
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
        color: tileColor, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFC29B40).withOpacity(0.15),
          child: Icon(icon, color: const Color(0xFFC29B40)),
        ),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
        subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: textColor.withOpacity(0.6))),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: textColor.withOpacity(0.3)),
      ),
    );
  }
}

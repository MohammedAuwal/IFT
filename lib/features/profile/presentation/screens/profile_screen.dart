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
import 'package:mix/shared/widgets/app_bottom_sheets.dart';
import 'package:mix/shared/widgets/app_dialogs.dart';
import 'package:mix/shared/widgets/app_list_tile_card.dart';
import 'package:mix/shared/widgets/app_metric_card.dart';
import 'package:mix/shared/widgets/app_page_scaffold.dart';
import 'package:mix/shared/widgets/app_section_title.dart';
import 'package:mix/shared/widgets/app_surface_card.dart';
import 'package:mix/core/theme/build_context_theme_x.dart';
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
    if (_isGuest) {
      await _goToLogin();
      return;
    }

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

  Future<void> _editDisplayName(String currentName) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final controller = TextEditingController(text: currentName);
    final colors = context.appColors;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = ctx.appColors;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Edit name',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            style: GoogleFonts.poppins(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: GoogleFonts.poppins(color: c.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (newName == null || newName.trim().isEmpty || !mounted) return;

    setState(() => _savingName = true);

    try {
      await _firebaseService.updateDisplayName(newName.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e'),
          backgroundColor: colors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _addAddress() async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address')),
      );
      return;
    }

    try {
      await _firebaseService.addAddress(address);
      _addressCtrl.clear();

      setState(() {
        _selectedAddressSuggestion = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address added and selected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add address: $e')),
      );
    }
  }

  Future<void> _removeAddress(String address) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    final confirm = await AppDialogs.confirm(
      context: context,
      title: 'Remove address',
      message: 'Are you sure you want to remove this address?',
      confirmText: 'Remove',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirm) return;

    try {
      await _firebaseService.removeAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove address: $e')),
      );
    }
  }

  Future<void> _selectAddress(String address) async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    try {
      await _firebaseService.setSelectedAddress(address);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery address selected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select address: $e')),
      );
    }
  }

  Future<void> _openWhatsAppSupport() async {
    final uri = Uri.parse(
      'https://wa.me/2340000000000?text=Hello%20Mix%20support',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  Future<void> _showAboutDialog() async {
    await AppDialogs.info(
      context: context,
      title: "Maamah's Mix",
      message:
          'Premium African spices, flours & traditional foods delivered to your doorstep.\n\nVersion 1.0.0',
      icon: Icons.info_outline_rounded,
    );
  }

  Future<void> _handleLogout() async {
    if (_isGuest) {
      await _goToLogin();
      return;
    }

    if (_loggingOut) return;

    final confirm = await AppDialogs.confirm(
      context: context,
      title: 'Log out',
      message: 'Are you sure you want to log out?',
      confirmText: 'Log out',
      destructive: true,
      icon: Icons.logout_rounded,
    );

    if (!confirm || !mounted) return;

    setState(() => _loggingOut = true);

    try {
      await _authService.signOut();
      if (!mounted) return;
      await AppRouter.clearAndGo(context, RouteNames.mainShell);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _showNotificationSoundPicker() {
    final sounds = LocalNotificationService.instance.availableSounds;

    AppBottomSheets.showSheet<void>(
      context: context,
      child: Builder(
        builder: (ctx) {
          final sheetColors = ctx.appColors;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBottomSheets.sheetHeader(
                  ctx,
                  title: 'Notification Sound',
                  subtitle: 'Choose how notification alerts sound',
                ),
                const SizedBox(height: 16),
                ...sounds.map((sound) {
                  final isSelected = sound == _currentNotifSound;
                  final label = sound == 'default'
                      ? 'Default Sound'
                      : 'Silent (No Sound)';
                  final icon = sound == 'default'
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded;

                  return ListTile(
                    onTap: () async {
                      await LocalNotificationService.instance
                          .setNotificationSound(sound);
                      setState(() => _currentNotifSound = sound);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    leading: Icon(
                      icon,
                      color: isSelected
                          ? sheetColors.brandPrimary
                          : sheetColors.textSecondary,
                    ),
                    title: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? sheetColors.brandPrimary
                            : sheetColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: sheetColors.brandPrimary,
                          )
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: isSelected
                        ? sheetColors.brandPrimary.withOpacity(0.08)
                        : null,
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Widget _buildGuestContent(BuildContext context) {
    final colors = context.appColors;
    final themeController = ThemeScope.of(context);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                AppSurfaceCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: colors.brandPrimary.withOpacity(0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.brandPrimary.withOpacity(0.25),
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: colors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'M',
                                style: GoogleFonts.cinzel(
                                  color: colors.brandSecondary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Continue as Guest',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Browse products freely. Sign in to save favorites, track orders, manage addresses, and enjoy the full Mix experience.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _goToLogin,
                          icon: const Icon(Icons.login_rounded),
                          label: Text(
                            'Sign In / Create Account',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                _ProfileTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification sound',
                  subtitle:
                      'Current: ${_currentNotifSound == 'default' ? 'Default Sound' : 'Silent'}',
                  onTap: _showNotificationSoundPicker,
                ),
                _ProfileTile(
                  icon: Icons.favorite_border_rounded,
                  title: 'Favorites',
                  subtitle: 'Sign in to save your favorite products',
                  onTap: _goToLogin,
                ),
                _ProfileTile(
                  icon: Icons.location_on_outlined,
                  title: 'Saved addresses',
                  subtitle: 'Sign in to save delivery addresses',
                  onTap: _goToLogin,
                ),
                _ProfileTile(
                  icon: Icons.receipt_long_rounded,
                  title: 'Orders',
                  subtitle: 'Sign in to track your order history',
                  onTap: _goToLogin,
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
                  subtitle: "Learn more about Maamah's Mix",
                  onTap: _showAboutDialog,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Version 1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: colors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatedContent(BuildContext context) {
    final colors = context.appColors;
    final themeController = ThemeScope.of(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _firebaseService.watchUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
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
        final initial =
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(18),
                      borderRadius: BorderRadius.circular(22),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _uploadingPhoto
                                ? null
                                : _pickAndUploadProfileImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: colors.brandPrimary,
                                  backgroundImage: photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
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
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: colors.brandPrimary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.card,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _savingName
                                      ? null
                                      : () => _editDisplayName(
                                            displayName,
                                          ),
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayEmail,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                if (_uploadingPhoto)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            color: colors.brandPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Uploading photo...',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: colors.brandPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (_savingName)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Saving name...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: colors.brandPrimary,
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
                        Expanded(
                          child: AppMetricCard(
                            title: 'Favorites',
                            value: '${favorites.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppMetricCard(
                            title: 'Cart Items',
                            value: '${cart.length}',
                          ),
                        ),
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
                    _ProfileTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notification sound',
                      subtitle:
                          'Current: ${_currentNotifSound == 'default' ? 'Default Sound' : 'Silent'}',
                      onTap: _showNotificationSoundPicker,
                    ),
                    AppSurfaceCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppSectionTitle(
                            title: 'Saved addresses',
                            spacingBottom: 8,
                          ),
                          Text(
                            selectedAddress.isEmpty
                                ? 'No selected delivery address'
                                : 'Selected: $selectedAddress',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: selectedAddress.isEmpty
                                  ? colors.error
                                  : colors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: AddressAutocompleteField(
                                  controller: _addressCtrl,
                                  onSuggestionSelected: (suggestion) {
                                    _selectedAddressSuggestion =
                                        suggestion;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _addAddress,
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (addresses.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            ...addresses.map(
                              (address) {
                                final isSelected =
                                    selectedAddress == address;

                                return Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.brandPrimary
                                          : Colors.transparent,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          top: 2,
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons
                                                  .check_circle_rounded
                                              : Icons.place_outlined,
                                          size: 18,
                                          color: isSelected
                                              ? colors.brandPrimary
                                              : colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          address,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color:
                                                colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                _selectAddress(
                                              address,
                                            ),
                                            child: Text(
                                              isSelected
                                                  ? 'Selected'
                                                  : 'Use',
                                              style: GoogleFonts.poppins(
                                                color: colors.brandPrimary,
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _removeAddress(
                                              address,
                                            ),
                                            icon: Icon(
                                              Icons
                                                  .delete_outline_rounded,
                                              size: 20,
                                              color: colors.error,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No saved addresses yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: colors.textSecondary
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _ProfileTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Favorites',
                      subtitle: 'View all your favorite products',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FavoritesScreen(),
                          ),
                        );
                      },
                    ),
                    _ProfileTile(
                      icon: Icons.cleaning_services_rounded,
                      title: 'Clean old notifications',
                      subtitle:
                          'Delete notifications older than 30 days',
                      onTap: () async {
                        final count = await _firebaseService
                            .cleanupOldNotifications(days: 30);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Deleted $count old notification${count == 1 ? '' : 's'}',
                            ),
                          ),
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
                      subtitle: "Learn more about Maamah's Mix",
                      onTap: _showAboutDialog,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed:
                            _loggingOut ? null : _handleLogout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colors.error.withOpacity(0.10),
                          foregroundColor: colors.error,
                          elevation: 0,
                        ),
                        icon: _loggingOut
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.error,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: Text(
                          _loggingOut
                              ? 'Logging out...'
                              : 'Log out',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: colors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (_isGuest) {
      final guestContent = _buildGuestContent(context);

      if (!widget.showScaffold) {
        return Scaffold(
          backgroundColor: colors.scaffold,
          body: SafeArea(child: guestContent),
        );
      }

      return AppPageScaffold(
        title: 'Profile',
        body: guestContent,
      );
    }

    final content = _buildAuthenticatedContent(context);

    if (!widget.showScaffold) {
      return Scaffold(
        backgroundColor: colors.scaffold,
        body: SafeArea(child: content),
      );
    }

    return AppPageScaffold(
      title: 'Profile',
      body: content,
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
    final colors = context.appColors;

    return AppListTileCard(
      margin: const EdgeInsets.only(bottom: 12),
      leading: CircleAvatar(
        backgroundColor: colors.brandPrimary.withOpacity(0.15),
        child: Icon(icon, color: colors.brandPrimary),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: colors.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textSecondary,
          ),
      onTap: onTap,
    );
  }
}

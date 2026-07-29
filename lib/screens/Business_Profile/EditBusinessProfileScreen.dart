import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/Session.dart';
import '../../dto/CityDto.dart';
import '../../model/BusinessModel.dart';
import '../../service/BusinessService.dart';
import '../../service/LocationService.dart';
import '../../service/UserProfileService.dart';
import '../../theme/app_theme.dart';

class EditBusinessProfileScreen extends StatefulWidget {
  final BusinessModel business;

  const EditBusinessProfileScreen({super.key, required this.business});

  @override
  State<EditBusinessProfileScreen> createState() =>
      _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState extends State<EditBusinessProfileScreen> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.business.name);
  late final TextEditingController _descriptionCtrl =
      TextEditingController(text: widget.business.description);
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.business.contactEmail); // ← NAYA
  late final TextEditingController _phoneCtrl =
      TextEditingController(text: widget.business.contactPhone); // ← NAYA

  CityDto? _selectedCity;
  final _citySearchCtrl = TextEditingController();

  String? _profilePhotoUrl;
  String? _coverPhotoUrl;

  bool _isSaving = false;
  bool _isUploadingProfilePhoto = false;
  bool _isUploadingCoverPhoto = false;

  final _scaffoldKey = GlobalKey<ScaffoldState>(); // ← drawer ke liye

  static const _navyDark = Color(0xFF0B1622);
  static const _navyCard = Color(0xFF13212F);
  static const _orange = Color(0xFFE8722A);

  @override
  void initState() {
    super.initState();
    _profilePhotoUrl = widget.business.profilePhotoUrl;
    _coverPhotoUrl = widget.business.coverPhotoUrl;

    if (widget.business.cityId != null && widget.business.cityName != null) {
      _selectedCity = CityDto(
        id: widget.business.cityId!,
        name: widget.business.cityName!,
        stateId: 0,
        stateName: '',
        countryId: 0,
        countryName: '',
      );
      _citySearchCtrl.text = widget.business.cityName!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _citySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingProfilePhoto = true);
    try {
      final updatedUser =
          await UserProfileService.uploadProfilePhoto(File(picked.path));
      await Session().updateProfilePhoto(updatedUser.profilePhotoUrl);
      if (!mounted) return;
      setState(() => _profilePhotoUrl = updatedUser.profilePhotoUrl);
      _showSnack('Profile photo updated!');
    } catch (e) {
      _showSnack('Failed to update profile photo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingProfilePhoto = false);
    }
  }

  Future<void> _pickAndUploadCoverPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isUploadingCoverPhoto = true);
    try {
      final updatedUser =
          await UserProfileService.uploadCoverPhoto(File(picked.path));
      if (!mounted) return;
      setState(() => _coverPhotoUrl = updatedUser.coverPhotoUrl);
      _showSnack('Cover photo updated!');
    } catch (e) {
      _showSnack('Failed to update cover photo: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingCoverPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Business name is required', isError: true);
      return;
    }

    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      _showSnack('Enter a valid email address', isError: true);
      return;
    }

    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone)) {
      _showSnack('Enter a valid phone number', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await BusinessService.update(
        businessId: widget.business.id,
        name: name,
        description: _descriptionCtrl.text.trim(),
        cityId: _selectedCity?.id,
        contactEmail: email.isEmpty ? null : email,
        // ← NAYA
        contactPhone: phone.isEmpty ? null : phone, // ← NAYA
      );
      if (!mounted) return;
      _showSnack('Business profile saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Save failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _navyCard,
        title: const Text('Log out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: _orange)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await Session().clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : _navyCard,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _navyDark,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _navyCard, width: 1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _navyCard,
                    backgroundImage: _profilePhotoUrl != null
                        ? NetworkImage(_profilePhotoUrl!)
                        : null,
                    child: _profilePhotoUrl == null
                        ? const Icon(Icons.storefront,
                            color: Colors.white38, size: 26)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.business.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppFonts.heading(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.storefront_outlined,
              label: 'Business Profile',
              onTap: () => Navigator.pop(context),
              selected: true,
            ),
            _drawerItem(
              icon: Icons.receipt_long_outlined,
              label: 'Bookings',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.insights_outlined,
              label: 'Analytics',
              onTap: () => Navigator.pop(context),
            ),
            _drawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            const Divider(color: _navyCard, height: 1),
            _drawerItem(
              icon: Icons.logout,
              label: 'Log out',
              iconColor: _orange,
              textColor: _orange,
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Color iconColor = Colors.white70,
    Color textColor = Colors.white,
  }) {
    return Material(
      color: selected ? _navyCard : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: selected ? _orange : iconColor),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textColor,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _navyDark,
      endDrawer: _buildDrawer(),
      // ← right side
      appBar: AppBar(
        backgroundColor: _navyDark,
        elevation: 0,
        title: const Text('Edit Business Profile',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover photo ──
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadCoverPhoto,
                    child: Container(
                      height: 130,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _navyCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _coverPhotoUrl != null
                          ? Image.network(_coverPhotoUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Icon(Icons.add_photo_alternate,
                                  color: Colors.white38, size: 36),
                            ),
                    ),
                  ),
                  if (_isUploadingCoverPhoto)
                    const CircularProgressIndicator(color: _orange),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickAndUploadCoverPhoto,
                  child: const Text('Change Cover Photo',
                      style: TextStyle(color: _orange)),
                ),
              ),

              const SizedBox(height: 12),

              // ── Profile photo / logo ──
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadProfilePhoto,
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: _navyCard,
                        backgroundImage: _profilePhotoUrl != null
                            ? NetworkImage(_profilePhotoUrl!)
                            : null,
                        child: _profilePhotoUrl == null
                            ? const Icon(Icons.storefront,
                                color: Colors.white38, size: 32)
                            : null,
                      ),
                    ),
                    if (_isUploadingProfilePhoto)
                      const CircularProgressIndicator(color: _orange),
                    if (!_isUploadingProfilePhoto)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: _orange,
                          child: const Icon(Icons.camera_alt,
                              size: 13, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text('Business Info',
                  style: AppFonts.heading(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 12),

              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Business Name*'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl, // ← NAYA
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Contact Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl, // ← NAYA
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Contact Phone'),
              ),

              const SizedBox(height: 28),
              Text('Location',
                  style: AppFonts.heading(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 12),

              Autocomplete<CityDto>(
                displayStringForOption: (city) => city.displayLabel,
                optionsBuilder: (textValue) async {
                  if (textValue.text.trim().length < 2) {
                    return const Iterable<CityDto>.empty();
                  }
                  try {
                    return await LocationService.searchCities(textValue.text);
                  } catch (_) {
                    return const Iterable<CityDto>.empty();
                  }
                },
                onSelected: (city) {
                  setState(() => _selectedCity = city);
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                  if (_selectedCity != null && controller.text.isEmpty) {
                    controller.text = _selectedCity!.displayLabel;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'City'),
                    onChanged: (_) {
                      if (_selectedCity != null) {
                        setState(() => _selectedCity = null);
                      }
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: _navyCard,
                      elevation: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final city = options.elementAt(index);
                            return ListTile(
                              title: Text(city.displayLabel,
                                  style: const TextStyle(color: Colors.white)),
                              onTap: () => onSelected(city),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('SAVE CHANGES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

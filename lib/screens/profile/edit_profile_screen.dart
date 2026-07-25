import 'package:flutter/material.dart';
import '../../dto/CityDto.dart';
import '../../service/LocationService.dart';
import '../../theme/app_theme.dart';
import '../../model/UserModel.dart';
import '../../service/ProfileService.dart';
import '../../service/UserService.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final String professionalType; // e.g. "MUSICIAN", "PHOTOGRAPHER"

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.professionalType,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ── Basic info controllers (User entity) ──
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _usernameCtrl =
      TextEditingController(text: widget.user.username);
  late final TextEditingController _mobileCtrl =
      TextEditingController(text: widget.user.mobileNumber);
  late final TextEditingController _bioCtrl =
      TextEditingController(text: widget.user.bio);

  // ── Location (Profile entity) ──
  // We no longer store city/state/country as free text. The user searches
  // and picks a City; we keep the whole CityDto so state/country can be
  // shown read-only, but only `cityId` is ever sent to the backend.
  CityDto? _selectedCity;
  final _citySearchCtrl = TextEditingController();

  // Musician-specific
  List<CategoryDto> _categories = [];
  List<InstrumentTypeDto> _instrumentTypes = [];
  CategoryDto? _selectedCategory;
  InstrumentTypeDto? _selectedPrimaryInstrument;

  // Photographer-specific (simple text fields as placeholder)
  final _cameraGearCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isMusician => widget.professionalType.toUpperCase() == 'MUSICIAN';

  bool get _isPhotographer =>
      widget.professionalType.toUpperCase() == 'PHOTOGRAPHER';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _mobileCtrl.dispose();
    _bioCtrl.dispose();
    _citySearchCtrl.dispose();
    _cameraGearCtrl.dispose();
    _specializationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    ProfileDto? profile;

    // Step 1: profile fetch
    try {
      profile = await ProfileService.getProfile(widget.user.id);
    } catch (e) {
      if (mounted) _showSnack('Failed to load profile: $e');
    }

    if (profile != null) {
      if (profile.cityId != null &&
          profile.cityName != null &&
          profile.stateName != null &&
          profile.countryName != null) {
        _selectedCity = CityDto(
          id: profile.cityId!,
          name: profile.cityName!,
          stateId: 0,
          stateName: profile.stateName!,
          countryId: 0,
          countryName: profile.countryName!,
        );
        _citySearchCtrl.text = _selectedCity!.displayLabel;
      }

      final details = profile.details ?? <String, dynamic>{};
      _cameraGearCtrl.text = details['cameraGear'] ?? '';
      _specializationCtrl.text = details['specialization'] ?? '';
    }

    // Step 2: category/instrument loading — profile fail ho tab bhi ye chalega
    if (_isMusician) {
      try {
        _categories = await ProfileService.getCategories();
        final existingInstrumentId = profile?.details?['primaryInstrument'];
        if (existingInstrumentId != null) {
          for (final cat in _categories) {
            final types = await ProfileService.getInstrumentTypes(cat.id);
            final match = types.where((t) => t.id == existingInstrumentId);
            if (match.isNotEmpty) {
              _selectedCategory = cat;
              _instrumentTypes = types;
              _selectedPrimaryInstrument = match.first;
              break;
            }
          }
        }
      } catch (e) {
        if (mounted) _showSnack('Failed to load instruments: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onCategoryChanged(CategoryDto? category) async {
    setState(() {
      _selectedCategory = category;
      _selectedPrimaryInstrument = null;
      _instrumentTypes = [];
    });
    if (category == null) return;
    try {
      final types = await ProfileService.getInstrumentTypes(category.id);
      setState(() => _instrumentTypes = types);
    } catch (e) {
      _showSnack('Failed to load instruments: $e');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final mobile = _mobileCtrl.text.trim();

    if (name.isEmpty) {
      _showSnack('Name is required');
      return;
    }
    if (_selectedCity == null) {
      _showSnack('City is required');
      return;
    }
    if (mobile.isNotEmpty && !RegExp(r'^\+?[0-9]{10,15}$').hasMatch(mobile)) {
      _showSnack('Enter a valid mobile number');
      return;
    }

    final Map<String, dynamic> details = {};

    if (_isMusician) {
      if (_selectedPrimaryInstrument == null) {
        _showSnack('Primary instrument is mandatory for Musicians');
        return;
      }
      details['primaryInstrument'] = _selectedPrimaryInstrument!.id;
    } else if (_isPhotographer) {
      if (_cameraGearCtrl.text.trim().isNotEmpty) {
        details['cameraGear'] = _cameraGearCtrl.text.trim();
      }
      if (_specializationCtrl.text.trim().isNotEmpty) {
        details['specialization'] = _specializationCtrl.text.trim();
      }
    }

    setState(() => _isSaving = true);
    try {
      await UserService.updateMe(
        name: name,
        username: username.isEmpty ? null : username,
        bio: _bioCtrl.text.trim(),
        mobileNumber: mobile.isEmpty ? null : mobile,
      );

      // Only cityId travels to the backend now — state/country are derived
      // server-side from the City → State → Country relation.
      await ProfileService.saveProfile(
        userId: widget.user.id,
        professionalType: widget.professionalType,
        cityId: _selectedCity!.id,
        details: details,
      );

      if (!mounted) return;
      _showSnack('Profile saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppFonts.body(color: AppColors.textPrimary)),
        backgroundColor: AppColors.bgSurfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Info',
                        style: AppFonts.heading(
                            fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      style: AppFonts.body(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Name*'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameCtrl,
                      style: AppFonts.body(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      style: AppFonts.body(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Mobile Number'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      style: AppFonts.body(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Bio'),
                    ),
                    const SizedBox(height: 28),
                    Text('Location',
                        style: AppFonts.heading(
                            fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),

                    // ── City autocomplete: searches backend, saves cityId ──
                    Autocomplete<CityDto>(
                      displayStringForOption: (city) => city.displayLabel,
                      optionsBuilder: (textValue) async {
                        if (textValue.text.trim().length < 2) {
                          return const Iterable<CityDto>.empty();
                        }
                        try {
                          return await LocationService.searchCities(
                              textValue.text);
                        } catch (_) {
                          return const Iterable<CityDto>.empty();
                        }
                      },
                      onSelected: (city) {
                        setState(() => _selectedCity = city);
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmit) {
                        // Keep the field pre-filled when editing an existing profile.
                        if (_selectedCity != null && controller.text.isEmpty) {
                          controller.text = _selectedCity!.displayLabel;
                        }
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: AppFonts.body(color: AppColors.textPrimary),
                          decoration: const InputDecoration(labelText: 'City*'),
                          onChanged: (_) {
                            // user is typing a new search -> old selection no longer valid
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
                            color: AppColors.bgSurfaceElevated,
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
                                        style: AppFonts.body(
                                            color: AppColors.textPrimary)),
                                    onTap: () => onSelected(city),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Read-only state/country, derived from the selected city.
                    if (_selectedCity != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedCity!.stateName}, ${_selectedCity!.countryName}',
                        style: AppFonts.body(color: AppColors.textSecondary),
                      ),
                    ],

                    const SizedBox(height: 28),
                    if (_isMusician) ...[
                      Text('Musician Details',
                          style: AppFonts.heading(
                              fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CategoryDto>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppColors.bgSurfaceElevated,
                        decoration: const InputDecoration(
                            labelText: 'Instrument Category*'),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name,
                                      style: AppFonts.body(
                                          color: AppColors.textPrimary)),
                                ))
                            .toList(),
                        onChanged: _onCategoryChanged,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<InstrumentTypeDto>(
                        value: _selectedPrimaryInstrument,
                        isExpanded: true,
                        dropdownColor: AppColors.bgSurfaceElevated,
                        decoration: const InputDecoration(
                            labelText: 'Primary Instrument*'),
                        items: _instrumentTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name,
                                      style: AppFonts.body(
                                          color: AppColors.textPrimary)),
                                ))
                            .toList(),
                        onChanged: _instrumentTypes.isEmpty
                            ? null
                            : (val) => setState(
                                () => _selectedPrimaryInstrument = val),
                      ),
                    ],
                    if (_isPhotographer) ...[
                      Text('Photographer Details',
                          style: AppFonts.heading(
                              fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cameraGearCtrl,
                        style: AppFonts.body(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'Camera Gear'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _specializationCtrl,
                        style: AppFonts.body(color: AppColors.textPrimary),
                        decoration:
                            const InputDecoration(labelText: 'Specialization'),
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.textOnGold),
                            )
                          : const Text('SAVE CHANGES'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

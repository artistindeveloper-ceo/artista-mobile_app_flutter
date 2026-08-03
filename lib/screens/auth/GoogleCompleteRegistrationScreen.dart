import 'package:flutter/material.dart';

import '../../model/CategoryModel.dart';
import '../../model/UserModel.dart';
import '../../service/AuthService.dart';
import '../../service/CategoryService.dart';
import '../../theme/app_theme.dart';

enum AccountType { individual, business }

/// Google Sign-In se naya user aane par (SIGNUP_REQUIRED) ye screen khulti
/// hai — password nahi maangte (Google se auth ho chuka hai), sirf account
/// type + category (+ business name agar business hai) poochte hain.
/// Dropdown data RegisterScreen wale hi CategoryService se DB se load hota
/// hai — koi hardcoded list nahi.
class GoogleCompleteRegistrationScreen extends StatefulWidget {
  final String signupToken;
  final String? email;
  final String? name;
  final VoidCallback
      onComplete; // success ke baad home pe navigate karne ke liye

  const GoogleCompleteRegistrationScreen({
    super.key,
    required this.signupToken,
    required this.onComplete,
    this.email,
    this.name,
  });

  @override
  State<GoogleCompleteRegistrationScreen> createState() =>
      _GoogleCompleteRegistrationScreenState();
}

class _GoogleCompleteRegistrationScreenState
    extends State<GoogleCompleteRegistrationScreen> {
  final _businessNameCtrl = TextEditingController();
  bool _isLoading = false;

  AccountType _accountType = AccountType.individual;

  CategoryModel? _selectedProfessionType;
  List<CategoryModel> _professionTypes = [];
  bool _loadingProfessionTypes = true;
  String? _professionTypesError;

  CategoryModel? _selectedBusinessType;
  List<CategoryModel> _businessTypes = [];
  bool _loadingBusinessTypes = true;
  String? _businessTypesError;

  @override
  void initState() {
    super.initState();
    _loadProfessionTypes();
    _loadBusinessTypes();
  }

  Future<void> _loadProfessionTypes() async {
    setState(() {
      _loadingProfessionTypes = true;
      _professionTypesError = null;
    });
    try {
      final categories = await CategoryService.getProfileCategories();
      if (!mounted) return;
      setState(() => _professionTypes = categories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _professionTypesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingProfessionTypes = false);
    }
  }

  Future<void> _loadBusinessTypes() async {
    setState(() {
      _loadingBusinessTypes = true;
      _businessTypesError = null;
    });
    try {
      final categories = await CategoryService.getBusinessCategories();
      if (!mounted) return;
      setState(() => _businessTypes = categories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _businessTypesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingBusinessTypes = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (_accountType == AccountType.individual &&
        _selectedProfessionType == null) {
      _showSnack('Please select your profession type');
      return;
    }
    if (_accountType == AccountType.business) {
      if (_selectedBusinessType == null) {
        _showSnack('Please select your business type');
        return;
      }
      if (_businessNameCtrl.text.trim().isEmpty) {
        _showSnack('Please enter your business name');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final UserModel user = await AuthService.completeGoogleRegistration(
        signupToken: widget.signupToken,
        accountType:
            _accountType == AccountType.individual ? 'INDIVIDUAL' : 'BUSINESS',
        professionalType: _accountType == AccountType.individual
            ? _selectedProfessionType!.code
            : null,
        businessType: _accountType == AccountType.business
            ? _selectedBusinessType!.code
            : null,
        businessName: _accountType == AccountType.business
            ? _businessNameCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      // completeGoogleRegistration() session save + socket connect kar
      // chuka hai — ab seedha home pe bhej do.
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        automaticallyImplyLeading: false,
        // wapas login pe jaana sahi nahi (signup token consume ho chuka)
        title: Text('Complete Your Profile',
            style:
                AppFonts.heading(fontSize: 20, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              Image.asset('assets/images/Artist.inlogo.png', width: 160),

              const SizedBox(height: 24),

              if (widget.name != null || widget.email != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.name != null)
                        Text(widget.name!,
                            style: AppFonts.heading(
                                fontSize: 16, color: AppColors.textPrimary)),
                      if (widget.email != null)
                        Text(widget.email!,
                            style: AppFonts.body(
                                color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              Text('Just one more step to set up your account',
                  style: AppFonts.body(
                      color: AppColors.textSecondary, fontSize: 13)),

              const SizedBox(height: 16),

              // Account Type toggle — Individual vs Business
              SegmentedButton<AccountType>(
                segments: const [
                  ButtonSegment(
                    value: AccountType.individual,
                    label: Text('Individual'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment(
                    value: AccountType.business,
                    label: Text('Business'),
                    icon: Icon(Icons.storefront_outlined),
                  ),
                ],
                selected: {_accountType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _accountType = selection.first;
                    if (_accountType == AccountType.individual) {
                      _selectedBusinessType = null;
                      _businessNameCtrl.clear();
                    } else {
                      _selectedProfessionType = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_accountType == AccountType.individual)
                _buildCategoryDropdown(
                  label: 'Profession Type*',
                  loading: _loadingProfessionTypes,
                  error: _professionTypesError,
                  onRetry: _loadProfessionTypes,
                  items: _professionTypes,
                  value: _selectedProfessionType,
                  onChanged: (value) =>
                      setState(() => _selectedProfessionType = value),
                ),

              if (_accountType == AccountType.business) ...[
                _buildCategoryDropdown(
                  label: 'Business Type*',
                  loading: _loadingBusinessTypes,
                  error: _businessTypesError,
                  onRetry: _loadBusinessTypes,
                  items: _businessTypes,
                  value: _selectedBusinessType,
                  onChanged: (value) =>
                      setState(() => _selectedBusinessType = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _businessNameCtrl,
                  style: AppFonts.body(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Business Name*'),
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _completeRegistration,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textOnGold),
                      )
                    : const Text('FINISH SETUP'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String label,
    required bool loading,
    required String? error,
    required VoidCallback onRetry,
    required List<CategoryModel> items,
    required CategoryModel? value,
    required ValueChanged<CategoryModel?> onChanged,
  }) {
    if (loading) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Loading...',
                style: AppFonts.body(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (error != null) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Expanded(
              child: Text('Could not load options',
                  style: AppFonts.body(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text('Retry',
                  style: AppFonts.body(
                      color: AppColors.gold, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<CategoryModel>(
      value: value,
      dropdownColor: AppColors.bgSurfaceElevated,
      style: AppFonts.body(color: AppColors.textPrimary),
      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
      decoration: InputDecoration(labelText: label),
      items: items
          .map((cat) => DropdownMenuItem<CategoryModel>(
                value: cat,
                child: Text(cat.displayName,
                    style: AppFonts.body(color: AppColors.textPrimary)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

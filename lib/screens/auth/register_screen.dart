import 'package:flutter/material.dart';

import '../../service/AuthService.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }
    if (password != confirm) {
      _showSnack('Passwords do not match!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(name: name, email: email, password: password);
      if (!mounted) return;
      _showSnack('Account created! Please login.');
      Navigator.pop(context); // Login screen pe wapas
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
        content: Text(
          msg,
          style: AppFonts.body(color: AppColors.textPrimary),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Account',
            style:
                AppFonts.heading(fontSize: 20, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Logo
              Image.asset('assets/images/Artist.inlogo.png', width: 160),

              const SizedBox(height: 32),

              // Name
              TextField(
                controller: _nameCtrl,
                style: AppFonts.body(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Full Name*'),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: AppFonts.body(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Email*'),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: AppFonts.body(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password*',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                style: AppFonts.body(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm Password*',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textOnGold),
                      )
                    : const Text('CREATE ACCOUNT'),
              ),

              const SizedBox(height: 16),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                      style: AppFonts.body(
                          color: AppColors.textSecondary, fontSize: 13)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Login',
                        style: AppFonts.body(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

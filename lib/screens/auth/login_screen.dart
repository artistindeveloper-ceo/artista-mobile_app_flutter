import 'package:flutter/material.dart';

import '../../service/AuthService.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _login() async {
    final credential = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (credential.isEmpty || password.isEmpty) {
      _showSnack('Please enter your mobile/email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NOTE: backend currently expects "email" field. If your users will
      // type a mobile number here instead, this still works as long as the
      // value typed matches what's stored against that user on the backend.
      await AuthService.login(emailOrMobile: credential, password: password);
      if (!mounted) return;
      _goToHome();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo
              Image.asset(
                'assets/images/Artist.inlogo.png',
                width: 220,
              ),

              const SizedBox(height: 45),

              // Mobile number field
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.text,
                style: AppFonts.body(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Mobile Number*',
                ),
              ),

              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: AppFonts.body(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password*',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot Password?',
                    style: AppFonts.body(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textOnGold,
                        ),
                      )
                    : const Text('LOGIN'),
              ),

              const SizedBox(height: 20),

              // Or Sign in with
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or Sign in with',
                      style: AppFonts.body(
                          color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.divider)),
                ],
              ),

              const SizedBox(height: 20),

              // Social login buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(
                    label: 'G',
                    color: AppColors.googleRed,
                    onTap: () {},
                  ),
                  const SizedBox(width: 20),
                  _SocialButton(
                    label: 'f',
                    color: AppColors.facebookBlue,
                    onTap: () {},
                    isF: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Skip Login
              OutlinedButton(
                onPressed: _goToHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.border),
                  backgroundColor: AppColors.bgSurface,
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'SKIP LOGIN',
                  style: AppFonts.body(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppFonts.body(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Register',
                      style: AppFonts.body(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isF;

  const _SocialButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.isF = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isF ? 26 : 22,
              fontWeight: FontWeight.bold,
              fontFamily: isF ? 'serif' : null,
            ),
          ),
        ),
      ),
    );
  }
}

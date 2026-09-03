import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';
import 'qr_scan_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _scanQr() async {
    final email = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const QrScanLoginScreen()),
    );
    if (email != null && mounted) {
      _userCtrl.text = email;
      // Focus password field
      FocusScope.of(context).nextFocus();
    }
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).login(
        _userCtrl.text.trim(), _passCtrl.text.trim(),
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _error = 'Invalid credentials. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        // Dark navy brand header
        Container(
          width: double.infinity,
          color: AppColors.navBg,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 40,
            bottom: 40, left: 28, right: 28,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_rupee_rounded,
                  color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Text('PujoPay',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
                ),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Welcome back',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Sign in to continue',
              style: TextStyle(color: Color(0xFF6B8BAA), fontSize: 14),
            ),
          ]),
        ),

        // Form area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),

              TextField(
                controller: _userCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.muted, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.muted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                  ]),
                ),
              ],

              const SizedBox(height: 28),
              AppButton(label: 'Sign In', onPressed: _login, loading: _loading),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _scanQr,
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: const Text('Scan QR to fill email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navBg,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text('PujoPay v1.0',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

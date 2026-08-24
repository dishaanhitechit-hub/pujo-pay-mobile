import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentL,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.name ?? '—',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16,
                  ),
                ),
                Text((auth.role ?? '').toUpperCase(),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 28),
          _sectionLabel('Quick Actions'),
          _tile(Icons.token_outlined, 'Tokens', () => context.push('/token')),
          if (auth.canViewAll)
            _tile(Icons.people_outline, 'Donors', () => context.push('/donors')),

          const SizedBox(height: 28),
          _sectionLabel('App'),
          _tile(Icons.info_outline, 'Version', null, trailing: 'v1.0.0'),
          _tile(Icons.link, 'Server', null, trailing: '132.154.156.82'),

          const SizedBox(height: 36),
          AppButton(
            label: 'Sign Out',
            color: AppColors.danger,
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.jetBrainsMono(
      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1,
    )),
  );

  Widget _tile(IconData icon, String label, VoidCallback? onTap, {String? trailing}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 14))),
            if (trailing != null)
              Text(trailing, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ]),
        ),
      );
}

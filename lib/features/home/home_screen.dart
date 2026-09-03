import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/auth_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/action_tile.dart';
import '../../shared/widgets/avatar_circle.dart';
import '../../shared/widgets/section_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => ref.read(authProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(auth: auth)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, AppSpacing.section, AppSpacing.page, 40,
              ),
              sliver: SliverList.list(children: [
                _Group(title: 'Collections', actions: _collectionActions(auth)),
                _Group(title: 'Manage',      actions: _manageActions(auth)),
                _Group(title: 'Organisation', actions: _orgActions(auth)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Action sets, gated by the same permission keys the backend enforces ────

  List<AppAction> _collectionActions(AuthState a) => [
        if (a.canCollect)
          const AppAction(icon: Icons.payments_rounded, label: 'Collect',
              route: '/collect/new', color: AppColors.accent),
        if (a.canViewCollections)
          const AppAction(icon: Icons.history_rounded, label: 'My\nCollections',
              route: '/collections', color: AppColors.teal),
        const AppAction(icon: Icons.handshake_rounded, label: 'Pledges',
            route: '/pledge', color: AppColors.purple),
        if (a.canGenerateToken)
          const AppAction(icon: Icons.confirmation_number_rounded, label: 'Tokens',
              route: '/token', color: AppColors.green),
        if (a.canViewPaymentRecords)
          const AppAction(icon: Icons.group_rounded, label: 'Donors',
              route: '/donors', color: AppColors.indigo),
        if (a.canViewDashboard)
          const AppAction(icon: Icons.bar_chart_rounded, label: 'Dashboard',
              route: '/dashboard', color: AppColors.blue),
      ];

  List<AppAction> _manageActions(AuthState a) => [
        if (a.canViewDashboard)
          const AppAction(icon: Icons.how_to_reg_rounded, label: 'Attendance',
              route: '/attendance', color: AppColors.cyan),
        if (a.canManageEvents)
          const AppAction(icon: Icons.event_rounded, label: 'Events',
              route: '/admin/events', color: AppColors.blue),
        if (a.canManageEvents)
          const AppAction(icon: Icons.account_balance_wallet_rounded, label: 'Budget',
              route: '/admin/budgets', color: AppColors.amber),
        if (a.canManageExpenses)
          const AppAction(icon: Icons.receipt_long_rounded, label: 'Expenses',
              route: '/admin/expenses', color: AppColors.rose),
        if (a.canBulkToken)
          const AppAction(icon: Icons.qr_code_2_rounded, label: 'Bulk\nTokens',
              route: '/admin/token-config', color: AppColors.green),
      ];

  List<AppAction> _orgActions(AuthState a) => [
        const AppAction(icon: Icons.campaign_rounded, label: 'Announce\n-ments',
            route: '/announcements', color: AppColors.purple),
        if (a.canManageContent)
          const AppAction(icon: Icons.groups_rounded, label: 'Committee',
              route: '/admin/committee', color: AppColors.indigo),
        if (a.canManageContent)
          const AppAction(icon: Icons.forum_rounded, label: 'Queries',
              route: '/admin/contact-queries', color: AppColors.pink),
        if (a.canManageUsers)
          const AppAction(icon: Icons.manage_accounts_rounded, label: 'Users',
              route: '/admin/users', color: AppColors.teal),
        if (a.canManageUsers)
          const AppAction(icon: Icons.tune_rounded, label: 'Settings',
              route: '/admin/config', color: AppColors.muted),
      ];
}

/// A titled block of tiles. Renders nothing when the user has access to none.
class _Group extends StatelessWidget {
  final String title;
  final List<AppAction> actions;
  const _Group({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          SectionCard(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 14),
            child: ActionGrid(actions: actions),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AuthState auth;
  const _Header({required this.auth});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1A2E45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, 14, AppSpacing.page, 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        auth.name ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _RoleChip(label: auth.roleLabel),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Tapping the picture opens the full profile card.
                Hero(
                  tag: 'profile-avatar',
                  child: Material(
                    color: Colors.transparent,
                    child: AvatarCircle(
                      url: auth.avatarUrl,
                      initials: auth.initials,
                      size: 52,
                      background: const Color(0x33E8622A),
                      foreground: Colors.white,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  const _RoleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          color: AppColors.accent,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

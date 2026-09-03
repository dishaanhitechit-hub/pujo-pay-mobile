import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'core/navigation/route_observer.dart';
import 'shared/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/collect/new_payment_screen.dart';
import 'features/collect/upi_qr_screen.dart';
import 'features/collect/cash_confirm_screen.dart';
import 'features/collect/cheque_screen.dart';
import 'features/collect/receipt_screen.dart';
import 'features/pledge/pledge_list_screen.dart';
import 'features/pledge/create_pledge_screen.dart';
import 'features/pledge/pledge_detail_screen.dart';
import 'features/token/token_screen.dart';
import 'features/donor/donor_list_screen.dart';
import 'features/donor/donor_detail_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/collect/my_collections_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/attendance/attendance_screen.dart';
import 'features/admin/users_screen.dart';
import 'features/admin/events_screen.dart';
import 'features/admin/budgets_screen.dart';
import 'features/admin/expenses_screen.dart';
import 'features/admin/announcements_screen.dart';
import 'features/admin/committee_screen.dart';
import 'features/admin/contact_queries_screen.dart';
import 'features/admin/config_screen.dart';

void main() {
  runApp(const ProviderScope(child: PujoPay()));
}

class PujoPay extends ConsumerStatefulWidget {
  const PujoPay({super.key});
  @override
  ConsumerState<PujoPay> createState() => _PujoPayState();
}

class _PujoPayState extends ConsumerState<PujoPay> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Router created once — never recreated on auth changes.
    // Redirect reads auth via ref.read so it always gets the latest state.
    _router = GoRouter(
      observers: [appRouteObserver],
      initialLocation: '/splash',
      redirect: (ctx, state) {
        final loc      = state.matchedLocation;
        final loggedIn = ref.read(authProvider).isLoggedIn;

        // Splash manages its own navigation — don't touch it
        if (loc == '/splash') return null;

        if (!loggedIn && loc != '/login') return '/login';
        if (loggedIn  && loc == '/login') return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/login',  builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/home',   builder: (_, _) => const HomeScreen()),

        // Collect flow
        GoRoute(path: '/collect/new',
          builder: (_, _) => const NewPaymentScreen()),
        GoRoute(path: '/collect/upi/:id',
          builder: (_, s) {
            final extra = s.extra as Map? ?? {};
            return UpiQrScreen(
              paymentId: int.parse(s.pathParameters['id']!),
              donorName: extra['donorName'] as String?,
              amount:    extra['amount'] as String?,
            );
          }),
        GoRoute(path: '/collect/cash/:id',
          builder: (_, s) {
            final extra = s.extra as Map? ?? {};
            return CashConfirmScreen(
              paymentId: int.parse(s.pathParameters['id']!),
              donorName: extra['donorName'] as String?,
              amount:    extra['amount'] as String?,
            );
          }),
        GoRoute(path: '/collect/cheque/:id',
          builder: (_, s) {
            final extra = s.extra as Map? ?? {};
            return ChequeScreen(
              paymentId: int.parse(s.pathParameters['id']!),
              donorName: extra['donorName'] as String?,
              amount:    extra['amount'] as String?,
            );
          }),
        GoRoute(path: '/collect/receipt/:id',
          builder: (_, s) => ReceiptScreen(paymentId: int.parse(s.pathParameters['id']!))),

        // Pledge
        GoRoute(path: '/pledge',        builder: (_, _) => const PledgeListScreen()),
        GoRoute(path: '/pledge/create', builder: (_, _) => const CreatePledgeScreen()),
        GoRoute(path: '/pledge/:id',
          builder: (_, s) => PledgeDetailScreen(pledgeId: int.parse(s.pathParameters['id']!))),

        // Token
        GoRoute(path: '/token', builder: (_, _) => const TokenScreen()),

        // Donors
        GoRoute(path: '/donors', builder: (_, _) => const DonorListScreen()),
        GoRoute(path: '/donor/:id',
          builder: (_, s) => DonorDetailScreen(donorId: int.parse(s.pathParameters['id']!))),

        // Standalone screens (launcher tiles)
        GoRoute(path: '/dashboard',   builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/collections', builder: (_, _) => const MyCollectionsScreen()),
        GoRoute(path: '/settings',    builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/profile',     builder: (_, _) => const ProfileScreen()),

        // Attendance
        GoRoute(path: '/attendance', builder: (_, _) => const AttendanceScreen()),

        // Announcements are readable by every signed-in user; the create action
        // inside is gated on content.manage.
        GoRoute(
          path: '/announcements',
          builder: (ctx, _) => AnnouncementsScreen(
            canManage: ProviderScope.containerOf(ctx)
                .read(authProvider)
                .canManageContent,
          ),
        ),

        // Admin
        GoRoute(path: '/admin/users',           builder: (_, _) => const UsersScreen()),
        GoRoute(path: '/admin/events',          builder: (_, _) => const EventsScreen()),
        GoRoute(path: '/admin/budgets',         builder: (_, _) => const BudgetsScreen()),
        GoRoute(path: '/admin/expenses',        builder: (_, _) => const ExpensesScreen()),
        GoRoute(path: '/admin/committee',       builder: (_, _) => const CommitteeScreen()),
        GoRoute(path: '/admin/contact-queries', builder: (_, _) => const ContactQueriesScreen()),
        GoRoute(path: '/admin/token-config',    builder: (_, _) => const ConfigScreen.token()),
        GoRoute(path: '/admin/config',          builder: (_, _) => const ConfigScreen.app()),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PujoPay',
      theme: appTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

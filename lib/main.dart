import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'core/navigation/route_observer.dart';
import 'shared/theme/app_theme.dart';
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

void main() {
  runApp(const ProviderScope(child: PujoPay()));
}

class PujoPay extends ConsumerWidget {
  const PujoPay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    final router = GoRouter(
      observers: [appRouteObserver],
      initialLocation: auth.isLoggedIn ? '/home' : '/login',
      redirect: (ctx, state) {
        final loggedIn = ref.read(authProvider).isLoggedIn;
        final onLogin  = state.matchedLocation == '/login';
        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin)  return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/home',  builder: (_, __) => const HomeScreen()),

        // Collect flow
        GoRoute(path: '/collect/new',
          builder: (_, __) => const NewPaymentScreen()),
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
        GoRoute(path: '/pledge',        builder: (_, __) => const PledgeListScreen()),
        GoRoute(path: '/pledge/create', builder: (_, __) => const CreatePledgeScreen()),
        GoRoute(path: '/pledge/:id',
          builder: (_, s) => PledgeDetailScreen(pledgeId: int.parse(s.pathParameters['id']!))),

        // Token
        GoRoute(path: '/token', builder: (_, __) => const TokenScreen()),

        // Donors (admin/exec)
        GoRoute(path: '/donors', builder: (_, __) => const DonorListScreen()),
        GoRoute(path: '/donor/:id',
          builder: (_, s) => DonorDetailScreen(donorId: int.parse(s.pathParameters['id']!))),
      ],
    );

    return MaterialApp.router(
      title: 'PujoPay',
      theme: appTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

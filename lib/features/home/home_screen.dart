import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../collect/new_payment_screen.dart';
import '../pledge/pledge_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../collect/my_collections_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canViewAll = auth.canViewAll;

    final tabs = [
      if (canViewAll)
        const _Tab(icon: Icons.dashboard_outlined, label: 'Dashboard', screen: DashboardScreen()),
      const _Tab(icon: Icons.payments_outlined,  label: 'Collect',   screen: NewPaymentScreen()),
      const _Tab(icon: Icons.history,            label: 'My Collections', screen: MyCollectionsScreen()),
      const _Tab(icon: Icons.handshake_outlined, label: 'Pledges',   screen: PledgeListScreen()),
      const _Tab(icon: Icons.settings_outlined,  label: 'More',      screen: SettingsScreen()),
    ];

    return Scaffold(
      body: tabs[_tab].screen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: tabs.map((t) => BottomNavigationBarItem(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _Tab({required this.icon, required this.label, required this.screen});
}

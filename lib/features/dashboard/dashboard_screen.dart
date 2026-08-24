import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../core/navigation/route_observer.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _State();
}

class _State extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  final _client = DioClient();
  late final _tabs = TabController(length: 2, vsync: this);

  Map? _summary;
  List _payments    = [];
  List _collectors  = [];
  bool _loading     = true;
  bool _loadingColl = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _tabs.addListener(() { if (_tabs.index == 1 && _collectors.isEmpty) _loadCollectors(); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  @override
  void didPopNext() => _load();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await _client.get(Api.dashboardSummary);
      final p = await _client.get(Api.dashboardPayments, params: {'perPage': 20});
      setState(() {
        // Backend keys: grandTotal, cashTotal, upiTotal, chequeTotal, totalConfirmed, totalPledged
        _summary  = s.data['data'];
        _payments = p.data['data']['payments'] ?? [];
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCollectors() async {
    setState(() => _loadingColl = true);
    try {
      final res = await _client.get(Api.dashboardCollectors);
      setState(() => _collectors = res.data['data'] as List? ?? []);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingColl = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Collectors')],
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.accent,
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _overviewTab(),
        _collectorsTab(),
      ]),
    );
  }

  Widget _overviewTab() => _loading
      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
      : RefreshIndicator(
          onRefresh: _load,
          color: AppColors.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_summary != null) ...[
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(label: 'Total Collected',
                      value: '₹${_summary!['grandTotal'] ?? 0}',
                      icon: Icons.account_balance_wallet_outlined),
                    StatCard(label: 'Confirmed',
                      value: '${_summary!['totalConfirmed'] ?? 0}',
                      icon: Icons.check_circle_outline, color: AppColors.success),
                    StatCard(label: 'UPI',
                      value: '₹${_summary!['upiTotal'] ?? 0}',
                      icon: Icons.qr_code, color: AppColors.accent),
                    StatCard(label: 'Cash',
                      value: '₹${_summary!['cashTotal'] ?? 0}',
                      icon: Icons.payments_outlined, color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    '${_summary!['totalDonors'] ?? 0} donors · ₹${_summary!['totalPledged'] ?? 0} pledged',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ]),
                const SizedBox(height: 20),
              ],

              Text('Recent Payments', style: GoogleFonts.jetBrainsMono(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1)),
              const SizedBox(height: 10),

              ..._payments.map((p) {
                final status = p['status'] as String? ?? '';
                final color  = status == 'completed' ? AppColors.success
                    : status == 'pending' ? AppColors.warning : AppColors.muted;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['donor']?['name'] ?? '—', style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(p['collector']?['name'] ?? '—',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('₹${p['amount']}', style: const TextStyle(
                        color: AppColors.text, fontWeight: FontWeight.w700)),
                      Text(status, style: TextStyle(
                        color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ]),
                );
              }),
            ]),
          ),
        );

  Widget _collectorsTab() => _loadingColl
      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
      : RefreshIndicator(
          onRefresh: _loadCollectors,
          color: AppColors.accent,
          child: _collectors.isEmpty
              ? const Center(child: Text('No data', style: TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _collectors.length,
                  itemBuilder: (_, i) {
                    final c = _collectors[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentL, shape: BoxShape.circle),
                          child: const Icon(Icons.person, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c['name'] ?? '—', style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${c['confirmedCount'] ?? 0} payments',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ])),
                        Text('₹${c['grandTotal'] ?? 0}', style: const TextStyle(
                          color: AppColors.text, fontWeight: FontWeight.w700)),
                      ]),
                    );
                  },
                ),
        );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../core/navigation/route_observer.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';

class PledgeListScreen extends StatefulWidget {
  const PledgeListScreen({super.key});
  @override
  State<PledgeListScreen> createState() => _State();
}

class _State extends State<PledgeListScreen> with RouteAware, WidgetsBindingObserver {
  final _client = DioClient();
  List _pledges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
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
      final res = await _client.get(Api.pledgeList);
      setState(() => _pledges = res.data['data']['pledges'] ?? []);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pledges / EMI'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/pledge/create').then((_) => _load()),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('New Pledge'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _pledges.isEmpty
              ? const Center(child: Text('No pledges yet', style: TextStyle(color: AppColors.muted)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pledges.length,
                    itemBuilder: (_, i) => _PledgeTile(_pledges[i]),
                  ),
                ),
    );
  }
}

class _PledgeTile extends StatelessWidget {
  final Map p;
  const _PledgeTile(this.p);

  @override
  Widget build(BuildContext context) {
    final status = p['status'] as String? ?? '';
    final color = status == 'complete' ? AppColors.success
        : status == 'cancelled' ? AppColors.danger : AppColors.accent;
    final paid  = double.tryParse(p['paidAmount']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(p['totalAmount']?.toString() ?? '0') ?? 0;
    final pct   = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => context.push('/pledge/${p['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(p['donor']?['name'] ?? '—',
              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6),
              ),
              child: Text(status.toUpperCase(),
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('₹$paid / ₹$total',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border,
            color: color,
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
          ),
        ]),
      ),
    );
  }
}

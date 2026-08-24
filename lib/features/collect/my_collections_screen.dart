import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/navigation/route_observer.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';

class MyCollectionsScreen extends ConsumerStatefulWidget {
  const MyCollectionsScreen({super.key});
  @override
  ConsumerState<MyCollectionsScreen> createState() => _State();
}

class _State extends ConsumerState<MyCollectionsScreen> with RouteAware, WidgetsBindingObserver {
  final _client = DioClient();
  Map? _summary;
  List _payments = [];
  List _events   = [];
  int? _eventId;
  String _statusFilter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEvents();
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

  Future<void> _loadEvents() async {
    try {
      final res = await _client.get(Api.collectorEvents);
      setState(() => _events = res.data['data'] as List? ?? []);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{
        'perPage': 50,
        if (_eventId != null) 'eventId': _eventId,
        if (_statusFilter.isNotEmpty) 'status': _statusFilter,
      };
      final s = await _client.get(Api.collectorSummary,
          params: _eventId != null ? {'eventId': _eventId} : null);
      final p = await _client.get(Api.collectorPayments, params: params);
      setState(() {
        _summary  = s.data['data'];
        _payments = p.data['data']['payments'] ?? [];
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collections'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(children: [
        // Filter bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            // Event filter
            if (_events.isNotEmpty) ...[
              _chip(
                label: _eventId == null
                    ? 'All Events'
                    : (_events.firstWhere((e) => e['id'] == _eventId,
                        orElse: () => {'name': 'Event'})['name'] as String),
                selected: _eventId != null,
                onTap: () => _showEventPicker(),
              ),
              const SizedBox(width: 8),
            ],
            // Status filters
            for (final s in [
              ('All', ''), ('Completed', 'completed'), ('Cancelled', 'cancelled'),
            ]) ...[
              _chip(
                label: s.$1,
                selected: _statusFilter == s.$2,
                onTap: () { setState(() => _statusFilter = s.$2); _load(); },
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      // Summary grid — uses correct backend keys: grandTotal, upiTotal, cashTotal, chequeTotal
                      if (_summary != null) ...[
                        GridView.count(
                          crossAxisCount: 2, shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12, mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            StatCard(label: 'Total',
                              value: '₹${_summary!['grandTotal'] ?? 0}',
                              icon: Icons.account_balance_wallet_outlined),
                            StatCard(label: 'UPI',
                              value: '₹${_summary!['upiTotal'] ?? 0}',
                              icon: Icons.qr_code, color: AppColors.success),
                            StatCard(label: 'Cash',
                              value: '₹${_summary!['cashTotal'] ?? 0}',
                              icon: Icons.payments_outlined, color: AppColors.warning),
                            StatCard(label: 'Cheque',
                              value: '₹${_summary!['chequeTotal'] ?? 0}',
                              icon: Icons.receipt_long_outlined, color: AppColors.muted),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${_summary!['confirmedCount'] ?? 0} confirmed',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ]),
                        const SizedBox(height: 16),
                      ],
                      if (_payments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No payments', style: TextStyle(color: AppColors.muted)),
                        )
                      else
                        ..._payments.map((p) => _PaymentTile(p)),
                    ]),
                  ),
                ),
        ),
      ]),
    );
  }

  void _showEventPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            title: const Text('All Events', style: TextStyle(color: AppColors.text)),
            onTap: () { Navigator.pop(context); setState(() => _eventId = null); _load(); },
          ),
          ..._events.map((e) => ListTile(
            title: Text(e['name'] ?? '—', style: const TextStyle(color: AppColors.text)),
            trailing: _eventId == e['id']
                ? const Icon(Icons.check, color: AppColors.accent) : null,
            onTap: () { Navigator.pop(context); setState(() => _eventId = e['id']); _load(); },
          )),
        ],
      ),
    );
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentL : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Text(label, style: TextStyle(
            color: selected ? AppColors.accent : AppColors.muted,
            fontSize: 12, fontWeight: FontWeight.w600,
          )),
        ),
      );
}

class _PaymentTile extends StatelessWidget {
  final Map p;
  const _PaymentTile(this.p);

  @override
  Widget build(BuildContext context) {
    final status = p['status'] as String? ?? '';
    final color = status == 'completed' ? AppColors.success
        : status == 'pending' ? AppColors.warning : AppColors.danger;

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
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.currency_rupee, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['donor']?['name'] ?? '—',
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
          Text('${(p['method'] as String? ?? '').toUpperCase()} · ${p['receiptNo'] ?? '—'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          if (p['event'] != null)
            Text(p['event']['name'] as String? ?? '',
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹${p['amount']}',
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

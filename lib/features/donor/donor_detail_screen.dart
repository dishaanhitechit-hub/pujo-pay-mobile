import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../core/navigation/route_observer.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';

class DonorDetailScreen extends StatefulWidget {
  final int donorId;
  const DonorDetailScreen({super.key, required this.donorId});
  @override
  State<DonorDetailScreen> createState() => _State();
}

class _State extends State<DonorDetailScreen> with RouteAware, WidgetsBindingObserver {
  final _client = DioClient();
  Map? _donor;
  List _payments = [];
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
    try {
      final res = await _client.get(Api.donorDetail(widget.donorId));
      final d = res.data['data'];
      setState(() {
        _donor    = d['donor'];
        _payments = d['payments'] ?? [];
        _loading  = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_donor?['name'] ?? 'Donor')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_donor?['name'] ?? '—', style: GoogleFonts.jetBrainsMono(
                        color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      if (_donor?['phone'] != null)   _row(Icons.phone_outlined, _donor!['phone']),
                      if (_donor?['address'] != null) _row(Icons.location_on_outlined, _donor!['address']),
                      if (_donor?['email'] != null)   _row(Icons.email_outlined, _donor!['email']),
                      const Divider(color: AppColors.border, height: 24),
                      Row(children: [
                        _stat('Total Donated', '₹${_donor?['totalDonated'] ?? '0'}'),
                        _stat('Payments', '${_donor?['confirmedCount'] ?? 0}'),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 24),
                  Text('Payment History (${_payments.length})',
                    style: GoogleFonts.jetBrainsMono(
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
                          Text('₹${p['amount']}', style: const TextStyle(
                            color: AppColors.text, fontWeight: FontWeight.w700)),
                          Text((p['method'] as String? ?? '').toUpperCase(),
                            style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                          if (p['receiptNo'] != null)
                            Text(p['receiptNo'], style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ])),
                        Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    );
                  }),
                ]),
              ),
            ),
    );
  }

  Widget _row(IconData icon, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, color: AppColors.muted, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(val, style: const TextStyle(color: AppColors.text, fontSize: 13))),
    ]),
  );

  Widget _stat(String label, String value) => Expanded(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      Text(value, style: GoogleFonts.jetBrainsMono(
        color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16)),
    ],
  ));
}

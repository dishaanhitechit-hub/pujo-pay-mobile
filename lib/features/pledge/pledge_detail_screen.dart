import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/network/dio_client.dart';
import '../../core/navigation/route_observer.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class PledgeDetailScreen extends ConsumerStatefulWidget {
  final int pledgeId;
  const PledgeDetailScreen({super.key, required this.pledgeId});
  @override
  ConsumerState<PledgeDetailScreen> createState() => _State();
}

class _State extends ConsumerState<PledgeDetailScreen> with RouteAware, WidgetsBindingObserver {
  final _client = DioClient();
  Map? _pledge;
  List _payments = [];
  bool _loading = true;
  String? _error;

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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.get(Api.pledgeDetail(widget.pledgeId));
      if (res.statusCode == 200) {
        final d = res.data['data'];
        setState(() {
          _pledge   = d['pledge'];
          _payments = d['payments'] ?? [];
        });
      } else {
        setState(() => _error = res.data['message'] ?? 'Failed to load');
      }
    } catch (_) {
      setState(() => _error = 'Failed to load pledge.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payInstallment(String method, double amount) async {
    try {
      final res = await _client.post(Api.pledgePay(widget.pledgeId), data: {
        'method': method,
        'amount': amount,
      });
      if (res.statusCode != 201) {
        _showError(res.data['message'] ?? 'Failed to initiate');
        return;
      }
      final d = res.data['data'];
      final id = d['paymentId'] as int;
      final amt = d['amount'] as String? ?? '';
      final donor = (_pledge?['donor']?['name'] as String?) ?? '';
      if (!mounted) return;
      switch (method) {
        case 'upi':
          context.push('/collect/upi/$id', extra: {'donorName': donor, 'amount': amt});
          break;
        case 'cash':
          context.push('/collect/cash/$id', extra: {'donorName': donor, 'amount': amt});
          break;
        case 'cheque':
          context.push('/collect/cheque/$id', extra: {'donorName': donor, 'amount': amt});
          break;
      }
    } catch (_) {
      _showError('Failed to initiate installment payment.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  void _showPaySheet() {
    final amountCtrl = TextEditingController();
    final outstanding = double.tryParse(
      _pledge?['outstandingAmount']?.toString() ?? '0') ?? 0;
    if (outstanding > 0) amountCtrl.text = outstanding.toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Pay Installment', style: GoogleFonts.jetBrainsMono(
            color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16,
          )),
          const SizedBox(height: 20),
          TextField(
            controller: amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              labelText: 'Amount (₹) *',
              prefixIcon: Icon(Icons.currency_rupee, color: AppColors.muted, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          _methodTile('UPI', Icons.qr_code, AppColors.accent, 'upi', amountCtrl),
          const SizedBox(height: 10),
          _methodTile('Cash', Icons.payments_outlined, AppColors.warning, 'cash', amountCtrl),
          const SizedBox(height: 10),
          _methodTile('Cheque', Icons.receipt_long_outlined, AppColors.muted, 'cheque', amountCtrl),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _methodTile(String label, IconData icon, Color color, String method,
      TextEditingController amountCtrl) =>
      GestureDetector(
        onTap: () {
          final amount = double.tryParse(amountCtrl.text.trim());
          if (amount == null || amount <= 0) {
            _showError('Enter a valid amount');
            return;
          }
          Navigator.pop(context);
          _payInstallment(method, amount);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final status = _pledge?['status'] as String? ?? '';
    final isOpen = status == 'open';
    final statusColor = status == 'complete' ? AppColors.success
        : status == 'cancelled' ? AppColors.danger : AppColors.accent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pledge Detail'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      floatingActionButton: isOpen
          ? FloatingActionButton.extended(
              onPressed: _showPaySheet,
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add),
              label: const Text('Pay Installment'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.accent,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Pledge summary card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(
                              _pledge?['donor']?['name'] ?? '—',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800,
                              ),
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          _infoRow('Total', '₹${_pledge?['totalAmount'] ?? '0'}'),
                          _infoRow('Paid', '₹${_pledge?['paidAmount'] ?? '0'}'),
                          _infoRow('Outstanding', '₹${_pledge?['outstandingAmount'] ?? '0'}'),
                          if (_pledge?['event'] != null)
                            _infoRow('Event', _pledge!['event']['name'] ?? '—'),
                          if (_pledge?['notes'] != null && (_pledge!['notes'] as String).isNotEmpty)
                            _infoRow('Notes', _pledge!['notes']),

                          const SizedBox(height: 12),
                          // Progress bar
                          Builder(builder: (_) {
                            final total = double.tryParse(_pledge?['totalAmount']?.toString() ?? '0') ?? 0;
                            final paid  = double.tryParse(_pledge?['paidAmount']?.toString() ?? '0') ?? 0;
                            final pct   = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;
                            return LinearProgressIndicator(
                              value: pct,
                              backgroundColor: AppColors.border,
                              color: statusColor,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(4),
                            );
                          }),
                        ]),
                      ),

                      const SizedBox(height: 24),
                      Text('Payments (${_payments.length})',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_payments.isEmpty)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No payments yet', style: TextStyle(color: AppColors.muted)),
                        ))
                      else
                        ..._payments.map((p) {
                          final pStatus = p['status'] as String? ?? '';
                          final pColor  = pStatus == 'completed' ? AppColors.success
                              : pStatus == 'pending' ? AppColors.warning : AppColors.muted;
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
                                  color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15)),
                                Text((p['method'] as String? ?? '').toUpperCase(),
                                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                if (p['receiptNo'] != null)
                                  Text(p['receiptNo'], style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(pStatus.toUpperCase(),
                                  style: TextStyle(color: pColor, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          );
                        }),
                    ]),
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

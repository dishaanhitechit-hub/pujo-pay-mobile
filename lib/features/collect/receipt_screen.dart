import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class ReceiptScreen extends StatefulWidget {
  final int paymentId;
  const ReceiptScreen({super.key, required this.paymentId});
  @override
  State<ReceiptScreen> createState() => _State();
}

class _State extends State<ReceiptScreen> {
  final _client = DioClient();
  Map? _payment;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _client.get(Api.receipt(widget.paymentId));
      setState(() { _payment = res.data['data']; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.success)));

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Success icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 2),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Payment Confirmed!',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(_payment?['receiptNo'] ?? '',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),

          const SizedBox(height: 28),
          _receiptBox(),

          const SizedBox(height: 28),
          AppButton(label: 'New Collection', icon: Icons.add,
            onPressed: () => context.go('/home')),
        ]),
      ),
    );
  }

  Widget _receiptBox() {
    final p = _payment ?? {};
    final rows = [
      ['Donor',   p['donor']?['name'] ?? '—'],
      ['Amount',  '₹${p['amount'] ?? '—'}'],
      ['Method',  (p['method'] ?? '').toUpperCase()],
      ['Status',  p['status'] ?? '—'],
      if (p['utrNumber'] != null) ['UTR', p['utrNumber']],
      if (p['chequeNumber'] != null) ['Cheque #', p['chequeNumber']],
      if (p['bankName'] != null) ['Bank', p['bankName']],
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final last = e.key == rows.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: last ? null : Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Text(e.value[0], style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const Spacer(),
              Text(e.value[1], style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

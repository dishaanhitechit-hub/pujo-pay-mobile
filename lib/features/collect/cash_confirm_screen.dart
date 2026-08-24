import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class CashConfirmScreen extends StatefulWidget {
  final int paymentId;
  final String? donorName;
  final String? amount;
  const CashConfirmScreen({super.key, required this.paymentId, this.donorName, this.amount});
  @override
  State<CashConfirmScreen> createState() => _State();
}

class _State extends State<CashConfirmScreen> {
  final _client = DioClient();
  bool _confirming = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() { _confirming = true; _error = null; });
    try {
      // Backend expects form data (no extra fields needed for cash)
      await _client.postForm(Api.confirmCash(widget.paymentId), {});
      if (mounted) context.pushReplacement('/collect/receipt/${widget.paymentId}');
    } catch (_) {
      setState(() => _error = 'Confirmation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warning.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.payments_outlined, color: AppColors.warning, size: 36),
            ),
            const SizedBox(height: 24),
            Text('Confirm Cash Collection',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap below to confirm you have received the cash from the donor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],

            const SizedBox(height: 36),
            AppButton(label: 'Confirm Cash Received', onPressed: _confirm,
              loading: _confirming, color: AppColors.warning),
            const SizedBox(height: 12),
            AppButton(label: 'Cancel', onPressed: () => context.pop(),
              color: AppColors.card),
          ],
        ),
      ),
    );
  }
}

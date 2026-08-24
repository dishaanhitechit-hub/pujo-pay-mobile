import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class UpiQrScreen extends StatefulWidget {
  final int paymentId;
  final String? donorName;
  final String? amount;
  const UpiQrScreen({super.key, required this.paymentId, this.donorName, this.amount});
  @override
  State<UpiQrScreen> createState() => _State();
}

class _State extends State<UpiQrScreen> {
  final _client  = DioClient();
  final _utrCtrl = TextEditingController();
  bool _confirming = false;
  String? _error;

  // QR encodes the web payment page URL — donor scans with any UPI app
  String get _qrData => '${Api.baseUrl}/pay/qr/${widget.paymentId}';

  Future<void> _confirm() async {
    setState(() { _confirming = true; _error = null; });
    try {
      // Backend expects form data with field: utr_number
      await _client.postForm(
        Api.confirmUpi(widget.paymentId),
        {'utr_number': _utrCtrl.text.trim()},
      );
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
      appBar: AppBar(title: const Text('UPI Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(data: _qrData, size: 200),
          ),
          const SizedBox(height: 8),
          const Text('Donor scans this QR with any UPI app',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (widget.amount != null)
            Text('₹${widget.amount}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.text,
              ),
            ),
          if (widget.donorName != null)
            Text(widget.donorName!,
              style: const TextStyle(color: AppColors.muted, fontSize: 14)),

          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Enter UTR number after payment (optional):',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _utrCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              labelText: 'UTR / Reference Number',
              prefixIcon: Icon(Icons.tag, color: AppColors.muted, size: 18),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],

          const SizedBox(height: 24),
          AppButton(label: 'Mark as Paid', onPressed: _confirm,
            loading: _confirming, color: AppColors.success),
          const SizedBox(height: 12),
          AppButton(label: 'Cancel', onPressed: () => context.pop(),
            color: AppColors.card),
        ]),
      ),
    );
  }
}

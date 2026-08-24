import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class ChequeScreen extends StatefulWidget {
  final int paymentId;
  final String? donorName;
  final String? amount;
  const ChequeScreen({super.key, required this.paymentId, this.donorName, this.amount});
  @override
  State<ChequeScreen> createState() => _State();
}

class _State extends State<ChequeScreen> {
  final _client      = DioClient();
  final _chequeCtrl  = TextEditingController();
  final _bankCtrl    = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    if (_chequeCtrl.text.trim().isEmpty || _bankCtrl.text.trim().isEmpty || _date == null) {
      setState(() => _error = 'All fields are required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // Backend expects form data with snake_case field names
      await _client.postForm(Api.confirmCheque(widget.paymentId), {
        'cheque_number': _chequeCtrl.text.trim(),
        'bank_name':     _bankCtrl.text.trim(),
        'cheque_date':   '${_date!.year}-${_date!.month.toString().padLeft(2,'0')}-${_date!.day.toString().padLeft(2,'0')}',
      });
      if (mounted) context.pushReplacement('/collect/receipt/${widget.paymentId}');
    } catch (_) {
      setState(() => _error = 'Confirmation failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime(2020), lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cheque Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          TextField(
            controller: _chequeCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              labelText: 'Cheque Number *',
              prefixIcon: Icon(Icons.tag, color: AppColors.muted, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bankCtrl,
            style: const TextStyle(color: AppColors.text),
            decoration: const InputDecoration(
              labelText: 'Bank Name *',
              prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.muted, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: AppColors.muted, size: 18),
                const SizedBox(width: 12),
                Text(
                  _date == null ? 'Cheque Date *'
                      : '${_date!.day}/${_date!.month}/${_date!.year}',
                  style: TextStyle(
                    color: _date == null ? AppColors.muted : AppColors.text,
                    fontSize: 14,
                  ),
                ),
              ]),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],

          const SizedBox(height: 28),
          AppButton(label: 'Confirm Cheque', onPressed: _confirm, loading: _loading),
        ]),
      ),
    );
  }
}

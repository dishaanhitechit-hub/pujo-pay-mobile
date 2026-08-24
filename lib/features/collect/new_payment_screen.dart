import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class NewPaymentScreen extends ConsumerStatefulWidget {
  const NewPaymentScreen({super.key});
  @override
  ConsumerState<NewPaymentScreen> createState() => _NewPaymentScreenState();
}

class _NewPaymentScreenState extends ConsumerState<NewPaymentScreen> {
  final _client      = DioClient();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _amountCtrl  = TextEditingController();

  String _method = 'upi';
  int? _eventId;
  List _events = [];
  bool _loadingEvents = true;
  bool _loading = false;
  String? _error;

  final _methods = ['upi', 'cash', 'cheque'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final res = await _client.get(Api.collectorEvents);
      final list = res.data['data'] as List? ?? [];
      setState(() {
        _events = list;
        if (list.isNotEmpty) _eventId = list[0]['id'];
        _loadingEvents = false;
      });
    } catch (_) {
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Donor name is required');
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Amount is required');
      return;
    }
    if (_eventId == null) {
      setState(() => _error = 'Please select an event');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final res = await _client.post(Api.initiatePayment, data: {
        'donorName':    _nameCtrl.text.trim(),
        'donorPhone':   _phoneCtrl.text.trim(),
        'donorAddress': _addressCtrl.text.trim(),
        'amount':       amount,
        'method':       _method,
        'eventId':      _eventId,
      });

      if (res.statusCode != 201) {
        final msg = res.data['message'] ?? 'Failed to initiate payment';
        setState(() => _error = msg.toString());
        return;
      }

      final d = res.data['data'];
      final paymentId = d['paymentId'] as int;
      final donorName = d['donorName'] as String? ?? _nameCtrl.text.trim();
      final amountStr = d['amount'] as String? ?? _amountCtrl.text.trim();

      if (!mounted) return;
      switch (_method) {
        case 'upi':
          context.push('/collect/upi/$paymentId',
              extra: {'donorName': donorName, 'amount': amountStr});
          break;
        case 'cash':
          context.push('/collect/cash/$paymentId',
              extra: {'donorName': donorName, 'amount': amountStr});
          break;
        case 'cheque':
          context.push('/collect/cheque/$paymentId',
              extra: {'donorName': donorName, 'amount': amountStr});
          break;
      }
    } catch (e) {
      setState(() => _error = 'Failed to initiate payment. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Collection')),
      body: _loadingEvents
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event selector
                  _section('Event'),
                  if (_events.isEmpty)
                    const Text('No active events found.',
                        style: TextStyle(color: AppColors.danger, fontSize: 13))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _eventId,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: AppColors.text, fontSize: 14),
                          items: _events.map<DropdownMenuItem<int>>((e) =>
                            DropdownMenuItem(
                              value: e['id'] as int,
                              child: Text(e['name'] as String? ?? '—'),
                            ),
                          ).toList(),
                          onChanged: (v) => setState(() => _eventId = v),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  _section('Donor Details'),
                  _field(_nameCtrl,    'Full Name *',    icon: Icons.person_outline),
                  _field(_phoneCtrl,   'Phone Number',   icon: Icons.phone_outlined, type: TextInputType.phone),
                  _field(_addressCtrl, 'Address',        icon: Icons.location_on_outlined, lines: 2),

                  const SizedBox(height: 20),
                  _section('Payment'),
                  _field(_amountCtrl, 'Amount (₹) *',   icon: Icons.currency_rupee, type: TextInputType.number),
                  const SizedBox(height: 12),

                  Text('Payment Method', style: GoogleFonts.jetBrainsMono(
                    fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 8),
                  Row(
                    children: _methods.map((m) {
                      final selected = _method == m;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _method = m),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.accentL : AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppColors.accent : AppColors.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(m.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: selected ? AppColors.accent : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                    ),
                  ],

                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Continue to ${_method.toUpperCase()} →',
                    onPressed: _events.isEmpty ? null : _submit,
                    loading: _loading,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: GoogleFonts.jetBrainsMono(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.muted, letterSpacing: 1,
    )),
  );

  Widget _field(TextEditingController c, String label, {
    IconData? icon, TextInputType? type, int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c, keyboardType: type, maxLines: lines,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.muted, size: 18) : null,
      ),
    ),
  );
}

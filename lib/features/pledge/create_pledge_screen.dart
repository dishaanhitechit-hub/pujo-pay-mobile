import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class CreatePledgeScreen extends StatefulWidget {
  const CreatePledgeScreen({super.key});
  @override
  State<CreatePledgeScreen> createState() => _State();
}

class _State extends State<CreatePledgeScreen> {
  final _client      = DioClient();
  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _amountCtrl  = TextEditingController();
  final _notesCtrl   = TextEditingController();
  List _events   = [];
  int? _eventId;
  bool _loadingEvents = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadEvents(); }

  Future<void> _loadEvents() async {
    try {
      final res = await _client.get(Api.collectorEvents);
      final list = res.data['data'] as List? ?? [];
      setState(() {
        _events  = list;
        if (list.isNotEmpty) _eventId = list[0]['id'];
        _loadingEvents = false;
      });
    } catch (_) { setState(() => _loadingEvents = false); }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _amountCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name and total amount are required');
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
      final res = await _client.post(Api.createPledge, data: {
        'donorName':    _nameCtrl.text.trim(),
        'donorPhone':   _phoneCtrl.text.trim(),
        'donorAddress': _addressCtrl.text.trim(),
        'totalAmount':  amount,
        'notes':        _notesCtrl.text.trim(),
        'eventId':      _eventId,
      });
      if (res.statusCode == 201) {
        if (mounted) context.pop();
      } else {
        setState(() => _error = res.data['message'] ?? 'Failed to create pledge');
      }
    } catch (_) {
      setState(() => _error = 'Failed to create pledge. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Pledge')),
      body: _loadingEvents
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Event'),
                if (_events.isEmpty)
                  const Text('No active events.', style: TextStyle(color: AppColors.danger, fontSize: 13))
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

                const SizedBox(height: 16),
                _label('Donor Details'),
                _field(_nameCtrl,    'Full Name *',            Icons.person_outline),
                _field(_phoneCtrl,   'Phone',                  Icons.phone_outlined, type: TextInputType.phone),
                _field(_addressCtrl, 'Address',                Icons.location_on_outlined, lines: 2),
                _label('Pledge'),
                _field(_amountCtrl,  'Total Pledge Amount (₹) *', Icons.currency_rupee, type: TextInputType.number),
                _field(_notesCtrl,   'Notes',                  Icons.notes_outlined),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                AppButton(label: 'Create Pledge', onPressed: _events.isEmpty ? null : _submit, loading: _loading),
              ]),
            ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.jetBrainsMono(
      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1)),
  );

  Widget _field(TextEditingController c, String label, IconData icon, {
    TextInputType? type, int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c, keyboardType: type, maxLines: lines,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.muted, size: 18),
      ),
    ),
  );
}

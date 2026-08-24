import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/network/dio_client.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/app_button.dart';

class TokenScreen extends StatefulWidget {
  const TokenScreen({super.key});
  @override
  State<TokenScreen> createState() => _State();
}

class _State extends State<TokenScreen> with SingleTickerProviderStateMixin {
  final _client   = DioClient();
  late final _tabs = TabController(length: 2, vsync: this);

  // Generate form
  final _nameCtrl  = TextEditingController();
  final _topicCtrl = TextEditingController();
  String _type = 'single';
  bool _generating = false;
  String? _genError;
  Map? _lastToken;

  // List
  List _tokens = [];
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    _loadList();
    _tabs.addListener(() { if (_tabs.index == 1) _loadList(); });
  }

  Future<void> _loadList() async {
    setState(() => _loadingList = true);
    try {
      final res = await _client.get(Api.tokenList, params: {'perPage': 50});
      setState(() => _tokens = res.data['data']['tokens'] ?? []);
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _generate() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _genError = 'Participant name is required');
      return;
    }
    setState(() { _generating = true; _genError = null; _lastToken = null; });
    try {
      final res = await _client.post(Api.generateToken, data: {
        'participantName': _nameCtrl.text.trim(),
        'type': _type,
        if (_topicCtrl.text.trim().isNotEmpty) 'topic': _topicCtrl.text.trim(),
      });
      if (res.statusCode == 201) {
        setState(() => _lastToken = res.data['data']);
        _nameCtrl.clear();
        _topicCtrl.clear();
      } else {
        setState(() => _genError = res.data['message'] ?? 'Failed to generate');
      }
    } catch (_) {
      setState(() => _genError = 'Failed to generate token.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tokens'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Generate'), Tab(text: 'History')],
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.accent,
        ),
      ),
      body: TabBarView(controller: _tabs, children: [
        _generateTab(),
        _historyTab(),
      ]),
    );
  }

  Widget _generateTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Success card
      if (_lastToken != null) ...[
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text('Token Generated!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            _infoRow('Token No', _lastToken!['tokenNo'] ?? '—'),
            _infoRow('Name', _lastToken!['participantName'] ?? '—'),
            _infoRow('Type', (_lastToken!['type'] as String? ?? '').toUpperCase()),
          ]),
        ),
      ],

      _label('Type'),
      Row(children: ['single', 'dual'].map((t) {
        final sel = _type == t;
        return Expanded(child: GestureDetector(
          onTap: () => setState(() => _type = t),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? AppColors.accentL : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? AppColors.accent : AppColors.border, width: sel ? 1.5 : 1),
            ),
            child: Text(t.toUpperCase(), textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: sel ? AppColors.accent : AppColors.muted,
              ),
            ),
          ),
        ));
      }).toList()),

      const SizedBox(height: 16),
      TextField(
        controller: _nameCtrl,
        style: const TextStyle(color: AppColors.text),
        decoration: const InputDecoration(
          labelText: 'Participant Name *',
          prefixIcon: Icon(Icons.person_outline, color: AppColors.muted, size: 18),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _topicCtrl,
        style: const TextStyle(color: AppColors.text),
        decoration: const InputDecoration(
          labelText: 'Topic (optional)',
          prefixIcon: Icon(Icons.topic_outlined, color: AppColors.muted, size: 18),
        ),
      ),

      if (_genError != null) ...[
        const SizedBox(height: 12),
        Text(_genError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
      ],
      const SizedBox(height: 24),
      AppButton(label: 'Generate Token', onPressed: _generate, loading: _generating),
    ]),
  );

  Widget _historyTab() => _loadingList
      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
      : RefreshIndicator(
          onRefresh: _loadList,
          color: AppColors.accent,
          child: _tokens.isEmpty
              ? const Center(child: Text('No tokens yet', style: TextStyle(color: AppColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tokens.length,
                  itemBuilder: (_, i) {
                    final t = _tokens[i];
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
                          Text(t['tokenNo'] ?? '—', style: GoogleFonts.jetBrainsMono(
                            color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(t['participantName'] ?? '—',
                            style: const TextStyle(color: AppColors.text, fontSize: 14)),
                          if (t['topic'] != null)
                            Text(t['topic'], style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ])),
                        Text((t['type'] as String? ?? '').toUpperCase(),
                          style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                      ]),
                    );
                  },
                ),
        );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.jetBrainsMono(
      fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1)),
  );

  Widget _infoRow(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Text('$l: ', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      Text(v, style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}

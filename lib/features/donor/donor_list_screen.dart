import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../core/navigation/route_observer.dart';
import '../../config/api.dart';
import '../../shared/theme/app_theme.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});
  @override
  State<DonorListScreen> createState() => _State();
}

class _State extends State<DonorListScreen> with RouteAware, WidgetsBindingObserver {
  final _client     = DioClient();
  final _searchCtrl = TextEditingController();
  List _donors = [];
  bool _loading = true;
  int _page = 1;
  bool _hasMore = true;

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
  void didPopNext() => _load(reset: true);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) { _page = 1; _donors = []; _hasMore = true; }
    setState(() => _loading = true);
    try {
      final res = await _client.get(Api.donorList, params: {
        'page': _page,
        'perPage': 20,
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      });
      final d    = res.data['data'];
      final list = d['donors'] as List? ?? [];
      setState(() {
        _donors.addAll(list);
        _hasMore = (_page < (d['pages'] ?? 1));
        _page++;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donors')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppColors.text),
            onSubmitted: (_) => _load(reset: true),
            decoration: InputDecoration(
              hintText: 'Search donors…',
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, color: AppColors.muted, size: 18),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.muted, size: 16),
                      onPressed: () { _searchCtrl.clear(); _load(reset: true); },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _loading && _donors.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : _donors.isEmpty
                  ? const Center(child: Text('No donors found', style: TextStyle(color: AppColors.muted)))
                  : RefreshIndicator(
                      onRefresh: () => _load(reset: true),
                      color: AppColors.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _donors.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _donors.length) {
                            _load();
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                            );
                          }
                          final d = _donors[i];
                          return GestureDetector(
                            onTap: () => context.push('/donor/${d['id']}'),
                            child: Container(
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
                                    color: AppColors.accentL,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person, color: AppColors.accent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(d['name'] ?? '—', style: const TextStyle(
                                    color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                                  if (d['phone'] != null)
                                    Text(d['phone'], style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text('₹${d['totalDonated'] ?? '0'}',
                                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text('${d['confirmedCount'] ?? 0} payments',
                                    style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

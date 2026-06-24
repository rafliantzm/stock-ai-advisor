import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../core/api/api_result.dart';
import '../../core/api/edge_function_client.dart';
import '../../core/models/analysis_models.dart';
import '../../core/utils/map_utils.dart';
import '../../design_system/ui_components.dart';
import 'data/screener_repository.dart';

class ScreenerScreen extends StatefulWidget {
  const ScreenerScreen({super.key});

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  late final EdgeFunctionClient _api;
  final _repository = const ScreenerRepository();
  String _presetName = ScreenerRepository.p1Categories.first;
  List<Map<String, dynamic>> _results = [];
  List<DailyCandidate> _dailyCandidates = [];
  Map<String, dynamic>? _preset;
  var _isLoading = false;
  String? _error;
  String? _emptyReason;

  @override
  void initState() {
    super.initState();
    _api = EdgeFunctionClient(config: AppConfig.fromEnvironment());
  }

  Future<void> _runScreener() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _emptyReason = null;
    });
    try {
      final result = await _api.post(
        'run-screener',
        body: {'preset_name': _presetName, 'limit': 10},
      );
      final results = asMapList(result.data['results']);
      setState(() {
        _preset = asStringMap(result.data['preset']);
        _results = results;
        _dailyCandidates = _repository.dailyCandidatesFromResults(results);
        if (results.isEmpty) {
          _emptyReason =
              'Preset berjalan, tetapi belum ada watchlist candidate untuk kategori ini.';
        }
      });
    } on ApiException catch (error) {
      setState(() {
        _results = [];
        _dailyCandidates = [];
        if (error.code == 'not_found') {
          _emptyReason =
              'Kategori "$_presetName" belum didukung backend P0. Empty state ini disengaja sampai preset tersedia.';
        } else {
          _error = error.message;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppSectionHeader(
          title: 'AI Stock Screener',
          subtitle:
              'Jalankan preset edukatif untuk menemukan watchlist candidate berbasis score backend P0.',
          trailing: FilledButton.icon(
            onPressed: _isLoading ? null : _runScreener,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run'),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Screener Categories',
          subtitle:
              'Sebagian kategori P1 masih menunggu preset backend. Empty state akan tampil jika belum tersedia.',
          child: DropdownButtonFormField<String>(
            initialValue: _presetName,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ScreenerRepository.p1Categories
                .map(
                  (preset) =>
                      DropdownMenuItem(value: preset, child: Text(preset)),
                )
                .toList(),
            onChanged: _isLoading
                ? null
                : (value) => setState(() {
                    _presetName = value ?? _presetName;
                    _emptyReason = null;
                    _error = null;
                  }),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          AsyncStateView(title: 'Screener gagal dijalankan', message: _error),
        ],
        if (_isLoading) ...[
          const SizedBox(height: 80),
          const Center(child: CircularProgressIndicator()),
        ] else if (_results.isEmpty) ...[
          const SizedBox(height: 12),
          AsyncStateView(
            title: 'Belum ada hasil screener',
            message:
                _emptyReason ??
                'Pilih kategori lalu jalankan screener untuk melihat saham layak dianalisis.',
          ),
        ] else ...[
          const SizedBox(height: 16),
          AppSectionHeader(
            title: _preset?['name']?.toString() ?? _presetName,
            subtitle: '${_results.length} candidate ditemukan',
          ),
          const SizedBox(height: 12),
          ..._results.map(
            (result) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScreenerResultCard(result: result),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _DailyCandidatesSection(candidates: _dailyCandidates),
      ],
    );
  }
}

class _ScreenerResultCard extends StatelessWidget {
  const _ScreenerResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final symbol = asStringMap(result['symbol']);
    final scores = asStringMap(result['scores']);
    final label = result['candidate_label']?.toString() ?? 'layak_dianalisis';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol['symbol_code']?.toString() ?? '-',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (symbol['company_name'] != null)
                        Text(symbol['company_name'].toString()),
                    ],
                  ),
                ),
                StatusBadge(label: label),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ScorePill(label: 'Final', value: scores['final_score']),
                ScorePill(label: 'Technical', value: scores['technical_score']),
                ScorePill(label: 'Harmony', value: scores['harmony_score']),
                ScorePill(
                  label: 'Fundamental',
                  value: scores['fundamental_score'],
                ),
                ScorePill(label: 'Risk', value: scores['risk_score']),
                ScorePill(label: 'Liquidity', value: scores['liquidity_score']),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyCandidatesSection extends StatelessWidget {
  const _DailyCandidatesSection({required this.candidates});

  final List<DailyCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Daily Watchlist Candidates',
      subtitle: 'Menggunakan hasil screener terakhir jika tersedia.',
      child: candidates.isEmpty
          ? const AsyncStateView(
              title: 'Belum ada kandidat harian',
              message:
                  'Jalankan screener untuk mengisi Daily Watchlist Candidates.',
            )
          : Column(
              children: [
                for (final candidate in candidates) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              candidate.symbolCode,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(candidate.companyName),
                          ],
                        ),
                      ),
                      ScorePill(label: 'Final', value: candidate.score),
                      const SizedBox(width: 8),
                      StatusBadge(label: candidate.label),
                    ],
                  ),
                  if (candidate != candidates.last) const Divider(height: 24),
                ],
              ],
            ),
    );
  }
}

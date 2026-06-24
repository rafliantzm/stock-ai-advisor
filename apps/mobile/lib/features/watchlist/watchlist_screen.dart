import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../core/api/api_result.dart';
import '../../core/api/edge_function_client.dart';
import '../../core/models/analysis_models.dart';
import '../../core/utils/map_utils.dart';
import '../../design_system/ui_components.dart';
import '../stock_detail/stock_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  late final EdgeFunctionClient _api;
  final _symbolController = TextEditingController();
  Map<String, dynamic>? _watchlist;
  List<Map<String, dynamic>> _items = [];
  var _isLoading = true;
  var _isMutating = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _api = EdgeFunctionClient(config: AppConfig.fromEnvironment());
    _load();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.post('get-watchlist');
      setState(() {
        _watchlist = asStringMap(result.data['selected_watchlist']);
        _items = asMapList(result.data['items']);
      });
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addSymbol() async {
    final watchlistId = _watchlist?['id']?.toString();
    final symbol = _symbolController.text.trim().toUpperCase();
    if (watchlistId == null || symbol.isEmpty) return;

    await _mutate(() async {
      final result = await _api.post(
        'add-watchlist-item',
        body: {'watchlist_id': watchlistId, 'symbol_code': symbol},
      );
      _success = result.data['already_exists'] == true
          ? '$symbol sudah ada di watchlist.'
          : '$symbol ditambahkan ke watchlist.';
      _symbolController.clear();
      await _load();
    });
  }

  Future<void> _archiveItem(String itemId, String symbol) async {
    await _mutate(() async {
      await _api.post(
        'remove-watchlist-item',
        body: {'watchlist_item_id': itemId},
      );
      _success = '$symbol diarsipkan dari watchlist.';
      await _load();
    });
  }

  Future<void> _evaluate() async {
    final watchlistId = _watchlist?['id']?.toString();
    if (watchlistId == null) return;

    await _mutate(() async {
      final result = await _api.post(
        'evaluate-watchlist',
        body: {'watchlist_id': watchlistId},
      );
      _success =
          'Evaluasi selesai: ${result.data['evaluated_count'] ?? 0} saham diperbarui.';
      await _load();
    });
  }

  Future<void> _mutate(Future<void> Function() action) async {
    setState(() {
      _isMutating = true;
      _error = null;
      _success = null;
    });
    try {
      await action();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) {
      return AsyncStateView(
        title: 'Watchlist belum bisa dimuat',
        message: _error,
        action: FilledButton(onPressed: _load, child: const Text('Coba lagi')),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppSectionHeader(
            title: _watchlist?['name']?.toString() ?? 'Watchlist',
            subtitle:
                'Pantau saham layak dianalisis, watchlist candidate, risk warning, dan invalidation level.',
            trailing: FilledButton.icon(
              onPressed: _isMutating ? null : _evaluate,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Evaluate'),
            ),
          ),
          const SizedBox(height: 16),
          _AddSymbolCard(
            controller: _symbolController,
            isLoading: _isMutating,
            onAdd: _addSymbol,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(message: _error!, isError: true),
          ],
          if (_success != null) ...[
            const SizedBox(height: 12),
            _MessageBanner(message: _success!, isError: false),
          ],
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const SizedBox(
              height: 280,
              child: AsyncStateView(
                title: 'Watchlist masih kosong',
                message:
                    'Tambahkan symbol seperti BBCA untuk mulai melihat technical setup dan score dummy P0.',
              ),
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WatchlistItemCard(
                  item: item,
                  onOpenDetail: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StockDetailScreen(item: item),
                    ),
                  ),
                  onArchive: _isMutating
                      ? null
                      : () => _archiveItem(
                          item['id'].toString(),
                          item['symbol_code'].toString(),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddSymbolCard extends StatelessWidget {
  const _AddSymbolCard({
    required this.controller,
    required this.isLoading,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  hintText: 'BBCA',
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: isLoading ? null : onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistItemCard extends StatelessWidget {
  const _WatchlistItemCard({
    required this.item,
    required this.onOpenDetail,
    required this.onArchive,
  });

  final Map<String, dynamic> item;
  final VoidCallback onOpenDetail;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final analysis = StockAnalysis.fromWatchlistItem(item);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onOpenDetail,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.symbolCode,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(analysis.companyName),
                      ],
                    ),
                  ),
                  StatusBadge(label: analysis.candidateLabel),
                  IconButton(
                    tooltip: 'Archive',
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ScorePill(label: 'Final', value: analysis.overallScore),
                  ScorePill(label: 'Technical', value: analysis.technicalScore),
                  ScorePill(label: 'Harmony', value: analysis.harmonyScore),
                  ScorePill(
                    label: 'Fundamental',
                    value: analysis.fundamentalScore,
                  ),
                  ScorePill(label: 'Risk', value: analysis.riskScore),
                  ScorePill(label: 'Liquidity', value: analysis.liquidityScore),
                  ScorePill(
                    label: 'Invalidation',
                    value: analysis.invalidationLevel,
                  ),
                  ScorePill(label: 'Rule Version', value: analysis.ruleVersion),
                ],
              ),
              const SizedBox(height: 12),
              CompactRiskWarningList(
                items: analysis.riskWarnings
                    .map(
                      (warning) => CompactRiskWarningItem(
                        level: warning.level,
                        message: warning.message,
                      ),
                    )
                    .toList(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open analysis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(
            color: isError
                ? scheme.onErrorContainer
                : scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

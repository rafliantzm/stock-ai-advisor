import 'package:flutter/material.dart';

import '../../app/app_config.dart';
import '../../core/api/api_result.dart';
import '../../core/api/edge_function_client.dart';
import '../../core/models/market_data_models.dart';
import '../../design_system/ui_components.dart';
import 'data/market_context_repository.dart';

class MarketContextScreen extends StatefulWidget {
  const MarketContextScreen({super.key});

  @override
  State<MarketContextScreen> createState() => _MarketContextScreenState();
}

class _MarketContextScreenState extends State<MarketContextScreen> {
  late final EdgeFunctionClient _api;
  MarketContextResponse? _context;
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = EdgeFunctionClient(config: AppConfig.fromEnvironment());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _api.getMarketContext();
      setState(() => _context = result);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null && _context == null) {
      return AsyncStateView(
        title: 'Market context belum bisa dimuat',
        message:
            'Edge Function get-market-context belum tersedia atau sesi perlu diperbarui. $_error',
        action: FilledButton(onPressed: _load, child: const Text('Coba lagi')),
      );
    }

    final response = _context;
    if (response == null) {
      return AsyncStateView(
        title: 'Market context kosong',
        message: 'provider belum aktif atau sample data belum tersedia.',
        action: FilledButton(onPressed: _load, child: const Text('Muat ulang')),
      );
    }

    final market = response.marketContext;
    final warningItems = [
      ...market.riskWarnings.map(
        (warning) => CompactRiskWarningItem(
          level: warning.level,
          message: warning.message,
        ),
      ),
      if (market.isSample)
        const CompactRiskWarningItem(
          level: 'sample',
          message: 'Market context memakai sample data.',
        ),
      if (market.isStale)
        CompactRiskWarningItem(
          level: 'stale',
          message: market.stalenessWarning ?? 'Cache market context stale.',
        ),
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppSectionHeader(
            title: 'Market Context',
            subtitle:
                'Data dibaca melalui Edge Function get-market-context dengan Supabase Auth user.',
            trailing: FilledButton.icon(
              onPressed: _isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: '${market.marketCode} / ${market.indexSymbol}',
            subtitle:
                '${response.provider.providerName} - ${response.provider.providerStatus}',
            child: ResponsiveGrid(
              children: [
                MetricTile(label: 'Market Status', value: market.marketStatus),
                MetricTile(label: 'Index Trend', value: market.indexTrend),
                MetricTile(label: 'Risk Regime', value: market.riskRegime),
                MetricTile(label: 'Last Updated', value: market.lastUpdated),
                MetricTile(label: 'Data Quality', value: market.dataQuality),
                MetricTile(
                  label: 'Cache TTL',
                  value: response.cache.ttlSeconds == null
                      ? 'Menunggu data'
                      : '${response.cache.ttlSeconds}s',
                ),
              ],
            ),
          ),
          if (warningItems.isNotEmpty) ...[
            const SizedBox(height: 12),
            CompactRiskWarningList(items: warningItems),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'Market Data Contract',
            subtitle: response.meta.providerStatus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(label: response.meta.dataQuality),
                    StatusBadge(label: response.meta.providerName),
                    if (market.isStale) const StatusBadge(label: 'stale'),
                    if (market.isSample)
                      const StatusBadge(label: 'sample data'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(response.disclaimer),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _NewsCatalystPlaceholder(),
        ],
      ),
    );
  }
}

class _NewsCatalystPlaceholder extends StatelessWidget {
  const _NewsCatalystPlaceholder();

  @override
  Widget build(BuildContext context) {
    const repository = MarketContextRepository();
    final newsItems = repository.getPlaceholderNews();

    return SectionCard(
      title: 'News / Catalyst Placeholder',
      subtitle: 'News provider belum aktif.',
      child: Column(
        children: [
          for (final item in newsItems) ...[
            MetricTile(
              label: item.category,
              value: item.title,
              helper: item.sourceLabel,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

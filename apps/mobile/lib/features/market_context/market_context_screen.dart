import 'package:flutter/material.dart';

import '../../design_system/ui_components.dart';
import 'data/market_context_repository.dart';

class MarketContextScreen extends StatelessWidget {
  const MarketContextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const repository = MarketContextRepository();
    final contextData = repository.getSampleContext();
    final newsItems = repository.getPlaceholderNews();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppSectionHeader(
          title: 'Market Context',
          subtitle:
              'Sample market context - provider belum aktif. Struktur siap dihubungkan ke get-market-context.',
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'IHSG Placeholder',
          subtitle: contextData.sourceLabel,
          child: ResponsiveGrid(
            children: [
              MetricTile(
                label: 'market status',
                value: contextData.marketStatus,
              ),
              MetricTile(label: 'index trend', value: contextData.indexTrend),
              MetricTile(label: 'risk regime', value: contextData.riskRegime),
              MetricTile(label: 'last updated', value: contextData.lastUpdated),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RiskWarningBox(
          level: 'sample',
          message:
              'Panel ini belum memakai market data provider. Jangan anggap sebagai kondisi pasar real-time.',
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'News / Catalyst Placeholder',
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
        ),
      ],
    );
  }
}

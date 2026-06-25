import 'package:flutter/material.dart';

import '../../core/models/analysis_models.dart';
import '../../design_system/ui_components.dart';
import 'data/stock_analysis_repository.dart';
import 'widgets/risk_calculator_card.dart';

class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    const repository = StockAnalysisRepository();
    final analysis = repository.fromWatchlistItem(item);
    final modes = repository.buildModeScores(analysis);

    return Scaffold(
      appBar: AppBar(title: Text(analysis.symbolCode)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppSectionHeader(
            title: '${analysis.symbolCode} Analysis',
            subtitle:
                '${analysis.companyName} - ${analysis.sourceLabel}. Market data P2 tersedia sebagai delayed provider context.',
            trailing: StatusBadge(label: analysis.candidateLabel),
          ),
          const SizedBox(height: 16),
          _PriceSnapshot(analysis: analysis),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Insight Utama',
            subtitle: 'Ringkasan edukatif berbasis latest_score',
            child: Text(repository.buildMainInsight(analysis)),
          ),
          const SizedBox(height: 12),
          _MultiModeAnalyzer(modes: modes),
          const SizedBox(height: 12),
          _TechnicalSignals(analysis: analysis),
          const SizedBox(height: 12),
          _FundamentalSnapshot(analysis: analysis),
          const SizedBox(height: 12),
          _RiskAnalysis(analysis: analysis),
          const SizedBox(height: 12),
          _StrategyExplanation(analysis: analysis),
          const SizedBox(height: 12),
          RiskCalculatorCard(
            defaultInvalidationLevel: analysis.invalidationLevel,
          ),
          const SizedBox(height: 12),
          const _NewsCatalystPanel(),
        ],
      ),
    );
  }
}

class _PriceSnapshot extends StatelessWidget {
  const _PriceSnapshot({required this.analysis});

  final StockAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Price Snapshot',
      subtitle:
          'P2 delayed provider context - price detail per symbol masih tahap integrasi',
      child: ResponsiveGrid(
        children: [
          const MetricTile(label: 'market price', value: 'Data belum cukup'),
          MetricTile(label: 'Final', value: analysis.overallScore),
          MetricTile(label: 'Invalidation', value: analysis.invalidationLevel),
        ],
      ),
    );
  }
}

class _MultiModeAnalyzer extends StatelessWidget {
  const _MultiModeAnalyzer({required this.modes});

  final List<ModeScore> modes;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Multi-Mode Analyzer',
      subtitle: 'Mode analisis P1 memakai score adapter, bukan instruksi.',
      child: Column(
        children: [
          for (final mode in modes) ...[
            _ModeScoreTile(mode: mode),
            if (mode != modes.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ModeScoreTile extends StatelessWidget {
  const _ModeScoreTile({required this.mode});

  final ModeScore mode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mode.mode,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ScorePill(label: 'Mode Score', value: mode.modeScore),
                const SizedBox(width: 8),
                StatusBadge(label: mode.label),
              ],
            ),
            const SizedBox(height: 8),
            Text(mode.reason),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ScorePill(label: 'Invalidation', value: mode.invalidationLevel),
                ScorePill(label: 'risk warning', value: mode.riskWarning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalSignals extends StatelessWidget {
  const _TechnicalSignals({required this.analysis});

  final StockAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Technical Signals',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ScorePill(label: 'Technical', value: analysis.technicalScore),
          ScorePill(label: 'Harmony', value: analysis.harmonyScore),
          ScorePill(label: 'technical setup', value: analysis.technicalSetup),
          const ScorePill(label: 'confirmation', value: 'wait confirmation'),
        ],
      ),
    );
  }
}

class _FundamentalSnapshot extends StatelessWidget {
  const _FundamentalSnapshot({required this.analysis});

  final StockAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Fundamental Snapshot',
      subtitle: 'Belum memakai financial provider P1',
      child: ResponsiveGrid(
        children: [
          MetricTile(label: 'Fundamental', value: analysis.fundamentalScore),
          const MetricTile(label: 'growth context', value: 'Data belum cukup'),
          const MetricTile(
            label: 'valuation context',
            value: 'Data belum cukup',
          ),
        ],
      ),
    );
  }
}

class _RiskAnalysis extends StatelessWidget {
  const _RiskAnalysis({required this.analysis});

  final StockAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Risk Analysis',
      child: Column(
        children: [
          ResponsiveGrid(
            children: [
              MetricTile(label: 'Risk', value: analysis.riskScore),
              MetricTile(label: 'Liquidity', value: analysis.liquidityScore),
              MetricTile(
                label: 'Invalidation',
                value: analysis.invalidationLevel,
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final warning in analysis.riskWarnings) ...[
            RiskWarningBox(level: warning.level, message: warning.message),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StrategyExplanation extends StatelessWidget {
  const _StrategyExplanation({required this.analysis});

  final StockAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Strategy Explanation',
      subtitle: 'AI/RAG belum aktif',
      child: Text(
        'P1 menampilkan penjelasan deterministik dari score backend. ${analysis.ruleVersionLabel} menjadi sumber utama, sementara AI/RAG akan ditambahkan sebagai explanation layer pada tahap berikutnya.',
      ),
    );
  }
}

class _NewsCatalystPanel extends StatelessWidget {
  const _NewsCatalystPanel();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'News / Catalyst Placeholder',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricTile(label: 'latest news', value: 'News provider belum aktif.'),
          SizedBox(height: 10),
          MetricTile(
            label: 'dividend/corporate action',
            value: 'News provider belum aktif.',
          ),
          SizedBox(height: 10),
          MetricTile(
            label: 'expansion catalyst',
            value: 'News provider belum aktif.',
          ),
        ],
      ),
    );
  }
}

import '../utils/map_utils.dart';

class RiskWarning {
  const RiskWarning({required this.level, required this.message, this.metric});

  factory RiskWarning.fromObject(Object? value) {
    final map = asStringMap(value);
    if (map.isEmpty) {
      return RiskWarning(level: 'medium', message: value?.toString() ?? '-');
    }
    return RiskWarning(
      level: map['level']?.toString() ?? 'medium',
      message: map['message']?.toString() ?? 'needs_more_data',
      metric: map['metric']?.toString(),
    );
  }

  final String level;
  final String message;
  final String? metric;
}

class ModeScore {
  const ModeScore({
    required this.mode,
    required this.modeScore,
    required this.label,
    required this.reason,
    required this.invalidationLevel,
    required this.riskWarning,
  });

  final String mode;
  final num modeScore;
  final String label;
  final String reason;
  final Object? invalidationLevel;
  final String riskWarning;
}

class StockAnalysis {
  const StockAnalysis({
    required this.symbolCode,
    required this.companyName,
    required this.candidateLabel,
    required this.overallScore,
    required this.technicalScore,
    required this.harmonyScore,
    required this.fundamentalScore,
    required this.riskScore,
    required this.liquidityScore,
    required this.invalidationLevel,
    required this.riskWarnings,
    required this.ruleVersion,
    required this.technicalSetup,
    required this.sourceLabel,
  });

  final String symbolCode;
  final String companyName;
  final String candidateLabel;
  final num? overallScore;
  final num? technicalScore;
  final num? harmonyScore;
  final num? fundamentalScore;
  final num? riskScore;
  final num? liquidityScore;
  final Object? invalidationLevel;
  final List<RiskWarning> riskWarnings;
  final String ruleVersion;
  final String technicalSetup;
  final String sourceLabel;

  factory StockAnalysis.fromWatchlistItem(Map<String, dynamic> item) {
    final symbol = asStringMap(item['symbols']);
    final latestScore = asStringMap(item['latest_score']);
    final warnings = _riskWarnings(latestScore);
    final finalScore =
        _num(latestScore['overall_score']) ?? _num(latestScore['final_score']);

    return StockAnalysis(
      symbolCode:
          item['symbol_code']?.toString() ??
          symbol['symbol_code']?.toString() ??
          '-',
      companyName: symbol['company_name']?.toString() ?? 'Company data pending',
      candidateLabel:
          latestScore['candidate_label']?.toString() ?? 'needs_more_data',
      overallScore: finalScore,
      technicalScore: _num(latestScore['technical_score']),
      harmonyScore: _num(latestScore['harmony_score']),
      fundamentalScore: _num(latestScore['fundamental_score']),
      riskScore: _num(latestScore['risk_score']),
      liquidityScore: _num(latestScore['liquidity_score']),
      invalidationLevel: latestScore['invalidation_level'] ?? 'needs_more_data',
      riskWarnings: warnings.isEmpty
          ? const [
              RiskWarning(
                level: 'info',
                message: 'risk warning menunggu data scoring terbaru',
              ),
            ]
          : warnings,
      ruleVersion:
          latestScore['rule_version']?.toString() ??
          latestScore['scoring_rule_version']?.toString() ??
          'p0_dummy_scoring_v1',
      technicalSetup:
          latestScore['technical_setup']?.toString() ?? 'needs_more_data',
      sourceLabel: latestScore.isEmpty
          ? 'Sample analysis - latest_score belum tersedia'
          : 'P1 analysis adapter - berbasis latest_score P0',
    );
  }

  bool get hasScore => overallScore != null;

  static List<RiskWarning> _riskWarnings(Map<String, dynamic> latestScore) {
    final raw = latestScore['risk_warnings'] ?? latestScore['risk_warning'];
    if (raw is List) return raw.map(RiskWarning.fromObject).toList();
    if (raw != null) return [RiskWarning.fromObject(raw)];
    return const [];
  }

  static num? _num(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}

class MarketContext {
  const MarketContext({
    required this.marketStatus,
    required this.indexTrend,
    required this.riskRegime,
    required this.lastUpdated,
    required this.sourceLabel,
  });

  final String marketStatus;
  final String indexTrend;
  final String riskRegime;
  final String lastUpdated;
  final String sourceLabel;
}

class DailyCandidate {
  const DailyCandidate({
    required this.symbolCode,
    required this.companyName,
    required this.label,
    required this.score,
  });

  final String symbolCode;
  final String companyName;
  final String label;
  final Object? score;
}

class NewsItem {
  const NewsItem({
    required this.title,
    required this.category,
    required this.sourceLabel,
  });

  final String title;
  final String category;
  final String sourceLabel;
}

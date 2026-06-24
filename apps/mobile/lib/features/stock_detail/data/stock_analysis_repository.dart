import '../../../core/models/analysis_models.dart';

class StockAnalysisRepository {
  const StockAnalysisRepository();

  StockAnalysis fromWatchlistItem(Map<String, dynamic> item) {
    return StockAnalysis.fromWatchlistItem(item);
  }

  List<ModeScore> buildModeScores(StockAnalysis analysis) {
    final technical = analysis.technicalScore ?? 50;
    final harmony = analysis.harmonyScore ?? 50;
    final fundamental = analysis.fundamentalScore ?? 50;
    final risk = analysis.riskScore ?? 50;
    final liquidity = analysis.liquidityScore ?? 50;

    return [
      ModeScore(
        mode: 'Day Trade',
        modeScore: _average([technical, liquidity, risk]),
        label: 'wait confirmation',
        reason:
            'Membutuhkan konfirmasi intraday dan volume. Data P1 masih berbasis latest_score, bukan market real-time.',
        invalidationLevel: analysis.invalidationLevel,
        riskWarning: _riskLabel(risk),
      ),
      ModeScore(
        mode: 'Swing',
        modeScore: _average([technical, harmony, risk]),
        label: 'layak dianalisis',
        reason:
            'Technical setup dan harmony score dipakai untuk memetakan kandidat observasi multi-hari.',
        invalidationLevel: analysis.invalidationLevel,
        riskWarning: _riskLabel(risk),
      ),
      ModeScore(
        mode: 'Hold Dividend',
        modeScore: _average([fundamental, risk, liquidity]),
        label: 'needs_more_data',
        reason:
            'Mode dividen membutuhkan data dividend yield dan corporate action yang belum aktif di P1.',
        invalidationLevel: analysis.invalidationLevel,
        riskWarning: 'Pantau kualitas fundamental dan likuiditas.',
      ),
      ModeScore(
        mode: 'Potential Bagger',
        modeScore: _average([fundamental, technical, harmony]),
        label: 'risk controlled candidate',
        reason:
            'Mode ini hanya menandai kandidat riset lanjutan. Validasi growth dan valuation belum real-time.',
        invalidationLevel: analysis.invalidationLevel,
        riskWarning: 'Risiko volatilitas tinggi, gunakan invalidation level.',
      ),
    ];
  }

  String buildMainInsight(StockAnalysis analysis) {
    if (!analysis.hasScore) {
      return 'latest_score belum tersedia. Jalankan evaluate-watchlist untuk menampilkan score dummy P0.';
    }
    return '${analysis.symbolCode} masuk kategori ${analysis.candidateLabel.replaceAll('_', ' ')}. Gunakan score sebagai bahan observasi, bukan instruksi transaksi.';
  }

  static num _average(List<num> values) {
    final total = values.fold<num>(0, (sum, value) => sum + value);
    return (total / values.length).round();
  }

  static String _riskLabel(num riskScore) {
    if (riskScore >= 70) return 'risk controlled candidate';
    if (riskScore >= 50) return 'risk warning sedang';
    return 'risk warning tinggi';
  }
}

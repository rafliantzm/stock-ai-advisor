import '../../../core/models/analysis_models.dart';
import '../../../core/utils/map_utils.dart';

class ScreenerRepository {
  const ScreenerRepository();

  static const p1Categories = [
    'Technical Breakout Candidate',
    'Swing Candidate',
    'Dividend Candidate',
    'Growth Expansion Candidate',
    'Top Volume Candidate',
    'Top Value Candidate',
    'Risk-Controlled Candidate',
  ];

  List<DailyCandidate> dailyCandidatesFromResults(
    List<Map<String, dynamic>> results,
  ) {
    return results.map((result) {
      final symbol = asStringMap(result['symbol']);
      final scores = asStringMap(result['scores']);
      return DailyCandidate(
        symbolCode: symbol['symbol_code']?.toString() ?? '-',
        companyName: symbol['company_name']?.toString() ?? 'Company pending',
        label: result['candidate_label']?.toString() ?? 'watchlist candidate',
        score: scores['final_score'],
      );
    }).toList();
  }
}

import '../../../core/models/analysis_models.dart';

class MarketContextRepository {
  const MarketContextRepository();

  MarketContext getSampleContext() {
    return const MarketContext(
      marketStatus: 'Sample status',
      indexTrend: 'Index trend placeholder',
      riskRegime: 'Neutral sample regime',
      lastUpdated: 'Sample market context - provider belum aktif',
      sourceLabel: 'Sample market context - provider belum aktif',
    );
  }

  List<NewsItem> getPlaceholderNews() {
    return const [
      NewsItem(
        title: 'News provider belum aktif.',
        category: 'latest news',
        sourceLabel: 'empty_state',
      ),
      NewsItem(
        title: 'Corporate action provider belum aktif.',
        category: 'dividend/corporate action',
        sourceLabel: 'empty_state',
      ),
      NewsItem(
        title: 'Expansion catalyst provider belum aktif.',
        category: 'expansion catalyst',
        sourceLabel: 'empty_state',
      ),
    ];
  }
}

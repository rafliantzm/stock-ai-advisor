import '../utils/map_utils.dart';
import 'analysis_models.dart';

class ProviderInfo {
  const ProviderInfo({
    required this.providerName,
    required this.providerStatus,
    this.providerType,
    this.status,
  });

  factory ProviderInfo.fromMap(Map<String, dynamic> map) {
    return ProviderInfo(
      providerName: map['provider_name']?.toString() ?? 'sample_provider',
      providerStatus:
          map['provider_status']?.toString() ??
          map['status']?.toString() ??
          'provider belum aktif',
      providerType: map['provider_type']?.toString(),
      status: map['status']?.toString(),
    );
  }

  final String providerName;
  final String providerStatus;
  final String? providerType;
  final String? status;
}

class SyncedSymbol {
  const SyncedSymbol({
    required this.symbolCode,
    required this.companyName,
    this.symbolId,
  });

  factory SyncedSymbol.fromMap(Map<String, dynamic> map) {
    return SyncedSymbol(
      symbolId: map['symbol_id']?.toString(),
      symbolCode: map['symbol_code']?.toString() ?? '-',
      companyName: map['company_name']?.toString() ?? 'Company pending',
    );
  }

  final String? symbolId;
  final String symbolCode;
  final String companyName;
}

class MarketContextData {
  const MarketContextData({
    required this.marketCode,
    required this.indexSymbol,
    required this.marketStatus,
    required this.indexTrend,
    required this.riskRegime,
    required this.dataQuality,
    required this.isStale,
    required this.riskWarnings,
    this.indexLast,
    this.indexChange,
    this.indexChangePercent,
    this.lastUpdated,
    this.stalenessWarning,
  });

  factory MarketContextData.fromMap(Map<String, dynamic> map) {
    return MarketContextData(
      marketCode: map['market_code']?.toString() ?? 'IDX',
      indexSymbol: map['index_symbol']?.toString() ?? 'IHSG',
      marketStatus: map['market_status']?.toString() ?? 'provider belum aktif',
      indexTrend: map['index_trend']?.toString() ?? 'needs_more_data',
      riskRegime: map['risk_regime']?.toString() ?? 'needs_more_data',
      indexLast: map['index_last'],
      indexChange: map['index_change'],
      indexChangePercent: map['index_change_percent'],
      lastUpdated: map['last_updated']?.toString(),
      dataQuality: map['data_quality']?.toString() ?? 'sample',
      isStale: map['is_stale'] == true,
      stalenessWarning: map['staleness_warning']?.toString(),
      riskWarnings: (map['risk_warning'] is List)
          ? (map['risk_warning'] as List).map(RiskWarning.fromObject).toList()
          : const [],
    );
  }

  final String marketCode;
  final String indexSymbol;
  final String marketStatus;
  final String indexTrend;
  final String riskRegime;
  final Object? indexLast;
  final Object? indexChange;
  final Object? indexChangePercent;
  final String? lastUpdated;
  final String dataQuality;
  final bool isStale;
  final String? stalenessWarning;
  final List<RiskWarning> riskWarnings;

  bool get isSample => dataQuality == 'sample';
}

class MarketCacheInfo {
  const MarketCacheInfo({
    required this.allowStale,
    required this.staleBlocked,
    required this.ttlSeconds,
  });

  factory MarketCacheInfo.fromMap(Map<String, dynamic> map) {
    return MarketCacheInfo(
      allowStale: map['allow_stale'] == true,
      staleBlocked: map['stale_blocked'] == true,
      ttlSeconds: _intFromObject(map['ttl_seconds']),
    );
  }

  final bool allowStale;
  final bool staleBlocked;
  final int? ttlSeconds;

  static int? _intFromObject(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class MarketDataMeta {
  const MarketDataMeta({
    required this.dataQuality,
    required this.providerName,
    required this.providerStatus,
    this.ruleVersion,
  });

  factory MarketDataMeta.fromMap(Map<String, dynamic> map) {
    return MarketDataMeta(
      dataQuality: map['data_quality']?.toString() ?? 'sample',
      providerName: map['provider_name']?.toString() ?? 'sample_provider',
      providerStatus:
          map['provider_status']?.toString() ?? 'provider belum aktif',
      ruleVersion: map['rule_version']?.toString(),
    );
  }

  final String dataQuality;
  final String providerName;
  final String providerStatus;
  final String? ruleVersion;
}

class MarketContextResponse {
  const MarketContextResponse({
    required this.marketContext,
    required this.provider,
    required this.cache,
    required this.meta,
    required this.disclaimer,
  });

  factory MarketContextResponse.fromResult(
    Map<String, dynamic> data,
    Map<String, dynamic> meta,
  ) {
    return MarketContextResponse(
      marketContext: MarketContextData.fromMap(
        asStringMap(data['market_context']),
      ),
      provider: ProviderInfo.fromMap(asStringMap(data['provider'])),
      cache: MarketCacheInfo.fromMap(asStringMap(data['cache'])),
      meta: MarketDataMeta.fromMap(meta),
      disclaimer:
          data['disclaimer']?.toString() ??
          'Data market context bersifat edukatif.',
    );
  }

  final MarketContextData marketContext;
  final ProviderInfo provider;
  final MarketCacheInfo cache;
  final MarketDataMeta meta;
  final String disclaimer;
}

class SyncMarketCandidatesResponse {
  const SyncMarketCandidatesResponse({
    required this.syncRunId,
    required this.provider,
    required this.syncedSymbols,
    required this.syncedCount,
    required this.rowsInserted,
    required this.dataQuality,
    required this.providerStatus,
    required this.riskWarnings,
    required this.meta,
  });

  factory SyncMarketCandidatesResponse.fromResult(
    Map<String, dynamic> data,
    Map<String, dynamic> meta,
  ) {
    return SyncMarketCandidatesResponse(
      syncRunId: data['sync_run_id']?.toString(),
      provider: ProviderInfo.fromMap(asStringMap(data['provider'])),
      syncedSymbols: asMapList(
        data['synced_symbols'],
      ).map(SyncedSymbol.fromMap).toList(),
      syncedCount: _intFromObject(data['synced_count']) ?? 0,
      rowsInserted: _intFromObject(data['rows_inserted']) ?? 0,
      dataQuality: data['data_quality']?.toString() ?? 'sample',
      providerStatus:
          data['provider_status']?.toString() ?? 'provider belum aktif',
      riskWarnings: (data['risk_warning'] is List)
          ? (data['risk_warning'] as List).map(RiskWarning.fromObject).toList()
          : const [],
      meta: MarketDataMeta.fromMap(meta),
    );
  }

  final String? syncRunId;
  final ProviderInfo provider;
  final List<SyncedSymbol> syncedSymbols;
  final int syncedCount;
  final int rowsInserted;
  final String dataQuality;
  final String providerStatus;
  final List<RiskWarning> riskWarnings;
  final MarketDataMeta meta;

  static int? _intFromObject(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

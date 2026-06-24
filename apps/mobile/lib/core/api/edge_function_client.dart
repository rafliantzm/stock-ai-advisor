import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app_config.dart';
import '../models/market_data_models.dart';
import 'api_result.dart';

class EdgeFunctionClient {
  EdgeFunctionClient({required this.config, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final AppConfig config;
  final http.Client _httpClient;

  Future<ApiResult> post(
    String functionName, {
    Map<String, dynamic> body = const {},
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('unauthorized', 'Sesi login tidak tersedia.');
    }

    final response = await _httpClient.post(
      config.edgeFunctionUri(functionName),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'apikey': config.supabaseAnonKey,
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (decoded['ok'] == true) {
      return ApiResult(
        data: Map<String, dynamic>.from(decoded['data'] as Map? ?? {}),
        meta: Map<String, dynamic>.from(decoded['meta'] as Map? ?? {}),
      );
    }

    final error = Map<String, dynamic>.from(decoded['error'] as Map? ?? {});
    throw ApiException(
      error['code']?.toString() ?? 'database_error',
      error['message']?.toString() ?? 'Terjadi kesalahan.',
      error['details'],
    );
  }

  Future<MarketContextResponse> getMarketContext({
    String marketCode = 'IDX',
    String indexSymbol = 'IHSG',
    bool allowStale = true,
    bool createSampleIfMissing = true,
  }) async {
    final result = await post(
      'get-market-context',
      body: {
        'market_code': marketCode,
        'index_symbol': indexSymbol,
        'allow_stale': allowStale,
        'create_sample_if_missing': createSampleIfMissing,
      },
    );
    return MarketContextResponse.fromResult(result.data, result.meta);
  }

  Future<SyncMarketCandidatesResponse> syncMarketCandidates({
    List<String> symbolCodes = const [],
    int limit = 10,
    bool includeMarketContext = true,
  }) async {
    final result = await post(
      'sync-market-candidates',
      body: {
        'symbol_codes': symbolCodes,
        'limit': limit,
        'include_market_context': includeMarketContext,
        'run_mode': 'on_demand',
      },
    );
    return SyncMarketCandidatesResponse.fromResult(result.data, result.meta);
  }
}

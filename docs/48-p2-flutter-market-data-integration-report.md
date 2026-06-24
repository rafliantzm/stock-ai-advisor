# 48. P2 Flutter Market Data Integration Report

## Scope

Branch:

- `p2-flutter-market-data-integration`

Tujuan:

- Menghubungkan Flutter P1 yang sudah stabil ke Edge Functions P2 awal.
- Endpoint yang diintegrasikan:
  - `sync-market-candidates`
  - `get-market-context`

Tidak termasuk pada tahap ini:

- market data provider production;
- OHLCV real;
- chart kompleks;
- AI/RAG;
- perubahan Edge Functions P0;
- fitur transaksi saham.

## Endpoints Integrated

### POST `/functions/v1/get-market-context`

Dipakai oleh:

- `MarketContextScreen`

Request body:

```json
{
  "market_code": "IDX",
  "index_symbol": "IHSG",
  "allow_stale": true,
  "create_sample_if_missing": true
}
```

Flutter adapter:

- `EdgeFunctionClient.getMarketContext`
- `MarketContextResponse`
- `MarketContextData`
- `ProviderInfo`
- `MarketCacheInfo`
- `MarketDataMeta`

### POST `/functions/v1/sync-market-candidates`

Dipakai oleh:

- `ScreenerScreen`

Request body:

```json
{
  "symbol_codes": [],
  "limit": 10,
  "include_market_context": true,
  "run_mode": "on_demand"
}
```

Jika hasil screener tersedia, Flutter mengirim daftar symbol dari hasil screener terakhir. Jika belum ada hasil screener, backend boleh memakai sample symbols aktif sesuai limit.

Flutter adapter:

- `EdgeFunctionClient.syncMarketCandidates`
- `SyncMarketCandidatesResponse`
- `SyncedSymbol`
- `RiskWarning`
- `ProviderInfo`
- `MarketDataMeta`

## Screens Updated

### MarketContextScreen

Sebelumnya:

- static placeholder dari repository lokal.

Sekarang:

- memanggil `get-market-context`;
- menampilkan loading state;
- menampilkan error state;
- menampilkan empty state;
- menampilkan sample-data state;
- menampilkan stale state;
- menampilkan risk warning compact;
- tetap menampilkan News/Catalyst placeholder karena news provider belum aktif.

Label aman yang digunakan:

- `sample data`
- `provider belum aktif`
- `risk warning`
- `needs_more_data`

### ScreenerScreen

Ditambahkan:

- card `P2 Market Data Sync`;
- tombol `Sync`;
- pemanggilan `sync-market-candidates`;
- tampilan `synced symbols`;
- tampilan `data_quality`;
- tampilan `provider_status`;
- loading/error/sample-data state.

Screener P1 tetap bisa berjalan seperti sebelumnya.

## Auth And Security Handling

- Flutter tetap memakai Supabase Auth session.
- `EdgeFunctionClient` mengambil `session.accessToken`.
- Request Edge Function memakai header:

```text
Authorization: Bearer <user_jwt>
apikey: <SUPABASE_ANON_KEY>
Content-Type: application/json
```

- Flutter tidak menyimpan backend secret.
- Flutter tidak menyimpan provider credential.
- Provider eksternal tetap harus diakses dari Edge Functions.
- Response UI tidak menampilkan credential backend.

## Typed Models / Adapters

File:

- `apps/mobile/lib/core/models/market_data_models.dart`

Models:

- `ProviderInfo`
- `SyncedSymbol`
- `MarketContextData`
- `MarketCacheInfo`
- `MarketDataMeta`
- `MarketContextResponse`
- `SyncMarketCandidatesResponse`

Model existing yang dipakai ulang:

- `RiskWarning`

## Known Limitations

- Market data provider production belum aktif.
- Data yang tampil masih bisa berupa `sample data`.
- OHLCV belum aktif.
- Technical indicators real belum dihitung dari provider OHLCV.
- Chart Lab masih preview.
- News provider belum aktif.
- AI/RAG belum aktif.
- Scoring P1 masih `p0_dummy_scoring_v1`.
- Tidak ada fitur transaksi saham.

## Test Results

Command:

```powershell
cd D:\WEB\stock-ai-advisor\apps\mobile
dart format lib test
flutter analyze
flutter test
```

Result:

- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.

Widget/model tests:

- Missing Supabase config state: Pass.
- Smart Alert default scenario: Pass.
- Missing score copy `Menunggu data`: Pass.
- Market context adapter reads P2 response contract: Pass.

## Next Step

1. Deploy `sync-market-candidates` dan `get-market-context`.
2. Jalankan migration `0005_create_market_data_schema.sql` jika belum.
3. Smoke test endpoint P2 dari Supabase Dashboard atau HTTP client.
4. Jalankan Flutter Web dan test:
   - Market Context refresh;
   - Screener sync market candidates;
   - stale/sample data display.
5. Setelah stabil, lanjut endpoint quote per saham dan Chart Lab OHLCV.
